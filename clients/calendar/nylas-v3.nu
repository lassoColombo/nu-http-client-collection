# Auto-generated client for Nylas Email, Calendar, Contacts, and Notetaker APIs vv3
# Source: https://developer.nylas.com/_spec-files/v3-ecc.yaml
# Auth: --token flag or $env.NYLAS_EMAIL_CALENDAR__CONTACTS__AND_NOTETAKER_APIS_TOKEN

const BASE_URL = "https://api.us.nylas.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NYLAS_EMAIL_CALENDAR__CONTACTS__AND_NOTETAKER_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
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
def base-url-completer [] { ["https://api.us.nylas.com" "https://api.eu.nylas.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def event-type-completer [] { ["default" "focusTime" "outOfOffice" "workingLocation"] }
def visibility-completer [] { ["default" "private" "public"] }
def status-completer [] { ["maybe" "no" "yes"] }
def order-by-completer [] { ["created_at" "join_time" "name"] }
def order-direction-completer [] { ["asc" "desc"] }
def state-completer [] { ["attending" "connecting" "failed_entry" "media_available" "media_deleted" "media_error" "media_processing" "scheduled" "waiting_for_entry"] }
def fields-completer [] { ["include_basic_headers" "include_headers" "include_tracking_options" "raw_mime" "standard"] }
def fields-completer-1 [] { ["include_basic_headers" "include_headers" "standard"] }
def source-completer [] { ["address_book" "domain" "inbox"] }
def trigger-event-completer [] { ["booking.cancelled" "booking.created" "booking.pending" "booking.reminder" "booking.rescheduled"] }
def engine-completer [] { ["handlebars" "mustache" "nunjucks" "twig"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "grants-calendars get-all-calendars" } } | get name | first)
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

# Return all calendars
#
# GET /v3/grants/{grant_id}/calendars
# operationId: get-all-calendars
export def "grants-calendars get-all-calendars" [
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --metadata-pair: string # Pass a metadata key/value pair (for example, `?metadata_pair=key1:value`) to search for metadata associated with objects. See [Metadata](/docs/reference/api/#metadata) for more information.
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "metadata_pair" $metadata_pair "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a calendar
#
# POST /v3/grants/{grant_id}/calendars
# operationId: create-calendar
# --notetaker shape: {meeting_settings?: record, name?: string, rules?: record}
export def "grants-calendars create-calendar" [
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --description: string # (Not supported for iCloud or EWS) A brief description of the calendar. (e.g. Junior sports league carpool drivers)
  --location: string # (Not supported for iCloud or EWS) The geographic location of the calendar, as free-form text. (e.g. London, England)
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  name: string # The name of the calendar. (e.g. My New Calendar)
  --notetaker: record # shape: {meeting_settings?: record, name?: string, rules?: record}
  --timezone: string # (Google and virtual calendars only) An [IANA timezone database](https://en.wikipedia.org/wiki/Tz_database) formatted string (for example, `America/New_York`). (e.g. America/Los_Angeles)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/calendars" $qp)
  let body = {description: $description, location: $location, metadata: $metadata, name: $name, notetaker: $notetaker, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a calendar
#
# GET /v3/grants/{grant_id}/calendars/{calendar_id}
# operationId: get-calendars-id
export def "grants-calendars get-calendars-id" [
  grant_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/calendars/($calendar_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a calendar
#
# PUT /v3/grants/{grant_id}/calendars/{calendar_id}
# operationId: put-calendars-id
# --notetaker shape: {meeting_settings?: record, name?: string, rules?: record}
export def "grants-calendars put-calendars-id" [
  grant_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --description: string # (Not supported for iCloud or EWS) A brief description of the calendar. (e.g. Junior sports league carpool drivers)
  --hex-color: string # (Not supported for iCloud or EWS) The background color of the calendar, in hexadecimal format (for example, `#0099EE`). When empty, Nylas uses the default background color.  You can set or modify this value using a `PUT` request only. (e.g. #039BE5)
  --hex-foreground-color: string # (Google only) The foreground color of the calendar, in hexadecimal format (for example, `#0099EE`). When empty, Nylas uses the default foreground color.  You can modify this value using a `PUT` request only. (e.g. #039BE5)
  --location: string # (Not supported for iCloud or EWS) The geographic location of the calendar, as free-form text. (e.g. London, England)
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  --name: string # The name of the calendar.  Microsoft doesn't allow you to update the name of a user's primary calendar. (e.g. My Updated Calendar)
  --timezone: string # (Google and virtual calendars only) An [IANA timezone database](https://en.wikipedia.org/wiki/Tz_database) formatted string (for example, `America/New_York`). (e.g. America/Los_Angeles)
  --notetaker: record # shape: {meeting_settings?: record, name?: string, rules?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/calendars/($calendar_id)" $qp)
  let body = {description: $description, hex_color: $hex_color, hex_foreground_color: $hex_foreground_color, location: $location, metadata: $metadata, name: $name, timezone: $timezone, notetaker: $notetaker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a calendar
#
# DELETE /v3/grants/{grant_id}/calendars/{calendar_id}
# operationId: delete-calendars-id
export def "grants-calendars delete-calendars-id" [
  grant_id: string
  calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/calendars/($calendar_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get availability
#
# POST /v3/calendars/availability
# operationId: post-availability
# --availability_rules shape: {availability_method?: "collective"|"max-fairness"|"max-availability", buffer?: record, default_open_hours?: list, round_robin_group_id?: string, tentative_as_busy?: bool}
# --participants item shape: {calendar_ids?: list, email?: string, grant_id?: string, open_hours?: list, only_specific_time_availability?: bool, specific_time_availability?: list}
export def "calendars-availability post-availability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availability-rules: record # shape: {availability_method?: "collective"|"max-fairness"|"max-availability", buffer?: record, default_open_hours?: list, round_robin_group_id?: string, tentative_as_busy?: bool}
  duration_minutes: int # The duration of each time slot, in minutes. The duration must be a multiple of 5 minutes. (e.g. 30)
  end_time: int # The end of the time slot that Nylas checks availability for, in seconds using the Unix timestamp format. The time must be a multiple of 5 minutes. (e.g. 1659733200)
  --interval-minutes: int # Nylas generates a time slot every `interval_minutes` (for example, every 30 minutes) and returns only slots when all participants are free. The interval must be a multiple of 5 minutes. (e.g. 30)
  participants: list # A list of participants to get availability information for. — item shape: {calendar_ids?: list, email?: string, grant_id?: string, open_hours?: list, only_specific_time_availability?: bool, specific_time_availability?: list}
  --round-to: int # Nylas rounds each time slot to the nearest `round_to` value. For example, if a time slot starts at 9:05a.m. and `round_to` is set to `15`, Nylas rounds it to 9:15a.m. The round to value must be a multiple of 5 minutes. (default: 15, e.g. 15)
  start_time: int # The beginning of the time slot that Nylas checks availability for, in seconds using the Unix timestamp format. The time must be a multiple of 5 minutes. (e.g. 1659366000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/calendars/availability")
  let body = {availability_rules: $availability_rules, duration_minutes: $duration_minutes, end_time: $end_time, interval_minutes: $interval_minutes, participants: $participants, round_to: $round_to, start_time: $start_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get free/busy schedule
#
# POST /v3/grants/{grant_id}/calendars/free-busy
# operationId: post-calendars-free-busy
export def "grants-calendars-free-busy post-calendars-free-busy" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  start_time: int # The start of a time block, in seconds using the Unix timestamp format. Nylas uses `start_time` and `end_time` to assess the specified account's free/busy schedule. (e.g. 1690862400)
  end_time: int # The end of a time block, in seconds using the Unix timestamp format. Nylas uses `start_time` and `end_time` to assess the specified account's free/busy schedule.  For Google and EWS accounts, Nylas can query a timespan of up to 3 months from the `start_time`.  For Microsoft Graph accounts, Nylas can query a timespan of up to 62 days from the `start_time`. (e.g. 1691208000)
  emails: list # A list of email addresses to check the free/busy schedules for.
  --tentative-as-busy: string@bool-completer # When `true`, Nylas treats tentative events as busy. (default: true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/calendars/free-busy")
  let body = {start_time: $start_time, end_time: $end_time, emails: $emails, tentative_as_busy: $tentative_as_busy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all events
#
# GET /v3/grants/{grant_id}/events
# operationId: get-all-events
@deprecated --flag expand-recurring
export def "grants-events get-all-events" [
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attendees: string # (Not supported for virtual calendars) Filter for events that include the specified attendees. This parameter accepts a comma-delimited list of email addresses.
  --busy: string@bool-completer # (Not supported for iCloud) Filter for events with the specified `busy` status.
  --calendar-id: string # Filter for the specified calendar ID.  (Not supported for iCloud) You can use `primary` to query the user's primary calendar.
  --description: string # Filter for events matching the specified description. The filter is case insensitive and will match partial descriptions.
  --end: int # Filter for events that end at or before the specified time, in seconds using the Unix timestamp format. For example, if you filter for events that end at 5:00p.m., and the calendar includes an event that runs from 4:30–5:30p.m., Nylas returns that event.  Defaults to one month from the time you make the request.  The `end` value cannot be earlier than `start`. For iCloud accounts, the difference between `start` and `end` can't be greater than one year.
  --event-type: string@event-type-completer # (Google only) Filter for events with the specified event type. You can pass this query parameter multiple times to select or exclude multiple event types. For example, `event_type=default&event_type=outOfOffice` returns all events that are default or `OOO`, and excludes any events that are `focusTime` or that have a `workingLocation`.  If you don't specify an event type, Nylas uses `default` to filter for regular events that don't have another specific type.
  --expand-recurring: string@bool-completer # **This parameter is deprecated. Use the [Import Events endpoint](/docs/reference/api/events/import-events/) instead**.  When `true`, Nylas returns all recurring events within the specified time range, including individual occurrences of the recurring event. Otherwise, Nylas only returns the parent event and any event overrides (individual occurrences that have been edited) in the time range. (DEPRECATED, default: true)
  --ical-uid: string # (Not supported for iCloud) Filter for events with the specified `ical_uid`. You _cannot_ apply other filters if you use this parameter.
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --location: string # Filter for events with the specified location. The filter is case insensitive and will match partial locations.
  --master-event-id: string # (Not supported for iCloud) Filter for instances of recurring events with the specified `master_event_id`.  `master_event_id` is _not_ respected by metadata filtering.  When using `master_event_id` to fetch recurring events with a Google grant, the order of the results will not be sorted chronologically. Instead, Nylas returns the unchanged occurrences first, followed by the modified occurrences. For example, if you have a recurring event with the following occurrences: - 2025-01-01 - 2025-01-02 - 2025-01-03  But you modify the time of the second occurrence to 2025-01-02, the results will be: - 2025-01-01 - 2025-01-03 - 2025-01-02 (modified)
  --metadata-pair: string # Pass a metadata key/value pair (for example, `?metadata_pair=key1:value`) to search for metadata associated with objects. See [Metadata](/docs/reference/api/#metadata) for more information.
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --show-cancelled: string@bool-completer # (Not supported for iCloud or EWS) If `true`, Nylas includes events whose `status` is `cancelled`.  Different providers have different semantics for cancelled events:  - **Google**: An event is considered cancelled after a user deletes it from their calendar, until it's eventually hard-deleted and is no longer readable. - **Microsoft**: An event is considered cancelled if the user is invited to an event and the organizer deletes it. The cancelled version of the event stays on the participants' calendars until they delete it manually. (default: false)
  --start: int # Filter for events that start at or after the specified time, in seconds using the Unix timestamp format. For example, if you filter for events that start at 9:00a.m., and the calendar includes an event that runs from 8:30–9:30a.m., Nylas returns that event.  Defaults to the time that you make the request.  The `start` value cannot be later than `end`. For iCloud accounts, the difference between `start` and `end` can't be greater than one year.
  --tentative-as-busy: string@bool-completer # (Microsoft and EWS only) When `true`, Nylas treats tentative events as busy. (default: true)
  --title: string # Filter for events that match the specified title. The filter is case insensitive and will match partial titles.
  --updated-after: int # (Google, Microsoft, and EWS only) Filter for events that have been updated after the specified time, in seconds using the Unix timestamp format.  `updated_after` is _not_ respected by metadata filtering.
  --updated-before: int # (Google, Microsoft, and EWS only) Filter for events that have been updated before the specified time, in seconds using the Unix timestamp format.  `updated_before` is _not_ respected by metadata filtering.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attendees" $attendees "scalar") (serialize-qp "busy" $busy "scalar") (serialize-qp "calendar_id" $calendar_id "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "expand_recurring" $expand_recurring "scalar") (serialize-qp "ical_uid" $ical_uid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "master_event_id" $master_event_id "scalar") (serialize-qp "metadata_pair" $metadata_pair "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "show_cancelled" $show_cancelled "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "tentative_as_busy" $tentative_as_busy "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "updated_after" $updated_after "scalar") (serialize-qp "updated_before" $updated_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an event
#
# POST /v3/grants/{grant_id}/events
# operationId: create-event
# --conferencing shape: {provider?: "Google Meet"|"Zoom Meeting"|"Microsoft Teams", autocreate?: record, details?: record}
# --notetaker shape: {meeting_settings?: record, name?: string}
# --participants item shape: {comment?: string, email: string, name?: string, phone_number?: string}
# --resources item shape: {email: string, name?: string}
# --reminders shape: {use_default?: bool, overrides?: list}
# --when shape: {time?: int, timezone?: string, start_time?: int, end_time?: int, start_timezone?: string, end_timezone?: string, date?: string, start_date?: string, end_date?: string}
export def "grants-events create-event" [
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendar-id: string # Filter for the specified calendar ID.  (Not supported for iCloud) You can use `primary` to query the user's primary calendar.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --notify-participants: string@bool-completer # Filter for events matching the specified `notify_participants` setting.  Microsoft and iCloud do _not_ support `notify_participants=false`. (default: true)
  --tentative-as-busy: string@bool-completer # (Microsoft and EWS only) When `true`, Nylas treats tentative events as busy. (default: true)
  --busy: string@bool-completer # When `true`, shows the event's time block as "busy" on shared or public calendars. This might be called "transparency" in some systems. This field may be `null` if not explicitly set. Treat `null` the same as `true` (the default behavior). (nullable, e.g. true)
  --capacity: int # The maximum number of participants that can attend the event. (e.g. 5)
  --conferencing: record # An object that lets you automatically create a conference, or enter conferencing details manually.  You can't use `autocreate` and `details` in the same request. If you do, Nylas returns an error.  Nylas stores conference information in the event description. To remove conference details, set `conferencing` to `{}` and remove the corresponding conference information from the description in the same request. — shape: {provider?: "Google Meet"|"Zoom Meeting"|"Microsoft Teams", autocreate?: record, details?: record}
  --description: string # A brief description of the event (for example, its agenda). Nylas might return the description as an HTML string, depending on how the provider formats it.  For Google accounts, this field accepts a maximum of 8,192 characters. (e.g. Come ready to talk philosophy!)
  --hide-participants: string@bool-completer # When `true`, hides the event's list of participants. (e.g. false)
  --location: string # The location of the event (for example, a physical address or the name of a meeting room). (e.g. Room 130)
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  --notetaker: record # shape: {meeting_settings?: record, name?: string}
  --participants: list # item shape: {comment?: string, email: string, name?: string, phone_number?: string}
  --resources: list # item shape: {email: string, name?: string}
  --recurrence: list # An array of `RRULE` and `EXDATE` strings. Nylas includes this field only if the event is the main (master) event. See [RFC-5545](https://tools.ietf.org/html/rfc5545#section-3.8.5) for more details. You can use [this tool](https://jkbrzt.github.io/rrule/) to learn more about the `RRULE` spec.  Events inherit their timezone from the `when` object. Nylas recommends that you use the `when` object to specify the event's start and end time.  Provider specifics: - On some providers, `EXDATE` might not include exception or cancelled event timestamps. When this happens, Nylas represents those event instances as separate objects in its responses. - Virtual calendars don't support `DTSTART` or `TZID`. - iCloud accounts do _not_ support changing an event from recurring to non-recurring. You can create, update, or delete information on recurring events. - Microsoft Graph adds one day to the `UNTIL` date. (e.g. [RRULE:FREQ=WEEKLY;BYDAY=MO, EXDATE:20210405T000000Z])
  --reminders: record # A list of reminders to send for the event. If left empty or omitted, the event uses the provider defaults. — shape: {use_default?: bool, overrides?: list}
  --title: string # The name of the event. (e.g. Annual Philosophy Club Meeting)
  --visibility: string@visibility-completer # (Not supported for iCloud events) Specifies whether the event is `public` or `private`. If not defined, Nylas uses the account's default provider settings. For Google and Microsoft, event visibility is `public` by default.  For virtual calendar events, you can explicitly set `visibility` to `private` or `public` on create and update requests. If not set, virtual calendar events default to `public` behavior. (nullable)
  when: record # An object that represents the time and duration of an event.  You can format `when` as one of four sub-objects: `time`, `timespan`, `date`, or `datespan`. These sub-objects allow you to capture and represent specific points in time.  `time` and `timespan` objects include optional timezone support. — shape: {time?: int, timezone?: string, start_time?: int, end_time?: int, start_timezone?: string, end_timezone?: string, date?: string, start_date?: string, end_date?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendar_id" $calendar_id "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "notify_participants" $notify_participants "scalar") (serialize-qp "tentative_as_busy" $tentative_as_busy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/events" $qp)
  let body = {busy: $busy, capacity: $capacity, conferencing: $conferencing, description: $description, hide_participants: $hide_participants, location: $location, metadata: $metadata, notetaker: $notetaker, participants: $participants, resources: $resources, recurrence: $recurrence, reminders: $reminders, title: $title, visibility: $visibility, when: $when} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import events
#
# GET /v3/grants/{grant_id}/events/import
# operationId: import-events
export def "grants-events-import import-events" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Specifies the maximum number of events Nylas returns in a single page of results. The actual number of events Nylas returns might be lower than this limit, even if other events match your query parameters. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --calendar-id: string # Filter for the specified calendar ID.  (Not supported for iCloud) You can use `primary` to query the user's primary calendar.
  --start: int # Filter for events that start at or after the specified time, in seconds using the Unix timestamp format. For example, if you filter for events that start at 9:00a.m., and the calendar includes an event that runs from 8:30–9:30a.m., Nylas returns that event.  Defaults to the time that you make the request.  The `start` value cannot be later than `end`. For iCloud accounts, the difference between `start` and `end` can't be greater than one year.
  --end: int # Filter for events that end at or before the specified time, in seconds using the Unix timestamp format. For example, if you filter for events that end at 5:00p.m., and the calendar includes an event that runs from 4:30–5:30p.m., Nylas returns that event.  Defaults to one month from the time you make the request.  The `end` value cannot be earlier than `start`. For iCloud accounts, the difference between `start` and `end` can't be greater than one year.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "calendar_id" $calendar_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/events/import" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return an event
#
# GET /v3/grants/{grant_id}/events/{event_id}
# operationId: get-events-id
export def "grants-events get-events-id" [
  grant_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendar-id: string # The calendar ID of the event.  For Microsoft, we do not validate whether the given calendar ID matches the real calendar ID of the event. This is due to a limitation of the Microsoft Graph API.  (Not supported for iCloud) You can use `primary` to query the user's primary calendar.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --tentative-as-busy: string@bool-completer # (Microsoft and EWS only) When `true`, Nylas treats tentative events as busy. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendar_id" $calendar_id "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "tentative_as_busy" $tentative_as_busy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an event
#
# PUT /v3/grants/{grant_id}/events/{event_id}
# operationId: put-events-id
# --conferencing shape: {provider?: "Google Meet"|"Zoom Meeting"|"Microsoft Teams", autocreate?: record, details?: record}
# --notetaker shape: {meeting_settings?: record, name?: string}
# --participants item shape: {comment?: string, email: string, name?: string, phone_number?: string}
# --resources item shape: {email: string, name?: string}
# --reminders shape: {use_default?: bool, overrides?: list}
# --when shape: {time?: int, timezone?: string, start_time?: int, end_time?: int, start_timezone?: string, end_timezone?: string, date?: string, start_date?: string, end_date?: string}
export def "grants-events put-events-id" [
  grant_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendar-id: string # The calendar ID of the event.  For Microsoft, we do not validate whether the given calendar ID matches the real calendar ID of the event. This is due to a limitation of the Microsoft Graph API.  (Not supported for iCloud) You can use `primary` to query the user's primary calendar.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --notify-participants: string@bool-completer # Filter for events matching the specified `notify_participants` setting.  Microsoft and iCloud do _not_ support `notify_participants=false`. (default: true)
  --tentative-as-busy: string@bool-completer # (Microsoft and EWS only) When `true`, Nylas treats tentative events as busy. (default: true)
  --busy: string@bool-completer # When `true`, shows the event's time block as "busy" on shared or public calendars. This might be called "transparency" in some systems. This field may be `null` if not explicitly set. Treat `null` the same as `true` (the default behavior). (nullable, e.g. true)
  --capacity: int # The maximum number of participants that can attend the event. (e.g. 5)
  --conferencing: record # An object that lets you automatically create a conference, or enter conferencing details manually.  You can't use `autocreate` and `details` in the same request. If you do, Nylas returns an error.  Nylas stores conference information in the event description. To remove conference details, set `conferencing` to `{}` and remove the corresponding conference information from the description in the same request. — shape: {provider?: "Google Meet"|"Zoom Meeting"|"Microsoft Teams", autocreate?: record, details?: record}
  --description: string # A brief description of the event (for example, its agenda). Nylas might return the description as an HTML string, depending on how the provider formats it.  For Google accounts, this field accepts a maximum of 8,192 characters. (e.g. Come ready to talk philosophy!)
  --hide-participants: string@bool-completer # When `true`, hides the event's list of participants. (e.g. false)
  --location: string # The location of the event (for example, a physical address or the name of a meeting room). (e.g. Room 130)
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  --notetaker: record # shape: {meeting_settings?: record, name?: string}
  --participants: list # item shape: {comment?: string, email: string, name?: string, phone_number?: string}
  --resources: list # item shape: {email: string, name?: string}
  --recurrence: list # An array of `RRULE` and `EXDATE` strings. Nylas includes this field only if the event is the main (master) event. See [RFC-5545](https://tools.ietf.org/html/rfc5545#section-3.8.5) for more details. You can use [this tool](https://jkbrzt.github.io/rrule/) to learn more about the `RRULE` spec.  Events inherit their timezone from the `when` object. Nylas recommends that you use the `when` object to specify the event's start and end time.  Provider specifics: - On some providers, `EXDATE` might not include exception or cancelled event timestamps. When this happens, Nylas represents those event instances as separate objects in its responses. - Virtual calendars don't support `DTSTART` or `TZID`. - iCloud accounts do _not_ support changing an event from recurring to non-recurring. You can create, update, or delete information on recurring events. - Microsoft Graph adds one day to the `UNTIL` date. (e.g. [RRULE:FREQ=WEEKLY;BYDAY=MO, EXDATE:20210405T000000Z])
  --reminders: record # A list of reminders to send for the event. If left empty or omitted, the event uses the provider defaults. — shape: {use_default?: bool, overrides?: list}
  --title: string # The name of the event. (e.g. Annual Philosophy Club Meeting)
  --visibility: string@visibility-completer # (Not supported for iCloud events) Specifies whether the event is `public` or `private`. If not defined, Nylas uses the account's default provider settings. For Google and Microsoft, event visibility is `public` by default.  For virtual calendar events, you can explicitly set `visibility` to `private` or `public` on create and update requests. If not set, virtual calendar events default to `public` behavior. (nullable)
  when: record # An object that represents the time and duration of an event.  You can format `when` as one of four sub-objects: `time`, `timespan`, `date`, or `datespan`. These sub-objects allow you to capture and represent specific points in time.  `time` and `timespan` objects include optional timezone support. — shape: {time?: int, timezone?: string, start_time?: int, end_time?: int, start_timezone?: string, end_timezone?: string, date?: string, start_date?: string, end_date?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendar_id" $calendar_id "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "notify_participants" $notify_participants "scalar") (serialize-qp "tentative_as_busy" $tentative_as_busy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/events/($event_id)" $qp)
  let body = {busy: $busy, capacity: $capacity, conferencing: $conferencing, description: $description, hide_participants: $hide_participants, location: $location, metadata: $metadata, notetaker: $notetaker, participants: $participants, resources: $resources, recurrence: $recurrence, reminders: $reminders, title: $title, visibility: $visibility, when: $when} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an event
#
# DELETE /v3/grants/{grant_id}/events/{event_id}
# operationId: delete-events-id
export def "grants-events delete-events-id" [
  grant_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendar-id: string # The calendar ID of the event.  For Microsoft, we do not validate whether the given calendar ID matches the real calendar ID of the event. This is due to a limitation of the Microsoft Graph API.  (Not supported for iCloud) You can use `primary` to query the user's primary calendar.
  --notify-participants: string@bool-completer # Filter for events matching the specified `notify_participants` setting.  Microsoft and iCloud do _not_ support `notify_participants=false`. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendar_id" $calendar_id "scalar") (serialize-qp "notify_participants" $notify_participants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/events/($event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send RSVP
#
# POST /v3/grants/{grant_id}/events/{event_id}/send-rsvp
# operationId: send-rsvp
export def "grants-events-send-rsvp send-rsvp" [
  grant_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendar-id: string # Filter for the specified calendar ID.  (Not supported for iCloud) You can use `primary` to query the user's primary calendar.
  --skip-nylas-email: string@bool-completer # When `true`, Nylas does not send the RSVP email to the event organizer. (default: false)
  --status: string@status-completer # A participant's RSVP status for the event. (e.g. maybe)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendar_id" $calendar_id "scalar") (serialize-qp "skip_nylas_email" $skip_nylas_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/events/($event_id)/send-rsvp" $qp)
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all Notetakers
#
# GET /v3/grants/{grant_id}/notetakers
# operationId: get-all-notetakers
export def "grants-notetakers get-all-notetakers" [
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --join-time-start: float # Filter for Notetaker bots that have join times that start at or after a specific time, in Unix timestamp format.
  --join-time-end: float # Filter for Notetaker bots that have join times that end at or are before a specific time, in Unix timestamp format.
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --order-by: string@order-by-completer # The field to order the Notetaker bots by. (default: created_at)
  --order-direction: string@order-direction-completer # The direction to order the Notetaker bots by. (default: asc)
  --state: string@state-completer # Filter for Notetaker bots with the specified meeting state.
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --prev-page-token: string # An identifier that specifies which page of data to return. You can get this value from the `prev_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "join_time_start" $join_time_start "scalar") (serialize-qp "join_time_end" $join_time_end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "prev_page_token" $prev_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite Notetaker to meeting
#
# POST /v3/grants/{grant_id}/notetakers
# operationId: invite-notetaker
# --meeting_settings shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
export def "grants-notetakers invite-notetaker" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --join-time: int # When the Notetaker bot should join the meeting, in seconds using the Unix timestamp format. If you don't specify a time, Notetaker joins the meeting immediately.  If you provide a time that's in the past, Nylas returns an error. (e.g. 1732657774)
  meeting_link: string # A meeting invitation link that Notetaker uses to join the meeting. (e.g. https://meet.google.com/xyz-abcd-ijk)
  --meeting-settings: record # A collection of settings for the Notetaker bot. — shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
  --name: string # The display name for the Notetaker bot. (default: Nylas Notetaker, e.g. Nylas Notetaker)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers")
  let body = {join_time: $join_time, meeting_link: $meeting_link, meeting_settings: $meeting_settings, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a Notetaker
#
# GET /v3/grants/{grant_id}/notetakers/{notetaker_id}
# operationId: get-notetaker
export def "grants-notetakers get-notetaker" [
  grant_id: string
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers/($notetaker_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update scheduled Notetaker
#
# PATCH /v3/grants/{grant_id}/notetakers/{notetaker_id}
# operationId: update-notetaker
# --meeting_settings shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
export def "grants-notetakers update-notetaker" [
  grant_id: string
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --join-time: int # When Notetaker should join the meeting, in seconds using the Unix timestamp format. If empty, Notetaker joins the meeting immediately.  If you provide a time that's in the past, Nylas returns an error. (e.g. 1732657774)
  --meeting-settings: record # A collection of settings for the Notetaker bot. — shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
  --name: string # The display name for the Notetaker bot. (default: Nylas Notetaker, e.g. Nylas Notetaker)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers/($notetaker_id)")
  let body = {join_time: $join_time, meeting_settings: $meeting_settings, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Notetaker
#
# DELETE /v3/grants/{grant_id}/notetakers/{notetaker_id}
# operationId: delete-notetaker
export def "grants-notetakers delete-notetaker" [
  grant_id: string
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers/($notetaker_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return Notetaker history
#
# GET /v3/grants/{grant_id}/notetakers/{notetaker_id}/history
# operationId: get-notetaker-history
export def "grants-notetakers-history get-notetaker-history" [
  grant_id: string
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers/($notetaker_id)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel scheduled Notetaker
#
# DELETE /v3/grants/{grant_id}/notetakers/{notetaker_id}/cancel
# operationId: cancel-notetaker
export def "grants-notetakers-cancel cancel-notetaker" [
  grant_id: string
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers/($notetaker_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Notetaker from meeting
#
# POST /v3/grants/{grant_id}/notetakers/{notetaker_id}/leave
# operationId: post-notetaker-leave
export def "grants-notetakers-leave post-notetaker-leave" [
  grant_id: string
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers/($notetaker_id)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return Notetaker media links
#
# GET /v3/grants/{grant_id}/notetakers/{notetaker_id}/media
# operationId: get-notetaker-media
export def "grants-notetakers-media get-notetaker-media" [
  grant_id: string
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/notetakers/($notetaker_id)/media")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all standalone Notetakers
#
# GET /v3/notetakers
# operationId: get-all-standalone-notetakers
export def "notetakers get-all-standalone-notetakers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --join-time-end: float # Filter for Notetaker bots that have join times that end at or are before a specific time, in Unix timestamp format.
  --join-time-start: float # Filter for Notetaker bots that have join times that start at or after a specific time, in Unix timestamp format.
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --order-by: string@order-by-completer # The field to order the Notetaker bots by. (default: created_at)
  --order-direction: string@order-direction-completer # The direction to order the Notetaker bots by. (default: asc)
  --state: string@state-completer # Filter for Notetaker bots with the specified meeting state.
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --prev-page-token: string # An identifier that specifies which page of data to return. You can get this value from the `prev_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "join_time_end" $join_time_end "scalar") (serialize-qp "join_time_start" $join_time_start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "prev_page_token" $prev_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/notetakers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invite standalone Notetaker to meeting
#
# POST /v3/notetakers
# operationId: invite-standalone-notetaker
# --meeting_settings shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
export def "notetakers invite-standalone-notetaker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --join-time: int # When the Notetaker bot should join the meeting, in seconds using the Unix timestamp format. If you don't specify a time, Notetaker joins the meeting immediately.  If you provide a time that's in the past, Nylas returns an error. (e.g. 1732657774)
  meeting_link: string # A meeting invitation link that Notetaker uses to join the meeting. (e.g. https://meet.google.com/xyz-abcd-ijk)
  --meeting-settings: record # A collection of settings for the Notetaker bot. — shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
  --name: string # The display name for the Notetaker bot. (default: Nylas Notetaker, e.g. Nylas Notetaker)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/notetakers")
  let body = {join_time: $join_time, meeting_link: $meeting_link, meeting_settings: $meeting_settings, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a standalone Notetaker
#
# GET /v3/notetakers/{notetaker_id}
# operationId: get-standalone-notetaker
export def "notetakers get-standalone-notetaker" [
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/notetakers/($notetaker_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update standalone Notetaker
#
# PATCH /v3/notetakers/{notetaker_id}
# operationId: update-standalone-notetaker
# --meeting_settings shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
export def "notetakers update-standalone-notetaker" [
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --join-time: int # When Notetaker should join the meeting, in seconds using the Unix timestamp format. If empty, Notetaker joins the meeting immediately.  If you provide a time that's in the past, Nylas returns an error. (e.g. 1732657774)
  --meeting-settings: record # A collection of settings for the Notetaker bot. — shape: {action_items?: bool, action_items_settings?: record, audio_recording?: bool, leave_after_silence_seconds?: int, summary?: bool, summary_settings?: record, transcription?: bool, transcription_settings?: record, video_recording?: bool}
  --name: string # The display name for the Notetaker bot. (default: Nylas Notetaker, e.g. Nylas Notetaker)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/notetakers/($notetaker_id)")
  let body = {join_time: $join_time, meeting_settings: $meeting_settings, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a standalone Notetaker
#
# DELETE /v3/notetakers/{notetaker_id}
# operationId: delete-standalone-notetaker
export def "notetakers delete-standalone-notetaker" [
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/notetakers/($notetaker_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return standalone Notetaker history
#
# GET /v3/notetakers/{notetaker_id}/history
# operationId: get-standalone-notetaker-history
export def "notetakers-history get-standalone-notetaker-history" [
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/notetakers/($notetaker_id)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel standalone Notetaker
#
# DELETE /v3/notetakers/{notetaker_id}/cancel
# operationId: cancel-standalone-notetaker
export def "notetakers-cancel cancel-standalone-notetaker" [
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/notetakers/($notetaker_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove standalone Notetaker from meeting
#
# POST /v3/notetakers/{notetaker_id}/leave
# operationId: post-standalone-notetaker-leave
export def "notetakers-leave post-standalone-notetaker-leave" [
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/notetakers/($notetaker_id)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return standalone Notetaker media links
#
# GET /v3/notetakers/{notetaker_id}/media
# operationId: get-standalone-notetaker-media
export def "notetakers-media get-standalone-notetaker-media" [
  notetaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/notetakers/($notetaker_id)/media")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return room resource information
#
# GET /v3/grants/{grant_id}/resources
# operationId: list-room-resources
export def "grants-resources list-room-resources" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all Messages
#
# GET /v3/grants/{grant_id}/messages
# operationId: get-messages
export def "grants-messages get-messages" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --any-email: string # Return messages that were sent to or received from this comma-separated list of email addresses (for example, `leyah@example.com,nyla@example.com`). Nylas returns messages that contain one of the specified email addresses in the To, From, CC, or BCC fields. You can specify up to 25 email addresses per request.
  --bcc: string # Return messages that include the specified email address in the BCC list. Because most SMTP gateways remove BCC information, Nylas usually returns messages sent from the current grant.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --cc: string # Return messages that include the specified email address in the CC list.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --qp-fields: string@fields-completer # Return the specified data for each message.  - `standard`: Returns the standard message payload. - `include_headers`: Returns messages and their full set of headers. - `include_basic_headers`: Returns messages with only the three RFC threading headers   (`Message-ID`, `In-Reply-To`, `References`) in the `headers` array. Use this option when you   only need to track message identity and thread relationships — payload size is significantly   smaller than `include_headers`. - `include_tracking_options`: Returns messages and their [tracking settings](/docs/v3/email/message-tracking/). - `raw_mime`: Returns the `grant_id`, `object`, `id`, and `raw_mime` fields for each message. (default: standard)
  --qp-from: string # Return messages sent from the specified email address. If you want to filter for messages sent from the current grant, use the `in` query parameter and specify the Sent folder instead.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --has-attachment: string@bool-completer # When `true`, Nylas returns messages that include attachments.
  --in-param: string # Return messages in the specified folder or label, by folder ID. Required when using `shared_from` or `query_imap`.
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --metadata-pair: string # Pass a metadata key/value pair (for example, `?metadata_pair=key1:value`) to search for metadata associated with objects. See [Metadata](/docs/reference/api/#metadata) for more information.
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --query-imap: string@bool-completer # (IMAP, Yahoo, and iCloud only) When `true`, Nylas queries the IMAP server directly instead of the Nylas database. You also need to set the `in` query parameter in your request so Nylas knows which folder to query. (default: false)
  --received-after: int # Return messages received after the specified time, in seconds using the Unix timestamp format.
  --received-before: int # Return messages received before the specified time, in seconds using the Unix timestamp format.
  --search-query-native: string # Specify a URL-encoded provider-specific query string. Each provider supports a limited set of query parameters that you can use in your request alongside `search_query_native`:  - **Google**: `in`, `limit`, and `page_token` - **Microsoft**: `in`, `limit`, and `page_token` - **IMAP/Yahoo/iCloud**: Any parameter - **EWS**: Any parameter _except_ `thread_id`  Required when using `shared_from`.  For more information, see [Searching with Nylas](/docs/dev-guide/best-practices/search/#search-messages-and-threads-using-search_query_native).
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --starred: string@bool-completer # When `true`, Nylas returns starred messages.  EWS only supports starred messages on Microsoft Exchange 2010 or later.
  --subject: string # Return messages with a matching subject. This filter is case-sensitive and returns partial matches.
  --thread-id: string # Return messages in the specified thread.
  --qp-to: string # Return messages sent to the specified email address.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --unread: string@bool-completer # When `true`, Nylas returns unread messages.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "any_email" $any_email "scalar") (serialize-qp "bcc" $bcc "scalar") (serialize-qp "cc" $cc "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "has_attachment" $has_attachment "scalar") (serialize-qp "in" $in_param "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "metadata_pair" $metadata_pair "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "query_imap" $query_imap "scalar") (serialize-qp "received_after" $received_after "scalar") (serialize-qp "received_before" $received_before "scalar") (serialize-qp "search_query_native" $search_query_native "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "shared_from" $shared_from "scalar") (serialize-qp "starred" $starred "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "thread_id" $thread_id "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "unread" $unread "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a Message
#
# GET /v3/grants/{grant_id}/messages/{message_id}
# operationId: get-messages-id
export def "grants-messages get-messages-id" [
  message_id: string
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string@fields-completer # Return the specified data for each message.   - `standard`: Returns the standard message payload.  - `include_headers`: Returns the message and its full set of headers.  - `include_basic_headers`: Returns the message with only the three RFC threading headers    (`Message-ID`, `In-Reply-To`, `References`) in the `headers` array. Use this option when you    only need to track message identity and thread relationships — payload size is significantly    smaller than `include_headers`.  - `include_tracking_options`: Returns the message and its [tracking settings](/docs/v3/email/message-tracking/).  - `raw_mime`: Returns the `grant_id`, `object`, `id`, and `raw_mime` fields for the message. (default: standard)
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --query-imap: string@bool-completer # (IMAP, iCloud, and Yahoo only) When `true`, Nylas queries from the IMAP server directly instead of the Nylas database. (default: false)
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query_imap" $query_imap "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/($message_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update message attributes
#
# PUT /v3/grants/{grant_id}/messages/{message_id}
# operationId: put-messages-id
export def "grants-messages put-messages-id" [
  message_id: string
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --query-imap: string@bool-completer # (IMAP, iCloud, and Yahoo only) When `true`, Nylas queries from the IMAP server directly instead of the Nylas database. (default: false)
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --starred: string@bool-completer # Set to `true` to mark as starred; `false` to mark as not starred. (e.g. true)
  --unread: string@bool-completer # Set to `true` to mark as unread; `false` to mark as read. (e.g. true)
  --folders: list # The ID(s) of the folder(s) to apply, overwriting all folders previously associated with the message. Microsoft messages can be in a single folder only. Google allows a single message to appear in multiple folders. (e.g. [folder-1, folder-2])
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "query_imap" $query_imap "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/($message_id)" $qp)
  let body = {starred: $starred, unread: $unread, folders: $folders, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a message
#
# DELETE /v3/grants/{grant_id}/messages/{message_id}
# operationId: delete-message
export def "grants-messages delete-message" [
  message_id: string
  grant_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hard-delete: string@bool-completer # When `true`, Nylas immediately deletes the specified message instead of sending it to the user's Trash folder. This operation is irreversible.  To use this query parameter, you need to turn on "Enable hard delete" in the [Nylas Dashboard](https://dashboard-v3.nylas.com/?utm_source=docs&utm_content=docs-hard-delete) under **Customizations > API**. (default: false)
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hard_delete" $hard_delete "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/($message_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clean messages
#
# PUT /v3/grants/{grant_id}/messages/clean
# operationId: clean-messages
export def "grants-messages-clean clean-messages" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --message-id: list # An array of IDs for the messages Nylas will clean. (e.g. [18df98cadcc8534a])
  --ignore-links: string@bool-completer # If `true`, removes link-related tags (`<a>`) from the message while keeping the text. (default: true, e.g. true)
  --ignore-images: string@bool-completer # If `true`, removes images from the message. (default: true, e.g. true)
  --images-as-markdown: string@bool-completer # If `true`, converts images in the message to [Markdown](https://en.wikipedia.org/wiki/Markdown). Can't be `false` when `html_as_markdown` is `true`. (default: true, e.g. true)
  --ignore-tables: string@bool-completer # If `true`, removes table-related tags (`<table>`, `<th>`, `<td>`, `<tr>`) from the message while keeping rows. (default: true, e.g. true)
  --remove-conclusion-phrases: string@bool-completer # If `true`, removes phrases such as "Best" and "Regards" from the message signature. (default: true, e.g. true)
  --html-as-markdown: string@bool-completer # **This property is in beta**. If `true`, converts the message to [Markdown](https://en.wikipedia.org/wiki/Markdown). Can't be `true` when `images_as_markdown` is `false`. (default: false, e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/clean" $qp)
  let body = {message_id: $message_id, ignore_links: $ignore_links, ignore_images: $ignore_images, images_as_markdown: $images_as_markdown, ignore_tables: $ignore_tables, remove_conclusion_phrases: $remove_conclusion_phrases, html_as_markdown: $html_as_markdown} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a Message
#
# POST /v3/grants/{grant_id}/messages/send
# operationId: send-message
# --attachments item shape: {content?: string, content_disposition?: string, content_id?: string, content_type?: string, filename?: string}
# --bcc item shape: {name?: string, email?: string}
# --cc item shape: {name?: string, email?: string}
# --custom_headers item shape: {name?: string, value?: string}
# --from item shape: {name?: string, email: string}
# --reply_to item shape: {name?: string, email?: string}
# --template shape: {id?: string, strict?: bool, variables?: record}
# --to item shape: {name?: string, email?: string}
# --tracking_options shape: {opens?: bool, thread_replies?: bool, links?: bool, label?: string}
export def "grants-messages-send send-message" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string@fields-completer-1 # Include message headers in the send response. Headers are returned in the same `headers` array format as [Get Message](/docs/reference/api/messages/get-messages-id/) responses.  - `standard`: Returns the standard send response (no `headers` array). - `include_headers`: Returns the full set of headers on the response. - `include_basic_headers`: Returns only the three RFC threading headers (`Message-ID`,   `In-Reply-To`, `References`). Use this option when you only need to track message identity   and thread relationships — payload size is significantly smaller than `include_headers`.  Supported on **synchronous** send only. The parameter has no effect when you set the `send_at` field on the request (scheduled send is asynchronous and doesn't return headers).  For provider support details, see [Using email headers and MIME data](/docs/v3/email/headers-mime-data/#provider-support). (default: standard)
  --Idempotency-Key: string # A unique, client-generated key (max 256 characters) that lets you safely retry this send request without sending duplicate emails. Nylas caches the response (success or error) for 1 hour, scoped per grant. A retry with the same key and payload returns the cached response with the `Idempotent-Response: true` header set. See [Idempotent send requests](/docs/v3/email/idempotent-send/) for the full retry behavior and error responses. (e.g. f47ac10b-58cc-4372-a567-0e02b2c3d479)
  --attachments: list # An array of files to be sent with the message. — item shape: {content?: string, content_disposition?: string, content_id?: string, content_type?: string, filename?: string}
  --bcc: list # A list of people BCC'd on the message. — item shape: {name?: string, email?: string}
  --body-body: string # The HTML body of the message. (e.g. Looking forward to seeing you!)
  --cc: list # A list of people CC'd on the message. — item shape: {name?: string, email?: string}
  --custom-headers: list # An array of custom headers to add to the message. — item shape: {name?: string, value?: string}
  --body-from: list # The sender of the message. Accepts a single object in an array. If omitted, Nylas uses the grant's email address and display name. — item shape: {name?: string, email: string}
  --is-plaintext: string@bool-completer # When `true`, the message body is sent as plain text and the MIME data doesn't include the HTML version of the message. When `false`, the message body is sent as HTML. (default: false)
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  --reply-to: list # A list of people who should receive replies to the message by default. — item shape: {name?: string, email?: string}
  --reply-to-message-id: string # The ID of the message you're replying to. For Gmail and Microsoft Graph, this is the message ID on the provider. For IMAP Send, this is the [RFC822](https://datatracker.ietf.org/doc/html/rfc822#section-4.6.1) `Message-ID` header of the message you're replying to.
  --send-at: int # The time when Nylas should send the message, in seconds using the Unix timestamp format. This time must be at least one minute in the future from the time you make your request. You can schedule a message to be sent up to 30 days in the future.
  --subject: string # The subject of the message. (e.g. Reminder: Annual Philosophy Club Meeting)
  --template: record # The [template](/docs/reference/api/application-level-templates/) to use for the message. Can be overriden by the `body` and `subject` fields. — shape: {id?: string, strict?: bool, variables?: record}
  --body-to: list # A list of people that the message will be sent to. — item shape: {name?: string, email?: string}
  --tracking-options: record # Tracking settings for the message. See [Track messages](/docs/v3/email/message-tracking/). — shape: {opens?: bool, thread_replies?: bool, links?: bool, label?: string}
  --use-draft: string@bool-completer # (Google and Microsoft only) When `true`, Nylas saves the message in the user's Drafts folder until its `send_at` time. This field can't be `true` if `send_at` is undefined. (default: false)
  --signature-id: string # The ID of a [signature](/docs/v3/email/signatures/) to append to the message body. Nylas inserts the signature after a line break at the end of the body, including after any quoted text in replies and forwards. Only one signature can be used per message. (e.g. sig_abc123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/send" $qp)
  let body = {attachments: $attachments, bcc: $bcc, body: $body_body, cc: $cc, custom_headers: $custom_headers, from: $body_from, is_plaintext: $is_plaintext, metadata: $metadata, reply_to: $reply_to, reply_to_message_id: $reply_to_message_id, send_at: $send_at, subject: $subject, template: $template, to: $body_to, tracking_options: $tracking_options, use_draft: $use_draft, signature_id: $signature_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return scheduled messages
#
# GET /v3/grants/{grant_id}/messages/schedules
# operationId: get-schedules
export def "grants-messages-schedules get-schedules" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/schedules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a scheduled message
#
# GET /v3/grants/{grant_id}/messages/schedules/{scheduleId}
# operationId: get-schedule-by-id
export def "grants-messages-schedules get-schedule-by-id" [
  grant_id: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/schedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a scheduled message
#
# DELETE /v3/grants/{grant_id}/messages/schedules/{scheduleId}
# operationId: delete-a-scheduled-message
export def "grants-messages-schedules delete-a-scheduled-message" [
  grant_id: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/schedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Compose a message
#
# POST /v3/grants/{grant_id}/messages/smart-compose
# operationId: post-smart-compose
export def "grants-messages-smart-compose post-smart-compose" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prompt: string # The prompt that Smart Compose uses to generate a message suggestion. (e.g. Reply to John Doe about the upcoming project.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/smart-compose")
  let body = {prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compose a reply
#
# POST /v3/grants/{grant_id}/messages/{message_id}/smart-compose
# operationId: post-smart-compose-reply
export def "grants-messages-smart-compose post-smart-compose-reply" [
  grant_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prompt: string # The prompt that Smart Compose uses to generate a message suggestion. (e.g. Reply to John Doe about the upcoming project.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/messages/($message_id)/smart-compose")
  let body = {prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all threads
#
# GET /v3/grants/{grant_id}/threads
# operationId: get-threads
export def "grants-threads get-threads" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --any-email: string # Filter for threads that contain messages sent to or received from the email addresses in the comma-separated list. You may specify a maximum of 25 email addresses per query. (e.g. mail1@example.com,mail2@example.com)
  --bcc: string # Filter for threads that contain messages BCC'd to the specified email address. Because most SMTP gateways remove BCC information from sent messages, any messages that Nylas returns are likely sent from the parent account.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --cc: string # Filter for threads that contain messages CC'd to the specified email address.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --qp-from: string # Filter for threads that include messages sent from the specified email address. If you want to filter for threads that include messages sent from the current grant, use the `in` query parameter and specify the Sent folder instead.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --has-attachment: string@bool-completer # When `true`, filters for threads that include attachments. (default: false)
  --in-param: string # Return messages in the specified folder or label, by folder ID. Required when using `shared_from`.
  --earliest-message-date: int # Returns the date when the earliest or first message in the thread was sent or received, in Unix  timestamp format.
  --latest-message-after: int # Filter for threads whose most recent message was received after the specified time, in Unix timestamp format.
  --latest-message-before: int # Filter for threads whose most recent message was received before the specified time, in Unix timestamp format.
  --limit: int # The maximum number of objects to return. See [pagination](/docs/reference/api/#pagination) for more information. (default: 20)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --search-query-native: string # Specify a URL-encoded provider-specific query string. Each provider supports a limited set of query parameters that you can use in your request alongside `search_query_native`:  - **Google**: `in`, `limit`, and `page_token` - **Microsoft**: `in`, `limit`, and `page_token` - **IMAP/Yahoo/iCloud**: Any parameter - **EWS**: Any parameter _except_ `thread_id`  For more information, see [Searching with Nylas](/docs/dev-guide/best-practices/search/#search-messages-and-threads-using-search_query_native).
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --shared-folder-id: string # (Microsoft only) When provided, Nylas returns items from the specified shared folder ID. Required when using `shared_from`. This parameter only accepts a single folder ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --starred: string@bool-completer # Filter for threads that contain one or more starred messages.
  --subject: string # Return threads that contain messages with a matching subject. This filter is case-sensitive and returns partial matches.
  --qp-to: string # Filter for threads that contain messages sent to the specified email address.  For Microsoft grants, Nylas sometimes doesn't return messages that satisfy the conditions of this query parameter. This is because of a limitation on the provider. Instead, you can use the `thread_id` to retrieve a specific conversation.
  --unread: string@bool-completer # Filter for threads that contain one or more unread messages.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "any_email" $any_email "scalar") (serialize-qp "bcc" $bcc "scalar") (serialize-qp "cc" $cc "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "has_attachment" $has_attachment "scalar") (serialize-qp "in" $in_param "scalar") (serialize-qp "earliest_message_date" $earliest_message_date "scalar") (serialize-qp "latest_message_after" $latest_message_after "scalar") (serialize-qp "latest_message_before" $latest_message_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "search_query_native" $search_query_native "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "shared_folder_id" $shared_folder_id "scalar") (serialize-qp "shared_from" $shared_from "scalar") (serialize-qp "starred" $starred "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "unread" $unread "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/threads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a thread
#
# GET /v3/grants/{grant_id}/threads/{thread_id}
# operationId: get-threads-id
export def "grants-threads get-threads-id" [
  grant_id: string
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --shared-folder-id: string # (Microsoft only) When provided, Nylas returns items from the specified shared folder ID. Required when using `shared_from`. This parameter only accepts a single folder ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "shared_folder_id" $shared_folder_id "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/threads/($thread_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a thread
#
# PUT /v3/grants/{grant_id}/threads/{thread_id}
# operationId: put-threads-id
export def "grants-threads put-threads-id" [
  grant_id: string
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --shared-folder-id: string # (Microsoft only) When provided, Nylas returns items from the specified shared folder ID. Required when using `shared_from`. This parameter only accepts a single folder ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --starred: string@bool-completer # When `true`, indicates that the thread is starred. (e.g. true)
  --unread: string@bool-completer # When `false`, indicates that all messages in the thread have been read. (e.g. true)
  --folders: list # The IDs of the folders to apply to the thread. This overwrites all previously assigned folders for all messages in the thread. (e.g. [folder-1, folder-2])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "shared_folder_id" $shared_folder_id "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/threads/($thread_id)" $qp)
  let body = {starred: $starred, unread: $unread, folders: $folders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a thread
#
# DELETE /v3/grants/{grant_id}/threads/{thread_id}
# operationId: delete-threads-id
export def "grants-threads delete-threads-id" [
  grant_id: string
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --shared-folder-id: string # (Microsoft only) When provided, Nylas returns items from the specified shared folder ID. Required when using `shared_from`. This parameter only accepts a single folder ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shared_folder_id" $shared_folder_id "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/threads/($thread_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all Drafts
#
# GET /v3/grants/{grant_id}/drafts
# operationId: get-drafts
export def "grants-drafts get-drafts" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --metadata-pair: string # Pass a metadata key/value pair (for example, `?metadata_pair=key1:value`) to search for metadata associated with objects. See [Metadata](/docs/reference/api/#metadata) for more information.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --subject: string # Return items with a matching subject. The filter is case insensitive and will match partial subjects.
  --any-email: string # Return messages that have been sent or received from this comma-separated list of email addresses (for example, `mail1@example.com,mail2@example.com`). You can specify a maximum of 25 email addresses.
  --qp-to: string # Return items containing messages sent to this email address.
  --cc: string # Return items containing messages that were CC'd to this email address.
  --bcc: string # Return items containing messages that were BCC'd to this email address, likely sent from the parent account. (Most SMTP gateways remove BCC information, so this appears only if the user sent the email message, or received it because they were on the BCC list.)
  --starred: string@bool-completer # Return items with one or more starred messages. For EWS, this is only supported for Microsoft Exchange 2010 or later.
  --thread-id: string # Return items with a matching `thread_id`.
  --has-attachment: string@bool-completer # Return items with attachments.
  --query-imap: string@bool-completer # (IMAP, Yahoo, and iCloud only) When `true`, Nylas queries the IMAP server directly instead of the Nylas database. You also need to set the `in` query parameter in your request so Nylas knows which folder to query. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "metadata_pair" $metadata_pair "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "subject" $subject "scalar") (serialize-qp "any_email" $any_email "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "cc" $cc "scalar") (serialize-qp "bcc" $bcc "scalar") (serialize-qp "starred" $starred "scalar") (serialize-qp "thread_id" $thread_id "scalar") (serialize-qp "has_attachment" $has_attachment "scalar") (serialize-qp "query_imap" $query_imap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/drafts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Draft
#
# POST /v3/grants/{grant_id}/drafts
# operationId: post-draft
# --bcc item shape: {name?: string, email: string}
# --cc item shape: {name?: string, email: string}
# --tracking_options shape: {opens?: bool, thread_replies?: bool, links?: bool, label?: string}
# --attachments item shape: {filename?: string, content?: string, content_type?: string, content_id?: string, content_disposition?: string}
# --from item shape: {name?: string, email: string}
# --reply_to item shape: {name?: string, email: string}
# --to item shape: {name?: string, email: string}
# --custom_headers item shape: {name?: string, value?: string}
# --template shape: {id?: string, strict?: bool, variables?: record}
export def "grants-drafts post-draft" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bcc: list # The name/email address pairs of the recipients to be BCC'd. (e.g. [{email: brandon.carson@example.com, name: }]) — item shape: {name?: string, email: string}
  --body-body: string # The body of the draft, in HTML format. (e.g. Hi, Welcome to Nylas!)
  --cc: list # The name/email address pairs of the recipients to be CC'd. (e.g. [{email: clivescounters@example.com, name: }]) — item shape: {name?: string, email: string}
  --tracking-options: record # shape: {opens?: bool, thread_replies?: bool, links?: bool, label?: string}
  --attachments: list # An array of file attachments to include in the draft. You can use either the `application/json` or `multipart/form-data` schema, depending on the size of the attachment.  The `application/json` schema is limited to 3MB, including the message body. The `content` must be Base64-encoded.  The `multipart/form-data` schema is limited by the provider to 25MB. See the [Attachments references](/docs/reference/api/attachments/) for more information. — item shape: {filename?: string, content?: string, content_type?: string, content_id?: string, content_disposition?: string}
  --body-from: list # An array that contains a single name and email address pair that Nylas sets as the `from` header. By default, Nylas uses the email address associated with the `grant_id`.  Nylas supports multiple `from` addresses for email aliases only. (e.g. [{email: leyah@example.com, name: Leyah Miller}]) — item shape: {name?: string, email: string}
  --is-plaintext: string@bool-completer # When `true`, the message body is sent as plain text and the MIME data doesn't include the HTML version of the message. When `false`, the message body is sent as HTML. (default: false)
  --reply-to: list # An array of name/email address pairs that should receive replies to the message. This is used to set an alternative `Reply-To` header in the sent message. Not all providers support setting this in a draft. (e.g. [{email: healthcare.demo@example.com, name: }]) — item shape: {name?: string, email: string}
  --reply-to-message-id: string # The unique identifier of the message to which you want to draft a reply. (e.g. 1t8tv3890q4vgmwq6pmdwm8qg)
  --starred: string@bool-completer # If `true`, the draft is starred. (e.g. false)
  --subject: string # The subject line of the draft. (e.g. Invitation: Welcome! @ Thu Oct 28, 2021 7am - 8am (EDT) - Toronto)
  --body-to: list # The name/email address pairs of the recipients. (e.g. [{email: demo@example.com, name: }, {email: realestate.demo@example.com, name: }]) — item shape: {name?: string, email: string}
  --custom-headers: list # An array of custom headers to add to the message. — item shape: {name?: string, value?: string}
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  --template: record # The [template](/docs/reference/api/application-level-templates/) to use for the message. Can be overriden by the `body` and `subject` fields. — shape: {id?: string, strict?: bool, variables?: record}
  --signature-id: string # The ID of a [signature](/docs/v3/email/signatures/) to append to the draft body. Nylas inserts the signature after a line break at the end of the body. Only one signature can be used per draft. (e.g. sig_abc123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/drafts")
  let body = {bcc: $bcc, body: $body_body, cc: $cc, tracking_options: $tracking_options, attachments: $attachments, from: $body_from, is_plaintext: $is_plaintext, reply_to: $reply_to, reply_to_message_id: $reply_to_message_id, starred: $starred, subject: $subject, to: $body_to, custom_headers: $custom_headers, metadata: $metadata, template: $template, signature_id: $signature_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a Draft
#
# GET /v3/grants/{grant_id}/drafts/{draft_id}
# operationId: get-draft-id
export def "grants-drafts get-draft-id" [
  grant_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --query-imap: string@bool-completer # (IMAP, iCloud, and Yahoo only) When `true`, Nylas queries from the IMAP server directly instead of the Nylas database. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "query_imap" $query_imap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/drafts/($draft_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a draft
#
# PUT /v3/grants/{grant_id}/drafts/{draft_id}
# operationId: put-drafts-id
# --bcc item shape: {name?: string, email: string}
# --cc item shape: {name?: string, email: string}
# --attachments item shape: {filename?: string, content?: string, content_type?: string, content_id?: string, content_disposition?: string}
# --reply_to item shape: {name?: string, email: string}
# --to item shape: {name?: string, email: string}
# --template shape: {id?: string, strict?: bool, variables?: record}
export def "grants-drafts put-drafts-id" [
  grant_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --bcc: list # The name/email address pairs of the recipients to be BCC'd. (e.g. [{email: brandon.carson@example.com, name: }]) — item shape: {name?: string, email: string}
  --body-body: string # The body of the draft, in HTML format. (e.g. Hi, Welcome to Nylas!)
  --cc: list # The name/email address pairs of the recipients to be CC'd. (e.g. [{email: clivescounters@example.com, name: }]) — item shape: {name?: string, email: string}
  --attachments: list # An array of file attachments to include in the draft. You can use either the `application/json` or `multipart/form-data` schema, depending on attachment size. The `application/json` format is limited to 3MB including the message body, and the `content` must be Base64 encoded. The `multipart/form-data` format size is limited by the provider to 25MB.  See [Attachments](/#tag--Attachments) for more information. — item shape: {filename?: string, content?: string, content_type?: string, content_id?: string, content_disposition?: string}
  --reply-to: list # An array of name/email address pairs that should receive replies to the message. This is used to set an alternative `Reply-To` header in the sent message. Not all providers support setting this in a draft. (e.g. [{email: healthcare.demo@example.com, name: }]) — item shape: {name?: string, email: string}
  --starred: string@bool-completer # If `true`, the draft is starred. (e.g. false)
  --subject: string # The subject line of the draft. (e.g. Invitation: Welcome! @ Thu Oct 28, 2021 7am - 8am (EDT) - Toronto)
  --body-to: list # The name/email address pairs of the recipients. (e.g. [{email: demo@example.com, name: }, {email: realestate.demo@example.com, name: }]) — item shape: {name?: string, email: string}
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  --template: record # The [template](/docs/reference/api/application-level-templates/) to use for the message. Can be overriden by the `body` and `subject` fields. — shape: {id?: string, strict?: bool, variables?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/drafts/($draft_id)" $qp)
  let body = {bcc: $bcc, body: $body_body, cc: $cc, attachments: $attachments, reply_to: $reply_to, starred: $starred, subject: $subject, to: $body_to, metadata: $metadata, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Draft
#
# DELETE /v3/grants/{grant_id}/drafts/{draft_id}
# operationId: delete-drafts-id
export def "grants-drafts delete-drafts-id" [
  grant_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/drafts/($draft_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a Draft
#
# POST /v3/grants/{grant_id}/drafts/{draft_id}
# operationId: send-draft-id
export def "grants-drafts send-draft-id" [
  grant_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --signature-id: string # The ID of a [signature](/docs/v3/email/signatures/) to append to the message body when sending. Nylas inserts the signature after a line break at the end of the body, including after any quoted text. Only use this if the draft was created without a signature, or if you want to add one at send time. (e.g. sig_abc123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/drafts/($draft_id)" $qp)
  let body = {signature_id: $signature_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all folders
#
# GET /v3/grants/{grant_id}/folders
# operationId: get-folder
export def "grants-folders get-folder" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --include-hidden-folders: string@bool-completer # (Microsoft only) When `true`, Nylas includes hidden folders in its response. (default: false)
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --parent-id: string # (Microsoft and EWS only) Use the ID of a folder to find all child folders it contains.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --single-level: string@bool-completer # (Microsoft only) If `true`, retrieves folders from a single-level hierarchy only. If `false`, retrieves folders across a multi-level hierarchy. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "include_hidden_folders" $include_hidden_folders "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "shared_from" $shared_from "scalar") (serialize-qp "single_level" $single_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Folder
#
# POST /v3/grants/{grant_id}/folders
# operationId: post-folder
export def "grants-folders post-folder" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  name: string # Creates a folder with the specified display name.
  --parent-id: string # (Microsoft and EWS only) The ID of the parent folder.
  --text-color: string # (Google only) The text color of the folder, in hexadecimal format (for example, `#0099EE`). See the [list of Google-defined values](https://developers.google.com/gmail/api/reference/rest/v1/users.labels#color) for more information.
  --background-color: string # (Google only) The background color of the folder, in hexadecimal format (for example, `#0099EE`). See the [list of Google-defined values](https://developers.google.com/gmail/api/reference/rest/v1/users.labels#color) for more information.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/folders" $qp)
  let body = {name: $name, parent_id: $parent_id, text_color: $text_color, background_color: $background_color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a Folder
#
# GET /v3/grants/{grant_id}/folders/{folder_id}
# operationId: get-folders-id
export def "grants-folders get-folders-id" [
  grant_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --include-hidden-folders: string@bool-completer # (Microsoft only) When `true`, Nylas includes hidden folders in its response. (default: false)
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "include_hidden_folders" $include_hidden_folders "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/folders/($folder_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a folder
#
# PUT /v3/grants/{grant_id}/folders/{folder_id}
# operationId: put-folders-id
export def "grants-folders put-folders-id" [
  grant_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --include-hidden-folders: string@bool-completer # (Microsoft only) When `true`, Nylas includes hidden folders in its response. (default: false)
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
  --name: string # The name of the folder to be updated.
  --parent-id: string # (Microsoft and EWS only) The ID of the parent folder.
  --text-color: string # (Google only) The text color of the folder, in hexadecimal format (for example, `#0099EE`). See [Google's reference documentation](https://developers.google.com/gmail/api/reference/rest/v1/users.labels#color) for a list of accepted values.
  --background-color: string # (Google only) The background color of the folder, in hexadecimal format (for example, `#0099EE`). See [Google's reference documentation](https://developers.google.com/gmail/api/reference/rest/v1/users.labels#color) for a list of accepted values.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "include_hidden_folders" $include_hidden_folders "scalar") (serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/folders/($folder_id)" $qp)
  let body = {name: $name, parent_id: $parent_id, text_color: $text_color, background_color: $background_color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Folder
#
# DELETE /v3/grants/{grant_id}/folders/{folder_id}
# operationId: delete-folders-id
export def "grants-folders delete-folders-id" [
  grant_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --shared-from: string # (Microsoft only) When provided, Nylas returns items that were shared from the specified email address. It also accepts grant ID. This parameter only accepts single email address or grant ID. Check out the [Shared folders](/docs/provider-guides/microsoft/shared-folders) guide for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shared_from" $shared_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/folders/($folder_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return Attachment metadata
#
# GET /v3/grants/{grant_id}/attachments/{attachment_id}
# operationId: get-attachments-id
export def "grants-attachments get-attachments-id" [
  grant_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message-id: string # ID of the message the specified attachment belongs to.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --query-imap: string@bool-completer # (IMAP, iCloud, and Yahoo only) When `true`, Nylas queries from the IMAP server directly instead of the Nylas database. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "message_id" $message_id "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "query_imap" $query_imap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/attachments/($attachment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download an Attachment
#
# GET /v3/grants/{grant_id}/attachments/{attachment_id}/download
# operationId: get-attachments-id-download
export def "grants-attachments-download get-attachments-id-download" [
  grant_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message-id: string # ID of the message the specified attachment belongs to.
  --query-imap: string@bool-completer # (IMAP, Yahoo, and iCloud only) When `true`, Nylas downloads the attachment directly from the IMAP server instead of the Nylas database. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "message_id" $message_id "scalar") (serialize-qp "query_imap" $query_imap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/attachments/($attachment_id)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an attachment upload session
#
# POST /v3/grants/{grant_id}/attachment-uploads
# operationId: create-attachment-upload-session
export def "grants-attachment-uploads create-attachment-upload-session" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filename: string # The name of the file as it will appear in the email. No allowlist or sanitization is applied. (e.g. quarterly-report.pdf)
  content_type: string # The MIME type of the file (for example, `application/pdf`, `image/png`). No MIME allowlist is applied — any non-empty string is accepted and passed through to storage. (e.g. application/pdf)
  --size: int # Expected file size in bytes. Recommended — when provided, Nylas validates that the uploaded object matches this size at completion. If omitted, the size-match check is skipped and any non-zero upload is accepted. Maximum: `157286400` (150 MB). (format: int64, e.g. 5242880)
]: any -> record<request_id: string, data: record<attachment_id: string, method: string, url: string, headers: record, expires_at: string, max_size: int, size: int, content_type: string, filename: string, grant_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/attachment-uploads")
  let body = {filename: $filename, content_type: $content_type, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete an attachment upload session
#
# POST /v3/grants/{grant_id}/attachment-uploads/{attachment_id}/complete
# operationId: complete-attachment-upload-session
export def "grants-attachment-uploads-complete complete-attachment-upload-session" [
  grant_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, data: record<attachment_id: string, grant_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/attachment-uploads/($attachment_id)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create contact
#
# POST /v3/grants/{grant_id}/contacts
# operationId: post-contact
# --emails item shape: {email: string, type?: "work"|"home"|"other"}
# --groups item shape: {id: string}
# --im_addresses item shape: {im_address: string, type?: string}
# --phone_numbers item shape: {number: string, type?: "work"|"home"|"mobile"|"other"}
# --physical_addresses item shape: {city?: string, country?: string, postal_code?: string, state?: string, street_address?: string, type: "work"|"home"|"other"}
# --web_pages item shape: {url: string, type?: "work"|"home"|"other"}
export def "grants-contacts post-contact" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --birthday: string # The contact's birthday in [ISO-8601 format](https://en.wikipedia.org/wiki/ISO_8601#Calendar_dates). (e.g. 1980-12-31)
  --company-name: string # The name of the company that the contact is affiliated with (for example, their workplace). (e.g. Nylas)
  --emails: list # item shape: {email: string, type?: "work"|"home"|"other"}
  given_name: string # The contact's given name. (e.g. John)
  --groups: list # A list of IDs for contact groups the contact is included in. Microsoft, iCloud and IMAP support at most one contact group per contact. — item shape: {id: string}
  --im-addresses: list # item shape: {im_address: string, type?: string}
  --job-title: string # The contact's occupation or job title. (e.g. Software Engineer)
  --manager-name: string # The name of the contact's manager. (e.g. Bill)
  --middle-name: string # The contact's middle name. (e.g. Jacob)
  --nickname: string # A custom nickname for the contact. (e.g. JD)
  --notes: string # Notes about with the contact (for example, their favorite food). (e.g. Loves Ramen)
  --office-location: string # The location of the office where the contact works. (e.g. 123 Main Street)
  --phone-numbers: list # item shape: {number: string, type?: "work"|"home"|"mobile"|"other"}
  --physical-addresses: list # item shape: {city?: string, country?: string, postal_code?: string, state?: string, street_address?: string, type: "work"|"home"|"other"}
  --suffix: string # (Not supported for EWS) The suffix of a contact's name, if applicable. (e.g. Jr.)
  --surname: string # The contact's surname. (e.g. Doe)
  --web-pages: list # An array of the contact's websites. Different providers may have different limits on the number of web pages. - IMAP/iCloud/Yahoo: at most one web page per contact. - Microsoft/EWS: at most one web page per contact. The type must be `work`. — item shape: {url: string, type?: "work"|"home"|"other"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/contacts" $qp)
  let body = {birthday: $birthday, company_name: $company_name, emails: $emails, given_name: $given_name, groups: $groups, im_addresses: $im_addresses, job_title: $job_title, manager_name: $manager_name, middle_name: $middle_name, nickname: $nickname, notes: $notes, office_location: $office_location, phone_numbers: $phone_numbers, physical_addresses: $physical_addresses, suffix: $suffix, surname: $surname, web_pages: $web_pages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all contacts
#
# GET /v3/grants/{grant_id}/contacts
# operationId: list-contact
export def "grants-contacts list-contact" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 30)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --email: string # Returns the contacts containing the specified email address.
  --phone-number: string # (Google, IMAP, iCloud, Yahoo, and EWS only) Returns contacts containing the specified phone number.
  --qp-source: string@source-completer # Returns the specified contacts from the user's address book, domain, or any auto-generated contacts from messages. If you want to filter for multiple sources, pass a comma-separated list (for example, `source=address_book,inbox`).  EWS doesn't support `inbox`. Compound source filters are supported for IMAP and iCloud only. (default: address_book)
  --group: string # (Not supported for EWS) Returns the contacts included in the specified Contact Group.
  --recurse: string # (Microsoft Only) When `true`, returns the contacts in the specified Contact Group subgroups. The recursion goes only one level deep.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "phone_number" $phone_number "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "recurse" $recurse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a contact
#
# GET /v3/grants/{grant_id}/contacts/{contact_id}
# operationId: get-contact
export def "grants-contacts get-contact" [
  grant_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --profile-picture: string@bool-completer # If `true` and `picture_url` is present, the response includes a Base64 binary data blob that you can use to view information as an image file (for example, a JPEG).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar") (serialize-qp "profile_picture" $profile_picture "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/contacts/($contact_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a contact
#
# PUT /v3/grants/{grant_id}/contacts/{contact_id}
# operationId: put-contact
# --emails item shape: {email: string, type?: "work"|"home"|"other"}
# --groups item shape: {id: string}
# --im_addresses item shape: {im_address: string, type?: string}
# --phone_numbers item shape: {number: string, type?: "work"|"home"|"mobile"|"other"}
# --physical_addresses item shape: {city?: string, country?: string, postal_code?: string, state?: string, street_address?: string, type: "work"|"home"|"other"}
# --web_pages item shape: {url: string, type?: "work"|"home"|"other"}
export def "grants-contacts put-contact" [
  grant_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --birthday: string # The contact's birthday in [ISO-8601 format](https://en.wikipedia.org/wiki/ISO_8601#Calendar_dates). (e.g. 1980-12-31)
  --company-name: string # The name of the company that the contact is affiliated with (for example, their workplace). (e.g. Nylas)
  --emails: list # item shape: {email: string, type?: "work"|"home"|"other"}
  given_name: string # The contact's given name. (e.g. John)
  --groups: list # A list of IDs for contact groups the contact is included in. Microsoft, iCloud and IMAP support at most one contact group per contact. — item shape: {id: string}
  --im-addresses: list # item shape: {im_address: string, type?: string}
  --job-title: string # The contact's occupation or job title. (e.g. Software Engineer)
  --manager-name: string # The name of the contact's manager. (e.g. Bill)
  --middle-name: string # The contact's middle name. (e.g. Jacob)
  --nickname: string # A custom nickname for the contact. (e.g. JD)
  --notes: string # Notes about with the contact (for example, their favorite food). (e.g. Loves Ramen)
  --office-location: string # The location of the office where the contact works. (e.g. 123 Main Street)
  --phone-numbers: list # item shape: {number: string, type?: "work"|"home"|"mobile"|"other"}
  --physical-addresses: list # item shape: {city?: string, country?: string, postal_code?: string, state?: string, street_address?: string, type: "work"|"home"|"other"}
  --suffix: string # (Not supported for EWS) The suffix of a contact's name, if applicable. (e.g. Jr.)
  --surname: string # The contact's surname. (e.g. Doe)
  --web-pages: list # An array of the contact's websites. Different providers may have different limits on the number of web pages. - IMAP/iCloud/Yahoo: at most one web page per contact. - Microsoft/EWS: at most one web page per contact. The type must be `work`. — item shape: {url: string, type?: "work"|"home"|"other"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/contacts/($contact_id)" $qp)
  let body = {birthday: $birthday, company_name: $company_name, emails: $emails, given_name: $given_name, groups: $groups, im_addresses: $im_addresses, job_title: $job_title, manager_name: $manager_name, middle_name: $middle_name, nickname: $nickname, notes: $notes, office_location: $office_location, phone_numbers: $phone_numbers, physical_addresses: $physical_addresses, suffix: $suffix, surname: $surname, web_pages: $web_pages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact
#
# DELETE /v3/grants/{grant_id}/contacts/{contact_id}
# operationId: delete-contact
export def "grants-contacts delete-contact" [
  grant_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/contacts/($contact_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all Contact Groups
#
# GET /v3/grants/{grant_id}/contacts/groups
# operationId: list-contact-groups
export def "grants-contacts-groups list-contact-groups" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/contacts/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all signatures
#
# GET /v3/grants/{grant_id}/signatures
# operationId: list-signatures
export def "grants-signatures list-signatures" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/signatures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a signature
#
# POST /v3/grants/{grant_id}/signatures
# operationId: post-signature
export def "grants-signatures post-signature" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  name: string # A label for the signature (for example, "Work", "Personal", or "Mobile"). (e.g. Work Signature)
  --body-body: string # The HTML content of the signature. Maximum 100 KB. Images must use externally hosted URLs (base64 inline images are not supported). Nylas sanitizes the HTML on input to prevent malicious content. (e.g. <div><p><strong>Nick Barraclough</strong></p><p>Product Manager | Nylas</p><p><a href="mailto:nick@nylas.com">nick@nylas.com</a></p></div>)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/signatures" $qp)
  let body = {name: $name, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a signature
#
# GET /v3/grants/{grant_id}/signatures/{signature_id}
# operationId: get-signature
export def "grants-signatures get-signature" [
  grant_id: string
  signature_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/signatures/($signature_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a signature
#
# PUT /v3/grants/{grant_id}/signatures/{signature_id}
# operationId: put-signature
export def "grants-signatures put-signature" [
  grant_id: string
  signature_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: string # Specify fields that you want Nylas to return, as a comma-separated list (for example, `select=id,updated_at`). This allows you to receive only the portion of object data that you're interested in. You can use `select` to optimize response size and reduce latency by limiting queries to only the information that you need.
  --name: string # Updated label for the signature. (e.g. Updated Work Signature)
  --body-body: string # Updated HTML content for the signature. Maximum 100 KB. Images must use externally hosted URLs (base64 inline images are not supported). Nylas sanitizes the HTML on input to prevent malicious content. (e.g. <div><p><strong>Nick Barraclough</strong></p><p>Senior Product Manager | Nylas</p></div>)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "select" $select "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/signatures/($signature_id)" $qp)
  let body = {name: $name, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a signature
#
# DELETE /v3/grants/{grant_id}/signatures/{signature_id}
# operationId: delete-signature
export def "grants-signatures delete-signature" [
  grant_id: string
  signature_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/signatures/($signature_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all workflows
#
# GET /v3/workflows
# operationId: list-workflows
export def "workflows list-workflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workflow
#
# POST /v3/workflows
# operationId: create-workflow
# --from shape: {email?: string, name?: string}
export def "workflows create-workflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delay: int # The number of minutes between a `trigger_event` being met and the workflow sending a message. (default: 0, e.g. 5)
  --is-enabled: string@bool-completer # When `true`, indicates that the workflow is enabled. (default: true, e.g. true)
  name: string # The name of the workflow. (e.g. New booking confirmation workflow)
  template_id: string # The ID of the email template the workflow uses. (e.g. 14c00cc8-648c-4381-ad10-52641d9bac8e)
  trigger_event: string@trigger-event-completer # The event which triggers the workflow. (e.g. booking.created)
  --body-from: record # Details of the sender if the workflow should use [transactional send](/docs/reference/api/transactional-send/). If not provided, the sender will be the grant associated with the trigger event. (nullable) — shape: {email?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/workflows")
  let body = {delay: $delay, is_enabled: $is_enabled, name: $name, template_id: $template_id, trigger_event: $trigger_event, from: $body_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a workflow
#
# GET /v3/workflows/{workflow_id}
# operationId: get-workflow
export def "workflows get-workflow" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/workflows/($workflow_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workflow
#
# PUT /v3/workflows/{workflow_id}
# operationId: update-workflow
# --from shape: {email?: string, name?: string}
export def "workflows update-workflow" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delay: int # The number of minutes between a `trigger_event` being met and the workflow sending a message. (e.g. 1)
  --is-enabled: string@bool-completer # When `true`, indicates that the workflow is enabled. (e.g. false)
  --name: string # The name of the workflow. (e.g. Updated booking confirmation workflow)
  --template-id: string # The ID of the email template the workflow uses. (e.g. 14c00cc8-648c-4381-ad10-52641d9bac8e)
  --trigger-event: string@trigger-event-completer # The event which triggers the workflow. (e.g. booking.created)
  --body-from: record # Details of the sender if the workflow should use [transactional send](/docs/reference/api/transactional-send/). If not provided, the sender will be the grant associated with the trigger event. (nullable) — shape: {email?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/workflows/($workflow_id)")
  let body = {delay: $delay, is_enabled: $is_enabled, name: $name, template_id: $template_id, trigger_event: $trigger_event, from: $body_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a workflow
#
# DELETE /v3/workflows/{workflow_id}
# operationId: delete-workflow
export def "workflows delete-workflow" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/workflows/($workflow_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all workflows
#
# GET /v3/grants/{grant_id}/workflows
# operationId: list-grant-workflows
export def "grants-workflows list-grant-workflows" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workflow
#
# POST /v3/grants/{grant_id}/workflows
# operationId: create-grant-workflow
# --from shape: {email?: string, name?: string}
export def "grants-workflows create-grant-workflow" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delay: int # The number of minutes between a `trigger_event` being met and the workflow sending a message. (default: 0, e.g. 5)
  --is-enabled: string@bool-completer # When `true`, indicates that the workflow is enabled. (default: true, e.g. true)
  name: string # The name of the workflow. (e.g. New booking confirmation workflow)
  template_id: string # The ID of the email template the workflow uses. (e.g. 14c00cc8-648c-4381-ad10-52641d9bac8e)
  trigger_event: string@trigger-event-completer # The event which triggers the workflow. (e.g. booking.created)
  --body-from: record # Details of the sender if the workflow should use [transactional send](/docs/reference/api/transactional-send/). If not provided, the sender will be the grant associated with the trigger event. (nullable) — shape: {email?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/workflows")
  let body = {delay: $delay, is_enabled: $is_enabled, name: $name, template_id: $template_id, trigger_event: $trigger_event, from: $body_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a workflow
#
# GET /v3/grants/{grant_id}/workflows/{workflow_id}
# operationId: get-grant-workflow
export def "grants-workflows get-grant-workflow" [
  grant_id: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/workflows/($workflow_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workflow
#
# PUT /v3/grants/{grant_id}/workflows/{workflow_id}
# operationId: update-grant-workflow
# --from shape: {email?: string, name?: string}
export def "grants-workflows update-grant-workflow" [
  grant_id: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delay: int # The number of minutes between a `trigger_event` being met and the workflow sending a message. (e.g. 1)
  --is-enabled: string@bool-completer # When `true`, indicates that the workflow is enabled. (e.g. false)
  --name: string # The name of the workflow. (e.g. Updated booking confirmation workflow)
  --template-id: string # The ID of the email template the workflow uses. (e.g. 14c00cc8-648c-4381-ad10-52641d9bac8e)
  --trigger-event: string@trigger-event-completer # The event which triggers the workflow. (e.g. booking.created)
  --body-from: record # Details of the sender if the workflow should use [transactional send](/docs/reference/api/transactional-send/). If not provided, the sender will be the grant associated with the trigger event. (nullable) — shape: {email?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/workflows/($workflow_id)")
  let body = {delay: $delay, is_enabled: $is_enabled, name: $name, template_id: $template_id, trigger_event: $trigger_event, from: $body_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a workflow
#
# DELETE /v3/grants/{grant_id}/workflows/{workflow_id}
# operationId: delete-grant-workflow
export def "grants-workflows delete-grant-workflow" [
  grant_id: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/workflows/($workflow_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all templates
#
# GET /v3/templates
# operationId: list-app-level-templates
export def "templates list-app-level-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /v3/templates
# operationId: create-app-level-template
export def "templates create-app-level-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The body content of the template, in HTML format. (e.g. <p>Hello {{user.name}}, your booking has been confirmed.</p>)
  --engine: string@engine-completer # The templating engine to use. (default: mustache, e.g. mustache)
  name: string # The name of the template. (e.g. Booking confirmed message)
  subject: string # The subject line of the template. (e.g. {{user.name}}, your booking is confirmed!)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/templates")
  let body = {body: $body_body, engine: $engine, name: $name, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a template
#
# GET /v3/templates/{template_id}
# operationId: get-app-level-template
export def "templates get-app-level-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a template
#
# PUT /v3/templates/{template_id}
# operationId: update-app-level-template
export def "templates update-app-level-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The body content of the template, in HTML format. (e.g. <p>Hello {{user.name}}, your booking has been confirmed.</p>)
  --engine: string@engine-completer # The templating engine to use. (e.g. mustache)
  --name: string # The name of the template. (e.g. Updated booking confirmed message)
  --subject: string # The subject line of the template. (e.g. {{user.name}}, your booking is confirmed!)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/($template_id)")
  let body = {body: $body_body, engine: $engine, name: $name, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /v3/templates/{template_id}
# operationId: delete-app-level-template
export def "templates delete-app-level-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Render template as HTML
#
# POST /v3/templates/render
# operationId: render-template-html
# --variables shape: {additionalProperties?: string}
export def "templates-render render-template-html" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The body content of the template, in HTML format. (e.g. <p>Hello {{user.name}}, this shows test was {{ foo }}.</p>)
  engine: string@engine-completer # The templating engine to use. (e.g. mustache)
  --strict: string@bool-completer # When `true`, Nylas returns an error if the template contains variables that aren't defined in the `variables` object. (default: true, e.g. true)
  --body-variables: record # A set of key/value pairs representing variables to substitute for values in the template. (e.g. {user: {name: Leyah, surname: Miller}, foo: testing successful}) — shape: {additionalProperties?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/templates/render")
  let body = {body: $body_body, engine: $engine, strict: $strict, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Render a template
#
# POST /v3/templates/{template_id}/render
# operationId: render-app-level-template
# --variables shape: {additionalProperties?: string}
export def "templates-render render-app-level-template" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strict: string@bool-completer # When `true`, Nylas returns an error if the template contains variables that aren't defined in the `variables` object. (default: true, e.g. true)
  --body-variables: record # A set of key/value pairs representing variables to substitute for values in the template. (e.g. {user: {name: Leyah, surname: Miller}}) — shape: {additionalProperties?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/($template_id)/render")
  let body = {strict: $strict, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all templates
#
# GET /v3/grants/{grant_id}/templates
# operationId: get-grant-level-templates
export def "grants-templates get-grant-level-templates" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to return. See [Pagination](/docs/reference/api/#pagination) for more information. (default: 50)
  --page-token: string # An identifier that specifies which page of data to return. You can get this value from the `next_cursor` response field. See [Pagination](/docs/reference/api/#pagination) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/grants/($grant_id)/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /v3/grants/{grant_id}/templates
# operationId: create-grant-level-template
export def "grants-templates create-grant-level-template" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The body content of the template, in HTML format. (e.g. <p>Hello {{user.name}}, your booking has been confirmed.</p>)
  --engine: string@engine-completer # The templating engine to use. (default: mustache, e.g. mustache)
  name: string # The name of the template. (e.g. Booking confirmed message)
  subject: string # The subject line of the template. (e.g. {{user.name}}, your booking is confirmed!)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/templates")
  let body = {body: $body_body, engine: $engine, name: $name, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a template
#
# GET /v3/grants/{grant_id}/templates/{template_id}
# operationId: get-grant-level-template
export def "grants-templates get-grant-level-template" [
  grant_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a template
#
# PUT /v3/grants/{grant_id}/templates/{template_id}
# operationId: update-grant-level-template
export def "grants-templates update-grant-level-template" [
  grant_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The body content of the template, in HTML format. (e.g. <p>Hello {{user.name}}, your booking has been confirmed.</p>)
  --engine: string@engine-completer # The templating engine to use. (e.g. mustache)
  --name: string # The name of the template. (e.g. Updated booking confirmed message)
  --subject: string # The subject line of the template. (e.g. {{user.name}}, your booking is confirmed!)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/templates/($template_id)")
  let body = {body: $body_body, engine: $engine, name: $name, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /v3/grants/{grant_id}/templates/{template_id}
# operationId: delete-grant-level-template
export def "grants-templates delete-grant-level-template" [
  grant_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Render a template
#
# POST /v3/grants/{grant_id}/templates/{template_id}/render
# operationId: render-grant-level-template
# --variables shape: {additionalProperties?: string}
export def "grants-templates-render render-grant-level-template" [
  grant_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --strict: string@bool-completer # When `true`, Nylas returns an error if the template contains variables that aren't defined in the `variables` object. (default: true, e.g. true)
  --body-variables: record # A set of key/value pairs representing variables to substitute for values in the template. (e.g. {user: {name: Leyah, surname: Miller}}) — shape: {additionalProperties?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/templates/($template_id)/render")
  let body = {strict: $strict, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Render template as HTML
#
# POST /v3/grants/{grant_id}/templates/render
# operationId: render-grant-level-template-html
# --variables shape: {additionalProperties?: string}
export def "grants-templates-render render-grant-level-template-html" [
  grant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The body content of the template, in HTML format. (e.g. <p>Hello {{user.name}}, this shows test was {{ foo }}.</p>)
  engine: string@engine-completer # The templating engine to use. (e.g. mustache)
  --strict: string@bool-completer # When `true`, Nylas returns an error if the template contains variables that aren't defined in the `variables` object. (default: true, e.g. true)
  --body-variables: record # A set of key/value pairs representing variables to substitute for values in the template. (e.g. {user: {name: Leyah, surname: Miller}, foo: testing successful}) — shape: {additionalProperties?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/grants/($grant_id)/templates/render")
  let body = {body: $body_body, engine: $engine, strict: $strict, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a transactional email
#
# POST /v3/domains/{domain_name}/messages/send
# operationId: send-transactional-email
# --attachments item shape: {content?: string, content_disposition?: string, content_id?: string, content_type?: string, filename?: string}
# --bcc item shape: {email?: string, name?: string}
# --cc item shape: {email?: string, name?: string}
# --custom_headers item shape: {name?: string, value?: string}
# --from shape: {email?: string, name?: string}
# --reply_to item shape: {name?: string, email?: string}
# --template shape: {id?: string, strict?: bool, variables?: record}
# --to item shape: {email?: string, name?: string}
# --tracking_options shape: {opens?: bool, links?: bool, label?: string}
export def "domains-messages-send send-transactional-email" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Idempotency-Key: string # A unique, client-generated key (max 256 characters) that lets you safely retry this send request without sending duplicate emails. Nylas caches the response (success or error) for 1 hour, scoped per Nylas application (not per domain -- a key collides across all verified domains under the same application). A retry with the same key and payload returns the cached response with the `Idempotent-Response: true` header set. See [Idempotent send requests](/docs/v3/email/idempotent-send/) for the full retry behavior and error responses. (e.g. f47ac10b-58cc-4372-a567-0e02b2c3d479)
  --attachments: list # An array of files to be sent with the message. — item shape: {content?: string, content_disposition?: string, content_id?: string, content_type?: string, filename?: string}
  --bcc: list # A list of people to be BCC'd on the message. — item shape: {email?: string, name?: string}
  --body-body: string # The HTML-formatted body of the message. (e.g. Looking forward to seeing you!)
  --cc: list # A list of people to be CC'd on the message. — item shape: {email?: string, name?: string}
  --custom-headers: list # An array of custom headers to add to the message. — item shape: {name?: string, value?: string}
  --body-from: record # Information about the person sending the message. — shape: {email?: string, name?: string}
  --is-plaintext: string@bool-completer # When `true`, Nylas sends the message body as plain text and the MIME data doesn't include an HTML version of the message. When `false`, Nylas sends the message body as HTML. (default: false, e.g. true)
  --metadata: record # The metadata associated with the object. For more information, see [Metadata](/docs/reference/api/#metadata).
  --reply-to: list # A list of people who should receive replies to the message by default. — item shape: {name?: string, email?: string}
  --reply-to-message-id: string # The ID of the message you are replying to. If you are using a message that was sent using Nylas' Transactional Send, you may use the ID that was returned in the Nylas response. For all other messages, this is the [RFC822](https://datatracker.ietf.org/doc/html/rfc822#section-4.6.1) `Message-ID` header of the message you're replying to.
  --send-at: int # The time when Nylas should send the message, in seconds using the Unix timestamp format. Must be at least one minute in the future from the time you make your request. You can schedule a message to be sent up to 30 days in the future.
  --subject: string # The subject line of the message. (e.g. Reminder: Annual Philosophy Club meeting)
  --template: record # The [template](/docs/reference/api/application-level-templates/) to use for the message. Can be overriden by the `body` and `subject` fields. — shape: {id?: string, strict?: bool, variables?: record}
  --body-to: list # A list of recipients for the message. — item shape: {email?: string, name?: string}
  --tracking-options: record # Tracking settings for the message. See [Track messages](/docs/v3/email/message-tracking/). — shape: {opens?: bool, links?: bool, label?: string}
]: any -> record<data: record<id: string, attachments: list<record>, bcc: list<record>, body: string, cc: list<record>, from: list<record>, object: string, reply_to: list<record>, snippet: string, subject: string, tracking_options: record<opens: bool, links: bool, label: string>, to: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/domains/($domain_name)/messages/send")
  let body = {attachments: $attachments, bcc: $bcc, body: $body_body, cc: $cc, custom_headers: $custom_headers, from: $body_from, is_plaintext: $is_plaintext, metadata: $metadata, reply_to: $reply_to, reply_to_message_id: $reply_to_message_id, send_at: $send_at, subject: $subject, template: $template, to: $body_to, tracking_options: $tracking_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
