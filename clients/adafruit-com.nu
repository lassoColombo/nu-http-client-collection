# Auto-generated client for Adafruit IO REST API v2.0.0
# Source: https://api.apis.guru/v2/specs/adafruit.com/2.0.0/swagger.json
# Auth: --token flag or $env.ADAFRUIT_IO_REST_API_TOKEN

const BASE_URL = "https://io.adafruit.com/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ADAFRUIT_IO_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-aio-key" => { {scheme: $scheme, headers: {X-AIO-Key: $token_val}, query: "", location: "header"} }
    "x-aio-signature" => { {scheme: $scheme, headers: {X-AIO-Signature: $token_val}, query: "", location: "header"} }
    "query-X-AIO-Key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "X-AIO-Key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://io.adafruit.com/api/v2" "http://io.adafruit.com/api/v2"] }
def auth-scheme-completer [] { ["x-aio-key" "x-aio-signature" "query-X-AIO-Key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/csv"] }
def mode-completer [] { ["r" "rw" "w"] }
def scope-completer [] { ["organization" "public" "secret" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "user get" } } | get name | first)
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

# Get information about the current user
#
# GET /user
# operationId: currentUser
export def "user get" [
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
]: nothing -> record<color: string, created_at: string, id: float, name: string, time_zone: string, updated_at: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user" $auth.query)
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

# Send data to a feed via webhook URL.
#
# POST /webhooks/feed/:token
# operationId: createWebhookFeedData
export def "webhooks-feed-token create-data" [
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
  --value: string
]: any -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/feed/:token" $auth.query)
  let req_body = {"value": $value} | compact
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

