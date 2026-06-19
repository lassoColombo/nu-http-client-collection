# Auto-generated client for Calendar API vv3
# Source: https://api.apis.guru/v2/specs/googleapis.com/calendar/v3/openapi.json
# Auth: --token flag or $env.CALENDAR_API_TOKEN

const BASE_URL = "https://www.googleapis.com/calendar/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CALENDAR_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/calendar/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def order-by-completer [] { ["startTime" "updated"] }
def send-updates-completer [] { ["all" "externalOnly" "none"] }
def min-access-role-completer [] { ["freeBusyReader" "owner" "reader" "writer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "calendars create" } } | get name | first)
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

# Creates a secondary calendar.
#
# POST /calendars
# operationId: calendar.calendars.insert
# --conferenceProperties shape: {allowedConferenceSolutionTypes?: list<string>}
export def "calendars create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --description: string # Description of the calendar. Optional.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the calendar. To retrieve IDs call the calendarList.list() method.
  --kind: string # Type of the resource ("calendar#calendar"). (default: calendar#calendar)
  --location: string # Geographic location of the calendar as free-form text. Optional.
  --summary: string # Title of the calendar.
  --time-zone: string # The time zone of the calendar. (Formatted as an IANA Time Zone Database name, e.g. "Europe/Zurich".) Optional.
]: any -> record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calendars" $qp)
  let req_body = {"conferenceProperties": $conference_properties, "description": $description, "etag": $etag, "id": $id, "kind": $kind, "location": $location, "summary": $summary, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Deletes a secondary calendar. Use calendars.clear for clearing all events on primary calendars.
#
# DELETE /calendars/{calendarId}
# operationId: calendar.calendars.delete
export def "calendars delete" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Returns metadata for a calendar.
#
# GET /calendars/{calendarId}
# operationId: calendar.calendars.get
export def "calendars get" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Updates metadata for a calendar. This method supports patch semantics.
#
# PATCH /calendars/{calendarId}
# operationId: calendar.calendars.patch
# --conferenceProperties shape: {allowedConferenceSolutionTypes?: list<string>}
export def "calendars update-by-calendar-id" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --description: string # Description of the calendar. Optional.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the calendar. To retrieve IDs call the calendarList.list() method.
  --kind: string # Type of the resource ("calendar#calendar"). (default: calendar#calendar)
  --location: string # Geographic location of the calendar as free-form text. Optional.
  --summary: string # Title of the calendar.
  --time-zone: string # The time zone of the calendar. (Formatted as an IANA Time Zone Database name, e.g. "Europe/Zurich".) Optional.
]: any -> record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}") $qp)
  let req_body = {"conferenceProperties": $conference_properties, "description": $description, "etag": $etag, "id": $id, "kind": $kind, "location": $location, "summary": $summary, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Updates metadata for a calendar.
#
# PUT /calendars/{calendarId}
# operationId: calendar.calendars.update
# --conferenceProperties shape: {allowedConferenceSolutionTypes?: list<string>}
export def "calendars update-by-calendar-id-1" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --description: string # Description of the calendar. Optional.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the calendar. To retrieve IDs call the calendarList.list() method.
  --kind: string # Type of the resource ("calendar#calendar"). (default: calendar#calendar)
  --location: string # Geographic location of the calendar as free-form text. Optional.
  --summary: string # Title of the calendar.
  --time-zone: string # The time zone of the calendar. (Formatted as an IANA Time Zone Database name, e.g. "Europe/Zurich".) Optional.
]: any -> record<conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, description: string, etag: string, id: string, kind: string, location: string, summary: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}") $qp)
  let req_body = {"conferenceProperties": $conference_properties, "description": $description, "etag": $etag, "id": $id, "kind": $kind, "location": $location, "summary": $summary, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Returns the rules in the access control list for the calendar.
#
# GET /calendars/{calendarId}/acl
# operationId: calendar.acl.list
export def "calendars-acl list" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted ACLs in the result. Deleted ACLs are represented by role equal to "none". Deleted ACLs will always be included if syncToken is provided. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All entries deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
]: nothing -> record<etag: string, items: table<etag: string, id: string, kind: string, role: string, scope: record>, kind: string, nextPageToken: string, nextSyncToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/acl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token, "showDeleted": $show_deleted, "syncToken": $sync_token} | compact), body: null}
}

# Creates an access control rule.
#
# POST /calendars/{calendarId}/acl
# operationId: calendar.acl.insert
# --scope shape: {type?: string, value?: string}
export def "calendars-acl create" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --send-notifications: oneof<nothing, bool> # Whether to send notifications about the calendar sharing change. Optional. The default is True.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the Access Control List (ACL) rule. See Sharing calendars.
  --kind: string # Type of the resource ("calendar#aclRule"). (default: calendar#aclRule)
  --role: string # The role assigned to the scope. Possible values are: - "none" - Provides no access. - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --scope: record # The extent to which calendar access is granted by this ACL rule. — shape: {type?: string, value?: string}
]: any -> record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/acl") $qp)
  let req_body = {"etag": $etag, "id": $id, "kind": $kind, "role": $role, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "sendNotifications": $send_notifications} | compact), body: $req_body}
}

# Watch for changes to ACL resources.
#
# POST /calendars/{calendarId}/acl/watch
# operationId: calendar.acl.watch
export def "calendars-acl-watch watch" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted ACLs in the result. Deleted ACLs are represented by role equal to "none". Deleted ACLs will always be included if syncToken is provided. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All entries deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/acl/watch") $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token, "showDeleted": $show_deleted, "syncToken": $sync_token} | compact), body: $req_body}
}

# Deletes an access control rule.
#
# DELETE /calendars/{calendarId}/acl/{ruleId}
# operationId: calendar.acl.delete
export def "calendars-acl delete" [
  calendar_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/calendars/{calendar_id}/acl/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Returns an access control rule.
#
# GET /calendars/{calendarId}/acl/{ruleId}
# operationId: calendar.acl.get
export def "calendars-acl get" [
  calendar_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/calendars/{calendar_id}/acl/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Updates an access control rule. This method supports patch semantics.
#
# PATCH /calendars/{calendarId}/acl/{ruleId}
# operationId: calendar.acl.patch
# --scope shape: {type?: string, value?: string}
export def "calendars-acl update-by-calendar-id-rule-id" [
  calendar_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --send-notifications: oneof<nothing, bool> # Whether to send notifications about the calendar sharing change. Note that there are no notifications on access removal. Optional. The default is True.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the Access Control List (ACL) rule. See Sharing calendars.
  --kind: string # Type of the resource ("calendar#aclRule"). (default: calendar#aclRule)
  --role: string # The role assigned to the scope. Possible values are: - "none" - Provides no access. - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --scope: record # The extent to which calendar access is granted by this ACL rule. — shape: {type?: string, value?: string}
]: any -> record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/calendars/{calendar_id}/acl/{rule_id}") $qp)
  let req_body = {"etag": $etag, "id": $id, "kind": $kind, "role": $role, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "sendNotifications": $send_notifications} | compact), body: $req_body}
}

