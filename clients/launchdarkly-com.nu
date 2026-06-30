# Auto-generated client for LaunchDarkly REST API v5.3.0
# Source: https://api.apis.guru/v2/specs/launchdarkly.com/5.3.0/swagger.json
# Auth: --token flag or $env.LAUNCHDARKLY_REST_API_TOKEN

const BASE_URL = "https://app.launchdarkly.com/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LAUNCHDARKLY_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://app.launchdarkly.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def kind-completer [] { ["google-pubsub" "kinesis" "mparticle" "segment"] }
def kind-completer-1 [] { ["approve" "comment" "decline"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "root get" } } | get name | first)
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

# You can issue a GET request to the root resource to find all of the resource categories supported by the API.
#
# GET /
# operationId: getRoot
export def "root get" [
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
  let full_url = (build-url $base "/" $auth.query)
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

# Returns a list of relay proxy configurations in the account.
#
# GET /account/relay-auto-configs
# operationId: getRelayProxyConfigs
export def "account-relay-auto-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<_creator: record, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/relay-auto-configs" $auth.query)
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

# Create a new relay proxy config.
#
# POST /account/relay-auto-configs
# operationId: postRelayAutoConfig
# --policy item shape: {actions?: list<string>, effect?: string, notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
export def "account-relay-auto-configs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human-friendly name for the relay proxy configuration (e.g. My relay proxy config)
  --policy: list # item shape: {actions?: list<string>, effect?: string, notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
]: any -> record<_creator: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _id: string, creationDate: int, displayKey: string, fullKey: string, lastModified: int, name: string, policy: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/relay-auto-configs" $auth.query)
  let req_body = {"name": $name, "policy": $policy} | compact
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

# Delete a relay proxy configuration by ID.
#
# DELETE /account/relay-auto-configs/{id}
# operationId: deleteRelayProxyConfig
export def "account-relay-auto-configs delete-proxy" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/relay-auto-configs/{id}") $auth.query)
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

# Get a single relay proxy configuration by ID.
#
# GET /account/relay-auto-configs/{id}
# operationId: getRelayProxyConfig
export def "account-relay-auto-configs get-proxy" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/relay-auto-configs/{id}") $auth.query)
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