# Send arbitrary data to a feed via webhook URL.
#
# POST /webhooks/feed/:token/raw
# operationId: createRawWebhookFeedData
export def "webhooks-feed-token-raw create-data" [
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
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/feed/:token/raw" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# All activities for current user
#
# DELETE /{username}/activities
# operationId: destroyActivities
export def "activities delete" [
  username: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/activities") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# All activities for current user
#
# GET /{username}/activities
# operationId: allActivities
export def "activities list" [
  username: string
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
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/activities") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_time": $start_time, "end_time": $end_time, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get activities by type for current user
#
# GET /{username}/activities/{type}
# operationId: getActivity
export def "activities get-activity" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> table<action: string, created_at: string, data: record, id: float, model: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), type: (encode-path-segment $type)} | format pattern "/{username}/activities/{type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_time": $start_time, "end_time": $end_time, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# All dashboards for current user
#
# GET /{username}/dashboards
# operationId: allDashboards
export def "dashboards list" [
  username: string
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
]: nothing -> table<blocks: list<record>, description: string, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/dashboards") $auth.query)
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

# Create a new Dashboard
#
# POST /{username}/dashboards
# operationId: createDashboard
export def "dashboards create" [
  username: string
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
  --description: string
  --key: string
  --name: string
]: any -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/dashboards") $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name} | compact
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

# All blocks for current user
#
# GET /{username}/dashboards/{dashboard_id}/blocks
# operationId: allBlocks
export def "dashboards-blocks list" [
  username: string
  dashboard_id: string
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
]: nothing -> table<block_feeds: list<record>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($dashboard_id | is-empty) { error make --unspanned { msg: "path parameter 'dashboard_id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/{username}/dashboards/{dashboard_id}/blocks") $auth.query)
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

# Create a new Block
#
# POST /{username}/dashboards/{dashboard_id}/blocks
# operationId: createBlock
# --block_feeds item shape: {feed_id?: string, group_id?: string}
export def "dashboards-blocks create" [
  username: string
  dashboard_id: string
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
  --block-feeds: list # item shape: {feed_id?: string, group_id?: string}
  --column: float
  --body-dashboard-id: float
  --description: string
  --key: string
  --name: string
  --properties: record
  --row: float
  --size-x: float
  --size-y: float
  --visual-type: string
]: any -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($dashboard_id | is-empty) { error make --unspanned { msg: "path parameter 'dashboard_id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), dashboard_id: (encode-path-segment $dashboard_id)} | format pattern "/{username}/dashboards/{dashboard_id}/blocks") $auth.query)
  let req_body = {"block_feeds": $block_feeds, "column": $column, "dashboard_id": $body_dashboard_id, "description": $description, "key": $key, "name": $name, "properties": $properties, "row": $row, "size_x": $size_x, "size_y": $size_y, "visual_type": $visual_type} | compact
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

# Delete an existing Block
#
# DELETE /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: destroyBlock
export def "dashboards-blocks delete" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($dashboard_id | is-empty) { error make --unspanned { msg: "path parameter 'dashboard_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), dashboard_id: (encode-path-segment $dashboard_id), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns Block based on ID
#
# GET /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: getBlock
export def "dashboards-blocks get" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($dashboard_id | is-empty) { error make --unspanned { msg: "path parameter 'dashboard_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), dashboard_id: (encode-path-segment $dashboard_id), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}") $auth.query)
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

# Update properties of an existing Block
#
# PATCH /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: updateBlock
# --block_feeds item shape: {feed_id?: string, group_id?: string}
export def "dashboards-blocks update-by-username-dashboard-id" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
  --block-feeds: list # item shape: {feed_id?: string, group_id?: string}
  --column: float
  --body-dashboard-id: float
  --description: string
  --key: string
  --name: string
  --properties: record
  --row: float
  --size-x: float
  --size-y: float
  --visual-type: string
]: any -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($dashboard_id | is-empty) { error make --unspanned { msg: "path parameter 'dashboard_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), dashboard_id: (encode-path-segment $dashboard_id), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}") $auth.query)
  let req_body = {"block_feeds": $block_feeds, "column": $column, "dashboard_id": $body_dashboard_id, "description": $description, "key": $key, "name": $name, "properties": $properties, "row": $row, "size_x": $size_x, "size_y": $size_y, "visual_type": $visual_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace an existing Block
#
# PUT /{username}/dashboards/{dashboard_id}/blocks/{id}
# operationId: replaceBlock
# --block_feeds item shape: {feed_id?: string, group_id?: string}
export def "dashboards-blocks update-by-username-dashboard-id-1" [
  username: string
  dashboard_id: string
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
  --accept: string@accept-completer # Response content type
  --block-feeds: list # item shape: {feed_id?: string, group_id?: string}
  --column: float
  --body-dashboard-id: float
  --description: string
  --key: string
  --name: string
  --properties: record
  --row: float
  --size-x: float
  --size-y: float
  --visual-type: string
]: any -> record<block_feeds: table<feed: record, group: record, id: string>, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($dashboard_id | is-empty) { error make --unspanned { msg: "path parameter 'dashboard_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), dashboard_id: (encode-path-segment $dashboard_id), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{dashboard_id}/blocks/{id}") $auth.query)
  let req_body = {"block_feeds": $block_feeds, "column": $column, "dashboard_id": $body_dashboard_id, "description": $description, "key": $key, "name": $name, "properties": $properties, "row": $row, "size_x": $size_x, "size_y": $size_y, "visual_type": $visual_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete an existing Dashboard
#
# DELETE /{username}/dashboards/{id}
# operationId: destroyDashboard
export def "dashboards delete" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns Dashboard based on ID
#
# GET /{username}/dashboards/{id}
# operationId: getDashboard
export def "dashboards get" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{id}") $auth.query)
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

# Update properties of an existing Dashboard
#
# PATCH /{username}/dashboards/{id}
# operationId: updateDashboard
export def "dashboards update-by-username-id" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --description: string
  --key: string
  --name: string
]: any -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{id}") $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace an existing Dashboard
#
# PUT /{username}/dashboards/{id}
# operationId: replaceDashboard
export def "dashboards update-by-username-id-1" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --description: string
  --key: string
  --name: string
]: any -> record<blocks: table<block_feeds: list, column: float, description: string, key: string, name: string, row: float, size_x: float, size_y: float, visual_type: string>, description: string, key: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/dashboards/{id}") $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# All feeds for current user
#
# GET /{username}/feeds
# operationId: allFeeds
export def "feeds list" [
  username: string
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
]: nothing -> table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/feeds") $auth.query)
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

# Create a new Feed
#
# POST /{username}/feeds
# operationId: createFeed
export def "feeds create" [
  username: string
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
  --group-key: string
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "group_key" $group_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/feeds") $qp $auth.query)
  let req_body = {"description": $description, "key": $key, "license": $license, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"group_key": $group_key} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an existing Feed
#
# DELETE /{username}/feeds/{feed_key}
# operationId: destroyFeed
export def "feeds delete" [
  username: string
  feed_key: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get feed by feed key
#
# GET /{username}/feeds/{feed_key}
# operationId: getFeed
export def "feeds get" [
  username: string
  feed_key: string
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
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}") $auth.query)
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

# Update properties of an existing Feed
#
# PATCH /{username}/feeds/{feed_key}
# operationId: updateFeed
export def "feeds update-by-username-feed-key" [
  username: string
  feed_key: string
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
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}") $auth.query)
  let req_body = {"description": $description, "key": $key, "license": $license, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace an existing Feed
#
# PUT /{username}/feeds/{feed_key}
# operationId: replaceFeed
export def "feeds update-by-username-feed-key-1" [
  username: string
  feed_key: string
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
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}") $auth.query)
  let req_body = {"description": $description, "key": $key, "license": $license, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get all data for the given feed
#
# GET /{username}/feeds/{feed_key}/data
# operationId: allData
export def "feeds-data list" [
  username: string
  feed_key: string
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
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_time": $start_time, "end_time": $end_time, "limit": $limit, "include": $include} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new Data
#
# POST /{username}/feeds/{feed_key}/data
# operationId: createData
export def "feeds-data create" [
  username: string
  feed_key: string
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
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data") $auth.query)
  let req_body = {"created_at": $created_at, "ele": $ele, "epoch": $epoch, "lat": $lat, "lon": $lon, "value": $value} | compact
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

# Create multiple new Data records
#
# POST /{username}/feeds/{feed_key}/data/batch
# operationId: batchCreateData
export def "feeds-data-batch create" [
  username: string
  feed_key: string
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
  --body: list
]: any -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data/batch") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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

# Chart data for current feed
#
# GET /{username}/feeds/{feed_key}/data/chart
# operationId: chartData
export def "feeds-data-chart get" [
  username: string
  feed_key: string
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
  --start-time: string # Start time for filtering, returns records created after given time. (format: date-time)
  --end-time: string # End time for filtering, returns records created before give time. (format: date-time)
  --resolution: int # A resolution size in minutes. By giving a resolution value you will get back grouped data points aggregated over resolution-sized intervals. NOTE: time span is preferred over resolution, so if you request a span of time that includes more than max limit points you may get a larger resolution than you requested. Valid resolutions are 1, 5, 10, 30, 60, and 120. (format: int32)
  --hours: int # The number of hours the chart should cover. (format: int32)
]: nothing -> record<columns: list<string>, data: list<list<string>>, feed: record<id: int, key: string, name: string>, parameters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "hours" $hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data/chart") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_time": $start_time, "end_time": $end_time, "resolution": $resolution, "hours": $hours} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# First Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/first
# operationId: firstData
export def "feeds-data-first get" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data/first") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Last Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/last
# operationId: lastData
export def "feeds-data-last get" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data/last") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Next Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/next
# operationId: nextData
export def "feeds-data-next get" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data/next") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Previous Data in Queue
#
# GET /{username}/feeds/{feed_key}/data/previous
# operationId: previousData
export def "feeds-data-previous get" [
  username: string
  feed_key: string
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
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data/previous") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Last Data in MQTT CSV format
#
# GET /{username}/feeds/{feed_key}/data/retain
# operationId: retainData
export def "feeds-data-retain get" [
  username: string
  feed_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/data/retain") $auth.query)
  let accept_val = "text/csv"
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

# Delete existing Data
#
# DELETE /{username}/feeds/{feed_key}/data/{id}
# operationId: destroyData
export def "feeds-data delete" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key), id: (encode-path-segment $id)} | format pattern "/{username}/feeds/{feed_key}/data/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns data based on feed key
#
# GET /{username}/feeds/{feed_key}/data/{id}
# operationId: getData
export def "feeds-data get" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
  --include: string # List of Data record fields to include in response as comma separated list. Acceptable values are: `value`, `lat`, `lon`, `ele`, `id`, and `created_at`.
]: nothing -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key), id: (encode-path-segment $id)} | format pattern "/{username}/feeds/{feed_key}/data/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update properties of existing Data
#
# PATCH /{username}/feeds/{feed_key}/data/{id}
# operationId: updateData
export def "feeds-data update-by-username-feed-key-id" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key), id: (encode-path-segment $id)} | format pattern "/{username}/feeds/{feed_key}/data/{id}") $auth.query)
  let req_body = {"created_at": $created_at, "ele": $ele, "epoch": $epoch, "lat": $lat, "lon": $lon, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace existing Data
#
# PUT /{username}/feeds/{feed_key}/data/{id}
# operationId: replaceData
export def "feeds-data update-by-username-feed-key-id-1" [
  username: string
  feed_key: string
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
  --accept: string@accept-completer # Response content type
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key), id: (encode-path-segment $id)} | format pattern "/{username}/feeds/{feed_key}/data/{id}") $auth.query)
  let req_body = {"created_at": $created_at, "ele": $ele, "epoch": $epoch, "lat": $lat, "lon": $lon, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get detailed feed by feed key
#
# GET /{username}/feeds/{feed_key}/details
# operationId: getFeedDetails
export def "feeds-details get" [
  username: string
  feed_key: string
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
]: nothing -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/feeds/{feed_key}/details") $auth.query)
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

# All groups for current user
#
# GET /{username}/groups
# operationId: allGroups
export def "groups list" [
  username: string
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
]: nothing -> table<created_at: string, description: string, feeds: list<record>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/groups") $auth.query)
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

# Create a new Group
#
# POST /{username}/groups
# operationId: createGroup
export def "groups create" [
  username: string
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
  --description: string
  --key: string
  --name: string
]: any -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/groups") $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name} | compact
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

# Delete an existing Group
#
# DELETE /{username}/groups/{group_key}
# operationId: destroyGroup
export def "groups delete" [
  username: string
  group_key: string
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns Group based on ID
#
# GET /{username}/groups/{group_key}
# operationId: getGroup
export def "groups get" [
  username: string
  group_key: string
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
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}") $auth.query)
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

# Update properties of an existing Group
#
# PATCH /{username}/groups/{group_key}
# operationId: updateGroup
export def "groups update-by-username-group-key" [
  username: string
  group_key: string
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
  --description: string
  --key: string
  --name: string
]: any -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}") $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace an existing Group
#
# PUT /{username}/groups/{group_key}
# operationId: replaceGroup
export def "groups update-by-username-group-key-1" [
  username: string
  group_key: string
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
  --description: string
  --key: string
  --name: string
]: any -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}") $auth.query)
  let req_body = {"description": $description, "key": $key, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Add an existing Feed to a Group
#
# POST /{username}/groups/{group_key}/add
# operationId: addFeedToGroup
export def "groups-add create-feed" [
  username: string
  group_key: string
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
  --feed-key: string
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let qp = [(serialize-qp "feed_key" $feed_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}/add") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"feed_key": $feed_key} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Create new data for multiple feeds in a group
#
# POST /{username}/groups/{group_key}/data
# operationId: createGroupData
# --feeds item shape: {key: string, value: string}
# --location shape: {ele?: float, lat: float, lon: float}
export def "groups-data create" [
  username: string
  group_key: string
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
  --created-at: string # Optional created_at timestamp which will be applied to all feed values created.
  feeds: list # An array of feed data records with `key` and `value` properties. — item shape: {key: string, value: string}
  --location: record # A location record with `lat`, `lon`, and [optional] `ele` properties. — shape: {ele?: float, lat: float, lon: float}
]: any -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}/data") $auth.query)
  let req_body = {"created_at": $created_at, "feeds": $feeds, "location": $location} | compact
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

# All feeds for current user in a given group
#
# GET /{username}/groups/{group_key}/feeds
# operationId: allGroupFeeds
export def "groups-feeds list" [
  username: string
  group_key: string
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
]: nothing -> table<created_at: string, description: string, details: record<data: record, shared_with: list>, enabled: bool, group: record, groups: list<record>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}/feeds") $auth.query)
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

# Create a new Feed in a Group
#
# POST /{username}/groups/{group_key}/feeds
# operationId: createGroupFeed
export def "groups-feeds create" [
  username: string
  group_key: string
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
  --description: string
  --key: string
  --license: string
  --name: string
]: any -> record<created_at: string, description: string, details: record<data: record<count: int, first: record, last: record>, shared_with: list<record>>, enabled: bool, group: record, groups: table<created_at: string, description: string, id: float, name: string, updated_at: string>, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}/feeds") $auth.query)
  let req_body = {"description": $description, "key": $key, "license": $license, "name": $name} | compact
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