# Updates an access control rule.
#
# PUT /calendars/{calendarId}/acl/{ruleId}
# operationId: calendar.acl.update
# --scope shape: {type?: string, value?: string}
export def "calendars-acl update-by-calendar-id-rule-id-1" [
  calendar_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --send-notifications: oneof<nothing, bool> # Whether to send notifications about the calendar sharing change. Note that there are no notifications on access removal. Optional. The default is True.
  --etag: string # ETag of the resource.
  --id: string # Identifier of the Access Control List (ACL) rule. See Sharing calendars.
  --kind: string # Type of the resource ("calendar#aclRule"). (default: calendar#aclRule)
  --role: string # The role assigned to the scope. Possible values are: - "none" - Provides no access. - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --scope: record # The extent to which calendar access is granted by this ACL rule. — shape: {type?: string, value?: string}
]: any -> record<etag: string, id: string, kind: string, role: string, scope: record<type: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/calendars/{calendar_id}/acl/{rule_id}") $qp)
  let req_body = {"etag": $etag, "id": $id, "kind": $kind, "role": $role, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "sendNotifications": $send_notifications} | compact), body: $req_body}
}

# Clears a primary calendar. This operation deletes all events associated with the primary calendar of an account.
#
# POST /calendars/{calendarId}/clear
# operationId: calendar.calendars.clear
export def "calendars-clear create" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/clear") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Returns events on the specified calendar.
#
# GET /calendars/{calendarId}/events
# operationId: calendar.events.list
export def "calendars-events list" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --event-types: list<string> # Event types to return. Optional. Possible values are: - "default" - "focusTime" - "outOfOffice"This parameter can be repeated multiple times to return events of different types. Currently, this is the only allowed value for this field: - ["default", "focusTime", "outOfOffice"] This value will be the default. If you're enrolled in the Working Location developer preview program, in addition to the default value above you can also set the "workingLocation" event type: - ["default", "focusTime", "outOfOffice", "workingLocation"] - ["workingLocation"] Additional combinations of these 4 event types will be made available in later releases. Developer Preview.
  --i-cal-uid: string # Specifies an event ID in the iCalendar format to be provided in the response. Optional. Use this if you want to search for an event by its iCalendar ID.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --max-results: int # Maximum number of events returned on one result page. The number of events in the resulting page may be less than this value, or none at all, even if there are more events matching the query. Incomplete pages can be detected by a non-empty nextPageToken field in the response. By default the value is 250 events. The page size can never be larger than 2500 events. Optional.
  --order-by: string@order-by-completer # The order of the events returned in the result. Optional. The default is an unspecified, stable order.
  --page-token: string # Token specifying which result page to return. Optional.
  --private-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only private properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --q: string # Free text search terms to find events that match these terms in the following fields: summary, description, location, attendee's displayName, attendee's email. Optional.
  --shared-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only shared properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events (with status equals "cancelled") in the result. Cancelled instances of recurring events (but not the underlying recurring event) will still be included if showDeleted and singleEvents are both False. If showDeleted and singleEvents are both True, only single instances of deleted events (but not the underlying recurring events) are returned. Optional. The default is False.
  --show-hidden-invitations: oneof<nothing, bool> # Whether to include hidden invitations in the result. Optional. The default is False.
  --single-events: oneof<nothing, bool> # Whether to expand recurring events into instances and only return single one-off events and instances of recurring events, but not the underlying recurring events themselves. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All events deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. There are several query parameters that cannot be specified together with nextSyncToken to ensure consistency of the client state. These are: - iCalUID - orderBy - privateExtendedProperty - q - sharedExtendedProperty - timeMin - timeMax - updatedMin If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --time-max: string # Upper bound (exclusive) for an event's start time to filter by. Optional. The default is not to filter by start time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMin is set, timeMax must be greater than timeMin.
  --time-min: string # Lower bound (exclusive) for an event's end time to filter by. Optional. The default is not to filter by end time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMax is set, timeMin must be smaller than timeMax.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
  --updated-min: string # Lower bound for an event's last modification time (as a RFC3339 timestamp) to filter by. When specified, entries deleted since this time will always be included regardless of showDeleted. Optional. The default is not to filter by last modification time.
]: nothing -> record<accessRole: string, defaultReminders: table<method: string, minutes: int>, description: string, etag: string, items: table<anyoneCanAddSelf: bool, attachments: list, attendees: list, attendeesOmitted: bool, colorId: string, conferenceData: record, created: string, creator: record, description: string, end: record, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record, gadget: record, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record, originalStartTime: record, privateCopy: bool, recurrence: list, recurringEventId: string, reminders: record, sequence: int, source: record, start: record, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record>, kind: string, nextPageToken: string, nextSyncToken: string, summary: string, timeZone: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "alwaysIncludeEmail" $always_include_email "scalar") (serialize-qp "eventTypes" $event_types "multi") (serialize-qp "iCalUID" $i_cal_uid "scalar") (serialize-qp "maxAttendees" $max_attendees "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "privateExtendedProperty" $private_extended_property "multi") (serialize-qp "q" $q "scalar") (serialize-qp "sharedExtendedProperty" $shared_extended_property "multi") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "showHiddenInvitations" $show_hidden_invitations "scalar") (serialize-qp "singleEvents" $single_events "scalar") (serialize-qp "syncToken" $sync_token "scalar") (serialize-qp "timeMax" $time_max "scalar") (serialize-qp "timeMin" $time_min "scalar") (serialize-qp "timeZone" $time_zone "scalar") (serialize-qp "updatedMin" $updated_min "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "alwaysIncludeEmail": $always_include_email, "eventTypes": $event_types, "iCalUID": $i_cal_uid, "maxAttendees": $max_attendees, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "privateExtendedProperty": $private_extended_property, "q": $q, "sharedExtendedProperty": $shared_extended_property, "showDeleted": $show_deleted, "showHiddenInvitations": $show_hidden_invitations, "singleEvents": $single_events, "syncToken": $sync_token, "timeMax": $time_max, "timeMin": $time_min, "timeZone": $time_zone, "updatedMin": $updated_min} | compact), body: null}
}

# Creates an event.
#
# POST /calendars/{calendarId}/events
# operationId: calendar.events.insert
# --attachments item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
# --attendees item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
# --conferenceData shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
# --creator shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --end shape: {date?: string, dateTime?: string, timeZone?: string}
# --extendedProperties shape: {private?: record, shared?: record}
# --gadget shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
# --organizer shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --originalStartTime shape: {date?: string, dateTime?: string, timeZone?: string}
# --reminders shape: {overrides?: list, useDefault?: bool}
# --source shape: {title?: string, url?: string}
# --start shape: {date?: string, dateTime?: string, timeZone?: string}
# --workingLocationProperties shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
export def "calendars-events create" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the creation of the new event. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Whether to send notifications about the creation of the new event. Note that some emails might still be sent. The default is false.
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --body-source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "conferenceDataVersion" $conference_data_version "scalar") (serialize-qp "maxAttendees" $max_attendees "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar") (serialize-qp "sendUpdates" $send_updates "scalar") (serialize-qp "supportsAttachments" $supports_attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/events") $qp)
  let req_body = {"anyoneCanAddSelf": $anyone_can_add_self, "attachments": $attachments, "attendees": $attendees, "attendeesOmitted": $attendees_omitted, "colorId": $color_id, "conferenceData": $conference_data, "created": $created, "creator": $creator, "description": $description, "end": $end, "endTimeUnspecified": $end_time_unspecified, "etag": $etag, "eventType": $event_type, "extendedProperties": $extended_properties, "gadget": $gadget, "guestsCanInviteOthers": $guests_can_invite_others, "guestsCanModify": $guests_can_modify, "guestsCanSeeOtherGuests": $guests_can_see_other_guests, "hangoutLink": $hangout_link, "htmlLink": $html_link, "iCalUID": $i_cal_uid, "id": $id, "kind": $kind, "location": $location, "locked": $locked, "organizer": $organizer, "originalStartTime": $original_start_time, "privateCopy": $private_copy, "recurrence": $recurrence, "recurringEventId": $recurring_event_id, "reminders": $reminders, "sequence": $sequence, "source": $body_source, "start": $start, "status": $status, "summary": $summary, "transparency": $transparency, "updated": $updated, "visibility": $visibility, "workingLocationProperties": $working_location_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "conferenceDataVersion": $conference_data_version, "maxAttendees": $max_attendees, "sendNotifications": $send_notifications, "sendUpdates": $send_updates, "supportsAttachments": $supports_attachments} | compact), body: $req_body}
}

