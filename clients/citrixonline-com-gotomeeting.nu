# Auto-generated client for GoToMeeting v1.0.0
# Source: https://api.apis.guru/v2/specs/citrixonline.com/gotomeeting/1.0.0/swagger.json
# Auth: --token flag or $env.GOTOMEETING_TOKEN

const BASE_URL = "https://api.citrixonline.com/G2M/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOTOMEETING_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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
  let full_url = (build-url $base "/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/attendees") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/historicalMeetings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/meetings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"history": $history, "startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/organizers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/organizers"))
  let req_body = {"firstName": $first_name, "lastName": $last_name, "organizerEmail": $organizer_email, "productType": $product_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/groups/{group_key}/upcomingMeetings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base "/historicalMeetings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base "/meetings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"history": $history, "startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base "/meetings")
  let req_body = {"conferencecallinfo": $conferencecallinfo, "endtime": $endtime, "meetingtype": $meetingtype, "passwordrequired": $passwordrequired, "starttime": $starttime, "subject": $subject, "timezonekey": $timezonekey} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}"))
  let req_body = {"conferencecallinfo": $conferencecallinfo, "endtime": $endtime, "meetingtype": $meetingtype, "passwordrequired": $passwordrequired, "starttime": $starttime, "subject": $subject, "timezonekey": $timezonekey} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/attendees"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/meetings/{meeting_id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base "/organizers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"email": $email} | compact), body: null}
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
  let full_url = (build-url $base "/organizers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"email": $email} | compact), body: null}
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
  let full_url = (build-url $base "/organizers")
  let req_body = {"firstName": $first_name, "lastName": $last_name, "organizerEmail": $organizer_email, "productType": $product_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}"))
  let req_body = {"productType": $product_type, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/attendees") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/historicalMeetings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/meetings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"scheduled": $scheduled, "history": $history, "startDate": $start_date, "endDate": $end_date} | compact), body: null}
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
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/upcomingMeetings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base "/upcomingMeetings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
