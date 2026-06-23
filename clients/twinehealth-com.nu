# Auto-generated client for Fitbit Plus API vv7.78.1
# Source: https://api.apis.guru/v2/specs/twinehealth.com/v7.78.1/openapi.json
# Auth: --token flag or $env.FITBIT_PLUS_API_TOKEN

const BASE_URL = "https://api.twinehealth.com/pub"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FITBIT_PLUS_API_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.twinehealth.com/pub"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def filter-type-completer [] { ["office-visit" "plan-check-in" "reminder" "telephone-call" "video-call"] }
def include-completer [] { ["owner"] }
def sort-completer [] { ["-send_time" "send_time"] }
def include-completer-1 [] { ["patient" "questions"] }
def include-completer-2 [] { ["patient"] }
def include-completer-3 [] { ["answer" "question_definition"] }
def include-completer-4 [] { ["groups" "organization"] }
def include-completer-5 [] { ["actions" "bundles" "current_results" "patient"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "action create" } } | get name | first)
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

# Create action
#
# POST /action
# operationId: createAction
export def "action create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/action")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get an action
#
# GET /action/{id}
# operationId: fetchAction
export def "action get" [
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
]: nothing -> record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/action/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an action
#
# PATCH /action/{id}
# operationId: updateAction
export def "action update" [
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
  --body: any
]: any -> record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/action/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Create bundle
#
# POST /bundle
# operationId: createBundle
export def "bundle create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bundle")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a bundle
#
# GET /bundle/{id}
# operationId: fetchBundle
export def "bundle get" [
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
]: nothing -> record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundle/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a bundle
#
# PATCH /bundle/{id}
# operationId: updateBundle
export def "bundle update" [
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
  --body: any
]: any -> record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bundle/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# List calendar events
#
# GET /calendar_event
# operationId: fetchCalendarEvents
export def "calendar-event list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch calendar event. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-attendees: string # Comma-separated list of coach or patient ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-type: string@filter-type-completer # Calendar event type
  --filter-completed: oneof<nothing, bool> # If not specified, return all calendar events. If set to `true` return only events marked as completed, if set to `false`, return only events not marked as completed yet.
  --filter-start-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events starting in November 2017 (America/New_York): `filter[start_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-end-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events ending in November 2017 (America/New_York): `filter[end_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-completed-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events completed in November 2017 (America/New_York): `filter[completed_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-created-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events created in November 2017 (America/New_York): `filter[created_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-updated-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events updated in November 2017 (America/New_York): `filter[updated_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
  --include: string@include-completer # List of related resources to include in the response
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "filter[attendees]" $filter_attendees "scalar") (serialize-qp "filter[type]" $filter_type "scalar") (serialize-qp "filter[completed]" $filter_completed "scalar") (serialize-qp "filter[start_at]" $filter_start_at "scalar") (serialize-qp "filter[end_at]" $filter_end_at "scalar") (serialize-qp "filter[completed_at]" $filter_completed_at "scalar") (serialize-qp "filter[created_at]" $filter_created_at "scalar") (serialize-qp "filter[updated_at]" $filter_updated_at "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[limit]" $page_limit "scalar") (serialize-qp "page[cursor]" $page_cursor "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calendar_event" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization, "filter[attendees]": $filter_attendees, "filter[type]": $filter_type, "filter[completed]": $filter_completed, "filter[start_at]": $filter_start_at, "filter[end_at]": $filter_end_at, "filter[completed_at]": $filter_completed_at, "filter[created_at]": $filter_created_at, "filter[updated_at]": $filter_updated_at, "page[number]": $page_number, "page[size]": $page_size, "page[limit]": $page_limit, "page[cursor]": $page_cursor, "include": $include} | compact), body: null}
}

# Create calendar event
#
# POST /calendar_event
# operationId: createCalendarEvent
export def "calendar-event create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calendar_event")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Delete a calendar event
#
# DELETE /calendar_event/{id}
# operationId: deleteCalendarEvent
export def "calendar-event delete" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calendar_event/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a calendar event
#
# GET /calendar_event/{id}
# operationId: fetchCalendarEvent
export def "calendar-event get" [
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
]: nothing -> record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calendar_event/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a calendar event
#
# PATCH /calendar_event/{id}
# operationId: updateCalendarEvent
export def "calendar-event update" [
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
  --body: any
]: any -> record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calendar_event/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Create calendar event response
#
# POST /calendar_event_response
# operationId: createCalendarEventResponse
export def "calendar-event-response create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<attendee: record, response_status: string>, relationships: record<calendar_event: record, user: record>, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calendar_event_response")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# List coaches
#
# GET /coach
# operationId: fetchCoaches
export def "coach get-coaches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coach" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[groups]": $filter_groups, "filter[organization]": $filter_organization} | compact), body: null}
}

# Get a coach
#
# GET /coach/{id}
# operationId: fetchCoach
export def "coach get" [
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
]: nothing -> record<data: record<attributes: record<first_name: string, last_name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/coach/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List email histories
#
# GET /email_history
# operationId: fetchEmailHistories
export def "email-history get-histories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-receiver: string # Fitbit Plus user id of email recipient. Required if filter[sender] is not defined.
  --filter-sender: string # Fitbit Plus user id of email sender. Required if filter[receiver] is not defined.
  --filter-email-type: string # Type of email
  --qp-sort: string@sort-completer # valid sorts: * send_time - ascending by send_time * -send_time - descending by send_time
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[receiver]" $filter_receiver "scalar") (serialize-qp "filter[sender]" $filter_sender "scalar") (serialize-qp "filter[emailType]" $filter_email_type "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email_history" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[receiver]": $filter_receiver, "filter[sender]": $filter_sender, "filter[emailType]": $filter_email_type, "sort": $qp_sort} | compact), body: null}
}

# Get an email history
#
# GET /email_history/{id}
# operationId: fetchEmailHistory
export def "email-history get" [
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
]: nothing -> record<data: record<attributes: record<email_address: string, email_type: string, send_time: string, status_times: record, twine_email_id: string>, id: string, relationships: record<receiver: record, sender: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/email_history/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List groups
#
# GET /group
# operationId: fetchGroups
export def "group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-organization: string # Organization identifier
  --filter-name: string # Group name
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "filter[name]" $filter_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/group" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[organization]": $filter_organization, "filter[name]": $filter_name} | compact), body: null}
}

# Create a group
#
# POST /group
# operationId: createGroup
export def "group create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<bio: string, name: string>, id: string, links: record<self: string>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/group")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a group
#
# GET /group/{id}
# operationId: fetchGroup
export def "group get" [
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
]: nothing -> record<data: record<attributes: record<bio: string, name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/group/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List health profiles
#
# GET /health_profile
# operationId: fetchHealthProfiles
export def "health-profile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch health profile. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
  --include: string@include-completer-1 # List of related resources to include in the response
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[limit]" $page_limit "scalar") (serialize-qp "page[cursor]" $page_cursor "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/health_profile" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization, "page[number]": $page_number, "page[size]": $page_size, "page[limit]": $page_limit, "page[cursor]": $page_cursor, "include": $include} | compact), body: null}
}

# Get a health profile
#
# GET /health_profile/{id}
# operationId: fetchHealthProfile
export def "health-profile get" [
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
  --include: string@include-completer-1 # List of related resources to include in the response
]: nothing -> record<data: record<attributes: record<stats: list>, id: string, links: record<self: string>, relationships: record<patient: record, questions: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/health_profile/{id}") $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include} | compact), body: null}
}

# List health profile answers
#
# GET /health_profile_answer
# operationId: fetchHealthProfileAnswers
export def "health-profile-answer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch healt profile answers. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 50)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
  --include: string@include-completer-2 # List of related resources to include in the response
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[limit]" $page_limit "scalar") (serialize-qp "page[cursor]" $page_cursor "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/health_profile_answer" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization, "page[number]": $page_number, "page[size]": $page_size, "page[limit]": $page_limit, "page[cursor]": $page_cursor, "include": $include} | compact), body: null}
}

# Get a health profile answer
#
# GET /health_profile_answer/{id}
# operationId: fetchHealthProfileAnswer
export def "health-profile-answer get" [
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
  --include: string@include-completer-2 # List of related resources to include in the response
]: nothing -> record<data: record<attributes: record<history: list, latest: record, question_id: string>, id: string, links: record<self: string>, relationships: record<patient: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/health_profile_answer/{id}") $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include} | compact), body: null}
}

# List health profile questions
#
# GET /health_profile_question
# operationId: fetchHealthProfileQuestions
export def "health-profile-question list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch healt profile questions. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --include: string@include-completer-3 # List of related resources to include in the response
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/health_profile_question" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization, "include": $include} | compact), body: null}
}

# Get a health profile question
#
# GET /health_profile_question/{id}
# operationId: fetchHealthProfileQuestion
export def "health-profile-question get" [
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
  --include: string@include-completer-3 # List of related resources to include in the response
]: nothing -> record<data: record<attributes: record, id: string, links: record<self: string>, relationships: record<answer: record, profile: record, question_definition: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/health_profile_question/{id}") $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include} | compact), body: null}
}

# List health question definitions
#
# GET /health_question_definition
# operationId: fetchHealthQuestionDefinitions
export def "health-question-definition list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health_question_definition")
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a health question definition
#
# GET /health_question_definition/{id}
# operationId: fetchHealthQuestionDefinition
export def "health-question-definition get" [
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
]: nothing -> record<data: record<attributes: record<category: string, format: record, requirements: list, text: string>, id: string, links: record<self: string>, relationships: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/health_question_definition/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an oauth token
#
# POST /oauth/token
# operationId: createToken
# --data shape: {attributes: record, type?: "token"}
export def "oauth-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer-4 # List of related resources to include in the response
  data: record # shape: {attributes: record, type?: "token"}
]: any -> record<data: record<attributes: record<access_token: string, expires_in: int, refresh_token: string, token_type: string>, id: string, relationships: record<groups: record, organization: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/token" $qp)
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"include": $include} | compact), body: $req_body}
}

# Get the groups for a token
#
# GET /oauth/token/{id}/groups
# operationId: fetchTokenGroups
export def "oauth-token-groups get" [
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
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/oauth/token/{id}/groups"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the organization for a token
#
# GET /oauth/token/{id}/organization
# operationId: fetchTokenOrganization
export def "oauth-token-organization get" [
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
]: nothing -> record<data: record<attributes: record<name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/oauth/token/{id}/organization"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an organization
#
# GET /organization/{id}
# operationId: fetchOrganization
export def "organization get" [
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
]: nothing -> record<data: record<attributes: record<name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/organization/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List patients
#
# GET /patient
# operationId: fetchPatients
export def "patient list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Comma-separated list of group ids. Note that either `filter[group]` or `filter[organization]` must be specified.
  --filter-organization: string # Fitbit Plus organization id. Note that either `filter[group]` or `filter[organization]` must be specified.
  --filter-identifier-system: string # Identifier system (example: "MyEHR") - requires a "filter[identifier][value]" parameter
  --filter-identifier-value: string # Identifier value (example: "12345") - requires a "filter[identifier][system]" parameter
  --filter-archived: oneof<nothing, bool> # If not specified, return all patients. If set to 'true' return only archived patients, if set to 'false', return only patients who are not archived.
  --filter-created-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for patients created in November 2017 (America/New_York): `filter[created_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-updated-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for patients updated in November 2017 (America/New_York): `filter[updated_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "filter[identifier][system]" $filter_identifier_system "scalar") (serialize-qp "filter[identifier][value]" $filter_identifier_value "scalar") (serialize-qp "filter[archived]" $filter_archived "scalar") (serialize-qp "filter[created_at]" $filter_created_at "scalar") (serialize-qp "filter[updated_at]" $filter_updated_at "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[limit]" $page_limit "scalar") (serialize-qp "page[cursor]" $page_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/patient" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[groups]": $filter_groups, "filter[organization]": $filter_organization, "filter[identifier][system]": $filter_identifier_system, "filter[identifier][value]": $filter_identifier_value, "filter[archived]": $filter_archived, "filter[created_at]": $filter_created_at, "filter[updated_at]": $filter_updated_at, "page[number]": $page_number, "page[size]": $page_size, "page[limit]": $page_limit, "page[cursor]": $page_cursor} | compact), body: null}
}

# Create a patient
#
# POST /patient
# operationId: createPatient
export def "patient create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patient")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Upsert patient
#
# PUT /patient
# operationId: upsertPatient
export def "patient update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patient")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a patient
#
# GET /patient/{id}
# operationId: fetchPatient
export def "patient get" [
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
]: nothing -> record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/patient/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a patient
#
# PATCH /patient/{id}
# operationId: updatePatient
export def "patient update-by-id" [
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
  --body: any
]: any -> record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/patient/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# List coaches for a patient
#
# GET /patient/{id}/coaches
# operationId: fetchPatientCoaches
export def "patient-coaches get" [
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
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/patient/{id}/coaches"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List groups for a patient
#
# GET /patient/{id}/groups
# operationId: fetchPatientGroups
export def "patient-groups get" [
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
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/patient/{id}/groups"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List patient health metrics
#
# GET /patient_health_metric
# operationId: fetchPatientHealthMetrics
export def "patient-health-metric list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Filter the patient health metrics for a specified patient. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[limit]" $page_limit "scalar") (serialize-qp "page[cursor]" $page_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/patient_health_metric" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization, "page[number]": $page_number, "page[size]": $page_size, "page[limit]": $page_limit, "page[cursor]": $page_cursor} | compact), body: null}
}

# Create patient health metrics
#
# POST /patient_health_metric
# operationId: createPatientHealthMetric
export def "patient-health-metric create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<code: record, diastolic: float, occurred_at: string, systolic: float, type: string, unit: string, value: any>, id: string, relationships: record<patient: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/patient_health_metric")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a patient health metric
#
# GET /patient_health_metric/{id}
# operationId: fetchPatientHealthMetric
export def "patient-health-metric get" [
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
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/patient_health_metric/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List patient plan summaries
#
# GET /patient_plan_summary
# operationId: fetchPatientPlanSummaries
export def "patient-plan-summary get-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch plan summary for. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --include: string@include-completer-5 # List of related resources to include in the response
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/patient_plan_summary" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization, "include": $include} | compact), body: null}
}

# Get the plan summary for a patient
#
# GET /patient_plan_summary/{id}
# operationId: fetchPatientPlanSummary
export def "patient-plan-summary get" [
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
  --include: string@include-completer-5 # List of related resources to include in the response
]: nothing -> record<data: record<attributes: record<adherence: record, critical: record, effective_from: string, time_zone: string, window_notification_times: record, window_order: list>, id: string, links: record<self: string>, relationships: record<actions: record, bundles: record, current_results: record, patient: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/patient_plan_summary/{id}") $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include} | compact), body: null}
}

# Update a plan summary
#
# PATCH /patient_plan_summary/{id}
# operationId: updatePatientPlanSummary
export def "patient-plan-summary update" [
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
  --body: any
]: any -> record<data: record<attributes: record<adherence: record, critical: record, effective_from: string, time_zone: string, window_notification_times: record, window_order: list>, id: string, links: record<self: string>, relationships: record<actions: record, bundles: record, current_results: record, patient: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/patient_plan_summary/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# List patient health results
#
# GET /result
# operationId: fetchPatientHealthResults
export def "result list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Filter the patient health results for a specified patient
  --filter-actions: string # A comma-separated list of action identifiers
  --filter-start-at: string # Filter results that occurred after the passed ISO date and time string (format: dateTime)
  --filter-end-at: string # Filter results that occurred before the passed ISO date and time string (format: dateTime)
  --filter-threads: string # A comma-separated list of thread identifiers
  --filter-created-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for results created in November 2017 (America/New_York): `filter[created_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-updated-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for results updated in November 2017 (America/New_York): `filter[updated_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-after: string # Page cursor
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[actions]" $filter_actions "scalar") (serialize-qp "filter[start_at]" $filter_start_at "scalar") (serialize-qp "filter[end_at]" $filter_end_at "scalar") (serialize-qp "filter[threads]" $filter_threads "scalar") (serialize-qp "filter[created_at]" $filter_created_at "scalar") (serialize-qp "filter[updated_at]" $filter_updated_at "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[limit]" $page_limit "scalar") (serialize-qp "page[after]" $page_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/result" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[actions]": $filter_actions, "filter[start_at]": $filter_start_at, "filter[end_at]": $filter_end_at, "filter[threads]": $filter_threads, "filter[created_at]": $filter_created_at, "filter[updated_at]": $filter_updated_at, "page[number]": $page_number, "page[size]": $page_size, "page[limit]": $page_limit, "page[after]": $page_after} | compact), body: null}
}

# Get a patient health result
#
# GET /result/{id}
# operationId: fetchPatientHealthResult
export def "result get-patient-health" [
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
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/result/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List rewards
#
# GET /reward
# operationId: fetchRewards
export def "reward list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient identifier. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-reward-program-activation: string # Reward program activation identifier
  --filter-thread: string # Thread identifier
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[reward_program_activation]" $filter_reward_program_activation "scalar") (serialize-qp "filter[thread]" $filter_thread "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reward" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[reward_program_activation]": $filter_reward_program_activation, "filter[thread]": $filter_thread, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization} | compact), body: null}
}

# Create a reward
#
# POST /reward
# operationId: createReward
export def "reward create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<_thread: string, allocated_at: string, allocated_unit: string, allocated_value: float, description: string, earned_at: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, target_at: string>, id: string, relationships: record<patient: record, reward_program_activation: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reward")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a reward
#
# GET /reward/{id}
# operationId: fetchReward
export def "reward get" [
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
]: nothing -> record<data: record<attributes: record<_thread: string, allocated_at: string, allocated_unit: string, allocated_value: float, description: string, earned_at: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, target_at: string>, id: string, relationships: record<patient: record, reward_program_activation: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reward/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List reward earnings
#
# GET /reward_earning
# operationId: fetchRewardEarnings
export def "reward-earning list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Group identifiers
  --filter-patient: string # Patient identifier
  --filter-ready-for-fulfillment: oneof<nothing, bool> # If true, only returns those reward earnings for which ready_for_fulfillment is true and fulfilled_at is null. If false, only returns those reward earnings for which ready_for_fulfillment is false and fulfilled_at is null.
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[ready_for_fulfillment]" $filter_ready_for_fulfillment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reward_earning" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[groups]": $filter_groups, "filter[patient]": $filter_patient, "filter[ready_for_fulfillment]": $filter_ready_for_fulfillment} | compact), body: null}
}

# Create a reward earning
#
# POST /reward_earning
# operationId: createRewardEarning
export def "reward-earning create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<earned_at: string, earned_unit: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, ready_for_fulfillment: bool>, id: string, relationships: record<group: record, patient: record, reward: record, reward_program_activation: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reward_earning")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a reward earning
#
# GET /reward_earning/{id}
# operationId: fetchRewardEarning
export def "reward-earning get" [
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
]: nothing -> record<data: record<attributes: record<earned_at: string, earned_unit: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, ready_for_fulfillment: bool>, id: string, relationships: record<group: record, patient: record, reward: record, reward_program_activation: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reward_earning/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List reward earning fulfillments
#
# GET /reward_earning_fulfillment
# operationId: fetchRewardEarningFulfillments
export def "reward-earning-fulfillment list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient identifier
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reward_earning_fulfillment" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient} | compact), body: null}
}

# Create a reward earning fulfillment
#
# POST /reward_earning_fulfillment
# operationId: createRewardEarningFulfillment
export def "reward-earning-fulfillment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<fulfilled_at: string, fulfilled_unit: string, fulfilled_value: float>, id: string, relationships: record<patient: record, reward_earning: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reward_earning_fulfillment")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a reward earning fulfillment
#
# GET /reward_earning_fulfillment/{id}
# operationId: fetchRewardEarningFulfillment
export def "reward-earning-fulfillment get" [
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
]: nothing -> record<data: record<attributes: record<fulfilled_at: string, fulfilled_unit: string, fulfilled_value: float>, id: string, relationships: record<patient: record, reward_earning: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reward_earning_fulfillment/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List reward programs
#
# GET /reward_program
# operationId: fetchRewardPrograms
export def "reward-program list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Comma-separated list of group identifiers. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reward_program" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[groups]": $filter_groups, "filter[organization]": $filter_organization} | compact), body: null}
}

# Create a reward program
#
# POST /reward_program
# operationId: createRewardProgram
export def "reward-program create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<budget_unit: string, budget_value: float, description: string, duration_active: float, end_at: string, frozen: bool, fulfill_as_earned: bool, name: string, start_at: string, tagline: string>, id: string, relationships: record<group: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reward_program")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a reward program
#
# GET /reward_program/{id}
# operationId: fetchRewardProgram
export def "reward-program get" [
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
]: nothing -> record<data: record<attributes: record<budget_unit: string, budget_value: float, description: string, duration_active: float, end_at: string, frozen: bool, fulfill_as_earned: bool, name: string, start_at: string, tagline: string>, id: string, relationships: record<group: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reward_program/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get group for a reward program
#
# GET /reward_program/{id}/group
# operationId: fetchRewardProgramGroup
export def "reward-program-group get" [
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
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reward_program/{id}/group"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List reward program activations
#
# GET /reward_program_activation
# operationId: fetchRewardProgramActivations
export def "reward-program-activation list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient identifier. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[patient]" $filter_patient "scalar") (serialize-qp "filter[groups]" $filter_groups "scalar") (serialize-qp "filter[organization]" $filter_organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reward_program_activation" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[patient]": $filter_patient, "filter[groups]": $filter_groups, "filter[organization]": $filter_organization} | compact), body: null}
}

# Create a reward program activation
#
# POST /reward_program_activation
# operationId: createRewardProgramActivation
export def "reward-program-activation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<attributes: record<activated_at: string, active: bool, allocated_count: float, budget_unit: string, deactivated_at: string, earned_count: float, expires_at: string, fulfill_as_earned: bool, total_allocated_value: float, total_earned_value: float>, id: string, relationships: record<patient: record, reward_program: record>, type: string>, meta: record<ignored: list<string>, req_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reward_program_activation")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.api+json" $req_body {query: {}, body: $req_body}
}

# Get a reward program activation
#
# GET /reward_program_activation/{id}
# operationId: fetchRewardProgramActivation
export def "reward-program-activation get" [
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
]: nothing -> record<data: record<attributes: record<activated_at: string, active: bool, allocated_count: float, budget_unit: string, deactivated_at: string, earned_count: float, expires_at: string, fulfill_as_earned: bool, total_allocated_value: float, total_earned_value: float>, id: string, relationships: record<patient: record, reward_program: record>, type: string>, meta: record<count: int, req_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reward_program_activation/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