# Imports an event. This operation is used to add a private copy of an existing event to a calendar.
#
# POST /calendars/{calendarId}/events/import
# operationId: calendar.events.import
# --attachments item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
# --attendees item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
# --conferenceData shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
# --creator shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --end shape: {date?: string, dateTime?: string, timeZone?: string}
# --extendedProperties shape: {private?: record, shared?: record}
# --gadget shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
# --organizer shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --originalStartTime shape: {date?: string, dateTime?: string, timeZone?: string}
# --reminders shape: {overrides?: list, useDefault?: bool}
# --source shape: {title?: string, url?: string}
# --start shape: {date?: string, dateTime?: string, timeZone?: string}
# --workingLocationProperties shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
export def "calendars-events-import import" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --body-source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "conferenceDataVersion" $conference_data_version "scalar") (serialize-qp "supportsAttachments" $supports_attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/events/import") $qp)
  let req_body = {"anyoneCanAddSelf": $anyone_can_add_self, "attachments": $attachments, "attendees": $attendees, "attendeesOmitted": $attendees_omitted, "colorId": $color_id, "conferenceData": $conference_data, "created": $created, "creator": $creator, "description": $description, "end": $end, "endTimeUnspecified": $end_time_unspecified, "etag": $etag, "eventType": $event_type, "extendedProperties": $extended_properties, "gadget": $gadget, "guestsCanInviteOthers": $guests_can_invite_others, "guestsCanModify": $guests_can_modify, "guestsCanSeeOtherGuests": $guests_can_see_other_guests, "hangoutLink": $hangout_link, "htmlLink": $html_link, "iCalUID": $i_cal_uid, "id": $id, "kind": $kind, "location": $location, "locked": $locked, "organizer": $organizer, "originalStartTime": $original_start_time, "privateCopy": $private_copy, "recurrence": $recurrence, "recurringEventId": $recurring_event_id, "reminders": $reminders, "sequence": $sequence, "source": $body_source, "start": $start, "status": $status, "summary": $summary, "transparency": $transparency, "updated": $updated, "visibility": $visibility, "workingLocationProperties": $working_location_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "conferenceDataVersion": $conference_data_version, "supportsAttachments": $supports_attachments} | compact), body: $req_body}
}

# Creates an event based on a simple text string.
#
# POST /calendars/{calendarId}/events/quickAdd
# operationId: calendar.events.quickAdd
export def "calendars-events-quick-add create" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --text: string # The text describing the event to be created.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the creation of the event. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the creation of the new event.
]: nothing -> record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar") (serialize-qp "sendUpdates" $send_updates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/events/quickAdd") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "text": $text, "sendNotifications": $send_notifications, "sendUpdates": $send_updates} | compact), body: null}
}

# Watch for changes to Events resources.
#
# POST /calendars/{calendarId}/events/watch
# operationId: calendar.events.watch
export def "calendars-events-watch watch" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --event-types: list<string> # Event types to return. Optional. Possible values are: - "default" - "focusTime" - "outOfOffice"This parameter can be repeated multiple times to return events of different types. Currently, this is the only allowed value for this field: - ["default", "focusTime", "outOfOffice"] This value will be the default. If you're enrolled in the Working Location developer preview program, in addition to the default value above you can also set the "workingLocation" event type: - ["default", "focusTime", "outOfOffice", "workingLocation"] - ["workingLocation"] Additional combinations of these 4 event types will be made available in later releases. Developer Preview.
  --i-cal-uid: string # Specifies an event ID in the iCalendar format to be provided in the response. Optional. Use this if you want to search for an event by its iCalendar ID.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --max-results: int # Maximum number of events returned on one result page. The number of events in the resulting page may be less than this value, or none at all, even if there are more events matching the query. Incomplete pages can be detected by a non-empty nextPageToken field in the response. By default the value is 250 events. The page size can never be larger than 2500 events. Optional.
  --order-by: string@order-by-completer # The order of the events returned in the result. Optional. The default is an unspecified, stable order.
  --page-token: string # Token specifying which result page to return. Optional.
  --private-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only private properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --q: string # Free text search terms to find events that match these terms in the following fields: summary, description, location, attendee's displayName, attendee's email. Optional.
  --shared-extended-property: list<string> # Extended properties constraint specified as propertyName=value. Matches only shared properties. This parameter might be repeated multiple times to return events that match all given constraints.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events (with status equals "cancelled") in the result. Cancelled instances of recurring events (but not the underlying recurring event) will still be included if showDeleted and singleEvents are both False. If showDeleted and singleEvents are both True, only single instances of deleted events (but not the underlying recurring events) are returned. Optional. The default is False.
  --show-hidden-invitations: oneof<nothing, bool> # Whether to include hidden invitations in the result. Optional. The default is False.
  --single-events: oneof<nothing, bool> # Whether to expand recurring events into instances and only return single one-off events and instances of recurring events, but not the underlying recurring events themselves. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. All events deleted since the previous list request will always be in the result set and it is not allowed to set showDeleted to False. There are several query parameters that cannot be specified together with nextSyncToken to ensure consistency of the client state. These are: - iCalUID - orderBy - privateExtendedProperty - q - sharedExtendedProperty - timeMin - timeMax - updatedMin If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --time-max: string # Upper bound (exclusive) for an event's start time to filter by. Optional. The default is not to filter by start time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMin is set, timeMax must be greater than timeMin.
  --time-min: string # Lower bound (exclusive) for an event's end time to filter by. Optional. The default is not to filter by end time. Must be an RFC3339 timestamp with mandatory time zone offset, for example, 2011-06-03T10:00:00-07:00, 2011-06-03T10:00:00Z. Milliseconds may be provided but are ignored. If timeMax is set, timeMin must be smaller than timeMax.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
  --updated-min: string # Lower bound for an event's last modification time (as a RFC3339 timestamp) to filter by. When specified, entries deleted since this time will always be included regardless of showDeleted. Optional. The default is not to filter by last modification time.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "alwaysIncludeEmail" $always_include_email "scalar") (serialize-qp "eventTypes" $event_types "multi") (serialize-qp "iCalUID" $i_cal_uid "scalar") (serialize-qp "maxAttendees" $max_attendees "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "privateExtendedProperty" $private_extended_property "multi") (serialize-qp "q" $q "scalar") (serialize-qp "sharedExtendedProperty" $shared_extended_property "multi") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "showHiddenInvitations" $show_hidden_invitations "scalar") (serialize-qp "singleEvents" $single_events "scalar") (serialize-qp "syncToken" $sync_token "scalar") (serialize-qp "timeMax" $time_max "scalar") (serialize-qp "timeMin" $time_min "scalar") (serialize-qp "timeZone" $time_zone "scalar") (serialize-qp "updatedMin" $updated_min "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/calendars/{calendar_id}/events/watch") $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "alwaysIncludeEmail": $always_include_email, "eventTypes": $event_types, "iCalUID": $i_cal_uid, "maxAttendees": $max_attendees, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "privateExtendedProperty": $private_extended_property, "q": $q, "sharedExtendedProperty": $shared_extended_property, "showDeleted": $show_deleted, "showHiddenInvitations": $show_hidden_invitations, "singleEvents": $single_events, "syncToken": $sync_token, "timeMax": $time_max, "timeMin": $time_min, "timeZone": $time_zone, "updatedMin": $updated_min} | compact), body: $req_body}
}

