# Auto-generated client for Turbine Labs API v1.0
# Source: https://api.apis.guru/v2/specs/turbinelabs.io/1.0/swagger.json
# Auth: --token flag or $env.TURBINE_LABS_API_TOKEN

const BASE_URL = "https://api.turbinelabs.io/v1.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TURBINE_LABS_API_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.turbinelabs.io/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["after" "before"] }
def protocol-completer [] { ["http" "http2" "http_auto" "tcp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-user-self get" } } | get name | first)
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

# Returns the user object for the account authorized and making this request.
#
# GET /admin/user/self
export def "admin-user-self get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<checksum: string, deleted_at: string, login_email: string, user_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/user/self" $auth.query)
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

# Delete the specified access token.
#
# DELETE /admin/user/self/access_token/{access-token-key}
export def "admin-user-self-access-token delete" [
  access_token_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the user to be modified (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record<code: int, fields: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token_key | is-empty) { error make --unspanned { msg: "path parameter 'access-token-key' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({access_token_key: (encode-path-segment $access_token_key)} | format pattern "/admin/user/self/access_token/{access_token_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Lists Access Tokens that are configured for the authenticated user.
#
# GET /admin/user/self/access_tokens
export def "admin-user-self-access-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/user/self/access_tokens" $auth.query)
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

# Creates a new Access Token and associates it with the authenticated user.
#
# POST /admin/user/self/access_tokens
export def "admin-user-self-access-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
]: any -> record<access_token_key: string, checksum: string, created_at: string, description: string, signed_token: string, user_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/user/self/access_tokens" $auth.query)
  let req_body = {"description": $description} | compact
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

# Allows an arbitrary filter to be specified and applied to the org\'s change log.
#
# GET /changelog/adhoc
export def "changelog-adhoc get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Encoded FilterSums representing the query you would like to execute. See object definition for details.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changelog/adhoc" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# get changes related to the indicated cluster
#
# GET /changelog/cluster-graph/{clusterKey}
export def "changelog-cluster-graph get" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_key | is-empty) { error make --unspanned { msg: "path parameter 'clusterKey' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_key: (encode-path-segment $cluster_key)} | format pattern "/changelog/cluster-graph/{cluster_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "max_results": $max_results, "ref_id": $ref_id, "direction": $direction} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# get changes related to the indicated domain
#
# GET /changelog/domain-graph/{domainKey}
export def "changelog-domain-graph get" [
  domain_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_key | is-empty) { error make --unspanned { msg: "path parameter 'domainKey' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_key: (encode-path-segment $domain_key)} | format pattern "/changelog/domain-graph/{domain_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "max_results": $max_results, "ref_id": $ref_id, "direction": $direction} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# get changes related to the indicated route
#
# GET /changelog/route-graph/{routeKey}
export def "changelog-route-graph get" [
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_key | is-empty) { error make --unspanned { msg: "path parameter 'routeKey' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_key: (encode-path-segment $route_key)} | format pattern "/changelog/route-graph/{route_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "max_results": $max_results, "ref_id": $ref_id, "direction": $direction} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# get changes related to the indicated SharedRules
#
# GET /changelog/shared-rules-graph/{sharedRulesKey}
export def "changelog-shared-rules-graph get" [
  shared_rules_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_rules_key | is-empty) { error make --unspanned { msg: "path parameter 'sharedRulesKey' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shared_rules_key: (encode-path-segment $shared_rules_key)} | format pattern "/changelog/shared-rules-graph/{shared_rules_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "max_results": $max_results, "ref_id": $ref_id, "direction": $direction} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# get changes in a specified zone
#
# GET /changelog/zone/{zoneKey}
export def "changelog-zone get" [
  zone_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: float # The beginning of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --end: float # The end of the window we want to see changes for; measured in microseconds since Unix Epoch. (format: int64)
  --max-results: float # Determines how many ChangeDescription object should be returned to the calling code. (format: int64)
  --ref-id: string # When paginating a Changelog request start on the entry that comes immediately before or after this ID (as determined by the direction argument).
  --direction: string@direction-completer # If set to "before" then changes will be returned that occurred before reference ID. If "after" then changes will be returned that have occurred since the reference ID.
]: nothing -> record<details: record<pagination: record<direction: string, has_more: bool, ref_id: string, total_entries: int>>, result: table<actor_key: string, at: float, comment: string, diffs: list, txn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_key | is-empty) { error make --unspanned { msg: "path parameter 'zoneKey' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({zone_key: (encode-path-segment $zone_key)} | format pattern "/changelog/zone/{zone_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "max_results": $max_results, "ref_id": $ref_id, "direction": $direction} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# get clusters
#
# GET /cluster
export def "cluster list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ClusterFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ClusterFilter will be included.
]: nothing -> record<result: table<circuit_breakers: record, health_checks: list, instances: list, name: string, outlier_detection: record, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cluster" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filters": $filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# create cluster
#
# POST /cluster
# --circuit_breakers shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
# --health_checks item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
# --instances item shape: {host?: string, metadata?: list, port?: int}
# --outlier_detection shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
export def "cluster create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --circuit-breakers: record # Provides limits on various parameters to protect clusters against sudden surges in traffic. — shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
  --health-checks: list # item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
  --instances: list # item shape: {host?: string, metadata?: list, port?: int}
  name: string
  --outlier-detection: record # A form of passive health checking that dynamically determines whether instances in a cluster are performing unlike others and preemptively removes them from a load balancing set. — shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
  --require-tls: oneof<nothing, bool> # If set, requests to this collection of hosts will be made via HTTPS. At this time neither certificate validation and certificate pinning are supported for proxy clients of this cluster.
  zone_key: string
]: any -> record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster" $auth.query)
  let req_body = {"circuit_breakers": $circuit_breakers, "health_checks": $health_checks, "instances": $instances, "name": $name, "outlier_detection": $outlier_detection, "require_tls": $require_tls, "zone_key": $zone_key} | compact
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

# delete cluster
#
# DELETE /cluster/{clusterKey}
export def "cluster delete" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the cluster to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_key | is-empty) { error make --unspanned { msg: "path parameter 'clusterKey' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_key: (encode-path-segment $cluster_key)} | format pattern "/cluster/{cluster_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get cluster
#
# GET /cluster/{clusterKey}
export def "cluster get" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_key | is-empty) { error make --unspanned { msg: "path parameter 'clusterKey' must be non-empty" } }
  let full_url = (build-url $base ({cluster_key: (encode-path-segment $cluster_key)} | format pattern "/cluster/{cluster_key}") $auth.query)
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

# modify cluster
#
# PUT /cluster/{clusterKey}
# --circuit_breakers shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
# --health_checks item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
# --instances item shape: {host?: string, metadata?: list, port?: int}
# --outlier_detection shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
export def "cluster update" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --circuit-breakers: record # Provides limits on various parameters to protect clusters against sudden surges in traffic. — shape: {max_connections?: int, max_pending_requests?: int, max_requests?: int, max_retries?: int}
  --health-checks: list # item shape: {health_checker: record, healthy_edge_interval_msec?: int, healthy_threshold: int, interval_jitter_msec?: int, interval_msec: int, no_traffic_interval_msec?: int, reuse_connection?: bool, timeout_msec: int, unhealthy_edge_interval_msec?: int, unhealthy_interval_msec?: int, unhealthy_threshold: int}
  --instances: list # item shape: {host?: string, metadata?: list, port?: int}
  name: string
  --outlier-detection: record # A form of passive health checking that dynamically determines whether instances in a cluster are performing unlike others and preemptively removes them from a load balancing set. — shape: {base_ejection_time_msec?: int, consecutive_5xx?: int, consecutive_gateway_failure?: int, enforcing_consecutive_5xx?: int, enforcing_consecutive_gateway_failure?: int, enforcing_success_rate?: int, interval_msec?: int, max_ejection_percent?: int, success_rate_minimum_hosts?: int, success_rate_request_volume?: int, success_rate_stdev_factor?: int}
  --require-tls: oneof<nothing, bool> # If set, requests to this collection of hosts will be made via HTTPS. At this time neither certificate validation and certificate pinning are supported for proxy clients of this cluster.
  zone_key: string
  checksum: string
  --body-cluster-key: string
]: any -> record<result: record<circuit_breakers: record<max_connections: int, max_pending_requests: int, max_requests: int, max_retries: int>, health_checks: list<record>, instances: list<record>, name: string, outlier_detection: record<base_ejection_time_msec: int, consecutive_5xx: int, consecutive_gateway_failure: int, enforcing_consecutive_5xx: int, enforcing_consecutive_gateway_failure: int, enforcing_success_rate: int, interval_msec: int, max_ejection_percent: int, success_rate_minimum_hosts: int, success_rate_request_volume: int, success_rate_stdev_factor: int>, require_tls: bool, zone_key: string, checksum: string, cluster_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_key | is-empty) { error make --unspanned { msg: "path parameter 'clusterKey' must be non-empty" } }
  let full_url = (build-url $base ({cluster_key: (encode-path-segment $cluster_key)} | format pattern "/cluster/{cluster_key}") $auth.query)
  let req_body = {"circuit_breakers": $circuit_breakers, "health_checks": $health_checks, "instances": $instances, "name": $name, "outlier_detection": $outlier_detection, "require_tls": $require_tls, "zone_key": $zone_key, "checksum": $checksum, "cluster_key": $body_cluster_key} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# add instance
#
# POST /cluster/{clusterKey}/instances
# --metadata item shape: {key?: string, value?: string}
export def "cluster-instances create" [
  cluster_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host: string
  --metadata: list # item shape: {key?: string, value?: string}
  --port: int
]: any -> record<result: record<host: string, metadata: list<record>, port: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_key | is-empty) { error make --unspanned { msg: "path parameter 'clusterKey' must be non-empty" } }
  let full_url = (build-url $base ({cluster_key: (encode-path-segment $cluster_key)} | format pattern "/cluster/{cluster_key}/instances") $auth.query)
  let req_body = {"host": $host, "metadata": $metadata, "port": $port} | compact
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

# remove instance
#
# DELETE /cluster/{clusterKey}/instances/{instanceIdentifier}
export def "cluster-instances delete" [
  cluster_key: string
  instance_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the instance to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_key | is-empty) { error make --unspanned { msg: "path parameter 'clusterKey' must be non-empty" } }
  if ($instance_identifier | is-empty) { error make --unspanned { msg: "path parameter 'instanceIdentifier' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_key: (encode-path-segment $cluster_key), instance_identifier: (encode-path-segment $instance_identifier)} | format pattern "/cluster/{cluster_key}/instances/{instance_identifier}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get domains
#
# GET /domain
export def "domain list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of DomainFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any DomainFilter will be included.
]: nothing -> record<result: table<aliases: list, checksum: string, cors_config: record, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list, ssl_config: record, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domain" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filters": $filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# create domain
#
# POST /domain
# --cors_config shape: {allow_credentials?: bool, allowed_headers?: list<string>, allowed_methods: list<string>, allowed_origins: list<string>, exposed_headers?: list<string>, max_age?: int}
# --redirects item shape: {from: string, header_constraints?: list, name: string, redirect_type: "permanent"|"temporary", to: string}
# --ssl_config shape: {cert_key_pairs: list, cipher_filter?: string, protocols?: list<string>}
export def "domain create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aliases: list<string> # A set of alternate names that this Domain may be referenced by. May start ('*.') or end ('.*') with a wildcard.
  --checksum: string
  --cors-config: record # Experimental: Controls simple CORS responses for the associated domain. The configurable properties map closely to the CORS specification which should be referenced for a full discussion on their meaning: https://www.w3.org/TR/cors/ or https://developer.mozilla.org/docs/Web/HTTP/Access_control_CORS. — shape: {allow_credentials?: bool, allowed_headers?: list<string>, allowed_methods: list<string>, allowed_origins: list<string>, exposed_headers?: list<string>, max_age?: int}
  --domain-key: string
  --force-https: oneof<nothing, bool> # If set to true, requests must use TLS. If a request is not using TLS, (as determined by the scheme or the presence of X-Forwarded-Proto header), a 301 redirect will be sent telling the client to use HTTPS.
  --gzip-enabled: oneof<nothing, bool> # Experimental: if set to true will enable gzip compression on data that passes trough this domain
  name: string
  port: int
  --redirects: list # item shape: {from: string, header_constraints?: list, name: string, redirect_type: "permanent"|"temporary", to: string}
  --ssl-config: record # Experimental: Specifies whether a domain should support SSL/TLS connections from clients. If not set the proxy will expect unencrypted HTTP traffic. — shape: {cert_key_pairs: list, cipher_filter?: string, protocols?: list<string>}
  zone_key: string
]: any -> record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domain" $auth.query)
  let req_body = {"aliases": $aliases, "checksum": $checksum, "cors_config": $cors_config, "domain_key": $domain_key, "force_https": $force_https, "gzip_enabled": $gzip_enabled, "name": $name, "port": $port, "redirects": $redirects, "ssl_config": $ssl_config, "zone_key": $zone_key} | compact
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

# delete domain
#
# DELETE /domain/{domainKey}
export def "domain delete" [
  domain_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the domain to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_key | is-empty) { error make --unspanned { msg: "path parameter 'domainKey' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_key: (encode-path-segment $domain_key)} | format pattern "/domain/{domain_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get domain
#
# GET /domain/{domainKey}
export def "domain get" [
  domain_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<aliases: list<string>, checksum: string, cors_config: record<allow_credentials: bool, allowed_headers: list, allowed_methods: list, allowed_origins: list, exposed_headers: list, max_age: int>, domain_key: string, force_https: bool, gzip_enabled: bool, name: string, port: int, redirects: list<record>, ssl_config: record<cert_key_pairs: list, cipher_filter: string, protocols: list>, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_key | is-empty) { error make --unspanned { msg: "path parameter 'domainKey' must be non-empty" } }
  let full_url = (build-url $base ({domain_key: (encode-path-segment $domain_key)} | format pattern "/domain/{domain_key}") $auth.query)
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

# list listeners
#
# GET /listener
export def "listener list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ListenerFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ListenerFilter will be included.
]: nothing -> record<result: table<domain_keys: list, ip: string, name: string, port: int, protocol: string, tracing_config: record, zone_key: string, checksum: string, listener_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listener" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filters": $filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# create listener
#
# POST /listener
# --tracing_config shape: {ingress?: bool, request_headers_for_tags?: list<string>}
export def "listener create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list<string>
  --ip: string # the interface this listener should bind to.
  name: string
  port: int # the port this listener should bind to.
  protocol: string@protocol-completer # the protocol this listener will handle. http and http2 configure the listener to only process requests of that type. http_auto will adapt to HTTP/1.1 and HTTP/2 as needed. tcp configures the listener to be a tcp proxy
  --tracing-config: record # Configures tracing operations to be performed on the given listener — shape: {ingress?: bool, request_headers_for_tags?: list<string>}
  --zone-key: string
]: any -> record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/listener" $auth.query)
  let req_body = {"domain_keys": $domain_keys, "ip": $ip, "name": $name, "port": $port, "protocol": $protocol, "tracing_config": $tracing_config, "zone_key": $zone_key} | compact
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

# delete listener
#
# DELETE /listener/{listenerKey}
export def "listener delete" [
  listener_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the listener to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list<string>>, zone_key: string, checksum: string, listener_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($listener_key | is-empty) { error make --unspanned { msg: "path parameter 'listenerKey' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({listener_key: (encode-path-segment $listener_key)} | format pattern "/listener/{listener_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get listener
#
# GET /listener/{listenerKey}
export def "listener get" [
  listener_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($listener_key | is-empty) { error make --unspanned { msg: "path parameter 'listenerKey' must be non-empty" } }
  let full_url = (build-url $base ({listener_key: (encode-path-segment $listener_key)} | format pattern "/listener/{listener_key}") $auth.query)
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

# modify listener
#
# PUT /listener/{listenerKey}
# --tracing_config shape: {ingress?: bool, request_headers_for_tags?: list<string>}
export def "listener update" [
  listener_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list<string>
  --ip: string # the interface this listener should bind to.
  name: string
  port: int # the port this listener should bind to.
  protocol: string@protocol-completer # the protocol this listener will handle. http and http2 configure the listener to only process requests of that type. http_auto will adapt to HTTP/1.1 and HTTP/2 as needed. tcp configures the listener to be a tcp proxy
  --tracing-config: record # Configures tracing operations to be performed on the given listener — shape: {ingress?: bool, request_headers_for_tags?: list<string>}
  zone_key: string
  checksum: string
  --body-listener-key: string
]: any -> record<result: record<domain_keys: list<string>, ip: string, name: string, port: int, protocol: string, tracing_config: record<ingress: bool, request_headers_for_tags: list>, zone_key: string, checksum: string, listener_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($listener_key | is-empty) { error make --unspanned { msg: "path parameter 'listenerKey' must be non-empty" } }
  let full_url = (build-url $base ({listener_key: (encode-path-segment $listener_key)} | format pattern "/listener/{listener_key}") $auth.query)
  let req_body = {"domain_keys": $domain_keys, "ip": $ip, "name": $name, "port": $port, "protocol": $protocol, "tracing_config": $tracing_config, "zone_key": $zone_key, "checksum": $checksum, "listener_key": $body_listener_key} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# list proxies
#
# GET /proxy
export def "proxy list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ProxyFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ProxyFilter will be included.
]: nothing -> record<result: table<domain_keys: list, listener_keys: list, name: string, zone_key: string, checksum: string, proxy_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proxy" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filters": $filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# create proxy
#
# POST /proxy
export def "proxy create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-keys: list<string>
  --listener-keys: list<string>
  name: string
  zone_key: string
]: any -> record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/proxy" $auth.query)
  let req_body = {"domain_keys": $domain_keys, "listener_keys": $listener_keys, "name": $name, "zone_key": $zone_key} | compact
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

# delete proxy
#
# DELETE /proxy/{proxyKey}
export def "proxy delete" [
  proxy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the proxy to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proxy_key | is-empty) { error make --unspanned { msg: "path parameter 'proxyKey' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({proxy_key: (encode-path-segment $proxy_key)} | format pattern "/proxy/{proxy_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get proxy
#
# GET /proxy/{proxyKey}
export def "proxy get" [
  proxy_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<domain_keys: list<string>, listener_keys: list<string>, name: string, zone_key: string, checksum: string, proxy_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($proxy_key | is-empty) { error make --unspanned { msg: "path parameter 'proxyKey' must be non-empty" } }
  let full_url = (build-url $base ({proxy_key: (encode-path-segment $proxy_key)} | format pattern "/proxy/{proxy_key}") $auth.query)
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

# get routes
#
# GET /route
export def "route list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of RouteFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any RouteFilter will be included.
]: nothing -> record<result: table<checksum: string, cohort_seed: record, domain_key: string, path: string, response_data: record, retry_policy: record, route_key: string, rules: list, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/route" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filters": $filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# create route
#
# POST /route
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
export def "route create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  domain_key: string
  path: string
  --response-data: any # When a request is served by this Route annotate the response with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from Route take precedence over those from a SharedRules object.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --route-key: string
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  shared_rules_key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/route" $auth.query)
  let req_body = {"checksum": $checksum, "cohort_seed": $cohort_seed, "domain_key": $domain_key, "path": $path, "response_data": $response_data, "retry_policy": $retry_policy, "route_key": $route_key, "rules": $rules, "shared_rules_key": $shared_rules_key, "zone_key": $zone_key} | compact
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

# delete route
#
# DELETE /route/{routeKey}
export def "route delete" [
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the route to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_key | is-empty) { error make --unspanned { msg: "path parameter 'routeKey' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_key: (encode-path-segment $route_key)} | format pattern "/route/{route_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get route
#
# GET /route/{routeKey}
export def "route get" [
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_key | is-empty) { error make --unspanned { msg: "path parameter 'routeKey' must be non-empty" } }
  let full_url = (build-url $base ({route_key: (encode-path-segment $route_key)} | format pattern "/route/{route_key}") $auth.query)
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

# modify route
#
# PUT /route/{routeKey}
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
export def "route update" [
  route_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  domain_key: string
  path: string
  --response-data: any # When a request is served by this Route annotate the response with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from Route take precedence over those from a SharedRules object.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --body-route-key: string
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  shared_rules_key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, domain_key: string, path: string, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, route_key: string, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_key | is-empty) { error make --unspanned { msg: "path parameter 'routeKey' must be non-empty" } }
  let full_url = (build-url $base ({route_key: (encode-path-segment $route_key)} | format pattern "/route/{route_key}") $auth.query)
  let req_body = {"checksum": $checksum, "cohort_seed": $cohort_seed, "domain_key": $domain_key, "path": $path, "response_data": $response_data, "retry_policy": $retry_policy, "route_key": $body_route_key, "rules": $rules, "shared_rules_key": $shared_rules_key, "zone_key": $zone_key} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# get shared_rules
#
# GET /shared_rules
export def "shared-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of SharedRulesFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any SharedRulesFilter will be included.
]: nothing -> record<result: table<checksum: string, cohort_seed: record, default: record, properties: list, response_data: record, retry_policy: record, rules: list, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shared_rules" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filters": $filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# create shared_rules
#
# POST /shared_rules
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --default shape: {dark?: list, light: list, tap?: list}
# --properties item shape: {key?: string, value?: string}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
export def "shared-rules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  default: record # shape: {dark?: list, light: list, tap?: list}
  --properties: list # item shape: {key?: string, value?: string}
  --response-data: any # When a request is served by a Route that is part of this SharedRules group the response is annotated with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from the applicable Route and ClusterConstarint takes precedence over those specified here.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  --shared-rules-key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shared_rules" $auth.query)
  let req_body = {"checksum": $checksum, "cohort_seed": $cohort_seed, "default": $default, "properties": $properties, "response_data": $response_data, "retry_policy": $retry_policy, "rules": $rules, "shared_rules_key": $shared_rules_key, "zone_key": $zone_key} | compact
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

# delete shared_rules object
#
# DELETE /shared_rules/{sharedRulesKey}
export def "shared-rules delete" [
  shared_rules_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the shared_rules to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_rules_key | is-empty) { error make --unspanned { msg: "path parameter 'sharedRulesKey' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shared_rules_key: (encode-path-segment $shared_rules_key)} | format pattern "/shared_rules/{shared_rules_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get shared_rules object
#
# GET /shared_rules/{sharedRulesKey}
export def "shared-rules get" [
  shared_rules_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_rules_key | is-empty) { error make --unspanned { msg: "path parameter 'sharedRulesKey' must be non-empty" } }
  let full_url = (build-url $base ({shared_rules_key: (encode-path-segment $shared_rules_key)} | format pattern "/shared_rules/{shared_rules_key}") $auth.query)
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

# modify shared_rules object
#
# PUT /shared_rules/{sharedRulesKey}
# --cohort_seed shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
# --default shape: {dark?: list, light: list, tap?: list}
# --properties item shape: {key?: string, value?: string}
# --retry_policy shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
# --rules item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
export def "shared-rules update" [
  shared_rules_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  checksum: string
  --cohort-seed: record # shape: {name?: string, type?: "header"|"cookie"|"query", use_zero_value_seed?: bool}
  default: record # shape: {dark?: list, light: list, tap?: list}
  --properties: list # item shape: {key?: string, value?: string}
  --response-data: any # When a request is served by a Route that is part of this SharedRules group the response is annotated with the information specified within this ResponseData object. It's possible that multiple response data configurations will apply; if that's the case then the values from the applicable Route and ClusterConstarint takes precedence over those specified here.
  --retry-policy: record # Number of times to retry a request and how long to wait before timing out. — shape: {num_retries?: int, per_try_timeout_msec?: int, timeout_msec?: int}
  --rules: list # item shape: {cohort_seed?: record, constraints?: record, matches?: list, methods?: list<string>, rule_key?: string}
  --body-shared-rules-key: string
  zone_key: string
]: any -> record<result: record<checksum: string, cohort_seed: record<name: string, type: string, use_zero_value_seed: bool>, default: record<dark: list, light: list, tap: list>, properties: list<record>, response_data: record<cookies: list, headers: list>, retry_policy: record<num_retries: int, per_try_timeout_msec: int, timeout_msec: int>, rules: list<record>, shared_rules_key: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($shared_rules_key | is-empty) { error make --unspanned { msg: "path parameter 'sharedRulesKey' must be non-empty" } }
  let full_url = (build-url $base ({shared_rules_key: (encode-path-segment $shared_rules_key)} | format pattern "/shared_rules/{shared_rules_key}") $auth.query)
  let req_body = {"checksum": $checksum, "cohort_seed": $cohort_seed, "default": $default, "properties": $properties, "response_data": $response_data, "retry_policy": $retry_policy, "rules": $rules, "shared_rules_key": $body_shared_rules_key, "zone_key": $zone_key} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# get a list of zones
#
# GET /zone
export def "zone list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded array of ZoneFilter objects. The filter is taken as a union of intersections. In other words an object that matches every constraint in any ZoneFilter will be included.
]: nothing -> record<result: table<checksum: string, name: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/zone" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filters": $filters} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# create zone
#
# POST /zone
export def "zone create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<result: record<checksum: string, name: string, zone_key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/zone" $auth.query)
  let req_body = {"name": $name} | compact
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

# delete zone
#
# DELETE /zone/{zoneKey}
export def "zone delete" [
  zone_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checksum: string # the current checksum of the zone to be deleted (e.g. 9cd24183-f848-48f8-6f55-0f07240700b9)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_key | is-empty) { error make --unspanned { msg: "path parameter 'zoneKey' must be non-empty" } }
  let qp = [(serialize-qp "checksum" $checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({zone_key: (encode-path-segment $zone_key)} | format pattern "/zone/{zone_key}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"checksum": $checksum} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# get zone
#
# GET /zone/{zoneKey}
export def "zone get" [
  zone_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<checksum: string, name: string, zone_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_key | is-empty) { error make --unspanned { msg: "path parameter 'zoneKey' must be non-empty" } }
  let full_url = (build-url $base ({zone_key: (encode-path-segment $zone_key)} | format pattern "/zone/{zone_key}") $auth.query)
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
