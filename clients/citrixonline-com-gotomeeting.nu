# Auto-generated client for GoToMeeting v1.0.0
# Source: https://api.apis.guru/v2/specs/citrixonline.com/gotomeeting/1.0.0/swagger.json
# Auth: --token flag or $env.GOTOMEETING_TOKEN

const BASE_URL = "https://api.citrixonline.com/G2M/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GOTOMEETING_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.citrixonline.com/G2M/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def product-type-completer [] { ["G2M" "G2T" "G2W" "OPENVOICE"] }
def history-completer [] { ["true"] }
def meetingtype-completer [] { ["immediate" "recurring" "scheduled"] }
def status-completer [] { ["suspended"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "groups get" } } | get name | first)
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

# Get groups
#
# GET /groups
export def "groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<groupName: string, groupkey: int, numOrganizers: int, parentKey: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get attendees by group
#
# GET /groups/{groupKey}/attendees
export def "groups-attendees get" [
  group_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # End of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<attendeeEmail: string, attendeeName: string, conferenceCallInfo: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, joinTime: string, lastName: string, leaveTime: string, meetingId: string, meetingInstanceKey: int, meetingType: string, numAttendees: int, organizerKey: string, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/attendees") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get historical meetings by group
#
# GET /groups/{groupKey}/historicalMeetings
export def "groups-historical-meetings get" [
  group_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # Required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<accountKey: string, duration: string, email: string, endTime: string, firstName: string, groupName: string, lastName: string, locale: string, meetingId: string, meetingType: string, numAttendees: string, organizerKey: string, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/historicalMeetings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEPRECATED: Get historical meetings by group
#
# GET /groups/{groupKey}/meetings
# DEPRECATED
@deprecated
export def "groups-meetings get" [
  group_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --history: oneof<nothing, bool> # When 'true', returns all past meetings within date range
  --start-date: string # If history=true, required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # If history=true, required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, duration: string, email: string, endTime: string, firstName: string, groupName: string, lastName: string, meetingId: string, meetingInstanceKey: int, meetingType: string, numAttendees: int, organizerKey: string, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "history" $history "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/meetings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"history": $history, "startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get organizers by group
#
# GET /groups/{groupKey}/organizers
export def "groups-organizers get" [
  group_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, firstName: string, groupId: int, groupName: string, lastName: string, maxNumAttendeesAllowed: int, organizerKey: int, products: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/organizers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Create organizer in group
#
# POST /groups/{groupKey}/organizers
export def "groups-organizers create" [
  group_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  first_name: string # The first name of the organizer
  last_name: string # The surname of the organizer
  organizer_email: string # The email address of the organizer
  product_type: string@product-type-completer # The products the organizer has access to, can be 'G2M', 'G2W', 'G2T' or 'OPENVOICE'
]: any -> table<email: string, key: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/organizers") $auth.query)
  let req_body = {"firstName": $first_name, "lastName": $last_name, "organizerEmail": $organizer_email, "productType": $product_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get upcoming meetings by group
#
# GET /groups/{groupKey}/upcomingMeetings
export def "groups-upcoming-meetings get" [
  group_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<accountKey: string, email: string, endTime: string, firstName: string, groupName: string, lastName: string, locale: string, meetingId: string, meetingType: string, organizerKey: string, passwordRequired: bool, startTime: string, status: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/upcomingMeetings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get historical meetings
#
# GET /historicalMeetings
export def "historical-meetings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # Required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, duration: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, numAttendees: string, organizerKey: string, sessionId: string, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historicalMeetings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEPRECATED: Get historical meetings
#
# GET /meetings
# DEPRECATED
@deprecated
export def "meetings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --history: oneof<nothing, bool> # When 'true', returns all past meetings within date range
  --start-date: string # If history=true, required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # If history=true, required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, date: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, lastName: string, meetingId: int, meetingInstanceKey: int, meetingKey: int, meetingType: string, newMeetingId: string, newOrganizerKey: string, numAttendees: int, organizerKey: string, organizerkey: string, passwordRequired: bool, sessionId: int, startTime: string, status: string, subject: string, uniqueMeetingId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "history" $history "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/meetings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"history": $history, "startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create meeting
#
# POST /meetings
export def "meetings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  conferencecallinfo: string # A required string. Can be one of the following options: PSTN (PSTN only), Free (PSTN and VoIP), Hybrid, (PSTN and VoIP), Private (you provide numbers and access code), or VoIP (VoIP only). You may also enter plain text for numbers and access codes with a limit of 255 characters
  endtime: string # The ending time of the meeting. Required ISO8601 UTC string, e.g. 2015-07-01T23:00:00Z (format: date-time)
  meetingtype: string@meetingtype-completer # The meeting type
  --passwordrequired: oneof<nothing, bool> # Indicates whether a password is required to join the meeting. Required parameter
  starttime: string # The starting time of the meeting. Required ISO8601 UTC string, e.g. 2015-07-01T22:00:00Z (format: date-time)
  subject: string # The subject of the meeting. 100 characters maximum. The characters '>' and '<' have to be replaced with the corresponding html character code (&gt; for '>' and &lt; for '<')
  timezonekey: string # DEPRECATED. Must be provided and set to empty string ''
]: any -> table<conferenceCallInfo: string, joinURL: string, maxParticipants: int, meetingid: int, uniqueMeetingId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meetings" $auth.query)
  let req_body = {"conferencecallinfo": $conferencecallinfo, "endtime": $endtime, "meetingtype": $meetingtype, "passwordrequired": $passwordrequired, "starttime": $starttime, "subject": $subject, "timezonekey": $timezonekey} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete meeting
#
# DELETE /meetings/{meetingId}
export def "meetings delete" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get meeting
#
# GET /meetings/{meetingId}
export def "meetings get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, createTime: string, duration: int, endTime: string, maxParticipants: int, meetingId: int, meetingKey: int, meetingType: string, passwordRequired: bool, startTime: string, status: string, subject: string, uniqueMeetingId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Update meeting
#
# PUT /meetings/{meetingId}
export def "meetings update" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  conferencecallinfo: string # A required string. Can be one of the following options: PSTN (PSTN only), Free (PSTN and VoIP), Hybrid, (PSTN and VoIP), Private (you provide numbers and access code), or VoIP (VoIP only). You may also enter plain text for numbers and access codes with a limit of 255 characters
  endtime: string # The ending time of the meeting. A required ISO8601 UTC string, e.g. 2015-07-01T22:00:00Z (format: date-time)
  meetingtype: string@meetingtype-completer # The meeting type
  --passwordrequired: oneof<nothing, bool> # Indicates whether a password is required to join the meeting. Required parameter
  starttime: string # The starting time of the meeting. A required ISO8601 UTC string, e.g. 2015-07-01T22:00:00Z (format: date-time)
  subject: string # A description of the meeting. 100 characters maximum. The characters '>' and '<' have to be replaced with the corresponding html character code (&gt; for '>' and &lt; for '<')
  timezonekey: string # DEPRECATED. Must be provided and set to empty string ''
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}") $auth.query)
  let req_body = {"conferencecallinfo": $conferencecallinfo, "endtime": $endtime, "meetingtype": $meetingtype, "passwordrequired": $passwordrequired, "starttime": $starttime, "subject": $subject, "timezonekey": $timezonekey} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get attendees by meeting
#
# GET /meetings/{meetingId}/attendees
export def "meetings-attendees get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<attendeeEmail: string, attendeeName: string, conferenceCallInfo: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, joinTime: string, lastName: string, leaveTime: string, meetingId: int, meetingInstanceKey: int, meetingType: string, name: string, numAttendees: int, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/attendees") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Start meeting
#
# GET /meetings/{meetingId}/start
export def "meetings-start get" [
  meeting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<hostURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meetingId' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/start") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Delete organizer by email
#
# DELETE /organizers
export def "organizers delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the organizer
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"email": $email} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get organizer by email / Get all organizers
#
# GET /organizers
export def "organizers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the organizer
  --authorization: string # Access token
]: nothing -> table<email: string, firstName: string, groupId: int, groupName: string, lastName: string, maxNumAttendeesAllowed: int, organizerKey: int, products: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"email": $email} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create organizer
#
# POST /organizers
export def "organizers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  first_name: string # The first name of the organizer
  last_name: string # The surname of the organizer
  organizer_email: string # The email address of the organizer
  product_type: string@product-type-completer # The products the organizer has access to, can be 'G2M', 'G2W', 'G2T' or 'OPENVOICE'
]: any -> table<email: string, key: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizers" $auth.query)
  let req_body = {"firstName": $first_name, "lastName": $last_name, "organizerEmail": $organizer_email, "productType": $product_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete organizer
#
# DELETE /organizers/{organizerKey}
export def "organizers delete-by-organizer-key" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get organizer
#
# GET /organizers/{organizerKey}
export def "organizers get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, firstName: string, groupId: int, groupName: string, lastName: string, maxNumAttendeesAllowed: int, organizerKey: int, products: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Update organizer
#
# PUT /organizers/{organizerKey}
export def "organizers update" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --product-type: string@product-type-completer # The products the organizer has access to, can be 'G2M', 'G2W', 'G2T' or 'OPENVOICE'
  --status: string@status-completer # The status of the organizer can be set to. Use 'suspended' to remove all products. The formerly used status 'active' is now DEPRECATED for this call. To activate the organizer please assign a product. In this case do not pass this parameter
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}") $auth.query)
  let req_body = {"productType": $product_type, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get attendees by organizer
#
# GET /organizers/{organizerKey}/attendees
export def "organizers-attendees get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # A required start of date range in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # A required end of date range in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<attendeeEmail: string, attendeeName: string, conferenceCallInfo: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, joinTime: string, lastName: string, leaveTime: string, meetingId: int, meetingInstanceKey: int, meetingType: string, name: string, newMeetingId: string, numAttendees: int, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/attendees") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get historical meetings by organizer
#
# GET /organizers/{organizerKey}/historicalMeetings
export def "organizers-historical-meetings get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # Required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, duration: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, numAttendees: string, organizerKey: string, sessionId: string, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/historicalMeetings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DEPRECATED: Get meetings by organizer
#
# GET /organizers/{organizerKey}/meetings
# DEPRECATED
@deprecated
export def "organizers-meetings get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scheduled: oneof<nothing, bool> # When 'true', returns all future meetings. Date range not supported.
  --history: oneof<nothing, bool> # When 'true', returns all past meetings within date range
  --start-date: string # If history is 'true', required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --end-date: string # If history is 'true', required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, createTime: string, endTime: string, maxParticipants: int, meetingType: string, meetingid: int, passwordRequired: bool, startTime: string, status: string, subject: string, uniqueMeetingId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let qp = [(serialize-qp "scheduled" $scheduled "scalar") (serialize-qp "history" $history "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/meetings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"scheduled": $scheduled, "history": $history, "startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get upcoming meetings by organizer
#
# GET /organizers/{organizerKey}/upcomingMeetings
export def "organizers-upcoming-meetings get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, organizerKey: string, passwordRequired: bool, startTime: string, status: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organizer_key | is-empty) { error make --unspanned { msg: "path parameter 'organizerKey' must be non-empty" } }
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/upcomingMeetings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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

# Get upcoming meetings
#
# GET /upcomingMeetings
export def "upcoming-meetings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, organizerKey: string, passwordRequired: bool, startTime: string, status: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/upcomingMeetings" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
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