# Deletes an event.
#
# DELETE /calendars/{calendarId}/events/{eventId}
# operationId: calendar.events.delete
export def "calendars-events delete" [
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the deletion of the event. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the deletion of the event.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar") (serialize-qp "sendUpdates" $send_updates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), event_id: (encode-path-segment $event_id)} | format pattern "/calendars/{calendar_id}/events/{event_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "sendNotifications": $send_notifications, "sendUpdates": $send_updates} | compact), body: null}
}

# Returns an event based on its Google Calendar ID. To retrieve an event using its iCalendar ID, call the events.list method using the iCalUID parameter.
#
# GET /calendars/{calendarId}/events/{eventId}
# operationId: calendar.events.get
export def "calendars-events get" [
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
]: nothing -> record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "alwaysIncludeEmail" $always_include_email "scalar") (serialize-qp "maxAttendees" $max_attendees "scalar") (serialize-qp "timeZone" $time_zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), event_id: (encode-path-segment $event_id)} | format pattern "/calendars/{calendar_id}/events/{event_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "alwaysIncludeEmail": $always_include_email, "maxAttendees": $max_attendees, "timeZone": $time_zone} | compact), body: null}
}

# Updates an event. This method supports patch semantics.
#
# PATCH /calendars/{calendarId}/events/{eventId}
# operationId: calendar.events.patch
# --attachments item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
# --attendees item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
# --conferenceData shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
# --creator shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --end shape: {date?: string, dateTime?: string, timeZone?: string}
# --extendedProperties shape: {private?: record, shared?: record}
# --gadget shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
# --organizer shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --originalStartTime shape: {date?: string, dateTime?: string, timeZone?: string}
# --reminders shape: {overrides?: list, useDefault?: bool}
# --source shape: {title?: string, url?: string}
# --start shape: {date?: string, dateTime?: string, timeZone?: string}
# --workingLocationProperties shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
export def "calendars-events update-by-calendar-id-event-id" [
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the event update (for example, description changes, etc.). Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the event update (for example, title changes, etc.).
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --body-source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "alwaysIncludeEmail" $always_include_email "scalar") (serialize-qp "conferenceDataVersion" $conference_data_version "scalar") (serialize-qp "maxAttendees" $max_attendees "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar") (serialize-qp "sendUpdates" $send_updates "scalar") (serialize-qp "supportsAttachments" $supports_attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), event_id: (encode-path-segment $event_id)} | format pattern "/calendars/{calendar_id}/events/{event_id}") $qp)
  let req_body = {"anyoneCanAddSelf": $anyone_can_add_self, "attachments": $attachments, "attendees": $attendees, "attendeesOmitted": $attendees_omitted, "colorId": $color_id, "conferenceData": $conference_data, "created": $created, "creator": $creator, "description": $description, "end": $end, "endTimeUnspecified": $end_time_unspecified, "etag": $etag, "eventType": $event_type, "extendedProperties": $extended_properties, "gadget": $gadget, "guestsCanInviteOthers": $guests_can_invite_others, "guestsCanModify": $guests_can_modify, "guestsCanSeeOtherGuests": $guests_can_see_other_guests, "hangoutLink": $hangout_link, "htmlLink": $html_link, "iCalUID": $i_cal_uid, "id": $id, "kind": $kind, "location": $location, "locked": $locked, "organizer": $organizer, "originalStartTime": $original_start_time, "privateCopy": $private_copy, "recurrence": $recurrence, "recurringEventId": $recurring_event_id, "reminders": $reminders, "sequence": $sequence, "source": $body_source, "start": $start, "status": $status, "summary": $summary, "transparency": $transparency, "updated": $updated, "visibility": $visibility, "workingLocationProperties": $working_location_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "alwaysIncludeEmail": $always_include_email, "conferenceDataVersion": $conference_data_version, "maxAttendees": $max_attendees, "sendNotifications": $send_notifications, "sendUpdates": $send_updates, "supportsAttachments": $supports_attachments} | compact), body: $req_body}
}

