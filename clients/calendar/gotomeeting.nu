# Auto-generated client for GoToMeeting v1.0.0
# Source: https://api.apis.guru/v2/specs/citrixonline.com/gotomeeting/1.0.0/swagger.json
# Auth: --token flag or $env.GOTOMEETING_TOKEN

const BASE_URL = "https://api.citrixonline.com/G2M/rest"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOTOMEETING_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.citrixonline.com/G2M/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def productType-completer [] { ["G2M" "G2T" "G2W" "OPENVOICE"] }
def history-completer [] { ["true"] }
def meetingtype-completer [] { ["immediate" "recurring" "scheduled"] }
def status-completer [] { ["suspended"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  --Authorization: string # Access token
]: nothing -> table<groupName: string, groupkey: int, numOrganizers: int, parentKey: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get attendees by group
#
# GET /groups/{groupKey}/attendees
export def "groups-attendees get" [
  groupKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # End of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<attendeeEmail: string, attendeeName: string, conferenceCallInfo: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, joinTime: string, lastName: string, leaveTime: string, meetingId: string, meetingInstanceKey: int, meetingType: string, numAttendees: int, organizerKey: string, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupKey)/attendees" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical meetings by group
#
# GET /groups/{groupKey}/historicalMeetings
export def "groups-historical-meetings get" [
  groupKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # Required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<accountKey: string, duration: string, email: string, endTime: string, firstName: string, groupName: string, lastName: string, locale: string, meetingId: string, meetingType: string, numAttendees: string, organizerKey: string, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupKey)/historicalMeetings" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DEPRECATED: Get historical meetings by group
#
# GET /groups/{groupKey}/meetings
# DEPRECATED
@deprecated
export def "groups-meetings get" [
  groupKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --history: string@bool-completer # When 'true', returns all past meetings within date range
  --startDate: string # If history=true, required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # If history=true, required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, duration: string, email: string, endTime: string, firstName: string, groupName: string, lastName: string, meetingId: string, meetingInstanceKey: int, meetingType: string, numAttendees: int, organizerKey: string, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "history" $history "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($groupKey)/meetings" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organizers by group
#
# GET /groups/{groupKey}/organizers
export def "groups-organizers get" [
  groupKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> table<email: string, firstName: string, groupId: int, groupName: string, lastName: string, maxNumAttendeesAllowed: int, organizerKey: int, products: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($groupKey)/organizers")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organizer in group
#
# POST /groups/{groupKey}/organizers
export def "groups-organizers post" [
  groupKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
  firstName: string # The first name of the organizer
  lastName: string # The surname of the organizer
  organizerEmail: string # The email address of the organizer
  productType: string@productType-completer # The products the organizer has access to, can be 'G2M', 'G2W', 'G2T' or 'OPENVOICE'
]: any -> table<email: string, key: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($groupKey)/organizers")
  let body = {firstName: $firstName, lastName: $lastName, organizerEmail: $organizerEmail, productType: $productType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get upcoming meetings by group
#
# GET /groups/{groupKey}/upcomingMeetings
export def "groups-upcoming-meetings get" [
  groupKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> table<accountKey: string, email: string, endTime: string, firstName: string, groupName: string, lastName: string, locale: string, meetingId: string, meetingType: string, organizerKey: string, passwordRequired: bool, startTime: string, status: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($groupKey)/upcomingMeetings")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --startDate: string # Required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # Required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, duration: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, numAttendees: string, organizerKey: string, sessionId: string, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historicalMeetings" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --history: string@bool-completer # When 'true', returns all past meetings within date range
  --startDate: string # If history=true, required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # If history=true, required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, date: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, lastName: string, meetingId: int, meetingInstanceKey: int, meetingKey: int, meetingType: string, newMeetingId: string, newOrganizerKey: string, numAttendees: int, organizerKey: string, organizerkey: string, passwordRequired: bool, sessionId: int, startTime: string, status: string, subject: string, uniqueMeetingId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "history" $history "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/meetings" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create meeting
#
# POST /meetings
export def "meetings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
  conferencecallinfo: string # A required string. Can be one of the following options: <br>PSTN (PSTN only), <br>Free (PSTN and VoIP), <br>Hybrid, (PSTN and VoIP), <br>Private (you provide numbers and access code), or <br>VoIP (VoIP only). <br>You may also enter plain text for numbers and access codes with a limit of 255 characters
  endtime: string # The ending time of the meeting. Required ISO8601 UTC string, e.g. 2015-07-01T23:00:00Z (format: date-time)
  meetingtype: string@meetingtype-completer # The meeting type
  --passwordrequired: string@bool-completer # Indicates whether a password is required to join the meeting. Required parameter
  starttime: string # The starting time of the meeting. Required ISO8601 UTC string, e.g. 2015-07-01T22:00:00Z (format: date-time)
  subject: string # The subject of the meeting. 100 characters maximum. The characters '&gt;' and '&lt;' have to be replaced with the corresponding html character code (&amp;gt; for &#39;&gt;&#39; and &amp;lt; for &#39;&lt;&#39;)
  timezonekey: string # DEPRECATED. Must be provided and set to empty string ''
]: any -> table<conferenceCallInfo: string, joinURL: string, maxParticipants: int, meetingid: int, uniqueMeetingId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meetings")
  let body = {conferencecallinfo: $conferencecallinfo, endtime: $endtime, meetingtype: $meetingtype, passwordrequired: $passwordrequired, starttime: $starttime, subject: $subject, timezonekey: $timezonekey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete meeting
#
# DELETE /meetings/{meetingId}
export def "meetings delete" [
  meetingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/meetings/($meetingId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get meeting
#
# GET /meetings/{meetingId}
export def "meetings get" [
  meetingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, createTime: string, duration: int, endTime: string, maxParticipants: int, meetingId: int, meetingKey: int, meetingType: string, passwordRequired: bool, startTime: string, status: string, subject: string, uniqueMeetingId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/meetings/($meetingId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update meeting
#
# PUT /meetings/{meetingId}
export def "meetings put" [
  meetingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
  conferencecallinfo: string # A required string. Can be one of the following options: <br>PSTN (PSTN only), <br>Free (PSTN and VoIP), <br>Hybrid, (PSTN and VoIP), <br>Private (you provide numbers and access code), or <br>VoIP (VoIP only). <br>You may also enter plain text for numbers and access codes with a limit of 255 characters
  endtime: string # The ending time of the meeting. A required ISO8601 UTC string, e.g. 2015-07-01T22:00:00Z (format: date-time)
  meetingtype: string@meetingtype-completer # The meeting type
  --passwordrequired: string@bool-completer # Indicates whether a password is required to join the meeting. Required parameter
  starttime: string # The starting time of the meeting. A required ISO8601 UTC string, e.g. 2015-07-01T22:00:00Z (format: date-time)
  subject: string # A description of the meeting. 100 characters maximum. The characters '&gt;' and '&lt;' have to be replaced with the corresponding html character code (&amp;gt; for &#39;&gt;&#39; and &amp;lt; for &#39;&lt;&#39;)
  timezonekey: string # DEPRECATED. Must be provided and set to empty string ''
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/meetings/($meetingId)")
  let body = {conferencecallinfo: $conferencecallinfo, endtime: $endtime, meetingtype: $meetingtype, passwordrequired: $passwordrequired, starttime: $starttime, subject: $subject, timezonekey: $timezonekey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attendees by meeting
#
# GET /meetings/{meetingId}/attendees
export def "meetings-attendees get" [
  meetingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> table<attendeeEmail: string, attendeeName: string, conferenceCallInfo: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, joinTime: string, lastName: string, leaveTime: string, meetingId: int, meetingInstanceKey: int, meetingType: string, name: string, numAttendees: int, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/meetings/($meetingId)/attendees")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start meeting
#
# GET /meetings/{meetingId}/start
export def "meetings-start get" [
  meetingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> record<hostURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/meetings/($meetingId)/start")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --email: string # The email address of the organizer
  --Authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizers" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --email: string # The email address of the organizer
  --Authorization: string # Access token
]: nothing -> table<email: string, firstName: string, groupId: int, groupName: string, lastName: string, maxNumAttendeesAllowed: int, organizerKey: int, products: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizers" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create organizer
#
# POST /organizers
export def "organizers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
  firstName: string # The first name of the organizer
  lastName: string # The surname of the organizer
  organizerEmail: string # The email address of the organizer
  productType: string@productType-completer # The products the organizer has access to, can be 'G2M', 'G2W', 'G2T' or 'OPENVOICE'
]: any -> table<email: string, key: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizers")
  let body = {firstName: $firstName, lastName: $lastName, organizerEmail: $organizerEmail, productType: $productType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete organizer
#
# DELETE /organizers/{organizerKey}
export def "organizers delete-by-organizerKey" [
  organizerKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizers/($organizerKey)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organizer
#
# GET /organizers/{organizerKey}
export def "organizers get" [
  organizerKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> table<email: string, firstName: string, groupId: int, groupName: string, lastName: string, maxNumAttendeesAllowed: int, organizerKey: int, products: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizers/($organizerKey)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update organizer
#
# PUT /organizers/{organizerKey}
export def "organizers put" [
  organizerKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
  --productType: string@productType-completer # The products the organizer has access to, can be 'G2M', 'G2W', 'G2T' or 'OPENVOICE'
  --status: string@status-completer # The status of the organizer can be set to. Use 'suspended' to remove all products. The formerly used status 'active' is now DEPRECATED for this call. To activate the organizer please assign a product. In this case do not pass this parameter
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizers/($organizerKey)")
  let body = {productType: $productType, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attendees by organizer
#
# GET /organizers/{organizerKey}/attendees
export def "organizers-attendees get" [
  organizerKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # A required start of date range in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # A required end of date range in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<attendeeEmail: string, attendeeName: string, conferenceCallInfo: string, duration: int, email: string, endTime: string, firstName: string, groupName: string, joinTime: string, lastName: string, leaveTime: string, meetingId: int, meetingInstanceKey: int, meetingType: string, name: string, newMeetingId: string, numAttendees: int, organizerkey: int, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizers/($organizerKey)/attendees" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical meetings by organizer
#
# GET /organizers/{organizerKey}/historicalMeetings
export def "organizers-historical-meetings get" [
  organizerKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # Required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # Required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, duration: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, numAttendees: string, organizerKey: string, sessionId: string, startTime: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizers/($organizerKey)/historicalMeetings" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DEPRECATED: Get meetings by organizer
#
# GET /organizers/{organizerKey}/meetings
# DEPRECATED
@deprecated
export def "organizers-meetings get" [
  organizerKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduled: string@bool-completer # When 'true', returns all future meetings. Date range not supported.
  --history: string@bool-completer # When 'true', returns all past meetings within date range
  --startDate: string # If history is 'true', required start of date range, in ISO8601 UTC format, e.g. 2015-07-01T22:00:00Z (format: date-time)
  --endDate: string # If history is 'true', required end of date range, in ISO8601 UTC format, e.g. 2015-07-01T23:00:00Z (format: date-time)
  --Authorization: string # Access token
]: nothing -> table<conferenceCallInfo: string, createTime: string, endTime: string, maxParticipants: int, meetingType: string, meetingid: int, passwordRequired: bool, startTime: string, status: string, subject: string, uniqueMeetingId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scheduled" $scheduled "scalar") (serialize-qp "history" $history "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizers/($organizerKey)/meetings" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get upcoming meetings by organizer
#
# GET /organizers/{organizerKey}/upcomingMeetings
export def "organizers-upcoming-meetings get" [
  organizerKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, organizerKey: string, passwordRequired: bool, startTime: string, status: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizers/($organizerKey)/upcomingMeetings")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --Authorization: string # Access token
]: nothing -> table<accountKey: string, conferenceCallInfo: string, email: string, endTime: string, firstName: string, lastName: string, locale: string, meetingId: string, meetingType: string, organizerKey: string, passwordRequired: bool, startTime: string, status: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/upcomingMeetings")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
