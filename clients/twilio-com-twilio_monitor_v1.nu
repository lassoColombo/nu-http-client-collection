# Auto-generated client for Twilio - Monitor v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_monitor_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_MONITOR_TOKEN

const BASE_URL = "https://monitor.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TWILIO_MONITOR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://monitor.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alerts list" } } | get name | first)
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

# GET /v1/Alerts
#
# operationId: ListAlert
export def "alerts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --log-level: string # Only show alerts for this log-level. Can be: `error`, `warning`, `notice`, or `debug`.
  --start-date: string # Only include alerts that occurred on or after this date and time. Specify the date and time in GMT and format as `YYYY-MM-DD` or `YYYY-MM-DDThh:mm:ssZ`. Queries for alerts older than 30 days are not supported. (format: date-time)
  --end-date: string # Only include alerts that occurred on or before this date and time. Specify the date and time in GMT and format as `YYYY-MM-DD` or `YYYY-MM-DDThh:mm:ssZ`. Queries for alerts older than 30 days are not supported. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<alerts: table<account_sid: string, alert_text: string, api_version: string, date_created: string, date_generated: string, date_updated: string, error_code: string, log_level: string, more_info: string, request_method: string, request_url: string, resource_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://monitor.twilio.com")
  let qp = [(serialize-qp "LogLevel" $log_level "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Alerts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LogLevel": $log_level, "StartDate": $start_date, "EndDate": $end_date, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /v1/Alerts/{Sid}
#
# operationId: FetchAlert
export def "alerts get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, alert_text: string, api_version: string, date_created: string, date_generated: string, date_updated: string, error_code: string, log_level: string, more_info: string, request_headers: string, request_method: string, request_url: string, request_variables: string, resource_sid: string, response_body: string, response_headers: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://monitor.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Alerts/{sid}") $auth.query)
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

# Returns a list of events in the account, sorted by event-date.
#
# GET /v1/Events
# operationId: ListEvent
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actor-sid: string # Only include events initiated by this Actor. Useful for auditing actions taken by specific users or API credentials.
  --event-type: string # Only include events of this [Event Type](https://www.twilio.com/docs/usage/monitor-events#event-types).
  --resource-sid: string # Only include events that refer to this resource. Useful for discovering the history of a specific resource.
  --source-ip-address: string # Only include events that originated from this IP address. Useful for tracking suspicious activity originating from the API or the Twilio Console.
  --start-date: string # Only include events that occurred on or after this date. Specify the date in GMT and [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only include events that occurred on or before this date. Specify the date in GMT and [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<events: table<account_sid: string, actor_sid: string, actor_type: string, description: string, event_data: any, event_date: string, event_type: string, links: record, resource_sid: string, resource_type: string, sid: string, source: string, source_ip_address: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://monitor.twilio.com")
  let qp = [(serialize-qp "ActorSid" $actor_sid "scalar") (serialize-qp "EventType" $event_type "scalar") (serialize-qp "ResourceSid" $resource_sid "scalar") (serialize-qp "SourceIpAddress" $source_ip_address "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ActorSid": $actor_sid, "EventType": $event_type, "ResourceSid": $resource_sid, "SourceIpAddress": $source_ip_address, "StartDate": $start_date, "EndDate": $end_date, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /v1/Events/{Sid}
#
# operationId: FetchEvent
export def "events get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, actor_sid: string, actor_type: string, description: string, event_data: any, event_date: string, event_type: string, links: record, resource_sid: string, resource_type: string, sid: string, source: string, source_ip_address: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://monitor.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Events/{sid}") $auth.query)
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