# Updates an event.
#
# PUT /calendars/{calendarId}/events/{eventId}
# operationId: calendar.events.update
# --attachments item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
# --attendees item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
# --conferenceData shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
# --creator shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --end shape: {date?: string, dateTime?: string, timeZone?: string}
# --extendedProperties shape: {private?: record, shared?: record}
# --gadget shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
# --organizer shape: {displayName?: string, email?: string, id?: string, self?: bool}
# --originalStartTime shape: {date?: string, dateTime?: string, timeZone?: string}
# --reminders shape: {overrides?: list, useDefault?: bool}
# --source shape: {title?: string, url?: string}
# --start shape: {date?: string, dateTime?: string, timeZone?: string}
# --workingLocationProperties shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
export def "calendars-events update-by-calendar-id-event-id-1" [
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --conference-data-version: int # Version number of conference data supported by the API client. Version 0 assumes no conference data support and ignores conference data in the event's body. Version 1 enables support for copying of ConferenceData as well as for creating new conferences using the createRequest field of conferenceData. The default is 0.
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the event update (for example, description changes, etc.). Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the event update (for example, title changes, etc.).
  --supports-attachments: oneof<nothing, bool> # Whether API client performing operation supports event attachments. Optional. The default is False.
  --anyone-can-add-self: oneof<nothing, bool> # Whether anyone can invite themselves to the event (deprecated). Optional. The default is False. (default: false)
  --attachments: list # File attachments for the event. In order to modify attachments the supportsAttachments request parameter should be set to true. There can be at most 25 attachments per event, — item shape: {fileId?: string, fileUrl?: string, iconLink?: string, mimeType?: string, title?: string}
  --attendees: list # The attendees of the event. See the Events with attendees guide for more information on scheduling events with other calendar users. Service accounts need to use domain-wide delegation of authority to populate the attendee list. — item shape: {additionalGuests?: int, comment?: string, displayName?: string, email?: string, id?: string, optional?: bool, organizer?: bool, resource?: bool, responseStatus?: string, self?: bool}
  --attendees-omitted: oneof<nothing, bool> # Whether attendees may have been omitted from the event's representation. When retrieving an event, this may be due to a restriction specified by the maxAttendee query parameter. When updating an event, this can be used to only update the participant's response. Optional. The default is False. (default: false)
  --color-id: string # The color of the event. This is an ID referring to an entry in the event section of the colors definition (see the colors endpoint). Optional.
  --conference-data: record # shape: {conferenceId?: string, conferenceSolution?: record, createRequest?: record, entryPoints?: list, notes?: string, parameters?: record, signature?: string}
  --created: string # Creation time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --creator: record # The creator of the event. Read-only. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --description: string # Description of the event. Can contain HTML. Optional.
  --end: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --end-time-unspecified: oneof<nothing, bool> # Whether the end time is actually unspecified. An end time is still provided for compatibility reasons, even if this attribute is set to True. The default is False. (default: false)
  --etag: string # ETag of the resource.
  --event-type: string # Specific type of the event. Read-only. Possible values are: - "default" - A regular event or not further specified. - "outOfOffice" - An out-of-office event. - "focusTime" - A focus-time event. - "workingLocation" - A working location event. Developer Preview. (default: default)
  --extended-properties: record # Extended properties of the event. — shape: {private?: record, shared?: record}
  --gadget: record # A gadget that extends this event. Gadgets are deprecated; this structure is instead only used for returning birthday calendar metadata. — shape: {display?: string, height?: int, iconLink?: string, link?: string, preferences?: record, title?: string, type?: string, width?: int}
  --guests-can-invite-others: oneof<nothing, bool> # Whether attendees other than the organizer can invite others to the event. Optional. The default is True. (default: true)
  --guests-can-modify: oneof<nothing, bool> # Whether attendees other than the organizer can modify the event. Optional. The default is False. (default: false)
  --guests-can-see-other-guests: oneof<nothing, bool> # Whether attendees other than the organizer can see who the event's attendees are. Optional. The default is True. (default: true)
  --hangout-link: string # An absolute link to the Google Hangout associated with this event. Read-only.
  --html-link: string # An absolute link to this event in the Google Calendar Web UI. Read-only.
  --i-cal-uid: string # Event unique identifier as defined in RFC5545. It is used to uniquely identify events accross calendaring systems and must be supplied when importing events via the import method. Note that the iCalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same iCalUIDs. To retrieve an event using its iCalUID, call the events.list method using the iCalUID parameter. To retrieve an event using its id, call the events.get method.
  --id: string # Opaque identifier of the event. When creating new single or recurring events, you can specify their IDs. Provided IDs must follow these rules: - characters allowed in the ID are those used in base32hex encoding, i.e. lowercase letters a-v and digits 0-9, see section 3.1.2 in RFC2938 - the length of the ID must be between 5 and 1024 characters - the ID must be unique per calendar Due to the globally distributed nature of the system, we cannot guarantee that ID collisions will be detected at event creation time. To minimize the risk of collisions we recommend using an established UUID algorithm such as one described in RFC4122. If you do not specify an ID, it will be automatically generated by the server. Note that the icalUID and the id are not identical and only one of them should be supplied at event creation time. One difference in their semantics is that in recurring events, all occurrences of one event have different ids while they all share the same icalUIDs.
  --kind: string # Type of the resource ("calendar#event"). (default: calendar#event)
  --location: string # Geographic location of the event as free-form text. Optional.
  --locked: oneof<nothing, bool> # Whether this is a locked event copy where no changes can be made to the main event fields "summary", "description", "location", "start", "end" or "recurrence". The default is False. Read-Only. (default: false)
  --organizer: record # The organizer of the event. If the organizer is also an attendee, this is indicated with a separate entry in attendees with the organizer field set to True. To change the organizer, use the move operation. Read-only, except when importing an event. — shape: {displayName?: string, email?: string, id?: string, self?: bool}
  --original-start-time: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --private-copy: oneof<nothing, bool> # If set to True, Event propagation is disabled. Note that it is not the same thing as Private event properties. Optional. Immutable. The default is False. (default: false)
  --recurrence: list<string> # List of RRULE, EXRULE, RDATE and EXDATE lines for a recurring event, as specified in RFC5545. Note that DTSTART and DTEND lines are not allowed in this field; event start and end times are specified in the start and end fields. This field is omitted for single events or instances of recurring events.
  --recurring-event-id: string # For an instance of a recurring event, this is the id of the recurring event to which this instance belongs. Immutable.
  --reminders: record # Information about the event's reminders for the authenticated user. — shape: {overrides?: list, useDefault?: bool}
  --sequence: int # Sequence number as per iCalendar. (format: int32)
  --body-source: record # Source from which the event was created. For example, a web page, an email message or any document identifiable by an URL with HTTP or HTTPS scheme. Can only be seen or modified by the creator of the event. — shape: {title?: string, url?: string}
  --start: record # shape: {date?: string, dateTime?: string, timeZone?: string}
  --status: string # Status of the event. Optional. Possible values are: - "confirmed" - The event is confirmed. This is the default status. - "tentative" - The event is tentatively confirmed. - "cancelled" - The event is cancelled (deleted). The list method returns cancelled events only on incremental sync (when syncToken or updatedMin are specified) or if the showDeleted flag is set to true. The get method always returns them. A cancelled status represents two different states depending on the event type: - Cancelled exceptions of an uncancelled recurring event indicate that this instance should no longer be presented to the user. Clients should store these events for the lifetime of the parent recurring event. Cancelled exceptions are only guaranteed to have values for the id, recurringEventId and originalStartTime fields populated. The other fields might be empty. - All other cancelled events represent deleted events. Clients should remove their locally synced copies. Such cancelled events will eventually disappear, so do not rely on them being available indefinitely. Deleted events are only guaranteed to have the id field populated. On the organizer's calendar, cancelled events continue to expose event details (summary, location, etc.) so that they can be restored (undeleted). Similarly, the events to which the user was invited and that they manually removed continue to provide details. However, incremental sync requests with showDeleted set to false will not return these details. If an event changes its organizer (for example via the move operation) and the original organizer is not on the attendee list, it will leave behind a cancelled event where only the id field is guaranteed to be populated.
  --summary: string # Title of the event.
  --transparency: string # Whether the event blocks time on the calendar. Optional. Possible values are: - "opaque" - Default value. The event does block time on the calendar. This is equivalent to setting Show me as to Busy in the Calendar UI. - "transparent" - The event does not block time on the calendar. This is equivalent to setting Show me as to Available in the Calendar UI. (default: opaque)
  --updated: string # Last modification time of the event (as a RFC3339 timestamp). Read-only. (format: date-time)
  --visibility: string # Visibility of the event. Optional. Possible values are: - "default" - Uses the default visibility for events on the calendar. This is the default value. - "public" - The event is public and event details are visible to all readers of the calendar. - "private" - The event is private and only event attendees may view event details. - "confidential" - The event is private. This value is provided for compatibility reasons. (default: default)
  --working-location-properties: record # shape: {customLocation?: record, homeOffice?: any, officeLocation?: record}
]: any -> record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "alwaysIncludeEmail" $always_include_email "scalar") (serialize-qp "conferenceDataVersion" $conference_data_version "scalar") (serialize-qp "maxAttendees" $max_attendees "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar") (serialize-qp "sendUpdates" $send_updates "scalar") (serialize-qp "supportsAttachments" $supports_attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), event_id: (encode-path-segment $event_id)} | format pattern "/calendars/{calendar_id}/events/{event_id}") $qp)
  let req_body = {"anyoneCanAddSelf": $anyone_can_add_self, "attachments": $attachments, "attendees": $attendees, "attendeesOmitted": $attendees_omitted, "colorId": $color_id, "conferenceData": $conference_data, "created": $created, "creator": $creator, "description": $description, "end": $end, "endTimeUnspecified": $end_time_unspecified, "etag": $etag, "eventType": $event_type, "extendedProperties": $extended_properties, "gadget": $gadget, "guestsCanInviteOthers": $guests_can_invite_others, "guestsCanModify": $guests_can_modify, "guestsCanSeeOtherGuests": $guests_can_see_other_guests, "hangoutLink": $hangout_link, "htmlLink": $html_link, "iCalUID": $i_cal_uid, "id": $id, "kind": $kind, "location": $location, "locked": $locked, "organizer": $organizer, "originalStartTime": $original_start_time, "privateCopy": $private_copy, "recurrence": $recurrence, "recurringEventId": $recurring_event_id, "reminders": $reminders, "sequence": $sequence, "source": $body_source, "start": $start, "status": $status, "summary": $summary, "transparency": $transparency, "updated": $updated, "visibility": $visibility, "workingLocationProperties": $working_location_properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "alwaysIncludeEmail": $always_include_email, "conferenceDataVersion": $conference_data_version, "maxAttendees": $max_attendees, "sendNotifications": $send_notifications, "sendUpdates": $send_updates, "supportsAttachments": $supports_attachments} | compact), body: $req_body}
}