# All data for current feed in a specific group
#
# GET /{username}/groups/{group_key}/feeds/{feed_key}/data
# operationId: allGroupFeedData
export def "groups-feeds-data list" [
  username: string
  group_key: string
  feed_key: string
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
  --start-time: string # Start time for filtering data. Returns data created after given time. (format: date-time)
  --end-time: string # End time for filtering data. Returns data created before give time. (format: date-time)
  --limit: int # Limit the number of records returned.
]: nothing -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/groups/{group_key}/feeds/{feed_key}/data") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_time": $start_time, "end_time": $end_time, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new Data in a feed belonging to a particular group
#
# POST /{username}/groups/{group_key}/feeds/{feed_key}/data
# operationId: createGroupFeedData
export def "groups-feeds-data create" [
  username: string
  group_key: string
  feed_key: string
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
  --created-at: string # format: dateTime
  --ele: string
  --epoch: float
  --lat: string
  --lon: string
  --value: string
]: any -> record<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/groups/{group_key}/feeds/{feed_key}/data") $auth.query)
  let req_body = {"created_at": $created_at, "ele": $ele, "epoch": $epoch, "lat": $lat, "lon": $lon, "value": $value} | compact
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

# Create multiple new Data records in a feed belonging to a particular group
#
# POST /{username}/groups/{group_key}/feeds/{feed_key}/data/batch
# operationId: batchCreateGroupFeedData
export def "groups-feeds-data-batch create" [
  username: string
  group_key: string
  feed_key: string
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
  --body: list
]: any -> table<completed_at: string, created_at: string, created_epoch: float, ele: float, expiration: string, feed_id: float, group_id: float, id: string, lat: float, lon: float, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  if ($feed_key | is-empty) { error make --unspanned { msg: "path parameter 'feed_key' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key), feed_key: (encode-path-segment $feed_key)} | format pattern "/{username}/groups/{group_key}/feeds/{feed_key}/data/batch") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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

# Remove a Feed from a Group
#
# POST /{username}/groups/{group_key}/remove
# operationId: removeFeedFromGroup
export def "groups-remove delete-feed" [
  username: string
  group_key: string
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
  --feed-key: string
]: nothing -> record<created_at: string, description: string, feeds: table<created_at: string, description: string, details: record, enabled: bool, group: record, groups: list, history: bool, id: float, key: string, last_value: string, license: string, name: string, status: string, status_notify: bool, status_timeout: int, unit_symbol: string, unit_type: string, updated_at: string, visibility: string>, id: float, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'group_key' must be non-empty" } }
  let qp = [(serialize-qp "feed_key" $feed_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), group_key: (encode-path-segment $group_key)} | format pattern "/{username}/groups/{group_key}/remove") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"feed_key": $feed_key} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get the user's data rate limit and current activity level.
