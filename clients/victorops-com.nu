# Auto-generated client for VictorOps v0.0.3
# Source: https://api.apis.guru/v2/specs/victorops.com/0.0.3/swagger.json
# Auth: --token flag or $env.VICTOROPS_TOKEN

const BASE_URL = "https://api.victorops.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VICTOROPS_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.victorops.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["RoutingKeys"] }
def timeout-completer [] { ["1" "10" "15" "20" "25" "30" "45" "5" "60"] }
def type-completer-1 [] { ["email" "phone" "push" "sms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-public-alerts get" } } | get name | first)
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

# Retrieve alert details.
#
# GET /api-public/v1/alerts/{uuid}
export def "api-public-alerts get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<ackAuthor: string, ackMsg: string, entityDisplayName: string, entityId: string, messageType: string, monitoringTool: string, raw: string, stateMessage: string, stateStartTime: float, timestamp: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/api-public/v1/alerts/{uuid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get current incident information
#
# GET /api-public/v1/incidents
export def "api-public-incidents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Create a new incident
#
# POST /api-public/v1/incidents
# --targets item shape: {slug: string, type: "User"|"EscalationPolicy"}
export def "api-public-incidents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  details: string
  summary: string
  targets: list # item shape: {slug: string, type: "User"|"EscalationPolicy"}
  user_name: string
]: any -> record<error: string, incidentNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents" $auth.query)
  let req_body = {"details": $details, "summary": $summary, "targets": $targets, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Acknowledge an incident or list of incidents
#
# PATCH /api-public/v1/incidents/ack
export def "api-public-incidents-ack update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  incident_names: list<string>
  --message: string
  user_name: string
]: any -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/ack" $auth.query)
  let req_body = {"incidentNames": $incident_names, "message": $message, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Acknowledge all incidents for which a user was paged.
#
# PATCH /api-public/v1/incidents/byUser/ack
export def "api-public-incidents-by-user-ack update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --message: string
  user_name: string
]: any -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/byUser/ack" $auth.query)
  let req_body = {"message": $message, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Resolve all incidents for which a user was paged.
#
# PATCH /api-public/v1/incidents/byUser/resolve
export def "api-public-incidents-by-user-resolve update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --message: string
  user_name: string
]: any -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/byUser/resolve" $auth.query)
  let req_body = {"message": $message, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Reroute one or more incidents to one or more new routable destinations.
#
# POST /api-public/v1/incidents/reroute
# --reroutes item shape: {incidentNumber: string, targets: list}
export def "api-public-incidents-reroute create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  reroutes: list # item shape: {incidentNumber: string, targets: list}
  user_name: string
]: any -> record<statuses: table<incidentNumber: string, message: string, success: bool, targetStatus: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/reroute" $auth.query)
  let req_body = {"reroutes": $reroutes, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Resolve an incident or list of incidents
#
# PATCH /api-public/v1/incidents/resolve
export def "api-public-incidents-resolve update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  incident_names: list<string>
  --message: string
  user_name: string
]: any -> record<results: table<cmdAccepted: bool, entityId: string, incidentNumber: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/incidents/resolve" $auth.query)
  let req_body = {"incidentNames": $incident_names, "message": $message, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get an organization's current maintenance mode state
#
# GET /api-public/v1/maintenancemode
export def "api-public-maintenancemode get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/maintenancemode" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Start maintenance mode for routing keys
#
# POST /api-public/v1/maintenancemode/start
export def "api-public-maintenancemode-start create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --names: list<string> # Routing keys that maintenance mode state covers. An empty list indicates global maintenance mode
  --purpose: string # the reason for the maintenance mode
  --type: string@type-completer
]: any -> record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/maintenancemode/start" $auth.query)
  let req_body = {"names": $names, "purpose": $purpose, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# End maintenance mode for routing keys
#
# PUT /api-public/v1/maintenancemode/{maintenancemodeid}/end
export def "api-public-maintenancemode-end update" [
  maintenancemodeid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<activeInstances: table<instanceId: string, isGlobal: bool, startedAt: float, startedBy: string, targets: list>, companyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($maintenancemodeid | is-empty) { error make --unspanned { msg: "path parameter 'maintenancemodeid' must be non-empty" } }
  let full_url = (build-url $base ({maintenancemodeid: (encode-path-segment $maintenancemodeid)} | format pattern "/api-public/v1/maintenancemode/{maintenancemodeid}/end") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get an organization's on-call users
#
# GET /api-public/v1/oncall/current
export def "api-public-oncall-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teamsOnCall: table<onCallNow: list, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/oncall/current" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# List routing keys with associated teams
#
# GET /api-public/v1/org/routing-keys
export def "api-public-org-routing-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, routingKeys: table<isDefault: bool, routingKey: string, targets: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/org/routing-keys" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# List the scheduled overrides
#
# GET /api-public/v1/overrides
export def "api-public-overrides list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, overrides: table<assignments: list, end: string, publicId: string, start: string, timezone: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/overrides" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Creates a new scheduled override
#
# POST /api-public/v1/overrides
export def "api-public-overrides create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --end: string # The override end time (ISO 8601)
  --start: string # The override start time (ISO 8601)
  --timezone: string
  --username: string
]: any -> record<_selfUrl: string, schedule: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/overrides" $auth.query)
  let req_body = {"end": $end, "start": $start, "timezone": $timezone, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Deletes a scheduled override
#
# DELETE /api-public/v1/overrides/{publicId}
export def "api-public-overrides delete" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($public_id | is-empty) { error make --unspanned { msg: "path parameter 'publicId' must be non-empty" } }
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id)} | format pattern "/api-public/v1/overrides/{public_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the specified scheduled override
#
# GET /api-public/v1/overrides/{publicId}
export def "api-public-overrides get" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, override: record<assignments: list<record>, end: string, publicId: string, start: string, timezone: string, user: record<firstName: string, lastName: string, username: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($public_id | is-empty) { error make --unspanned { msg: "path parameter 'publicId' must be non-empty" } }
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id)} | format pattern "/api-public/v1/overrides/{public_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the specified scheduled override
#
# GET /api-public/v1/overrides/{publicId}/assignments
export def "api-public-overrides-assignments list" [
  public_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($public_id | is-empty) { error make --unspanned { msg: "path parameter 'publicId' must be non-empty" } }
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id)} | format pattern "/api-public/v1/overrides/{public_id}/assignments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Delete the scheduled override assignment
#
# DELETE /api-public/v1/overrides/{publicId}/assignments/{policySlug}
export def "api-public-overrides-assignments delete" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($public_id | is-empty) { error make --unspanned { msg: "path parameter 'publicId' must be non-empty" } }
  if ($policy_slug | is-empty) { error make --unspanned { msg: "path parameter 'policySlug' must be non-empty" } }
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id), policy_slug: (encode-path-segment $policy_slug)} | format pattern "/api-public/v1/overrides/{public_id}/assignments/{policy_slug}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the specified scheduled override assignment
#
# GET /api-public/v1/overrides/{publicId}/assignments/{policySlug}
export def "api-public-overrides-assignments get" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($public_id | is-empty) { error make --unspanned { msg: "path parameter 'publicId' must be non-empty" } }
  if ($policy_slug | is-empty) { error make --unspanned { msg: "path parameter 'policySlug' must be non-empty" } }
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id), policy_slug: (encode-path-segment $policy_slug)} | format pattern "/api-public/v1/overrides/{public_id}/assignments/{policy_slug}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Update the scheduled override assignment
#
# PUT /api-public/v1/overrides/{publicId}/assignments/{policySlug}
export def "api-public-overrides-assignments update" [
  public_id: string
  policy_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  policy: string # The policy slug
  --username: string # The username being assinged
]: any -> record<_selfUrl: string, assigned: bool, policy: string, team: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($public_id | is-empty) { error make --unspanned { msg: "path parameter 'publicId' must be non-empty" } }
  if ($policy_slug | is-empty) { error make --unspanned { msg: "path parameter 'policySlug' must be non-empty" } }
  let full_url = (build-url $base ({public_id: (encode-path-segment $public_id), policy_slug: (encode-path-segment $policy_slug)} | format pattern "/api-public/v1/overrides/{public_id}/assignments/{policy_slug}") $auth.query)
  let req_body = {"policy": $policy, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get escalation policy info
#
# GET /api-public/v1/policies
export def "api-public-policies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<policies: table<policy: record, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the available contact types
#
# GET /api-public/v1/policies/types/contacts
export def "api-public-policies-types-contacts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, contactTypes: table<description: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies/types/contacts" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the available notification types
#
# GET /api-public/v1/policies/types/notifications
export def "api-public-policies-types-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, notificationTypes: table<description: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies/types/notifications" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the available timeout values
#
# GET /api-public/v1/policies/types/timeouts
export def "api-public-policies-types-timeouts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, timeoutTypes: table<description: string, type: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/policies/types/timeouts" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Create an on-call override (take on-call)
#
# PATCH /api-public/v1/policies/{policy}/oncall/user
export def "api-public-policies-oncall-user update" [
  policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  from_user: string
  to_user: string
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($policy | is-empty) { error make --unspanned { msg: "path parameter 'policy' must be non-empty" } }
  let full_url = (build-url $base ({policy: (encode-path-segment $policy)} | format pattern "/api-public/v1/policies/{policy}/oncall/user") $auth.query)
  let req_body = {"fromUser": $from_user, "toUser": $to_user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the user's paging policy
#
# GET /api-public/v1/profile/{username}/policies
export def "api-public-profile-policies get-by-username" [
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
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, steps: table<index: float, rules: list, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/api-public/v1/profile/{username}/policies") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Create a paging policy step
#
# POST /api-public/v1/profile/{username}/policies
# --rules item shape: {contact?: record, type?: "push"|"email"|"sms"|"phone"}
export def "api-public-profile-policies create-by-username" [
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
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --rules: list # item shape: {contact?: record, type?: "push"|"email"|"sms"|"phone"}
  --timeout: int@timeout-completer
]: any -> record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/api-public/v1/profile/{username}/policies") $auth.query)
  let req_body = {"rules": $rules, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get a paging policy step
#
# GET /api-public/v1/profile/{username}/policies/{step}
export def "api-public-profile-policies get-by-username-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($step | is-empty) { error make --unspanned { msg: "path parameter 'step' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step)} | format pattern "/api-public/v1/profile/{username}/policies/{step}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Create a rule for a paging policy step
#
# POST /api-public/v1/profile/{username}/policies/{step}
# --contact shape: {id?: float, type?: "email"|"phone"}
export def "api-public-profile-policies create-by-username-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --contact: record # shape: {id?: float, type?: "email"|"phone"}
  --type: string@type-completer-1 # e.g. email
]: any -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($step | is-empty) { error make --unspanned { msg: "path parameter 'step' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step)} | format pattern "/api-public/v1/profile/{username}/policies/{step}") $auth.query)
  let req_body = {"contact": $contact, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Update a paging policy step
#
# PUT /api-public/v1/profile/{username}/policies/{step}
# --rules item shape: {contact?: record, type?: "push"|"email"|"sms"|"phone"}
export def "api-public-profile-policies update-by-username-step" [
  username: string
  step: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --rules: list # item shape: {contact?: record, type?: "push"|"email"|"sms"|"phone"}
  --timeout: int@timeout-completer
]: any -> record<_selfUrl: string, step: record<index: float, rules: list<record>, timeout: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($step | is-empty) { error make --unspanned { msg: "path parameter 'step' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step)} | format pattern "/api-public/v1/profile/{username}/policies/{step}") $auth.query)
  let req_body = {"rules": $rules, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Delete a rule from a paging policy step
#
# DELETE /api-public/v1/profile/{username}/policies/{step}/{rule}
export def "api-public-profile-policies delete" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($step | is-empty) { error make --unspanned { msg: "path parameter 'step' must be non-empty" } }
  if ($rule | is-empty) { error make --unspanned { msg: "path parameter 'rule' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step), rule: (encode-path-segment $rule)} | format pattern "/api-public/v1/profile/{username}/policies/{step}/{rule}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get a rule from a paging policy step
#
# GET /api-public/v1/profile/{username}/policies/{step}/{rule}
export def "api-public-profile-policies get-by-username-step-rule" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($step | is-empty) { error make --unspanned { msg: "path parameter 'step' must be non-empty" } }
  if ($rule | is-empty) { error make --unspanned { msg: "path parameter 'rule' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step), rule: (encode-path-segment $rule)} | format pattern "/api-public/v1/profile/{username}/policies/{step}/{rule}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Update a rule for a paging policy step
#
# PUT /api-public/v1/profile/{username}/policies/{step}/{rule}
# --contact shape: {id?: float, type?: "email"|"phone"}
export def "api-public-profile-policies update-by-username-step-rule" [
  username: string
  step: float
  rule: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --contact: record # shape: {id?: float, type?: "email"|"phone"}
  --type: string@type-completer-1 # e.g. email
]: any -> record<_selfUrl: string, stepRule: record<contact: record<id: float, type: string>, index: float, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($step | is-empty) { error make --unspanned { msg: "path parameter 'step' must be non-empty" } }
  if ($rule | is-empty) { error make --unspanned { msg: "path parameter 'rule' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), step: (encode-path-segment $step), rule: (encode-path-segment $rule)} | format pattern "/api-public/v1/profile/{username}/policies/{step}/{rule}") $auth.query)
  let req_body = {"contact": $contact, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List teams
#
# GET /api-public/v1/team
export def "api-public-team list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/team" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Add a team
#
# POST /api-public/v1/team
export def "api-public-team create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  name: string
]: any -> record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/team" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Remove a team
#
# DELETE /api-public/v1/team/{team}
export def "api-public-team delete" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Retrieve information for a team
#
# GET /api-public/v1/team/{team}
export def "api-public-team get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Update a team
#
# PUT /api-public/v1/team/{team}
export def "api-public-team update" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  name: string
]: any -> record<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, isDefaultTeam: bool, memberCount: float, name: string, slug: string, version: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Retrieve a list of team admins for a team
#
# GET /api-public/v1/team/{team}/admins
export def "api-public-team-admins get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teamAdmins: table<_selfUrl: string, firstName: string, lastName: string, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/admins") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Retrieve a list of members for a team
#
# GET /api-public/v1/team/{team}/members
export def "api-public-team-members get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/members") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Add a team member
#
# POST /api-public/v1/team/{team}/members
export def "api-public-team-members create" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  username: string
]: any -> record<_selfUrl: string, _teamUrl: string, members: table<firstName: string, lastName: string, username: string, verified: string, version: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/members") $auth.query)
  let req_body = {"username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Remove a team member
#
# DELETE /api-public/v1/team/{team}/members/{user}
export def "api-public-team-members delete" [
  team: string
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  replacement: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team), user: (encode-path-segment $user)} | format pattern "/api-public/v1/team/{team}/members/{user}") $auth.query)
  let req_body = {"replacement": $replacement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a team's on-call schedule
#
# GET /api-public/v1/team/{team}/oncall/schedule
# DEPRECATED
@deprecated
export def "api-public-team-oncall-schedule get-by-team" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<overrides: table<end: float, orig: string, over: string, start: float>, schedule: table<oncall: string, overrideoncall: string, policyType: string, rolls: list, rotationName: string, shiftName: string, shiftRoll: float>, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/oncall/schedule") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"daysForward": $days_forward, "daysSkip": $days_skip, "step": $step} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an on-call override (take on-call)
#
# PATCH /api-public/v1/team/{team}/oncall/user
# DEPRECATED
@deprecated
export def "api-public-team-oncall-user update" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  from_user: string
  to_user: string
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/oncall/user") $auth.query)
  let req_body = {"fromUser": $from_user, "toUser": $to_user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Retrieve a list of escalation policies for a team
#
# GET /api-public/v1/team/{team}/policies
export def "api-public-team-policies get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<policies: table<name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v1/team/{team}/policies") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# List users
#
# GET /api-public/v1/user
export def "api-public-user list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, users: table<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/user" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Add a user
#
# POST /api-public/v1/user
export def "api-public-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --admin: oneof<nothing, bool>
  email: string # format: email
  --expiration-hours: float # The validity duration for the invitatation/set password link sent to the added user. (default: 24)
  first_name: string
  last_name: string
  username: string
]: any -> record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api-public/v1/user" $auth.query)
  let req_body = {"admin": $admin, "email": $email, "expirationHours": $expiration_hours, "firstName": $first_name, "lastName": $last_name, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Remove a user
#
# DELETE /api-public/v1/user/{user}
export def "api-public-user delete" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --replacement: string # The user to take the place of the deleted user in escalations
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}") $auth.query)
  let req_body = {"replacement": $replacement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve information for a user
#
# GET /api-public/v1/user/{user}
export def "api-public-user get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Update a user
#
# PUT /api-public/v1/user/{user}
export def "api-public-user update" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --admin: oneof<nothing, bool>
  email: string # format: email
  --expiration-hours: float # The validity duration for the invitatation/set password link sent to the added user. (default: 24)
  first_name: string
  last_name: string
  username: string
]: any -> record<_selfUrl: string, createdAt: string, email: string, firstName: string, lastName: string, passwordLastUpdated: string, username: string, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}") $auth.query)
  let req_body = {"admin": $admin, "email": $email, "expirationHours": $expiration_hours, "firstName": $first_name, "lastName": $last_name, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a list of all contact methods for a user
#
# GET /api-public/v1/user/{user}/contact-methods
export def "api-public-user-contact-methods get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<devices: table<_selfUrl: string, deviceType: string, extId: string, label: string>, emails: table<_selfUrl: string, deviceType: string, extId: string, label: string>, phones: table<_selfUrl: string, deviceType: string, extId: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get a list of all contact devices for a user
#
# GET /api-public/v1/user/{user}/contact-methods/devices
export def "api-public-user-contact-methods-devices list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Delete a contact device for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/devices/{contactId}
export def "api-public-user-contact-methods-devices delete" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices/{contact_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the indicated contact device for a user
#
# GET /api-public/v1/user/{user}/contact-methods/devices/{contactId}
export def "api-public-user-contact-methods-devices get" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices/{contact_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Update a contact device for a user
#
# PUT /api-public/v1/user/{user}/contact-methods/devices/{contactId}
export def "api-public-user-contact-methods-devices update" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  --chat-escalation-sound: string
  --device-label: string
  --escalation-notification-sound: string
  --resolved-notification-sound: string
]: any -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/devices/{contact_id}") $auth.query)
  let req_body = {"chat_escalation_sound": $chat_escalation_sound, "device_label": $device_label, "escalation_notification_sound": $escalation_notification_sound, "resolved_notification_sound": $resolved_notification_sound} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Get a list of all contact emails for a user
#
# GET /api-public/v1/user/{user}/contact-methods/emails
export def "api-public-user-contact-methods-emails list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Create a contact emails for a user
#
# POST /api-public/v1/user/{user}/contact-methods/emails
export def "api-public-user-contact-methods-emails create" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  email: string # format: email
  label: string
  --rank: int
]: any -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails") $auth.query)
  let req_body = {"email": $email, "label": $label, "rank": $rank} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Delete a contact email for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/emails/{contactId}
export def "api-public-user-contact-methods-emails delete" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails/{contact_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the indicated contact email for a user
#
# GET /api-public/v1/user/{user}/contact-methods/emails/{contactId}
export def "api-public-user-contact-methods-emails get" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/emails/{contact_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get a list of all contact phones for a user
#
# GET /api-public/v1/user/{user}/contact-methods/phones
export def "api-public-user-contact-methods-phones list" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Create a contact phones for a user
#
# POST /api-public/v1/user/{user}/contact-methods/phones
export def "api-public-user-contact-methods-phones create" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
  label: string
  phone: string
  --rank: int
]: any -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones") $auth.query)
  let req_body = {"label": $label, "phone": $phone, "rank": $rank} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Delete a contact phone for a user
#
# DELETE /api-public/v1/user/{user}/contact-methods/phones/{contactId}
export def "api-public-user-contact-methods-phones delete" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones/{contact_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get the indicated contact phone for a user
#
# GET /api-public/v1/user/{user}/contact-methods/phones/{contactId}
export def "api-public-user-contact-methods-phones get" [
  user: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<_selfUrl: string, deviceType: string, extId: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user), contact_id: (encode-path-segment $contact_id)} | format pattern "/api-public/v1/user/{user}/contact-methods/phones/{contact_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get a user's on-call schedule
#
# GET /api-public/v1/user/{user}/oncall/schedule
# DEPRECATED
@deprecated
export def "api-public-user-oncall-schedule get-by-user" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<overrides: list<record>, schedule: list<record>, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/oncall/schedule") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"daysForward": $days_forward, "daysSkip": $days_skip, "step": $step} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of paging policies for a user
#
# GET /api-public/v1/user/{user}/policies
export def "api-public-user-policies get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<policies: table<contactType: string, extId: string, order: int, timeout: int>, userId: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/policies") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Retrieve the user's team membership
#
# GET /api-public/v1/user/{user}/teams
export def "api-public-user-teams get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teams: table<_adminsUrl: string, _membersUrl: string, _policiesUrl: string, _selfUrl: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v1/user/{user}/teams") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
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

# Get a team's on-call schedule
#
# GET /api-public/v2/team/{team}/oncall/schedule
export def "api-public-team-oncall-schedule get-by-team-1" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<schedules: table<overrides: list, policy: record, schedule: list>, team: record<name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-public/v2/team/{team}/oncall/schedule") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"daysForward": $days_forward, "daysSkip": $days_skip, "step": $step} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a user's on-call schedule
#
# GET /api-public/v2/user/{user}/oncall/schedule
export def "api-public-user-oncall-schedule get-by-user-1" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days-forward: float # Days to include in returned schedule (30 max) (default: 14)
  --days-skip: float # Days to skip before computing schedule to return (90 max) (default: 0)
  --step: float # Step of escalation policy (3 max) (default: 0)
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<teamSchedules: table<schedules: list, team: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user | is-empty) { error make --unspanned { msg: "path parameter 'user' must be non-empty" } }
  let qp = [(serialize-qp "daysForward" $days_forward "scalar") (serialize-qp "daysSkip" $days_skip "scalar") (serialize-qp "step" $step "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user: (encode-path-segment $user)} | format pattern "/api-public/v2/user/{user}/oncall/schedule") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"daysForward": $days_forward, "daysSkip": $days_skip, "step": $step} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get/search incident history
#
# GET /api-reporting/v1/incidents
# DEPRECATED
@deprecated
export def "api-reporting-incidents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # The offset within the set of matching incidents (default: 0)
  --limit: float # The maximum number of matching incidents to return (100 max) (default: 20)
  --entity-id: string # The entity ID involved This is the unique identifier for the entity causing the incident.
  --incident-number: string # The incident number as shown in VictorOps Multiple values and ranges are allowed: 4,5,20:50
  --started-after: string # Return incidents started after this timestamp Specify the timestamp in ISO8601 format
  --started-before: string # Find incidents started before this timestamp Specify the timestamp in ISO8601 format
  --host: string # The host involved in the incident Multiple values can be separated with commas.
  --service: string # The service involved in the incident (if any) Multiple values can be separated with commas.
  --current-phase: string # The current phase of the incident "resolved", "triggered" or "acknowledged". Multiple values can be separated with commas.
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> table<incidents: list<record>, limit: float, offset: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "entityId" $entity_id "scalar") (serialize-qp "incidentNumber" $incident_number "scalar") (serialize-qp "startedAfter" $started_after "scalar") (serialize-qp "startedBefore" $started_before "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "currentPhase" $current_phase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api-reporting/v1/incidents" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "entityId": $entity_id, "incidentNumber": $incident_number, "startedAfter": $started_after, "startedBefore": $started_before, "host": $host, "service": $service, "currentPhase": $current_phase} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# A list of shift changes for a team
#
# GET /api-reporting/v1/team/{team}/oncall/log
export def "api-reporting-team-oncall-log get" [
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Return shift changes occurring after this timestamp. The default is the start of the day at midnight. Specify the timestamp in ISO8601 format (format: date-time)
  --end: string # Return shift changes occurring before this timestamp. The default is the end of the day at 11:59:59. Specify the timestamp in ISO8601 format (format: date-time)
  --user-name: string # The VictorOps user ID. Return shift changes occurring during the interval specified for this user. Without this parameter, all relevant users (with respect to the specified interval) are returned
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<end: string, start: string, teamSlug: string, userLogs: table<adjustedTotal: record, log: list, total: record, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team: (encode-path-segment $team)} | format pattern "/api-reporting/v1/team/{team}/oncall/log") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "userName": $user_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get/search incident history
#
# GET /api-reporting/v2/incidents
export def "api-reporting-incidents get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: float # The offset within the set of matching incidents (default: 0)
  --limit: float # The maximum number of matching incidents to return (100 max) (default: 20)
  --entity-id: string # The entity ID involved This is the unique identifier for the entity causing the incident.
  --incident-number: string # The incident number as shown in VictorOps Multiple values and ranges are allowed: 4,5,20:50
  --started-after: string # Return incidents started after this timestamp Specify the timestamp in ISO8601 format
  --started-before: string # Find incidents started before this timestamp Specify the timestamp in ISO8601 format
  --host: string # The host involved in the incident Multiple values can be separated with commas.
  --service: string # The service involved in the incident (if any) Multiple values can be separated with commas.
  --current-phase: string # The current phase of the incident "resolved", "triggered" or "acknowledged". Multiple values can be separated with commas. By default, response contains only "resolved" incidents
  --routing-key: string # The original routing of the incident
  --x-vo-api-id: string # Your API ID
  --x-vo-api-key: string # Your API Key
]: nothing -> record<incidents: table<alertCount: float, currentPhase: string, entityId: string, host: string, incidentNumber: string, lastAlertId: string, lastAlertTime: string, pagedPolicies: list, pagedTeams: list, pagedUsers: list, service: string, startTime: string, transitions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "entityId" $entity_id "scalar") (serialize-qp "incidentNumber" $incident_number "scalar") (serialize-qp "startedAfter" $started_after "scalar") (serialize-qp "startedBefore" $started_before "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "currentPhase" $current_phase "scalar") (serialize-qp "routingKey" $routing_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api-reporting/v2/incidents" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-VO-Api-Id": $x_vo_api_id, "X-VO-Api-Key": $x_vo_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "entityId": $entity_id, "incidentNumber": $incident_number, "startedAfter": $started_after, "startedBefore": $started_before, "host": $host, "service": $service, "currentPhase": $current_phase, "routingKey": $routing_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