# Returns instances of the specified recurring event.
#
# GET /calendars/{calendarId}/events/{eventId}/instances
# operationId: calendar.events.instances
export def "calendars-events-instances get" [
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --always-include-email: oneof<nothing, bool> # Deprecated and ignored. A value will always be returned in the email field for the organizer, creator and attendees, even if no real email address is available (i.e. a generated, non-working value will be provided).
  --max-attendees: int # The maximum number of attendees to include in the response. If there are more than the specified number of attendees, only the participant is returned. Optional.
  --max-results: int # Maximum number of events returned on one result page. By default the value is 250 events. The page size can never be larger than 2500 events. Optional.
  --original-start: string # The original start time of the instance in the result. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted events (with status equals "cancelled") in the result. Cancelled instances of recurring events will still be included if singleEvents is False. Optional. The default is False.
  --time-max: string # Upper bound (exclusive) for an event's start time to filter by. Optional. The default is not to filter by start time. Must be an RFC3339 timestamp with mandatory time zone offset.
  --time-min: string # Lower bound (inclusive) for an event's end time to filter by. Optional. The default is not to filter by end time. Must be an RFC3339 timestamp with mandatory time zone offset.
  --time-zone: string # Time zone used in the response. Optional. The default is the time zone of the calendar.
]: nothing -> record<accessRole: string, defaultReminders: table<method: string, minutes: int>, description: string, etag: string, items: table<anyoneCanAddSelf: bool, attachments: list, attendees: list, attendeesOmitted: bool, colorId: string, conferenceData: record, created: string, creator: record, description: string, end: record, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record, gadget: record, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record, originalStartTime: record, privateCopy: bool, recurrence: list, recurringEventId: string, reminders: record, sequence: int, source: record, start: record, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record>, kind: string, nextPageToken: string, nextSyncToken: string, summary: string, timeZone: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "alwaysIncludeEmail" $always_include_email "scalar") (serialize-qp "maxAttendees" $max_attendees "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "originalStart" $original_start "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "timeMax" $time_max "scalar") (serialize-qp "timeMin" $time_min "scalar") (serialize-qp "timeZone" $time_zone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), event_id: (encode-path-segment $event_id)} | format pattern "/calendars/{calendar_id}/events/{event_id}/instances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "alwaysIncludeEmail": $always_include_email, "maxAttendees": $max_attendees, "maxResults": $max_results, "originalStart": $original_start, "pageToken": $page_token, "showDeleted": $show_deleted, "timeMax": $time_max, "timeMin": $time_min, "timeZone": $time_zone} | compact), body: null}
}

# Moves an event to another calendar, i.e. changes an event's organizer.
#
# POST /calendars/{calendarId}/events/{eventId}/move
# operationId: calendar.events.move
export def "calendars-events-move move" [
  calendar_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --destination: string # Calendar identifier of the target calendar where the event is to be moved to.
  --send-notifications: oneof<nothing, bool> # Deprecated. Please use sendUpdates instead. Whether to send notifications about the change of the event's organizer. Note that some emails might still be sent even if you set the value to false. The default is false.
  --send-updates: string@send-updates-completer # Guests who should receive notifications about the change of the event's organizer.
]: nothing -> record<anyoneCanAddSelf: bool, attachments: table<fileId: string, fileUrl: string, iconLink: string, mimeType: string, title: string>, attendees: table<additionalGuests: int, comment: string, displayName: string, email: string, id: string, optional: bool, organizer: bool, resource: bool, responseStatus: string, self: bool>, attendeesOmitted: bool, colorId: string, conferenceData: record<conferenceId: string, conferenceSolution: record<iconUri: string, key: record, name: string>, createRequest: record<conferenceSolutionKey: record, requestId: string, status: record>, entryPoints: list<record>, notes: string, parameters: record<addOnParameters: record>, signature: string>, created: string, creator: record<displayName: string, email: string, id: string, self: bool>, description: string, end: record<date: string, dateTime: string, timeZone: string>, endTimeUnspecified: bool, etag: string, eventType: string, extendedProperties: record<private: record, shared: record>, gadget: record<display: string, height: int, iconLink: string, link: string, preferences: record, title: string, type: string, width: int>, guestsCanInviteOthers: bool, guestsCanModify: bool, guestsCanSeeOtherGuests: bool, hangoutLink: string, htmlLink: string, iCalUID: string, id: string, kind: string, location: string, locked: bool, organizer: record<displayName: string, email: string, id: string, self: bool>, originalStartTime: record<date: string, dateTime: string, timeZone: string>, privateCopy: bool, recurrence: list<string>, recurringEventId: string, reminders: record<overrides: list<record>, useDefault: bool>, sequence: int, source: record<title: string, url: string>, start: record<date: string, dateTime: string, timeZone: string>, status: string, summary: string, transparency: string, updated: string, visibility: string, workingLocationProperties: record<customLocation: record<label: string>, homeOffice: any, officeLocation: record<buildingId: string, deskId: string, floorId: string, floorSectionId: string, label: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "sendNotifications" $send_notifications "scalar") (serialize-qp "sendUpdates" $send_updates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id), event_id: (encode-path-segment $event_id)} | format pattern "/calendars/{calendar_id}/events/{event_id}/move") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "destination": $destination, "sendNotifications": $send_notifications, "sendUpdates": $send_updates} | compact), body: null}
}

# Stop watching resources through this channel
#
# POST /channels/stop
# operationId: calendar.channels.stop
export def "channels-stop stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels/stop" $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Returns the color definitions for calendars and events.
#
# GET /colors
# operationId: calendar.colors.get
export def "colors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<calendar: record, event: record, kind: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/colors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Returns free/busy information for a set of calendars.
#
# POST /freeBusy
# operationId: calendar.freebusy.query
# --items item shape: {id?: string}
export def "free-busy list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --calendar-expansion-max: int # Maximal number of calendars for which FreeBusy information is to be provided. Optional. Maximum value is 50. (format: int32)
  --group-expansion-max: int # Maximal number of calendar identifiers to be provided for a single group. Optional. An error is returned for a group with more members than this value. Maximum value is 100. (format: int32)
  --items: list # List of calendars and/or groups to query. — item shape: {id?: string}
  --time-max: string # The end of the interval for the query formatted as per RFC3339. (format: date-time)
  --time-min: string # The start of the interval for the query formatted as per RFC3339. (format: date-time)
  --time-zone: string # Time zone used in the response. Optional. The default is UTC. (default: UTC)
]: any -> record<calendars: record, groups: record, kind: string, timeMax: string, timeMin: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/freeBusy" $qp)
  let req_body = {"calendarExpansionMax": $calendar_expansion_max, "groupExpansionMax": $group_expansion_max, "items": $items, "timeMax": $time_max, "timeMin": $time_min, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: $req_body}
}