#
# GET /{username}/throttle
# operationId: getCurrentUserThrottle
export def "throttle get-user" [
  username: string
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
]: nothing -> record<active_data_rate: int, data_rate_limit: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/throttle") $auth.query)
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

# All tokens for current user
#
# GET /{username}/tokens
# operationId: allTokens
export def "tokens list" [
  username: string
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
]: nothing -> table<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/tokens") $auth.query)
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

# Create a new Token
#
# POST /{username}/tokens
# operationId: createToken
export def "tokens create" [
  username: string
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
  --body-token: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/tokens") $auth.query)
  let req_body = {"token": $body_token} | compact
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

# Delete an existing Token
#
# DELETE /{username}/tokens/{id}
# operationId: destroyToken
export def "tokens delete" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/tokens/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns Token based on ID
#
# GET /{username}/tokens/{id}
# operationId: getToken
export def "tokens get" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/tokens/{id}") $auth.query)
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

# Update properties of an existing Token
#
# PATCH /{username}/tokens/{id}
# operationId: updateToken
export def "tokens update-by-username-id" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --body-token: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/tokens/{id}") $auth.query)
  let req_body = {"token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace an existing Token
#
# PUT /{username}/tokens/{id}
# operationId: replaceToken
export def "tokens update-by-username-id-1" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --body-token: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/tokens/{id}") $auth.query)
  let req_body = {"token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# All triggers for current user
#
# GET /{username}/triggers
# operationId: allTriggers
export def "triggers list" [
  username: string
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
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/triggers") $auth.query)
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

# Create a new Trigger
#
# POST /{username}/triggers
# operationId: createTrigger
export def "triggers create" [
  username: string
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
  --name: string
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/{username}/triggers") $auth.query)
  let req_body = {"name": $name} | compact
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

# Delete an existing Trigger
#
# DELETE /{username}/triggers/{id}
# operationId: destroyTrigger
export def "triggers delete" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/triggers/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns Trigger based on ID
#
# GET /{username}/triggers/{id}
# operationId: getTrigger
export def "triggers get" [
  username: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/triggers/{id}") $auth.query)
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

# Update properties of an existing Trigger
#
# PATCH /{username}/triggers/{id}
# operationId: updateTrigger
export def "triggers update-by-username-id" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --name: string
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/triggers/{id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace an existing Trigger
#
# PUT /{username}/triggers/{id}
# operationId: replaceTrigger
export def "triggers update-by-username-id-1" [
  username: string
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
  --accept: string@accept-completer # Response content type
  --name: string
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), id: (encode-path-segment $id)} | format pattern "/{username}/triggers/{id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# All permissions for current user and type
#
# GET /{username}/{type}/{type_id}/acl
# operationId: allPermissions
export def "acl list-permissions" [
  username: string
  type: string
  type_id: string
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
]: nothing -> table<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($type_id | is-empty) { error make --unspanned { msg: "path parameter 'type_id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), type: (encode-path-segment $type), type_id: (encode-path-segment $type_id)} | format pattern "/{username}/{type}/{type_id}/acl") $auth.query)
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

# Create a new Permission
#
# POST /{username}/{type}/{type_id}/acl
# operationId: createPermission
export def "acl create-permission" [
  username: string
  type: string
  type_id: string
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
  --mode: string@mode-completer # default: r
  --scope: string@scope-completer # default: public
  --scope-value: string
]: any -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($type_id | is-empty) { error make --unspanned { msg: "path parameter 'type_id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), type: (encode-path-segment $type), type_id: (encode-path-segment $type_id)} | format pattern "/{username}/{type}/{type_id}/acl") $auth.query)
  let req_body = {"mode": $mode, "scope": $scope, "scope_value": $scope_value} | compact
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

# Delete an existing Permission
#
# DELETE /{username}/{type}/{type_id}/acl/{id}
# operationId: destroyPermission
export def "acl delete-permission" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($type_id | is-empty) { error make --unspanned { msg: "path parameter 'type_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), type: (encode-path-segment $type), type_id: (encode-path-segment $type_id), id: (encode-path-segment $id)} | format pattern "/{username}/{type}/{type_id}/acl/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Returns Permission based on ID
#
# GET /{username}/{type}/{type_id}/acl/{id}
# operationId: getPermission
export def "acl get-permission" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($type_id | is-empty) { error make --unspanned { msg: "path parameter 'type_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), type: (encode-path-segment $type), type_id: (encode-path-segment $type_id), id: (encode-path-segment $id)} | format pattern "/{username}/{type}/{type_id}/acl/{id}") $auth.query)
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

# Update properties of an existing Permission
#
# PATCH /{username}/{type}/{type_id}/acl/{id}
# operationId: updatePermission
export def "acl update-permission-by-username-type-id" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
  --mode: string@mode-completer # default: r
  --scope: string@scope-completer # default: public
  --scope-value: string
]: any -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($type_id | is-empty) { error make --unspanned { msg: "path parameter 'type_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), type: (encode-path-segment $type), type_id: (encode-path-segment $type_id), id: (encode-path-segment $id)} | format pattern "/{username}/{type}/{type_id}/acl/{id}") $auth.query)
  let req_body = {"mode": $mode, "scope": $scope, "scope_value": $scope_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Replace an existing Permission
#
# PUT /{username}/{type}/{type_id}/acl/{id}
# operationId: replacePermission
export def "acl update-permission-by-username-type-id-1" [
  username: string
  type: string
  type_id: string
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
  --accept: string@accept-completer # Response content type
  --mode: string@mode-completer # default: r
  --scope: string@scope-completer # default: public
  --scope-value: string
]: any -> record<created_at: string, id: float, model: string, object_id: float, scope: string, scope_value: string, updated_at: string, user_id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-aio-key"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($type_id | is-empty) { error make --unspanned { msg: "path parameter 'type_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), type: (encode-path-segment $type), type_id: (encode-path-segment $type_id), id: (encode-path-segment $id)} | format pattern "/{username}/{type}/{type_id}/acl/{id}") $auth.query)
  let req_body = {"mode": $mode, "scope": $scope, "scope_value": $scope_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