# Modify a relay proxy configuration by ID.
#
# PATCH /account/relay-auto-configs/{id}
# operationId: patchRelayProxyConfig
export def "account-relay-auto-configs update-proxy" [
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
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/relay-auto-configs/{id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Reset a relay proxy configuration's secret key with an optional expiry time for the old key.
#
# POST /account/relay-auto-configs/{id}/reset
# operationId: resetRelayProxyConfig
export def "account-relay-auto-configs-reset reset-proxy" [
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
  --expiry: int # An expiration time for the old relay proxy configuration key, expressed as a Unix epoch time in milliseconds. By default, the relay proxy configuration will expire immediately (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/relay-auto-configs/{id}/reset") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"expiry": $expiry} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get a list of all audit log entries. The query parameters allow you to restrict the returned results by date ranges, resource specifiers, or a full-text search query.
#
# GET /auditlog
# operationId: getAuditLogEntries
export def "auditlog get-audit-log-entries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have before this timestamp. (format: int64)
  --after: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have occurred after this timestamp. (format: int64)
  --q: string # Text to search for. You can search for the full or partial name of the resource involved or full or partial email address of the member who made the change.
  --limit: float # A limit on the number of audit log entries to be returned, between 1 and 20.
  --spec: string # A resource specifier, allowing you to filter audit log listings by resource.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, comment: string, date: int, description: string, kind: string, member: record, name: string, shortDescription: string, target: record, title: string, titleVerb: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "spec" $spec "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/auditlog" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"before": $before, "after": $after, "q": $q, "limit": $limit, "spec": $spec} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use this endpoint to fetch a single audit log entry by its resouce ID.
#
# GET /auditlog/{resourceId}
# operationId: getAuditLogEntry
export def "auditlog get-audit-log-entry" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, comment: string, date: int, description: string, kind: string, member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, name: string, shortDescription: string, target: record<_links: record<next: record, self: record>, name: string, resources: list<string>>, title: string, titleVerb: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/auditlog/{resource_id}") $auth.query)
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

# Returns a list of all data export destinations.
#
# GET /destinations
# operationId: getDestinations
export def "destinations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, config: record, kind: string, name: string, on: bool, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/destinations" $auth.query)
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

# Create a new data export destination
#
# POST /destinations/{projectKey}/{environmentKey}
# operationId: postDestination
export def "destinations create" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: record # destination-specific configuration. (e.g. {project: cool-project, topic: test})
  kind: string@kind-completer # The data export destination type. Available choices are kinesis, google-pubsub, mparticle, or segment. (e.g. google-pubsub)
  name: string # A human-readable name for your data export destination. (e.g. Example Google Pub/Sub Destination)
  --on: oneof<nothing, bool> # Whether the data export destination is on or not. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/destinations/{project_key}/{environment_key}") $auth.query)
  let req_body = {"config": $config, "kind": $kind, "name": $name, "on": $on} | compact
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

# Get a single data export destination by ID
#
# DELETE /destinations/{projectKey}/{environmentKey}/{destinationId}
# operationId: deleteDestination
export def "destinations delete" [
  project_key: string
  environment_key: string
  destination_id: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($destination_id | is-empty) { error make --unspanned { msg: "path parameter 'destinationId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), destination_id: (encode-path-segment $destination_id)} | format pattern "/destinations/{project_key}/{environment_key}/{destination_id}") $auth.query)
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

# Get a single data export destination by ID
#
# GET /destinations/{projectKey}/{environmentKey}/{destinationId}
# operationId: getDestination
export def "destinations get-by-project-key-environment-key-destination-id" [
  project_key: string
  environment_key: string
  destination_id: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($destination_id | is-empty) { error make --unspanned { msg: "path parameter 'destinationId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), destination_id: (encode-path-segment $destination_id)} | format pattern "/destinations/{project_key}/{environment_key}/{destination_id}") $auth.query)
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

# Perform a partial update to a data export destination.
#
# PATCH /destinations/{projectKey}/{environmentKey}/{destinationId}
# operationId: patchDestination
export def "destinations update" [
  project_key: string
  environment_key: string
  destination_id: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($destination_id | is-empty) { error make --unspanned { msg: "path parameter 'destinationId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), destination_id: (encode-path-segment $destination_id)} | format pattern "/destinations/{project_key}/{environment_key}/{destination_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get the status for a particular feature flag across environments
#
# GET /flag-status/{projectKey}/{featureFlagKey}
# operationId: getFeatureFlagStatusAcrossEnvironments
export def "flag-status get-feature-across-environments" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, environments: record, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flag-status/{project_key}/{feature_flag_key}") $auth.query)
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

# Get a list of statuses for all feature flags. The status includes the last time the feature flag was requested, as well as the state of the flag.
#
# GET /flag-statuses/{projectKey}/{environmentKey}
# operationId: getFeatureFlagStatuses
export def "flag-statuses get-feature" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, default: record, lastRequested: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/flag-statuses/{project_key}/{environment_key}") $auth.query)
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

# Get the status for a particular feature flag.
#
# GET /flag-statuses/{projectKey}/{environmentKey}/{featureFlagKey}
# operationId: getFeatureFlagStatus
export def "flag-statuses get-feature-status" [
  project_key: string
  environment_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, default: record, lastRequested: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flag-statuses/{project_key}/{environment_key}/{feature_flag_key}") $auth.query)
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

# Get a list of all features in the given project.
#
# GET /flags/{projectKey}
# operationId: getFeatureFlags
export def "flags list" [
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-env: list<string> # By default, each feature will include configurations for each environment. You can filter environments with the env query parameter. For example, setting env=["production"] will restrict the returned configurations to just your production environment.
  --summary: oneof<nothing, bool> # By default in api version >= 1, flags will _not_ include their list of prerequisites, targets or rules. Set summary=0 to include these fields for each flag returned.
  --archived: oneof<nothing, bool> # When set to 1, only archived flags will be included in the list of flags returned. By default, archived flags are not included in the list of flags.
  --limit: float # The number of objects to return. Defaults to -1, which returns everything.
  --offset: float # Where to start in the list. This is for use with pagination. For example, an offset of 10 would skip the first 10 items and then return the next limit items.
  --filter: string # A comma-separated list of filters. Each filter is of the form field:value.
  --qp-sort: string # A comma-separated list of fields to sort by. A field prefixed by a - will be sorted in descending order.
  --tag: string # Filter by tag. A tag can be used to group flags across projects.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_links: record, _maintainer: record, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record, creationDate: int, customProperties: record, defaults: record, description: string, environments: record, goalIds: list, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list, temporary: bool, variations: list>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  let qp = [(serialize-qp "env" $qp_env "multi") (serialize-qp "summary" $summary "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key)} | format pattern "/flags/{project_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"env": $qp_env, "summary": $summary, "archived": $archived, "limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort, "tag": $tag} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new feature flag.
#
# POST /flags/{projectKey}
# operationId: postFeatureFlag
# --clientSideAvailability shape: {usingEnvironmentId?: bool, usingMobileKey?: bool}
# --defaults shape: {offVariation: int, onVariation: int}
# --variations item shape: {_id?: string, description?: string, name?: string, value: record}
export def "flags create-feature" [
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clone: string # The key of the feature flag to be cloned. The key identifies the flag in your code. For example, setting clone=flagKey will copy the full targeting configuration for all environments (including on/off state) from the original flag to the new flag.
  --client-side-availability: record # shape: {usingEnvironmentId?: bool, usingMobileKey?: bool}
  --defaults: record # Default values to be used when a new environment is created. — shape: {offVariation: int, onVariation: int}
  --description: string # A description of the feature flag. (e.g. This flag controls whether test feature is turned on or not.)
  --include-in-snippet: oneof<nothing, bool> # Whether or not this flag should be made available to the client-side JavaScript SDK.
  key: string # A unique key that will be used to reference the flag in your code. (e.g. new-test-flag)
  name: string # A human-friendly name for the feature flag. Remember to note if this flag is intended to be temporary or permanent. (e.g. new test flag)
  --tags: list<string> # Tags for the feature flag.
  --temporary: oneof<nothing, bool> # Whether or not the flag is a temporary flag.
  variations: list # An array of possible variations for the flag. — item shape: {_id?: string, description?: string, name?: string, value: record}
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  let qp = [(serialize-qp "clone" $clone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key)} | format pattern "/flags/{project_key}") $qp $auth.query)
  let req_body = {"clientSideAvailability": $client_side_availability, "defaults": $defaults, "description": $description, "includeInSnippet": $include_in_snippet, "key": $key, "name": $name, "tags": $tags, "temporary": $temporary, "variations": $variations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"clone": $clone} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get dependent flags for the flag in the environment specified in path parameters
#
# GET /flags/{projectKey}/{environmentKey}/{featureFlagKey}/dependent-flags
export def "flags-dependent-flags get" [
  project_key: string
  environment_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flags/{project_key}/{environment_key}/{feature_flag_key}/dependent-flags") $auth.query)
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

# Delete a feature flag in all environments. Be careful-- only delete feature flags that are no longer being used by your application.
#
# DELETE /flags/{projectKey}/{featureFlagKey}
# operationId: deleteFeatureFlag
export def "flags delete-feature" [
  project_key: string
  feature_flag_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flags/{project_key}/{feature_flag_key}") $auth.query)
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

# Get a single feature flag by key.
#
# GET /flags/{projectKey}/{featureFlagKey}
# operationId: getFeatureFlag
export def "flags get-feature" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-env: list<string> # By default, each feature will include configurations for each environment. You can filter environments with the env query parameter. For example, setting env=["production"] will restrict the returned configurations to just your production environment.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let qp = [(serialize-qp "env" $qp_env "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flags/{project_key}/{feature_flag_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"env": $qp_env} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Perform a partial update to a feature.
#
# PATCH /flags/{projectKey}/{featureFlagKey}
# operationId: patchFeatureFlag
# --patch item shape: {op: string, path: string, value: record}
export def "flags update-feature" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # e.g. This is a comment string
  --patch: list # item shape: {op: string, path: string, value: record}
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flags/{project_key}/{feature_flag_key}") $auth.query)
  let req_body = {"comment": $comment, "patch": $patch} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Copies the feature flag configuration from one environment to the same feature flag in another environment.
#
# POST /flags/{projectKey}/{featureFlagKey}/copy
# operationId: copyFeatureFlag
# --source shape: {currentVersion?: int, key: string}
# --target shape: {currentVersion?: int, key: string}
export def "flags-copy copy-feature" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change. (e.g. This is a comment string)
  --excluded-actions: list<string> # Define the parts of the flag configuration that will not be copied.
  --included-actions: list<string> # Define the parts of the flag configuration that will be copied.
  --body-source: record # shape: {currentVersion?: int, key: string}
  --target: record # shape: {currentVersion?: int, key: string}
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _maintainer: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, _version: int, archived: bool, archivedDate: int, clientSideAvailability: record<usingEnvironmentId: bool, usingMobileKey: bool>, creationDate: int, customProperties: record, defaults: record<offVariation: int, onVariation: int>, description: string, environments: record, goalIds: list<string>, includeInSnippet: bool, key: string, kind: string, maintainerId: string, name: string, tags: list<string>, temporary: bool, variations: table<_id: string, description: string, name: string, value: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flags/{project_key}/{feature_flag_key}/copy") $auth.query)
  let req_body = {"comment": $comment, "excludedActions": $excluded_actions, "includedActions": $included_actions, "source": $body_source, "target": $target} | compact
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

# Get dependent flags across all environments for the flag specified in the path parameters
#
# GET /flags/{projectKey}/{featureFlagKey}/dependent-flags
export def "flags-dependent-flags list" [
  project_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _site: record<href: string, type: string>, items: table<_links: record, _site: record, environments: list, key: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/flags/{project_key}/{feature_flag_key}/dependent-flags") $auth.query)
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

# Get expiring user targets for feature flag
#
# GET /flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}
# operationId: getExpiringUserTargets
export def "flags-expiring-user-targets get" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/flags/{project_key}/{feature_flag_key}/expiring-user-targets/{environment_key}") $auth.query)
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

# Update, add, or delete expiring user targets on feature flag
#
# PATCH /flags/{projectKey}/{featureFlagKey}/expiring-user-targets/{environmentKey}
# operationId: patchExpiringUserTargets
export def "flags-expiring-user-targets update" [
  project_key: string
  feature_flag_key: string
  environment_key: string
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
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/flags/{project_key}/{feature_flag_key}/expiring-user-targets/{environment_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a list of all configured audit log event integrations associated with this account.
#
# GET /integrations
# operationId: getIntegrations
export def "integrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations" $auth.query)
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

# Get a list of all configured integrations of a given kind.
#
# GET /integrations/{integrationKey}
# operationId: getIntegrationSubscriptions
export def "integrations get-subscriptions" [
  integration_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string, type: string>>, items: table<_id: string, _links: record, _status: record, config: record, kind: string, name: string, on: bool, statements: list, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_key | is-empty) { error make --unspanned { msg: "path parameter 'integrationKey' must be non-empty" } }
  let full_url = (build-url $base ({integration_key: (encode-path-segment $integration_key)} | format pattern "/integrations/{integration_key}") $auth.query)
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

# Create a new integration subscription of a given kind.
#
# POST /integrations/{integrationKey}
# operationId: postIntegrationSubscription
# --statements item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
export def "integrations create-subscription" [
  integration_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  config: record # Integration-specific configuration fields. (e.g. {apiKey: 582**************************116, hostURL: https://api.datadoghq.com})
  name: string # A human-readable name for your subscription configuration. (e.g. Example Datadog Integration)
  --on: oneof<nothing, bool> # Whether the integration subscription is active or not. (e.g. true)
  --statements: list # item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
  --tags: list<string> # Tags for the integration subscription. (e.g. [])
]: any -> record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_key | is-empty) { error make --unspanned { msg: "path parameter 'integrationKey' must be non-empty" } }
  let full_url = (build-url $base ({integration_key: (encode-path-segment $integration_key)} | format pattern "/integrations/{integration_key}") $auth.query)
  let req_body = {"config": $config, "name": $name, "on": $on, "statements": $statements, "tags": $tags} | compact
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

# Delete an integration subscription by ID.
#
# DELETE /integrations/{integrationKey}/{integrationId}
# operationId: deleteIntegrationSubscription
export def "integrations delete-subscription" [
  integration_key: string
  integration_id: string
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
  if ($integration_key | is-empty) { error make --unspanned { msg: "path parameter 'integrationKey' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let full_url = (build-url $base ({integration_key: (encode-path-segment $integration_key), integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_key}/{integration_id}") $auth.query)
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

# Get a single integration subscription by ID.
#
# GET /integrations/{integrationKey}/{integrationId}
# operationId: getIntegrationSubscription
export def "integrations get-subscription" [
  integration_key: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_key | is-empty) { error make --unspanned { msg: "path parameter 'integrationKey' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let full_url = (build-url $base ({integration_key: (encode-path-segment $integration_key), integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_key}/{integration_id}") $auth.query)
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

# Modify an integration subscription by ID.
#
# PATCH /integrations/{integrationKey}/{integrationId}
# operationId: patchIntegrationSubscription
export def "integrations update-subscription" [
  integration_key: string
  integration_id: string
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
]: any -> record<_id: string, _links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, _status: record<errorCount: int, lastSuccess: int, successCount: int>, config: record, kind: string, name: string, on: bool, statements: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_key | is-empty) { error make --unspanned { msg: "path parameter 'integrationKey' must be non-empty" } }
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integrationId' must be non-empty" } }
  let full_url = (build-url $base ({integration_key: (encode-path-segment $integration_key), integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_key}/{integration_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of all members in the account.
#
# GET /members
# operationId: getMembers
export def "members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # The number of objects to return. Defaults to -1, which returns everything.
  --offset: float # Where to start in the list. This is for use with pagination. For example, an offset of 10 would skip the first 10 items and then return the next limit items.
  --filter: string # A comma-separated list of filters. Each filter is of the form field:value.
  --qp-sort: string # A comma-separated list of fields to sort by. A field prefixed by a - will be sorted in descending order.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/members" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "filter": $filter, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Invite new members.
#
# POST /members
# operationId: postMembers
export def "members create" [
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
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _lastSeen: int, _lastSeenMetadata: record, _links: record, _pendingInvite: bool, _verified: bool, customRoles: list, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, totalCount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/members" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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

# Get the current team member associated with the token
#
# GET /members/me
# operationId: getMe
export def "members-me get" [
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
  let full_url = (build-url $base "/members/me" $auth.query)
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

# Delete a team member by ID.
#
# DELETE /members/{memberId}
# operationId: deleteMember
export def "members delete" [
  member_id: string
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
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({member_id: (encode-path-segment $member_id)} | format pattern "/members/{member_id}") $auth.query)
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

# Get a single team member by ID.
#
# GET /members/{memberId}
# operationId: getMember
export def "members get" [
  member_id: string
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
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({member_id: (encode-path-segment $member_id)} | format pattern "/members/{member_id}") $auth.query)
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

# Modify a team member by ID.
#
# PATCH /members/{memberId}
# operationId: patchMember
export def "members update" [
  member_id: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($member_id | is-empty) { error make --unspanned { msg: "path parameter 'memberId' must be non-empty" } }
  let full_url = (build-url $base ({member_id: (encode-path-segment $member_id)} | format pattern "/members/{member_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of all projects in the account.
#
# GET /projects
# operationId: getProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, defaultClientSideAvailability: record, environments: list, includeInSnippetByDefault: bool, key: string, name: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects" $auth.query)
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

# Create a new project with the given key and name.
#
# POST /projects
# operationId: postProject
# --defaultClientSideAvailability shape: {usingEnvironmentId?: bool, usingMobileKey?: bool}
# --environments item shape: {color: string, confirmChanges?: bool, defaultTrackEvents?: bool, defaultTtl?: float, key: string, name: string, requireComments?: bool, secureMode?: bool, tags?: list<string>}
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
  --default-client-side-availability: record # shape: {usingEnvironmentId?: bool, usingMobileKey?: bool}
  --environments: list # item shape: {color: string, confirmChanges?: bool, defaultTrackEvents?: bool, defaultTtl?: float, key: string, name: string, requireComments?: bool, secureMode?: bool, tags?: list<string>}
  --include-in-snippet-by-default: oneof<nothing, bool> # e.g. false
  key: string # e.g. new-project
  name: string # e.g. New Project
  --tags: list<string> # e.g. [ops, dev]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects" $auth.query)
  let req_body = {"defaultClientSideAvailability": $default_client_side_availability, "environments": $environments, "includeInSnippetByDefault": $include_in_snippet_by_default, "key": $key, "name": $name, "tags": $tags} | compact
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

# Delete a project by key. Caution-- deleting a project will delete all associated environments and feature flags. You cannot delete the last project in an account.
#
# DELETE /projects/{projectKey}
# operationId: deleteProject
export def "projects delete" [
  project_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key)} | format pattern "/projects/{project_key}") $auth.query)
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

# Fetch a single project by key.
#
# GET /projects/{projectKey}
# operationId: getProject
export def "projects get" [
  project_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key)} | format pattern "/projects/{project_key}") $auth.query)
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

# Modify a project by ID.
#
# PATCH /projects/{projectKey}
# operationId: patchProject
export def "projects update" [
  project_key: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key)} | format pattern "/projects/{project_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Create a new environment in a specified project with a given name, key, and swatch color.
#
# POST /projects/{projectKey}/environments
# operationId: postEnvironment
export def "projects-environments create" [
  project_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  color: string # A color swatch (as an RGB hex value with no leading '#', e.g. C8C8C8). (e.g. 417505)
  --confirm-changes: oneof<nothing, bool> # Determines if this environment requires confirmation for flag and segment changes. (e.g. false)
  --default-track-events: oneof<nothing, bool> # Set to true to send detailed event information for newly created flags. (e.g. false)
  --default-ttl: float # The default TTL for the new environment. (e.g. 0)
  key: string # A project-unique key for the new environment. (e.g. dev)
  name: string # The name of the new environment. (e.g. Development)
  --require-comments: oneof<nothing, bool> # Determines if this environment requires comments for flag and segment changes. (e.g. false)
  --secure-mode: oneof<nothing, bool> # Determines whether the environment is in secure mode. (e.g. false)
  --tags: list<string> # An array of tags for this environment. (e.g. [tag1, tag2])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key)} | format pattern "/projects/{project_key}/environments") $auth.query)
  let req_body = {"color": $color, "confirmChanges": $confirm_changes, "defaultTrackEvents": $default_track_events, "defaultTtl": $default_ttl, "key": $key, "name": $name, "requireComments": $require_comments, "secureMode": $secure_mode, "tags": $tags} | compact
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

# Delete an environment in a specific project.
#
# DELETE /projects/{projectKey}/environments/{environmentKey}
# operationId: deleteEnvironment
export def "projects-environments delete" [
  project_key: string
  environment_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/environments/{environment_key}") $auth.query)
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

# Get an environment given a project and key.
#
# GET /projects/{projectKey}/environments/{environmentKey}
# operationId: getEnvironment
export def "projects-environments get" [
  project_key: string
  environment_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/environments/{environment_key}") $auth.query)
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

# Modify an environment by ID. If you try to patch the environment by setting both required and requiredApprovalTags, it will result in an error. Users can specify either required approvals for all flags in an environment or those with specific tags, but not both. Only customers on an Enterprise plan can require approval for flag updates with either mechanism.
#
# PATCH /projects/{projectKey}/environments/{environmentKey}
# operationId: patchEnvironment
export def "projects-environments update" [
  project_key: string
  environment_key: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/environments/{environment_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Reset an environment's SDK key with an optional expiry time for the old key.
#
# POST /projects/{projectKey}/environments/{environmentKey}/apiKey
# operationId: resetEnvironmentSDKKey
export def "projects-environments-api-key reset-sdk" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: int # An expiration time for the old environment SDK key, expressed as a Unix epoch time in milliseconds. By default, the key will expire immediately. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/environments/{environment_key}/apiKey") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"expiry": $expiry} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Reset an environment's mobile key. The optional expiry for the old key is deprecated for this endpoint, so the old key will always expire immediately.
#
# POST /projects/{projectKey}/environments/{environmentKey}/mobileKey
# operationId: resetEnvironmentMobileKey
export def "projects-environments-mobile-key reset" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: int # The expiry parameter is deprecated for this endpoint, so the old mobile key will always expire immediately. This parameter will be removed in an upcoming major API client version. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/environments/{environment_key}/mobileKey") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"expiry": $expiry} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get all approval requests for a feature flag config
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests
# operationId: getApprovalRequests
export def "projects-flags-environments-approval-requests list" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/approval-requests") $auth.query)
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

# Delete an approval request for a feature flag config
#
# DELETE /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# operationId: deleteApprovalRequest
# --instructions item shape: {kind?: string}
export def "projects-flags-environments-approval-requests delete" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change.
  description: string # A name that describes the changes you would like to apply to a feature flag configuration
  --execution-date: int # Timestamp for when instructions will be executed (format: int64)
  instructions: list # item shape: {kind?: string}
  notify_member_ids: list<string> # e.g. [memberId, memberId2]
  --operating-on-id: string # ID of scheduled change to edit or delete
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($approval_request_id | is-empty) { error make --unspanned { msg: "path parameter 'approvalRequestId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), approval_request_id: (encode-path-segment $approval_request_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/approval-requests/{approval_request_id}") $auth.query)
  let req_body = {"comment": $comment, "description": $description, "executionDate": $execution_date, "instructions": $instructions, "notifyMemberIds": $notify_member_ids, "operatingOnId": $operating_on_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a single approval request for a feature flag config
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# operationId: getApprovalRequest
export def "projects-flags-environments-approval-requests get" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($approval_request_id | is-empty) { error make --unspanned { msg: "path parameter 'approvalRequestId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), approval_request_id: (encode-path-segment $approval_request_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/approval-requests/{approval_request_id}") $auth.query)
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

# Create an approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}
# operationId: postApprovalRequest
# --instructions item shape: {kind?: string}
export def "projects-flags-environments-approval-requests create" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change.
  description: string # A name that describes the changes you would like to apply to a feature flag configuration
  --execution-date: int # Timestamp for when instructions will be executed (format: int64)
  instructions: list # item shape: {kind?: string}
  notify_member_ids: list<string> # e.g. [memberId, memberId2]
  --operating-on-id: string # ID of scheduled change to edit or delete
]: any -> record<_id: string, _version: int, allReviews: table<_id: string, creationDate: int, kind: string, memberId: string>, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: table<kind: string>, notifyMemberIds: list<string>, operatingOnId: string, requestorId: string, reviewStatus: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($approval_request_id | is-empty) { error make --unspanned { msg: "path parameter 'approvalRequestId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), approval_request_id: (encode-path-segment $approval_request_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/approval-requests/{approval_request_id}") $auth.query)
  let req_body = {"comment": $comment, "description": $description, "executionDate": $execution_date, "instructions": $instructions, "notifyMemberIds": $notify_member_ids, "operatingOnId": $operating_on_id} | compact
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

# Apply approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/apply
# operationId: postApplyApprovalRequest
export def "projects-flags-environments-approval-requests-apply create" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change. (e.g. Applying approved changes)
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($approval_request_id | is-empty) { error make --unspanned { msg: "path parameter 'approvalRequestId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), approval_request_id: (encode-path-segment $approval_request_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/approval-requests/{approval_request_id}/apply") $auth.query)
  let req_body = {"comment": $comment} | compact
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

# Review approval request for a feature flag config
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/approval-requests/{approvalRequestId}/review
# operationId: postReviewApprovalRequest
export def "projects-flags-environments-approval-requests-review create" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  approval_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # comment will be included in audit log item for change. (e.g. This is a comment string)
  kind: string@kind-completer-1 # One of approve, decline, or comment. (e.g. approve)
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, allReviews: list, appliedByMemberID: string, appliedDate: int, creationDate: int, executionDate: int, instructions: list, notifyMemberIds: list, operatingOnId: string, requestorId: string, reviewStatus: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($approval_request_id | is-empty) { error make --unspanned { msg: "path parameter 'approvalRequestId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), approval_request_id: (encode-path-segment $approval_request_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/approval-requests/{approval_request_id}/review") $auth.query)
  let req_body = {"comment": $comment, "kind": $kind} | compact
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

# Get all scheduled workflows for a feature flag by key.
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes
# operationId: getFlagConfigScheduledChanges
export def "projects-flags-environments-scheduled-changes list" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _version: int, executionDate: int, instructions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/scheduled-changes") $auth.query)
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

# Creates a new scheduled change for a feature flag.
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes
# operationId: postFlagConfigScheduledChanges
# --instructions item shape: {kind?: string}
export def "projects-flags-environments-scheduled-changes create-config" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # Used to describe the scheduled changes.
  --execution-date: int # A unix epoch time in milliseconds specifying the date the scheduled changes will be applied
  --instructions: list # item shape: {kind?: string}
]: any -> record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/scheduled-changes") $auth.query)
  let req_body = {"comment": $comment, "executionDate": $execution_date, "instructions": $instructions} | compact
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

# Lists conflicts between the given instructions and any existing scheduled changes for the feature flag. The actual HTTP verb should be REPORT, not POST.
#
# POST /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes-conflicts
# operationId: getFlagConfigScheduledChangesConflicts
# --instructions item shape: {kind?: string}
export def "projects-flags-environments-scheduled-changes-conflicts get-config" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --execution-date: int # A unix epoch time in milliseconds specifying the date the scheduled changes will be applied
  --instructions: list # item shape: {kind?: string}
]: any -> record<instructions: table<conflicts: list, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/scheduled-changes-conflicts") $auth.query)
  let req_body = {"executionDate": $execution_date, "instructions": $instructions} | compact
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

# Delete a scheduled change on a feature flag in an environment.
#
# DELETE /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# operationId: deleteFlagConfigScheduledChanges
export def "projects-flags-environments-scheduled-changes delete-config" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  scheduled_change_id: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($scheduled_change_id | is-empty) { error make --unspanned { msg: "path parameter 'scheduledChangeId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), scheduled_change_id: (encode-path-segment $scheduled_change_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/scheduled-changes/{scheduled_change_id}") $auth.query)
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

# Get a scheduled change on a feature flag by id.
#
# GET /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# operationId: getFlagConfigScheduledChange
export def "projects-flags-environments-scheduled-changes get-config" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  scheduled_change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($scheduled_change_id | is-empty) { error make --unspanned { msg: "path parameter 'scheduledChangeId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), scheduled_change_id: (encode-path-segment $scheduled_change_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/scheduled-changes/{scheduled_change_id}") $auth.query)
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

# Updates an existing scheduled-change on a feature flag in an environment.
#
# PATCH /projects/{projectKey}/flags/{featureFlagKey}/environments/{environmentKey}/scheduled-changes/{scheduledChangeId}
# operationId: patchFlagConfigScheduledChange
# --instructions item shape: {kind?: string}
export def "projects-flags-environments-scheduled-changes update-config" [
  project_key: string
  feature_flag_key: string
  environment_key: string
  scheduled_change_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # Used to describe the scheduled changes.
  --instructions: list # item shape: {kind?: string}
]: any -> record<_id: string, _version: int, executionDate: int, instructions: table<kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($scheduled_change_id | is-empty) { error make --unspanned { msg: "path parameter 'scheduledChangeId' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), feature_flag_key: (encode-path-segment $feature_flag_key), environment_key: (encode-path-segment $environment_key), scheduled_change_id: (encode-path-segment $scheduled_change_id)} | format pattern "/projects/{project_key}/flags/{feature_flag_key}/environments/{environment_key}/scheduled-changes/{scheduled_change_id}") $auth.query)
  let req_body = {"comment": $comment, "instructions": $instructions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Return a complete list of custom roles.
#
# GET /roles
# operationId: getCustomRoles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, description: string, key: string, name: string, policy: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles" $auth.query)
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

# Create a new custom role.
#
# POST /roles
# operationId: postCustomRole
# --policy item shape: {actions?: list<string>, effect?: string, notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
export def "roles create-custom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the custom role. (e.g. Description of revenue team role here)
  key: string # The 20-hexdigit id or the key for a custom role. (e.g. revenue-team)
  name: string # Name of the custom role. (e.g. revenue team)
  policy: list # item shape: {actions?: list<string>, effect?: string, notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles" $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name, "policy": $policy} | compact
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

# Delete a custom role by key.
#
# DELETE /roles/{customRoleKey}
# operationId: deleteCustomRole
export def "roles delete-custom" [
  custom_role_key: string
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
  if ($custom_role_key | is-empty) { error make --unspanned { msg: "path parameter 'customRoleKey' must be non-empty" } }
  let full_url = (build-url $base ({custom_role_key: (encode-path-segment $custom_role_key)} | format pattern "/roles/{custom_role_key}") $auth.query)
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

# Get one custom role by key.
#
# GET /roles/{customRoleKey}
# operationId: getCustomRole
export def "roles get-custom" [
  custom_role_key: string
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
  if ($custom_role_key | is-empty) { error make --unspanned { msg: "path parameter 'customRoleKey' must be non-empty" } }
  let full_url = (build-url $base ({custom_role_key: (encode-path-segment $custom_role_key)} | format pattern "/roles/{custom_role_key}") $auth.query)
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

# Modify a custom role by key.
#
# PATCH /roles/{customRoleKey}
# operationId: patchCustomRole
export def "roles update-custom" [
  custom_role_key: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($custom_role_key | is-empty) { error make --unspanned { msg: "path parameter 'customRoleKey' must be non-empty" } }
  let full_url = (build-url $base ({custom_role_key: (encode-path-segment $custom_role_key)} | format pattern "/roles/{custom_role_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Get a list of all user segments in the given project.
#
# GET /segments/{projectKey}/{environmentKey}
# operationId: getUserSegments
export def "segments list" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filter by tag. A tag can be used to group flags across projects.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_flags: list, _links: record, creationDate: int, description: string, excluded: list, included: list, key: string, name: string, rules: list, tags: list, unbounded: bool, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/segments/{project_key}/{environment_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag": $tag} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new user segment.
#
# POST /segments/{projectKey}/{environmentKey}
# operationId: postUserSegment
export def "segments create-user" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the user segment. (e.g. Users in this segment will have access to beta features.)
  key: string # A unique key that will be used to reference the user segment in feature flags. (e.g. new-segment)
  name: string # A human-friendly name for the user segment. (e.g. new segment)
  --tags: list<string> # Tags for the user segment.
  --unbounded: oneof<nothing, bool> # Controls whether this is considered a "big segment" which can support an unlimited numbers of users. Include/exclude lists sent with this payload are not used in big segments. Contact your account manager for early access to this feature. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/segments/{project_key}/{environment_key}") $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name, "tags": $tags, "unbounded": $unbounded} | compact
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

# Delete a user segment.
#
# DELETE /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# operationId: deleteUserSegment
export def "segments delete-user" [
  project_key: string
  environment_key: string
  user_segment_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_segment_key | is-empty) { error make --unspanned { msg: "path parameter 'userSegmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_segment_key: (encode-path-segment $user_segment_key)} | format pattern "/segments/{project_key}/{environment_key}/{user_segment_key}") $auth.query)
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

# Get a single user segment by key.
#
# GET /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# operationId: getUserSegment
export def "segments get-user" [
  project_key: string
  environment_key: string
  user_segment_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_segment_key | is-empty) { error make --unspanned { msg: "path parameter 'userSegmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_segment_key: (encode-path-segment $user_segment_key)} | format pattern "/segments/{project_key}/{environment_key}/{user_segment_key}") $auth.query)
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

# Perform a partial update to a user segment.
#
# PATCH /segments/{projectKey}/{environmentKey}/{userSegmentKey}
# operationId: patchUserSegment
export def "segments update-user" [
  project_key: string
  environment_key: string
  user_segment_key: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_segment_key | is-empty) { error make --unspanned { msg: "path parameter 'userSegmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_segment_key: (encode-path-segment $user_segment_key)} | format pattern "/segments/{project_key}/{environment_key}/{user_segment_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Update targets included or excluded in a big segment
#
# POST /segments/{projectKey}/{environmentKey}/{userSegmentKey}/users
# operationId: updateBigSegmentTargets
# --excluded shape: {add?: list<string>, remove?: list<string>}
# --included shape: {add?: list<string>, remove?: list<string>}
export def "segments-users update-big-targets" [
  project_key: string
  environment_key: string
  user_segment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --excluded: record # shape: {add?: list<string>, remove?: list<string>}
  --included: record # shape: {add?: list<string>, remove?: list<string>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_segment_key | is-empty) { error make --unspanned { msg: "path parameter 'userSegmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_segment_key: (encode-path-segment $user_segment_key)} | format pattern "/segments/{project_key}/{environment_key}/{user_segment_key}/users") $auth.query)
  let req_body = {"excluded": $excluded, "included": $included} | compact
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

# Get expiring user targets for user segment
#
# GET /segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}
# operationId: getExpiringUserTargetsOnSegment
export def "segments-expiring-user-targets get" [
  project_key: string
  user_segment_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($user_segment_key | is-empty) { error make --unspanned { msg: "path parameter 'userSegmentKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), user_segment_key: (encode-path-segment $user_segment_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/segments/{project_key}/{user_segment_key}/expiring-user-targets/{environment_key}") $auth.query)
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

# Update, add, or delete expiring user targets on user segment
#
# PATCH /segments/{projectKey}/{userSegmentKey}/expiring-user-targets/{environmentKey}
# operationId: patchExpiringUserTargetsOnSegment
export def "segments-expiring-user-targets update" [
  project_key: string
  user_segment_key: string
  environment_key: string
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
]: any -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _resourceId: record<environmentKey: string, flagKey: string, key: string, kind: string, projectKey: string>, _version: int, expirationDate: int, targetType: string, userKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($user_segment_key | is-empty) { error make --unspanned { msg: "path parameter 'userSegmentKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), user_segment_key: (encode-path-segment $user_segment_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/segments/{project_key}/{user_segment_key}/expiring-user-targets/{environment_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Returns a list of tokens in the account.
#
# GET /tokens
# operationId: getTokens
export def "tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-all: oneof<nothing, bool> # If set to true, and the authentication access token has the "Admin" role, personal access tokens for all members will be retrieved.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _member: record, creationDate: int, customRoleIds: list, defaultApiVersion: int, inlineRole: list, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showAll" $show_all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tokens" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"showAll": $show_all} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new token.
#
# POST /tokens
# operationId: postToken
# --inlineRole item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
export def "tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-role-ids: list<string> # A list of custom role IDs to use as access limits for the access token
  --default-api-version: int # The default API version for this token
  --inline-role: list # item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
  --name: string # A human-friendly name for the access token (e.g. My access token)
  --role: string # The name of a built-in role for the token (e.g. writer)
  --service-token: oneof<nothing, bool> # Whether the token will be a service token https://docs.launchdarkly.com/home/account-security/api-access-tokens#service-tokens
]: any -> record<_id: string, _links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _member: record<_id: string, _lastSeen: int, _lastSeenMetadata: record<tokenId: string>, _links: record<next: record, self: record>, _pendingInvite: bool, _verified: bool, customRoles: list<string>, email: string, firstName: string, isBeta: bool, lastName: string, role: string>, creationDate: int, customRoleIds: list<string>, defaultApiVersion: int, inlineRole: table<actions: list, effect: string, notActions: list, notResources: list, resources: list>, lastModified: int, lastUsed: int, memberId: string, name: string, ownerId: string, role: string, serviceToken: bool, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens" $auth.query)
  let req_body = {"customRoleIds": $custom_role_ids, "defaultApiVersion": $default_api_version, "inlineRole": $inline_role, "name": $name, "role": $role, "serviceToken": $service_token} | compact
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

# Delete an access token by ID.
#
# DELETE /tokens/{tokenId}
# operationId: deleteToken
export def "tokens delete" [
  token_id: string
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
  if ($token_id | is-empty) { error make --unspanned { msg: "path parameter 'tokenId' must be non-empty" } }
  let full_url = (build-url $base ({token_id: (encode-path-segment $token_id)} | format pattern "/tokens/{token_id}") $auth.query)
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

# Get a single access token by ID.
#
# GET /tokens/{tokenId}
# operationId: getToken
export def "tokens get" [
  token_id: string
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
  if ($token_id | is-empty) { error make --unspanned { msg: "path parameter 'tokenId' must be non-empty" } }
  let full_url = (build-url $base ({token_id: (encode-path-segment $token_id)} | format pattern "/tokens/{token_id}") $auth.query)
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

# Modify an access token by ID.
#
# PATCH /tokens/{tokenId}
# operationId: patchToken
export def "tokens update" [
  token_id: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_id | is-empty) { error make --unspanned { msg: "path parameter 'tokenId' must be non-empty" } }
  let full_url = (build-url $base ({token_id: (encode-path-segment $token_id)} | format pattern "/tokens/{token_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Reset an access token's secret key with an optional expiry time for the old key.
#
# POST /tokens/{tokenId}/reset
# operationId: resetToken
export def "tokens-reset reset" [
  token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: int # An expiration time for the old token key, expressed as a Unix epoch time in milliseconds. By default, the token will expire immediately. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_id | is-empty) { error make --unspanned { msg: "path parameter 'tokenId' must be non-empty" } }
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_id: (encode-path-segment $token_id)} | format pattern "/tokens/{token_id}/reset") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"expiry": $expiry} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns of the usage endpoints available.
#
# GET /usage
# operationId: getUsage
export def "usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage" $auth.query)
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

# Get events usage by event id and the feature flag key.
#
# GET /usage/evaluations/{envId}/{flagKey}
# operationId: getEvaluations
export def "usage-evaluations get" [
  env_id: string
  flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($env_id | is-empty) { error make --unspanned { msg: "path parameter 'envId' must be non-empty" } }
  if ($flag_key | is-empty) { error make --unspanned { msg: "path parameter 'flagKey' must be non-empty" } }
  let full_url = (build-url $base ({env_id: (encode-path-segment $env_id), flag_key: (encode-path-segment $flag_key)} | format pattern "/usage/evaluations/{env_id}/{flag_key}") $auth.query)
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

# Get events usage endpoints.
#
# GET /usage/events
# operationId: getEvents
export def "usage-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/events" $auth.query)
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

# Get events usage by event type.
#
# GET /usage/events/{type}
# operationId: getEvent
export def "usage-events get" [
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
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/usage/events/{type}") $auth.query)
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

# Get monthly active user data.
#
# GET /usage/mau
# operationId: getMAU
export def "usage-mau get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/mau" $auth.query)
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

# Get monthly active user data by category.
#
# GET /usage/mau/bycategory
# operationId: getMAUByCategory
export def "usage-mau-bycategory get-by-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: list<record>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/mau/bycategory" $auth.query)
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

# Returns a list of all streams.
#
# GET /usage/streams
# operationId: getStreams
export def "usage-streams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage/streams" $auth.query)
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

# Get a stream endpoint and return timeseries data.
#
# GET /usage/streams/{source}
# operationId: getStream
export def "usage-streams get" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>, subseries: list<record>>, metadata: table<sdk: string, source: string, version: string>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source | is-empty) { error make --unspanned { msg: "path parameter 'source' must be non-empty" } }
  let full_url = (build-url $base ({source: (encode-path-segment $source)} | format pattern "/usage/streams/{source}") $auth.query)
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

# Get a stream timeseries data by source show sdk version metadata.
#
# GET /usage/streams/{source}/bysdkversion
# operationId: getStreamBySDK
export def "usage-streams-bysdkversion get-by-sdk" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, metadata: table<sdk: string, source: string, version: string>, series: table<0: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source | is-empty) { error make --unspanned { msg: "path parameter 'source' must be non-empty" } }
  let full_url = (build-url $base ({source: (encode-path-segment $source)} | format pattern "/usage/streams/{source}/bysdkversion") $auth.query)
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

# Get a stream timeseries data by source and show all sdk version associated.
#
# GET /usage/streams/{source}/sdkversions
# operationId: getStreamSDKVersion
export def "usage-streams-sdkversions get-sdk-version" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<parent: record<href: string, type: string>, self: record<href: string, type: string>>, sdkVersions: table<sdk: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source | is-empty) { error make --unspanned { msg: "path parameter 'source' must be non-empty" } }
  let full_url = (build-url $base ({source: (encode-path-segment $source)} | format pattern "/usage/streams/{source}/sdkversions") $auth.query)
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

# Search users in LaunchDarkly based on their last active date, or a search query. It should not be used to enumerate all users in LaunchDarkly-- use the List users API resource.
#
# GET /user-search/{projectKey}/{environmentKey}
# operationId: getSearchUsers
export def "user-search get" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search query.
  --limit: int # Pagination limit.
  --offset: int # Specifies the first item to return in the collection.
  --after: int # A timestamp filter, expressed as a Unix epoch time in milliseconds. All entries returned will have occurred after this timestamp. (format: int64)
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/user-search/{project_key}/{environment_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "limit": $limit, "offset": $offset, "after": $after} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all users in the environment. Includes the total count of users. In each page, there will be up to 'limit' users returned (default 20). This is useful for exporting all users in the system for further analysis. Paginated collections will include a next link containing a URL with the next set of elements in the collection.
#
# GET /users/{projectKey}/{environmentKey}
# operationId: getUsers
export def "users list" [
  project_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Pagination limit.
  --h: string # This parameter is required when following "next" links.
  --scroll-id: string # This parameter is required when following "next" links.
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record>, totalCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "h" $h "scalar") (serialize-qp "scrollId" $scroll_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/users/{project_key}/{environment_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "h": $h, "scrollId": $scroll_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a user by ID.
#
# DELETE /users/{projectKey}/{environmentKey}/{userKey}
# operationId: deleteUser
export def "users delete" [
  project_key: string
  environment_key: string
  user_key: string
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
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_key: (encode-path-segment $user_key)} | format pattern "/users/{project_key}/{environment_key}/{user_key}") $auth.query)
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

# Get a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}
# operationId: getUser
export def "users get" [
  project_key: string
  environment_key: string
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar: string, environmentId: string, lastPing: string, ownerId: string, user: record<anonymous: bool, avatar: string, country: string, custom: record, email: string, firstName: string, ip: string, key: string, lastName: string, name: string, secondary: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_key: (encode-path-segment $user_key)} | format pattern "/users/{project_key}/{environment_key}/{user_key}") $auth.query)
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

# Fetch a single flag setting for a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}/flags
# operationId: getUserFlagSettings
export def "users-flags get-settings" [
  project_key: string
  environment_key: string
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_key: (encode-path-segment $user_key)} | format pattern "/users/{project_key}/{environment_key}/{user_key}/flags") $auth.query)
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

# Fetch a single flag setting for a user by key.
#
# GET /users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}
# operationId: getUserFlagSetting
export def "users-flags get-setting" [
  project_key: string
  environment_key: string
  user_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, _value: bool, setting: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_key: (encode-path-segment $user_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/users/{project_key}/{environment_key}/{user_key}/flags/{feature_flag_key}") $auth.query)
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

# Specifically enable or disable a feature flag for a user based on their key.
#
# PUT /users/{projectKey}/{environmentKey}/{userKey}/flags/{featureFlagKey}
# operationId: putFlagSetting
export def "users-flags update-setting" [
  project_key: string
  environment_key: string
  user_key: string
  feature_flag_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --setting: oneof<nothing, bool> # The variation value to set for the user. Must match the variation type of the flag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($feature_flag_key | is-empty) { error make --unspanned { msg: "path parameter 'featureFlagKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), environment_key: (encode-path-segment $environment_key), user_key: (encode-path-segment $user_key), feature_flag_key: (encode-path-segment $feature_flag_key)} | format pattern "/users/{project_key}/{environment_key}/{user_key}/flags/{feature_flag_key}") $auth.query)
  let req_body = {"setting": $setting} | compact
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

# Get expiring dates on flags for user
#
# GET /users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}
# operationId: getExpiringUserTargetsForUser
export def "users-expiring-user-targets get" [
  project_key: string
  user_key: string
  environment_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), user_key: (encode-path-segment $user_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/users/{project_key}/{user_key}/expiring-user-targets/{environment_key}") $auth.query)
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

# Update, add, or delete expiring user targets for a single user on all flags
#
# PATCH /users/{projectKey}/{userKey}/expiring-user-targets/{environmentKey}
# operationId: patchExpiringUserTargetsForFlags
export def "users-expiring-user-targets update-for-flags" [
  project_key: string
  user_key: string
  environment_key: string
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
]: any -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, _resourceId: record, _version: int, expirationDate: int, userKey: string, variationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_key | is-empty) { error make --unspanned { msg: "path parameter 'projectKey' must be non-empty" } }
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($environment_key | is-empty) { error make --unspanned { msg: "path parameter 'environmentKey' must be non-empty" } }
  let full_url = (build-url $base ({project_key: (encode-path-segment $project_key), user_key: (encode-path-segment $user_key), environment_key: (encode-path-segment $environment_key)} | format pattern "/users/{project_key}/{user_key}/expiring-user-targets/{environment_key}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Fetch a list of all webhooks.
#
# GET /webhooks
# operationId: getWebhooks
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
]: nothing -> record<_links: record<next: record<href: string, type: string>, self: record<href: string, type: string>>, items: table<_id: string, _links: record, name: string, on: bool, secret: string, statements: list, tags: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks" $auth.query)
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

# Create a webhook.
#
# POST /webhooks
# operationId: postWebhook
# --statements item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
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
  --name: string # The name of the webhook. (e.g. Example hook)
  --on: oneof<nothing, bool> # Whether this webhook is enabled or not. (e.g. true)
  --secret: string # If sign is true, and the secret attribute is omitted, LaunchDarkly will automatically generate a secret for you. (e.g. <password>)
  --sign: oneof<nothing, bool> # If sign is false, the webhook will not include a signature header, and the secret can be omitted.
  --statements: list # item shape: {actions?: list<string>, effect?: "allow"|"deny", notActions?: list<string>, notResources?: list<string>, resources?: list<string>}
  --tags: list<string> # Tags for the webhook. (e.g. [])
  url: string # The URL of the remote webhook. (e.g. https://example.com/example)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks" $auth.query)
  let req_body = {"name": $name, "on": $on, "secret": $secret, "sign": $sign, "statements": $statements, "tags": $tags, "url": $url} | compact
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

# Delete a webhook by ID.
#
# DELETE /webhooks/{resourceId}
# operationId: deleteWebhook
export def "webhooks delete" [
  resource_id: string
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/webhooks/{resource_id}") $auth.query)
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

# Get a webhook by ID.
#
# GET /webhooks/{resourceId}
# operationId: getWebhook
export def "webhooks get" [
  resource_id: string
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
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/webhooks/{resource_id}") $auth.query)
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

# Modify a webhook by ID.
#
# PATCH /webhooks/{resourceId}
# operationId: patchWebhook
export def "webhooks update" [
  resource_id: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/webhooks/{resource_id}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