# Returns the calendars on the user's calendar list.
#
# GET /users/me/calendarList
# operationId: calendar.calendarList.list
export def "users-me-calendar-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --min-access-role: string@min-access-role-completer # The minimum access role for the user in the returned entries. Optional. The default is no restriction.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted calendar list entries in the result. Optional. The default is False.
  --show-hidden: oneof<nothing, bool> # Whether to show hidden entries. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If only read-only fields such as calendar properties or ACLs have changed, the entry won't be returned. All entries deleted and hidden since the previous list request will always be in the result set and it is not allowed to set showDeleted neither showHidden to False. To ensure client state consistency minAccessRole query parameter cannot be specified together with nextSyncToken. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
]: nothing -> record<etag: string, items: table<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record, defaultReminders: list, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string>, kind: string, nextPageToken: string, nextSyncToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "minAccessRole" $min_access_role "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "showHidden" $show_hidden "scalar") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/calendarList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "minAccessRole": $min_access_role, "pageToken": $page_token, "showDeleted": $show_deleted, "showHidden": $show_hidden, "syncToken": $sync_token} | compact), body: null}
}

# Inserts an existing calendar into the user's calendar list.
#
# POST /users/me/calendarList
# operationId: calendar.calendarList.insert
# --conferenceProperties shape: {allowedConferenceSolutionTypes?: list<string>}
# --defaultReminders item shape: {method?: string, minutes?: int}
# --notificationSettings shape: {notifications?: list}
export def "users-me-calendar-list create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --color-rgb-format: oneof<nothing, bool> # Whether to use the foregroundColor and backgroundColor fields to write the calendar colors (RGB). If this feature is used, the index-based colorId field will be set to the best matching option automatically. Optional. The default is False.
  --access-role: string # The effective access role that the authenticated user has on the calendar. Read-only. Possible values are: - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --background-color: string # The main color of the calendar in the hexadecimal format "#0088aa". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --color-id: string # The color of the calendar. This is an ID referring to an entry in the calendar section of the colors definition (see the colors endpoint). This property is superseded by the backgroundColor and foregroundColor properties and can be ignored when using these properties. Optional.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --default-reminders: list # The default reminders that the authenticated user has for this calendar. — item shape: {method?: string, minutes?: int}
  --deleted: oneof<nothing, bool> # Whether this calendar list entry has been deleted from the calendar list. Read-only. Optional. The default is False. (default: false)
  --description: string # Description of the calendar. Optional. Read-only.
  --etag: string # ETag of the resource.
  --foreground-color: string # The foreground color of the calendar in the hexadecimal format "#ffffff". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --hidden: oneof<nothing, bool> # Whether the calendar has been hidden from the list. Optional. The attribute is only returned when the calendar is hidden, in which case the value is true. (default: false)
  --id: string # Identifier of the calendar.
  --kind: string # Type of the resource ("calendar#calendarListEntry"). (default: calendar#calendarListEntry)
  --location: string # Geographic location of the calendar as free-form text. Optional. Read-only.
  --notification-settings: record # The notifications that the authenticated user is receiving for this calendar. — shape: {notifications?: list}
  --primary: oneof<nothing, bool> # Whether the calendar is the primary calendar of the authenticated user. Read-only. Optional. The default is False. (default: false)
  --selected: oneof<nothing, bool> # Whether the calendar content shows up in the calendar UI. Optional. The default is False. (default: false)
  --summary: string # Title of the calendar. Read-only.
  --summary-override: string # The summary that the authenticated user has set for this calendar. Optional.
  --time-zone: string # The time zone of the calendar. Optional. Read-only.
]: any -> record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "colorRgbFormat" $color_rgb_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/calendarList" $qp)
  let req_body = {"accessRole": $access_role, "backgroundColor": $background_color, "colorId": $color_id, "conferenceProperties": $conference_properties, "defaultReminders": $default_reminders, "deleted": $deleted, "description": $description, "etag": $etag, "foregroundColor": $foreground_color, "hidden": $hidden, "id": $id, "kind": $kind, "location": $location, "notificationSettings": $notification_settings, "primary": $primary, "selected": $selected, "summary": $summary, "summaryOverride": $summary_override, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "colorRgbFormat": $color_rgb_format} | compact), body: $req_body}
}

# Watch for changes to CalendarList resources.
#
# POST /users/me/calendarList/watch
# operationId: calendar.calendarList.watch
export def "users-me-calendar-list-watch watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --min-access-role: string@min-access-role-completer # The minimum access role for the user in the returned entries. Optional. The default is no restriction.
  --page-token: string # Token specifying which result page to return. Optional.
  --show-deleted: oneof<nothing, bool> # Whether to include deleted calendar list entries in the result. Optional. The default is False.
  --show-hidden: oneof<nothing, bool> # Whether to show hidden entries. Optional. The default is False.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If only read-only fields such as calendar properties or ACLs have changed, the entry won't be returned. All entries deleted and hidden since the previous list request will always be in the result set and it is not allowed to set showDeleted neither showHidden to False. To ensure client state consistency minAccessRole query parameter cannot be specified together with nextSyncToken. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "minAccessRole" $min_access_role "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "showHidden" $show_hidden "scalar") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/calendarList/watch" $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "minAccessRole": $min_access_role, "pageToken": $page_token, "showDeleted": $show_deleted, "showHidden": $show_hidden, "syncToken": $sync_token} | compact), body: $req_body}
}

# Removes a calendar from the user's calendar list.
#
# DELETE /users/me/calendarList/{calendarId}
# operationId: calendar.calendarList.delete
export def "users-me-calendar-list delete" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/users/me/calendarList/{calendar_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Returns a calendar from the user's calendar list.
#
# GET /users/me/calendarList/{calendarId}
# operationId: calendar.calendarList.get
export def "users-me-calendar-list get" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/users/me/calendarList/{calendar_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}

# Updates an existing calendar on the user's calendar list. This method supports patch semantics.
#
# PATCH /users/me/calendarList/{calendarId}
# operationId: calendar.calendarList.patch
# --conferenceProperties shape: {allowedConferenceSolutionTypes?: list<string>}
# --defaultReminders item shape: {method?: string, minutes?: int}
# --notificationSettings shape: {notifications?: list}
export def "users-me-calendar-list update-by-calendar-id" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --color-rgb-format: oneof<nothing, bool> # Whether to use the foregroundColor and backgroundColor fields to write the calendar colors (RGB). If this feature is used, the index-based colorId field will be set to the best matching option automatically. Optional. The default is False.
  --access-role: string # The effective access role that the authenticated user has on the calendar. Read-only. Possible values are: - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --background-color: string # The main color of the calendar in the hexadecimal format "#0088aa". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --color-id: string # The color of the calendar. This is an ID referring to an entry in the calendar section of the colors definition (see the colors endpoint). This property is superseded by the backgroundColor and foregroundColor properties and can be ignored when using these properties. Optional.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --default-reminders: list # The default reminders that the authenticated user has for this calendar. — item shape: {method?: string, minutes?: int}
  --deleted: oneof<nothing, bool> # Whether this calendar list entry has been deleted from the calendar list. Read-only. Optional. The default is False. (default: false)
  --description: string # Description of the calendar. Optional. Read-only.
  --etag: string # ETag of the resource.
  --foreground-color: string # The foreground color of the calendar in the hexadecimal format "#ffffff". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --hidden: oneof<nothing, bool> # Whether the calendar has been hidden from the list. Optional. The attribute is only returned when the calendar is hidden, in which case the value is true. (default: false)
  --id: string # Identifier of the calendar.
  --kind: string # Type of the resource ("calendar#calendarListEntry"). (default: calendar#calendarListEntry)
  --location: string # Geographic location of the calendar as free-form text. Optional. Read-only.
  --notification-settings: record # The notifications that the authenticated user is receiving for this calendar. — shape: {notifications?: list}
  --primary: oneof<nothing, bool> # Whether the calendar is the primary calendar of the authenticated user. Read-only. Optional. The default is False. (default: false)
  --selected: oneof<nothing, bool> # Whether the calendar content shows up in the calendar UI. Optional. The default is False. (default: false)
  --summary: string # Title of the calendar. Read-only.
  --summary-override: string # The summary that the authenticated user has set for this calendar. Optional.
  --time-zone: string # The time zone of the calendar. Optional. Read-only.
]: any -> record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "colorRgbFormat" $color_rgb_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/users/me/calendarList/{calendar_id}") $qp)
  let req_body = {"accessRole": $access_role, "backgroundColor": $background_color, "colorId": $color_id, "conferenceProperties": $conference_properties, "defaultReminders": $default_reminders, "deleted": $deleted, "description": $description, "etag": $etag, "foregroundColor": $foreground_color, "hidden": $hidden, "id": $id, "kind": $kind, "location": $location, "notificationSettings": $notification_settings, "primary": $primary, "selected": $selected, "summary": $summary, "summaryOverride": $summary_override, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "colorRgbFormat": $color_rgb_format} | compact), body: $req_body}
}

# Updates an existing calendar on the user's calendar list.
#
# PUT /users/me/calendarList/{calendarId}
# operationId: calendar.calendarList.update
# --conferenceProperties shape: {allowedConferenceSolutionTypes?: list<string>}
# --defaultReminders item shape: {method?: string, minutes?: int}
# --notificationSettings shape: {notifications?: list}
export def "users-me-calendar-list update-by-calendar-id-1" [
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --color-rgb-format: oneof<nothing, bool> # Whether to use the foregroundColor and backgroundColor fields to write the calendar colors (RGB). If this feature is used, the index-based colorId field will be set to the best matching option automatically. Optional. The default is False.
  --access-role: string # The effective access role that the authenticated user has on the calendar. Read-only. Possible values are: - "freeBusyReader" - Provides read access to free/busy information. - "reader" - Provides read access to the calendar. Private events will appear to users with reader access, but event details will be hidden. - "writer" - Provides read and write access to the calendar. Private events will appear to users with writer access, and event details will be visible. - "owner" - Provides ownership of the calendar. This role has all of the permissions of the writer role with the additional ability to see and manipulate ACLs.
  --background-color: string # The main color of the calendar in the hexadecimal format "#0088aa". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --color-id: string # The color of the calendar. This is an ID referring to an entry in the calendar section of the colors definition (see the colors endpoint). This property is superseded by the backgroundColor and foregroundColor properties and can be ignored when using these properties. Optional.
  --conference-properties: record # shape: {allowedConferenceSolutionTypes?: list<string>}
  --default-reminders: list # The default reminders that the authenticated user has for this calendar. — item shape: {method?: string, minutes?: int}
  --deleted: oneof<nothing, bool> # Whether this calendar list entry has been deleted from the calendar list. Read-only. Optional. The default is False. (default: false)
  --description: string # Description of the calendar. Optional. Read-only.
  --etag: string # ETag of the resource.
  --foreground-color: string # The foreground color of the calendar in the hexadecimal format "#ffffff". This property supersedes the index-based colorId property. To set or change this property, you need to specify colorRgbFormat=true in the parameters of the insert, update and patch methods. Optional.
  --hidden: oneof<nothing, bool> # Whether the calendar has been hidden from the list. Optional. The attribute is only returned when the calendar is hidden, in which case the value is true. (default: false)
  --id: string # Identifier of the calendar.
  --kind: string # Type of the resource ("calendar#calendarListEntry"). (default: calendar#calendarListEntry)
  --location: string # Geographic location of the calendar as free-form text. Optional. Read-only.
  --notification-settings: record # The notifications that the authenticated user is receiving for this calendar. — shape: {notifications?: list}
  --primary: oneof<nothing, bool> # Whether the calendar is the primary calendar of the authenticated user. Read-only. Optional. The default is False. (default: false)
  --selected: oneof<nothing, bool> # Whether the calendar content shows up in the calendar UI. Optional. The default is False. (default: false)
  --summary: string # Title of the calendar. Read-only.
  --summary-override: string # The summary that the authenticated user has set for this calendar. Optional.
  --time-zone: string # The time zone of the calendar. Optional. Read-only.
]: any -> record<accessRole: string, backgroundColor: string, colorId: string, conferenceProperties: record<allowedConferenceSolutionTypes: list<string>>, defaultReminders: table<method: string, minutes: int>, deleted: bool, description: string, etag: string, foregroundColor: string, hidden: bool, id: string, kind: string, location: string, notificationSettings: record<notifications: list<record>>, primary: bool, selected: bool, summary: string, summaryOverride: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarId' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "colorRgbFormat" $color_rgb_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({calendar_id: (encode-path-segment $calendar_id)} | format pattern "/users/me/calendarList/{calendar_id}") $qp)
  let req_body = {"accessRole": $access_role, "backgroundColor": $background_color, "colorId": $color_id, "conferenceProperties": $conference_properties, "defaultReminders": $default_reminders, "deleted": $deleted, "description": $description, "etag": $etag, "foregroundColor": $foreground_color, "hidden": $hidden, "id": $id, "kind": $kind, "location": $location, "notificationSettings": $notification_settings, "primary": $primary, "selected": $selected, "summary": $summary, "summaryOverride": $summary_override, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "colorRgbFormat": $color_rgb_format} | compact), body: $req_body}
}

# Returns all user settings for the authenticated user.
#
# GET /users/me/settings
# operationId: calendar.settings.list
export def "users-me-settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
]: nothing -> record<etag: string, items: table<etag: string, id: string, kind: string, value: string>, kind: string, nextPageToken: string, nextSyncToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token, "syncToken": $sync_token} | compact), body: null}
}

# Watch for changes to Settings resources.
#
# POST /users/me/settings/watch
# operationId: calendar.settings.watch
export def "users-me-settings-watch watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # Maximum number of entries returned on one result page. By default the value is 100 entries. The page size can never be larger than 250 entries. Optional.
  --page-token: string # Token specifying which result page to return. Optional.
  --sync-token: string # Token obtained from the nextSyncToken field returned on the last page of results from the previous list request. It makes the result of this list request contain only entries that have changed since then. If the syncToken expires, the server will respond with a 410 GONE response code and the client should clear its storage and perform a full synchronization without any syncToken. Learn more about incremental synchronization. Optional. The default is to return all entries.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is "api#channel". (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel. Valid values are "web_hook" (or "webhook"). Both values refer to a channel where Http requests are used to deliver messages.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "syncToken" $sync_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/me/settings/watch" $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip, "maxResults": $max_results, "pageToken": $page_token, "syncToken": $sync_token} | compact), body: $req_body}
}

# Returns a single user setting.
#
# GET /users/me/settings/{setting}
# operationId: calendar.settings.get
export def "users-me-settings get" [
  setting: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<etag: string, id: string, kind: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($setting | is-empty) { error make --unspanned { msg: "path parameter 'setting' must be non-empty" } }
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({setting: (encode-path-segment $setting)} | format pattern "/users/me/settings/{setting}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alt": $alt, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "userIp": $user_ip} | compact), body: null}
}
