# Auto-generated client for Cal.diy API v2 v1.0.0
# Source: https://raw.githubusercontent.com/calcom/cal.com/main/docs/api-reference/v2/openapi.json
# Auth: --token flag or $env.CAL_DIY_API_V2_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CAL_DIY_API_V2_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sortStart-completer [] { ["asc" "desc"] }
def sortEnd-completer [] { ["asc" "desc"] }
def sortCreated-completer [] { ["asc" "desc"] }
def sortUpdatedAt-completer [] { ["asc" "desc"] }
def type-completer [] { ["daily_video" "google_calendar" "google_video" "office365_calendar" "office365_video" "zoom_video"] }
def language-completer [] { ["ar" "az" "bg" "bn" "ca" "cs" "da" "de" "el" "en" "es" "es-419" "et" "eu" "fi" "fr" "he" "hr" "hu" "id" "it" "iw" "ja" "km" "ko" "lv" "nl" "no" "pl" "pt" "pt-BR" "ro" "ru" "sk" "sr" "sv" "ta" "th" "tr" "uk" "vi" "zh-CN" "zh-TW"] }
def status-completer [] { ["accepted" "cancelled" "declined" "pending"] }
def timeFormat-completer [] { ["12" "24"] }
def weekStart-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Tuesday" "Wednesday"] }
def locale-completer [] { ["ar" "az" "bg" "bn" "ca" "cs" "da" "de" "el" "en" "es" "es-419" "et" "eu" "fi" "fr" "he" "hr" "hu" "id" "it" "iw" "ja" "km" "ko" "lv" "nl" "no" "pl" "pt" "pt-BR" "ro" "ru" "sk" "sr" "sv" "ta" "th" "tr" "uk" "vi" "zh-CN" "zh-TW"] }
def version-completer [] { ["2021-10-20"] }
def integration-completer [] { ["apple_calendar" "google_calendar" "office365_calendar"] }
def interfaceLanguage-completer [] { ["" "ar" "az" "bg" "bn" "ca" "cs" "da" "de" "el" "en" "es" "es-419" "et" "eu" "fi" "fr" "he" "hu" "it" "ja" "km" "ko" "nl" "no" "pl" "pt" "pt-BR" "ro" "ru" "sk-SK" "sr" "sv" "tr" "uk" "vi" "zh-CN" "zh-TW"] }
def sortCreatedAt-completer [] { ["asc" "desc"] }
def grant-type-completer [] { ["authorization_code"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-keys-refresh refresh" } } | get name | first)
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

# Refresh API Key
#
# POST /v2/api-keys/refresh
# operationId: ApiKeysController_refresh
export def "api-keys-refresh refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
  --apiKeyDaysValid: float # For how many days is managed organization api key valid. Defaults to 30 days. (default: 30, e.g. 60)
  --apiKeyNeverExpires: oneof<nothing, bool> # If true, organization api key never expires. (e.g. true)
]: any -> record<status: string, data: record<apiKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/api-keys/refresh")
  let body = {apiKeyDaysValid: $apiKeyDaysValid, apiKeyNeverExpires: $apiKeyNeverExpires} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a booking
#
# POST /v2/bookings
# operationId: BookingsController_2024_08_13_createBooking
@deprecated --flag meetingUrl
export def "bookings createBooking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --x-cal-secret-key: string # For platform customers - OAuth client secret key
  --x-cal-client-id: string # For platform customers - OAuth client ID
  --start: string # The start time of the booking in ISO 8601 format in UTC timezone. (e.g. 2024-08-13T09:00:00Z)
  --attendee: any # The attendee's details.
  --bookingFieldsResponses: record # Booking field responses consisting of an object with booking field slug as keys and user response as values for custom booking fields added by you. (e.g. {customField: customValue})
  --eventTypeId: float # The ID of the event type that is booked. Required unless eventTypeSlug and username are provided as an alternative to identifying the event type. (e.g. 123)
  --eventTypeSlug: string # The slug of the event type. Required along with username / teamSlug and optionally organizationSlug if eventTypeId is not provided. (e.g. my-event-type)
  --username: string # The username of the event owner. Required along with eventTypeSlug and optionally organizationSlug if eventTypeId is not provided. (e.g. john-doe)
  --teamSlug: string # Team slug for team that owns event type for which slots are fetched. Required along with eventTypeSlug and optionally organizationSlug if the team is part of organization (e.g. john-doe)
  --organizationSlug: string # The organization slug. Optional, only used when booking with eventTypeSlug + username or eventTypeSlug + teamSlug. (e.g. acme-corp)
  --guests: list # An optional list of guest emails attending the event. (e.g. [guest1@example.com, guest2@example.com])
  --meetingUrl: string # Deprecated - use 'location' instead. Meeting URL just for this booking. Displayed in email and calendar event. If not provided then cal video link will be generated. (DEPRECATED, e.g. https://example.com/meeting)
  --location: any # One of the event type locations. If instead of passing one of the location objects as required by schema you are still passing a string please use an object.
  --metadata: record # You can store any additional data you want here. Metadata must have at most 50 keys, each key up to 40 characters, and string values up to 500 characters. (e.g. {key: value})
  --lengthInMinutes: float # If it is an event type that has multiple possible lengths that attendee can pick from, you can pass the desired booking length here.     If not provided then event type default length will be used for the booking. (e.g. 30)
  --routing: any # Routing information from routing forms that determined the booking assignment. Both responseId and teamMemberIds are required if provided. (e.g. {responseId: 123, teamMemberIds: [101, 102]})
  --emailVerificationCode: string # Email verification code required when event type has email verification enabled. (e.g. 123456)
  --recurrenceCount: float # The number of recurrences. If not provided then event type recurrence count will be used. Can't be more than     event type recurrence count (e.g. 5)
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bookings")
  let body = {start: $start, attendee: $attendee, bookingFieldsResponses: $bookingFieldsResponses, eventTypeId: $eventTypeId, eventTypeSlug: $eventTypeSlug, username: $username, teamSlug: $teamSlug, organizationSlug: $organizationSlug, guests: $guests, meetingUrl: $meetingUrl, location: $location, metadata: $metadata, lengthInMinutes: $lengthInMinutes, routing: $routing, emailVerificationCode: $emailVerificationCode, recurrenceCount: $recurrenceCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization, "x-cal-secret-key": $x_cal_secret_key, "x-cal-client-id": $x_cal_client_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all bookings
#
# GET /v2/bookings
# operationId: BookingsController_2024_08_13_getBookings
export def "bookings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Filter bookings by status. If you want to filter by multiple statuses, separate them with a comma. (e.g. ?status=upcoming,past)
  --attendeeEmail: string # Filter bookings by the attendee's email address. (e.g. example@domain.com)
  --attendeeName: string # Filter bookings by the attendee's name. (e.g. John Doe)
  --bookingUid: string # Filter bookings by the booking Uid. (e.g. 2NtaeaVcKfpmSZ4CthFdfk)
  --eventTypeIds: string # Filter bookings by event type ids belonging to the user. Event type ids must be separated by a comma. (e.g. ?eventTypeIds=100,200)
  --eventTypeId: string # Filter bookings by event type id belonging to the user. (e.g. ?eventTypeId=100)
  --teamsIds: string # Filter bookings by team ids that user is part of. Team ids must be separated by a comma. (e.g. ?teamIds=50,60)
  --teamId: string # Filter bookings by team id that user is part of (e.g. ?teamId=50)
  --afterStart: string # Filter bookings with start after this date string. (e.g. ?afterStart=2025-03-07T10:00:00.000Z)
  --beforeEnd: string # Filter bookings with end before this date string. (e.g. ?beforeEnd=2025-03-07T11:00:00.000Z)
  --afterCreatedAt: string # Filter bookings that have been created after this date string. (e.g. ?afterCreatedAt=2025-03-07T10:00:00.000Z)
  --beforeCreatedAt: string # Filter bookings that have been created before this date string. (e.g. ?beforeCreatedAt=2025-03-14T11:00:00.000Z)
  --afterUpdatedAt: string # Filter bookings that have been updated after this date string. (e.g. ?afterUpdatedAt=2025-03-07T10:00:00.000Z)
  --beforeUpdatedAt: string # Filter bookings that have been updated before this date string. (e.g. ?beforeUpdatedAt=2025-03-14T11:00:00.000Z)
  --sortStart: string@sortStart-completer # Sort results by their start time in ascending or descending order. (e.g. ?sortStart=asc OR ?sortStart=desc)
  --sortEnd: string@sortEnd-completer # Sort results by their end time in ascending or descending order. (e.g. ?sortEnd=asc OR ?sortEnd=desc)
  --sortCreated: string@sortCreated-completer # Sort results by their creation time (when booking was made) in ascending or descending order. (e.g. ?sortCreated=asc OR ?sortCreated=desc)
  --sortUpdatedAt: string@sortUpdatedAt-completer # Sort results by their updated time (for example when booking status changes) in ascending or descending order. (e.g. ?sortUpdated=asc OR ?sortUpdated=desc)
  --take: float # The number of items to return (default: 100, e.g. 10)
  --skip: float # The number of items to skip (default: 0, e.g. 0)
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: list<any>, pagination: record<totalItems: float, remainingItems: float, returnedItems: float, itemsPerPage: float, currentPage: float, totalPages: float, hasNextPage: bool, hasPreviousPage: bool>, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "attendeeEmail" $attendeeEmail "scalar") (serialize-qp "attendeeName" $attendeeName "scalar") (serialize-qp "bookingUid" $bookingUid "scalar") (serialize-qp "eventTypeIds" $eventTypeIds "scalar") (serialize-qp "eventTypeId" $eventTypeId "scalar") (serialize-qp "teamsIds" $teamsIds "scalar") (serialize-qp "teamId" $teamId "scalar") (serialize-qp "afterStart" $afterStart "scalar") (serialize-qp "beforeEnd" $beforeEnd "scalar") (serialize-qp "afterCreatedAt" $afterCreatedAt "scalar") (serialize-qp "beforeCreatedAt" $beforeCreatedAt "scalar") (serialize-qp "afterUpdatedAt" $afterUpdatedAt "scalar") (serialize-qp "beforeUpdatedAt" $beforeUpdatedAt "scalar") (serialize-qp "sortStart" $sortStart "scalar") (serialize-qp "sortEnd" $sortEnd "scalar") (serialize-qp "sortCreated" $sortCreated "scalar") (serialize-qp "sortUpdatedAt" $sortUpdatedAt "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bookings" $qp)
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a booking by seat UID
#
# GET /v2/bookings/by-seat/{seatUid}
# operationId: BookingsController_2024_08_13_getBookingBySeatUid
export def "bookings-by-seat get" [
  seatUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --x-cal-secret-key: string # For platform customers - OAuth client secret key
  --x-cal-client-id: string # For platform customers - OAuth client ID
]: nothing -> record<status: string, data: any, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/by-seat/($seatUid)")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization, "x-cal-secret-key": $x_cal_secret_key, "x-cal-client-id": $x_cal_client_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a booking
#
# GET /v2/bookings/{bookingUid}
# operationId: BookingsController_2024_08_13_getBooking
export def "bookings get" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --x-cal-secret-key: string # For platform customers - OAuth client secret key
  --x-cal-client-id: string # For platform customers - OAuth client ID
]: nothing -> record<status: string, data: any, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization, "x-cal-secret-key": $x_cal_secret_key, "x-cal-client-id": $x_cal_client_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the recordings for the booking
#
# GET /v2/bookings/{bookingUid}/recordings
# operationId: BookingsController_2024_08_13_getBookingRecordings
export def "bookings-recordings get" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, error: record, data: table<id: string, roomName: string, startTs: float, status: string, maxParticipants: float, duration: float, shareToken: string, downloadLink: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/recordings")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Cal Video real time transcript download links for the booking
#
# GET /v2/bookings/{bookingUid}/transcripts
# operationId: BookingsController_2024_08_13_getBookingTranscripts
export def "bookings-transcripts get" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: list<string>, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/transcripts")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reschedule a booking
#
# POST /v2/bookings/{bookingUid}/reschedule
# operationId: BookingsController_2024_08_13_rescheduleBooking
export def "bookings-reschedule rescheduleBooking" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --x-cal-secret-key: string # For platform customers - OAuth client secret key
  --x-cal-client-id: string # For platform customers - OAuth client ID
  --start: string # The start time of the booking in ISO 8601 format in UTC timezone. (e.g. 2024-08-13T09:00:00Z)
  --rescheduledBy: string # Email of the person who is rescheduling the booking - only needed when rescheduling a booking that requires a confirmation. If event type owner email is provided then rescheduled booking will be automatically confirmed. If attendee email or no email is passed then the event type owner will have to confirm the rescheduled booking.
  --reschedulingReason: string # Reason for rescheduling the booking (e.g. User requested reschedule)
  --emailVerificationCode: string # Email verification code required when event type has email verification enabled. (e.g. 123456)
  --seatUid: string # Uid of the specific seat within booking. (e.g. 3be561a9-31f1-4b8e-aefc-9d9a085f0dd1)
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/reschedule")
  let body = {start: $start, rescheduledBy: $rescheduledBy, reschedulingReason: $reschedulingReason, emailVerificationCode: $emailVerificationCode, seatUid: $seatUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization, "x-cal-secret-key": $x_cal_secret_key, "x-cal-client-id": $x_cal_client_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a booking
#
# POST /v2/bookings/{bookingUid}/cancel
# operationId: BookingsController_2024_08_13_cancelBooking
export def "bookings-cancel cancelBooking" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --x-cal-secret-key: string # For platform customers - OAuth client secret key
  --x-cal-client-id: string # For platform customers - OAuth client ID
  --cancellationReason: string # e.g. User requested cancellation
  --cancelSubsequentBookings: oneof<nothing, bool> # For recurring non-seated booking only - if true, cancel booking with the bookingUid of the individual recurrence and all recurrences that come after it.
  --seatUid: string # Uid of the specific seat within booking. (e.g. 3be561a9-31f1-4b8e-aefc-9d9a085f0dd1)
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/cancel")
  let body = {cancellationReason: $cancellationReason, cancelSubsequentBookings: $cancelSubsequentBookings, seatUid: $seatUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization, "x-cal-secret-key": $x_cal_secret_key, "x-cal-client-id": $x_cal_client_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark a booking absence
#
# POST /v2/bookings/{bookingUid}/mark-absent
# operationId: BookingsController_2024_08_13_markNoShow
# --attendees item shape: {email: string, absent: bool}
export def "bookings-mark-absent markNoShow" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --host: oneof<nothing, bool> # Whether the host was absent (e.g. false)
  --attendees: list # item shape: {email: string, absent: bool}
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/mark-absent")
  let body = {host: $host, attendees: $attendees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reassign a booking to auto-selected host
#
# POST /v2/bookings/{bookingUid}/reassign
# operationId: BookingsController_2024_08_13_reassignBooking
export def "bookings-reassign reassignBooking" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<status: string, data: record<status: string, data: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/reassign")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reassign a booking to a specific host
#
# POST /v2/bookings/{bookingUid}/reassign/{userId}
# operationId: BookingsController_2024_08_13_reassignBookingToUser
export def "bookings-reassign reassignBookingToUser" [
  bookingUid: string
  userId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --reason: string # Reason for reassigning the booking (e.g. Host has to take another call)
]: any -> record<status: string, data: record<status: string, data: record<status: string, data: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/reassign/($userId)")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Confirm a booking
#
# POST /v2/bookings/{bookingUid}/confirm
# operationId: BookingsController_2024_08_13_confirmBooking
export def "bookings-confirm confirmBooking" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: any, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/confirm")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Decline a booking
#
# POST /v2/bookings/{bookingUid}/decline
# operationId: BookingsController_2024_08_13_declineBooking
export def "bookings-decline declineBooking" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --reason: string # Reason for declining a booking that requires a confirmation (e.g. Host has to take another call)
]: any -> record<status: string, data: any, error: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/decline")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get 'Add to Calendar' links for a booking
#
# GET /v2/bookings/{bookingUid}/calendar-links
# operationId: BookingsController_2024_08_13_getCalendarLinks
export def "bookings-calendar-links get" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: record, data: table<label: string, link: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/calendar-links")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get booking references
#
# GET /v2/bookings/{bookingUid}/references
# operationId: BookingsController_2024_08_13_getBookingReferences
export def "bookings-references get" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Filter booking references by type (e.g. google_calendar)
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: record, data: table<type: string, eventUid: string, destinationCalendarId: string, id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/references" $qp)
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video Meeting Sessions. Only supported for Cal Video
#
# GET /v2/bookings/{bookingUid}/conferencing-sessions
# operationId: BookingsController_2024_08_13_getVideoSessions
export def "bookings-conferencing-sessions get" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<id: string, room: string, startTime: float, duration: float, ongoing: bool, maxParticipants: float, participants: list>, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/conferencing-sessions")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update booking location for an existing booking
#
# PATCH /v2/bookings/{bookingUid}/location
# operationId: BookingLocationController_2024_08_13_updateBookingLocation
export def "bookings-location updateBookingLocation" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. This header is required as this endpoint does not exist in older API versions.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --location: any # One of the event type locations. If instead of passing one of the location objects as required by schema you are still passing a string please use an object.
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/location")
  let body = {location: $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all attendees for a booking
#
# GET /v2/bookings/{bookingUid}/attendees
# operationId: BookingAttendeesController_2024_08_13_getBookingAttendees
export def "bookings-attendees list" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. This header is required as this endpoint does not exist in older API versions.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<name: string, email: string, displayEmail: string, timeZone: string, language: string, absent: bool, phoneNumber: string, id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/attendees")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an attendee to a booking
#
# POST /v2/bookings/{bookingUid}/attendees
# operationId: BookingAttendeesController_2024_08_13_addAttendee
export def "bookings-attendees addAttendee" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. This header is required as this endpoint does not exist in older API versions.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  name: string # The name of the attendee. (e.g. John Doe)
  timeZone: string # The time zone of the attendee. (e.g. America/New_York)
  --phoneNumber: string # The phone number of the attendee in international format. (e.g. +919876543210)
  --language: string@language-completer # The preferred language of the attendee. Used for booking confirmation. (default: en, e.g. it)
  email: string # The email of the attendee. (e.g. john.doe@example.com)
]: any -> record<status: string, data: record<name: string, email: string, displayEmail: string, timeZone: string, language: string, absent: bool, phoneNumber: string, id: float, bookingId: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/attendees")
  let body = {name: $name, timeZone: $timeZone, phoneNumber: $phoneNumber, language: $language, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific attendee for a booking
#
# GET /v2/bookings/{bookingUid}/attendees/{attendeeId}
# operationId: BookingAttendeesController_2024_08_13_getBookingAttendee
export def "bookings-attendees get" [
  bookingUid: string
  attendeeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. This header is required as this endpoint does not exist in older API versions.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<name: string, email: string, displayEmail: string, timeZone: string, language: string, absent: bool, phoneNumber: string, id: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/attendees/($attendeeId)")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an attendee from a booking
#
# DELETE /v2/bookings/{bookingUid}/attendees/{attendeeId}
# operationId: BookingAttendeesController_2024_08_13_removeAttendee
export def "bookings-attendees removeAttendee" [
  bookingUid: string
  attendeeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. This header is required as this endpoint does not exist in older API versions.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<id: float, bookingId: float, name: string, email: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/attendees/($attendeeId)")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add guests to an existing booking
#
# POST /v2/bookings/{bookingUid}/guests
# operationId: BookingGuestsController_2024_08_13_addGuests
# --guests item shape: {email: string, name?: string, timeZone?: string, phoneNumber?: string, language?: "ar"|"ca"|"de"|"es"|"eu"|"he"|"id"|"ja"|"lv"|"pl"|"ro"|"sr"|"th"|"vi"|"az"|"cs"|"el"|"es-419"|"fi"|"hr"|"it"|"km"|"nl"|"pt"|"ru"|"sv"|"tr"|"zh-CN"|"bg"|"da"|"en"|"et"|"fr"|"hu"|"iw"|"ko"|"no"|"pt-BR"|"sk"|"ta"|"uk"|"zh-TW"|"bn"}
export def "bookings-guests addGuests" [
  bookingUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-08-13. This header is required as this endpoint does not exist in older API versions.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  guests: list # Array of guests to add to the booking. Maximum 10 guests per request. (e.g. [{email: john.doe@example.com, name: John Doe, timeZone: America/New_York}, {email: jane.smith@example.com, name: Jane Smith}]) — item shape: {email: string, name?: string, timeZone?: string, phoneNumber?: string, language?: "ar"|"ca"|"de"|"es"|"eu"|"he"|"id"|"ja"|"lv"|"pl"|"ro"|"sr"|"th"|"vi"|"az"|"cs"|"el"|"es-419"|"fi"|"hr"|"it"|"km"|"nl"|"pt"|"ru"|"sv"|"tr"|"zh-CN"|"bg"|"da"|"en"|"et"|"fr"|"hu"|"iw"|"ko"|"no"|"pt-BR"|"sk"|"ta"|"uk"|"zh-TW"|"bn"}
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bookings/($bookingUid)/guests")
  let body = {guests: $guests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List calendar connections
#
# GET /v2/calendars/connections
# operationId: CalUnifiedCalendarsController_listConnections
export def "calendars-connections listConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<connections: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/calendars/connections")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List events for a connection
#
# GET /v2/calendars/connections/{connectionId}/events
# operationId: CalUnifiedCalendarsController_listConnectionEvents
export def "calendars-connections-events listConnectionEvents" [
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start of the date range (ISO 8601 date or date-time) (e.g. 2026-03-01)
  --qp-to: string # End of the date range (ISO 8601 date or date-time) (e.g. 2026-03-31)
  --timeZone: string # IANA time zone for the request (e.g. America/New_York)
  --calendarId: string # Calendar ID. Use 'primary' for the user's primary calendar, or the external ID of a connected calendar. (default: primary)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<start: record, end: record, id: string, title: string, description: string, locations: list, attendees: list, status: string, hosts: list, calendarEventOwner: record, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "timeZone" $timeZone "scalar") (serialize-qp "calendarId" $calendarId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/connections/($connectionId)/events" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create event on a connection
#
# POST /v2/calendars/connections/{connectionId}/events
# operationId: CalUnifiedCalendarsController_createConnectionEvent
# --attendees item shape: {email: string, name?: string}
export def "calendars-connections-events createConnectionEvent" [
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendarId: string
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  title: string # Title of the calendar event
  start: any # Start date and time with time zone
  end: any # End date and time with time zone
  --description: string # Description of the event (nullable)
  --attendees: list # List of attendees — item shape: {email: string, name?: string}
]: any -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendarId" $calendarId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/connections/($connectionId)/events" $qp)
  let body = {title: $title, start: $start, end: $end, description: $description, attendees: $attendees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get event for a connection
#
# GET /v2/calendars/connections/{connectionId}/events/{eventId}
# operationId: CalUnifiedCalendarsController_getConnectionEvent
export def "calendars-connections-events get" [
  connectionId: string
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendarId: string
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendarId" $calendarId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/connections/($connectionId)/events/($eventId)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update event for a connection
#
# PATCH /v2/calendars/connections/{connectionId}/events/{eventId}
# operationId: CalUnifiedCalendarsController_updateConnectionEvent
# --start shape: {time?: string, timeZone?: string}
# --end shape: {time?: string, timeZone?: string}
# --attendees item shape: {email?: string, name?: string, responseStatus?: "accepted"|"pending"|"declined"|"needsAction", self?: bool, optional?: bool, host?: bool}
export def "calendars-connections-events updateConnectionEvent" [
  connectionId: string
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendarId: string
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --start: record # Start date and time of the calendar event with timezone information — shape: {time?: string, timeZone?: string}
  --end: record # End date and time of the calendar event with timezone information — shape: {time?: string, timeZone?: string}
  --title: string # Title of the calendar event
  --description: string # Detailed description of the calendar event (nullable)
  --attendees: list # List of attendees. CAUTION: You must pass the entire array with all updated values. Any attendees not included in this array will be removed from the event. (nullable) — item shape: {email?: string, name?: string, responseStatus?: "accepted"|"pending"|"declined"|"needsAction", self?: bool, optional?: bool, host?: bool}
  --status: string@status-completer # Status of the event (accepted, pending, declined, cancelled)
]: any -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendarId" $calendarId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/connections/($connectionId)/events/($eventId)" $qp)
  let body = {start: $start, end: $end, title: $title, description: $description, attendees: $attendees, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete event for a connection
#
# DELETE /v2/calendars/connections/{connectionId}/events/{eventId}
# operationId: CalUnifiedCalendarsController_deleteConnectionEvent
export def "calendars-connections-events delete" [
  connectionId: string
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendarId: string
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "calendarId" $calendarId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/connections/($connectionId)/events/($eventId)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get free/busy for a connection
#
# GET /v2/calendars/connections/{connectionId}/freebusy
# operationId: CalUnifiedCalendarsController_getConnectionFreeBusy
export def "calendars-connections-freebusy get" [
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start of the date range (ISO 8601 date or date-time) (e.g. 2026-03-10)
  --qp-to: string # End of the date range (ISO 8601 date or date-time) (e.g. 2026-03-10)
  --timeZone: string # IANA time zone (e.g. America/New_York)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<start: string, end: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "timeZone" $timeZone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/connections/($connectionId)/freebusy" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get meeting details from calendar
#
# GET /v2/calendars/{calendar}/events/{eventUid}
# operationId: CalUnifiedCalendarsController_getCalendarEventDetails
export def "calendars-events get" [
  calendar: string
  eventUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/events/($eventUid)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update meeting details in calendar
#
# PATCH /v2/calendars/{calendar}/events/{eventUid}
# operationId: CalUnifiedCalendarsController_updateCalendarEvent
# --start shape: {time?: string, timeZone?: string}
# --end shape: {time?: string, timeZone?: string}
# --attendees item shape: {email?: string, name?: string, responseStatus?: "accepted"|"pending"|"declined"|"needsAction", self?: bool, optional?: bool, host?: bool}
export def "calendars-events updateCalendarEvent" [
  calendar: string
  eventUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --start: record # Start date and time of the calendar event with timezone information — shape: {time?: string, timeZone?: string}
  --end: record # End date and time of the calendar event with timezone information — shape: {time?: string, timeZone?: string}
  --title: string # Title of the calendar event
  --description: string # Detailed description of the calendar event (nullable)
  --attendees: list # List of attendees. CAUTION: You must pass the entire array with all updated values. Any attendees not included in this array will be removed from the event. (nullable) — item shape: {email?: string, name?: string, responseStatus?: "accepted"|"pending"|"declined"|"needsAction", self?: bool, optional?: bool, host?: bool}
  --status: string@status-completer # Status of the event (accepted, pending, declined, cancelled)
]: any -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/events/($eventUid)")
  let body = {start: $start, end: $end, title: $title, description: $description, attendees: $attendees, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a calendar event
#
# DELETE /v2/calendars/{calendar}/events/{eventUid}
# operationId: CalUnifiedCalendarsController_deleteCalendarEvent
export def "calendars-events delete" [
  calendar: string
  eventUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/events/($eventUid)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get meeting details from calendar
#
# GET /v2/calendars/{calendar}/event/{eventUid}
# operationId: CalUnifiedCalendarsController_getCalendarEventDetails
export def "calendars-event get" [
  calendar: string
  eventUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/event/($eventUid)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update meeting details in calendar
#
# PATCH /v2/calendars/{calendar}/event/{eventUid}
# operationId: CalUnifiedCalendarsController_updateCalendarEvent
# --start shape: {time?: string, timeZone?: string}
# --end shape: {time?: string, timeZone?: string}
# --attendees item shape: {email?: string, name?: string, responseStatus?: "accepted"|"pending"|"declined"|"needsAction", self?: bool, optional?: bool, host?: bool}
export def "calendars-event updateCalendarEvent" [
  calendar: string
  eventUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --start: record # Start date and time of the calendar event with timezone information — shape: {time?: string, timeZone?: string}
  --end: record # End date and time of the calendar event with timezone information — shape: {time?: string, timeZone?: string}
  --title: string # Title of the calendar event
  --description: string # Detailed description of the calendar event (nullable)
  --attendees: list # List of attendees. CAUTION: You must pass the entire array with all updated values. Any attendees not included in this array will be removed from the event. (nullable) — item shape: {email?: string, name?: string, responseStatus?: "accepted"|"pending"|"declined"|"needsAction", self?: bool, optional?: bool, host?: bool}
  --status: string@status-completer # Status of the event (accepted, pending, declined, cancelled)
]: any -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/event/($eventUid)")
  let body = {start: $start, end: $end, title: $title, description: $description, attendees: $attendees, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List calendar events
#
# GET /v2/calendars/{calendar}/events
# operationId: CalUnifiedCalendarsController_listCalendarEvents
export def "calendars-events listCalendarEvents" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start of the date range (ISO 8601 date or date-time) (e.g. 2026-03-01)
  --qp-to: string # End of the date range (ISO 8601 date or date-time) (e.g. 2026-03-31)
  --timeZone: string # IANA time zone for the request (e.g. America/New_York)
  --calendarId: string # Calendar ID. Use 'primary' for the user's primary calendar, or the external ID of a connected calendar. (default: primary)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<start: record, end: record, id: string, title: string, description: string, locations: list, attendees: list, status: string, hosts: list, calendarEventOwner: record, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "timeZone" $timeZone "scalar") (serialize-qp "calendarId" $calendarId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/($calendar)/events" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a calendar event
#
# POST /v2/calendars/{calendar}/events
# operationId: CalUnifiedCalendarsController_createCalendarEvent
# --attendees item shape: {email: string, name?: string}
export def "calendars-events createCalendarEvent" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  title: string # Title of the calendar event
  start: any # Start date and time with time zone
  end: any # End date and time with time zone
  --description: string # Description of the event (nullable)
  --attendees: list # List of attendees — item shape: {email: string, name?: string}
]: any -> record<status: string, data: record<start: record<time: string, timeZone: string>, end: record<time: string, timeZone: string>, id: string, title: string, description: string, locations: list<any>, attendees: list<record>, status: string, hosts: list<record>, calendarEventOwner: record<email: string, name: string>, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/events")
  let body = {title: $title, start: $start, end: $end, description: $description, attendees: $attendees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get free/busy times
#
# GET /v2/calendars/{calendar}/freebusy
# operationId: CalUnifiedCalendarsController_getFreeBusy
export def "calendars-freebusy get" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start of the date range (ISO 8601 date or date-time) (e.g. 2026-03-10)
  --qp-to: string # End of the date range (ISO 8601 date or date-time) (e.g. 2026-03-10)
  --timeZone: string # IANA time zone (e.g. America/New_York)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<start: string, end: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "timeZone" $timeZone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/($calendar)/freebusy" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save an ICS feed
#
# POST /v2/calendars/ics-feed/save
# operationId: CalendarsController_createIcsFeed
export def "calendars-ics-feed-save createIcsFeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  urls: list # An array of ICS URLs (e.g. [https://cal.com/ics/feed.ics, http://cal.com/ics/feed.ics])
  --readOnly: oneof<nothing, bool> # Whether to allowing writing to the calendar or not (default: true, e.g. false)
]: any -> record<status: string, data: record<id: float, type: string, userId: int, teamId: int, appId: string, invalid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/calendars/ics-feed/save")
  let body = {urls: $urls, readOnly: $readOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check an ICS feed
#
# GET /v2/calendars/ics-feed/check
# operationId: CalendarsController_checkIcsFeed
export def "calendars-ics-feed-check checkIcsFeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/calendars/ics-feed/check")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get busy times
#
# GET /v2/calendars/busy-times
# operationId: CalendarsController_getBusyTimes
@deprecated --flag loggedInUsersTz
export def "calendars-busy-times get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loggedInUsersTz: string # Deprecated: Use timeZone instead. The timezone of the user represented as a string (DEPRECATED, e.g. America/New_York)
  --timeZone: string # The timezone for the busy times query represented as a string (e.g. America/New_York)
  --dateFrom: string # The starting date for the busy times query (e.g. 2023-10-01)
  --dateTo: string # The ending date for the busy times query (e.g. 2023-10-31)
  --credentialId: float
  --externalId: string
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<start: string, end: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loggedInUsersTz" $loggedInUsersTz "scalar") (serialize-qp "timeZone" $timeZone "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "credentialId" $credentialId "scalar") (serialize-qp "externalId" $externalId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/calendars/busy-times" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all calendars
#
# GET /v2/calendars
# operationId: CalendarsController_getCalendars
export def "calendars get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<connectedCalendars: list<record>, destinationCalendar: record<id: record, integration: string, externalId: string, primaryEmail: string, userId: float, eventTypeId: float, credentialId: float, delegationCredentialId: string, name: string, primary: bool, readOnly: bool, email: string, integrationTitle: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/calendars")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OAuth connect URL
#
# GET /v2/calendars/{calendar}/connect
# operationId: CalendarsController_redirect
export def "calendars-connect redirect" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isDryRun: oneof<nothing, bool>
  --redir: string # Redirect URL after successful calendar authorization.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isDryRun" $isDryRun "scalar") (serialize-qp "redir" $redir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/($calendar)/connect" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save Google or Outlook calendar credentials
#
# GET /v2/calendars/{calendar}/save
# operationId: CalendarsController_save
export def "calendars-save save" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string
  --code: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/calendars/($calendar)/save" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save Apple calendar credentials
#
# POST /v2/calendars/{calendar}/credentials
# operationId: CalendarsController_syncCredentials
export def "calendars-credentials syncCredentials" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  username: string
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/credentials")
  let body = {username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check a calendar connection
#
# GET /v2/calendars/{calendar}/check
# operationId: CalendarsController_check
export def "calendars-check check" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/check")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disconnect a calendar
#
# POST /v2/calendars/{calendar}/disconnect
# operationId: CalendarsController_deleteCalendarCredentials
export def "calendars-disconnect post" [
  calendar: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  id: int # Credential ID of the calendar to delete, as returned by the /calendars endpoint (e.g. 10)
]: any -> record<status: string, data: record<id: float, type: string, userId: float, teamId: float, appId: string, invalid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/calendars/($calendar)/disconnect")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Connect your conferencing application
#
# POST /v2/conferencing/{app}/connect
# operationId: ConferencingController_connect
export def "conferencing-connect connect" [
  app: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<id: float, type: string, userId: float, invalid: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/conferencing/($app)/connect")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OAuth conferencing app auth URL
#
# GET /v2/conferencing/{app}/oauth/auth-url
# operationId: ConferencingController_redirect
export def "conferencing-oauth-auth-url redirect" [
  app: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --returnTo: string
  --onErrorReturnTo: string
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnTo" $returnTo "scalar") (serialize-qp "onErrorReturnTo" $onErrorReturnTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/conferencing/($app)/oauth/auth-url" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Conferencing app OAuth callback
#
# GET /v2/conferencing/{app}/oauth/callback
# operationId: ConferencingController_save
export def "conferencing-oauth-callback save" [
  app: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string
  --code: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/conferencing/($app)/oauth/callback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List your conferencing applications
#
# GET /v2/conferencing
# operationId: ConferencingController_listInstalledConferencingApps
export def "conferencing listInstalledConferencingApps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<id: float, type: string, userId: float, invalid: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/conferencing")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set your default conferencing application
#
# POST /v2/conferencing/{app}/default
# operationId: ConferencingController_default
export def "conferencing-default default" [
  app: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/conferencing/($app)/default")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get your default conferencing application
#
# GET /v2/conferencing/default
# operationId: ConferencingController_getDefault
export def "conferencing-default get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<appSlug: string, appLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/conferencing/default")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disconnect your conferencing application
#
# DELETE /v2/conferencing/{app}/disconnect
# operationId: ConferencingController_disconnect
export def "conferencing-disconnect disconnect" [
  app: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/conferencing/($app)/disconnect")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all managed users
#
# GET /v2/oauth-clients/{clientId}/users
# operationId: OAuthClientUsersController_getManagedUsers
export def "oauth-clients-users list" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # The number of items to return (e.g. 10)
  --offset: float # The number of items to skip (e.g. 0)
  --emails: list # Filter managed users by email. If you want to filter by multiple emails, separate them with a comma. (e.g. ?emails=email1@example.com,email2@example.com)
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: table<id: float, email: string, username: string, name: string, bio: string, timeZone: string, weekStart: string, createdDate: string, timeFormat: float, defaultScheduleId: float, locale: string, avatarUrl: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "emails" $emails "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/users" $qp)
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a managed user
#
# POST /v2/oauth-clients/{clientId}/users
# operationId: OAuthClientUsersController_createUser
export def "oauth-clients-users createUser" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
  email: string # e.g. alice@example.com
  name: string # Managed user's name is used in emails (e.g. Alice Smith)
  --timeFormat: float@timeFormat-completer # Must be a number 12 or 24 (e.g. 12)
  --weekStart: string@weekStart-completer # e.g. Monday
  --timeZone: string # Timezone is used to create user's default schedule from Monday to Friday from 9AM to 5PM. If it is not passed then user does not have       a default schedule and it must be created manually via the /schedules endpoint. Until the schedule is created, the user can't access availability atom to set his / her availability nor booked.       It will default to Europe/London if not passed. (e.g. America/New_York)
  --locale: string@locale-completer # e.g. en
  --avatarUrl: string # URL of the user's avatar image (e.g. https://cal.com/api/avatar/2b735186-b01b-46d3-87da-019b8f61776b.png)
  --bio: string # Bio (e.g. I am a bio)
  --metadata: record # You can store any additional data you want here. Metadata must have at most 50 keys, each key up to 40 characters, and values up to 500 characters. (e.g. {key: value})
]: any -> record<status: string, data: record<accessToken: string, refreshToken: string, user: record<id: float, email: string, username: string, name: string, bio: string, timeZone: string, weekStart: string, createdDate: string, timeFormat: float, defaultScheduleId: float, locale: string, avatarUrl: string, metadata: record>, accessTokenExpiresAt: float, refreshTokenExpiresAt: float>, error: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/users")
  let body = {email: $email, name: $name, timeFormat: $timeFormat, weekStart: $weekStart, timeZone: $timeZone, locale: $locale, avatarUrl: $avatarUrl, bio: $bio, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a managed user
#
# GET /v2/oauth-clients/{clientId}/users/{userId}
# operationId: OAuthClientUsersController_getUserById
export def "oauth-clients-users get" [
  clientId: string
  userId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: record<id: float, email: string, username: string, name: string, bio: string, timeZone: string, weekStart: string, createdDate: string, timeFormat: float, defaultScheduleId: float, locale: string, avatarUrl: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/users/($userId)")
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a managed user
#
# PATCH /v2/oauth-clients/{clientId}/users/{userId}
# operationId: OAuthClientUsersController_updateUser
export def "oauth-clients-users updateUser" [
  clientId: string
  userId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
  --email: string
  --name: string
  --timeFormat: float@timeFormat-completer # Must be 12 or 24 (e.g. 12)
  --defaultScheduleId: float
  --weekStart: string@weekStart-completer # e.g. Monday
  --timeZone: string
  --locale: string@locale-completer # e.g. en
  --avatarUrl: string # URL of the user's avatar image (e.g. https://cal.com/api/avatar/2b735186-b01b-46d3-87da-019b8f61776b.png)
  --bio: string # Bio (e.g. I am a bio)
  --metadata: record # You can store any additional data you want here. Metadata must have at most 50 keys, each key up to 40 characters, and values up to 500 characters. (e.g. {key: value})
]: any -> record<status: string, data: record<id: float, email: string, username: string, name: string, bio: string, timeZone: string, weekStart: string, createdDate: string, timeFormat: float, defaultScheduleId: float, locale: string, avatarUrl: string, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/users/($userId)")
  let body = {email: $email, name: $name, timeFormat: $timeFormat, defaultScheduleId: $defaultScheduleId, weekStart: $weekStart, timeZone: $timeZone, locale: $locale, avatarUrl: $avatarUrl, bio: $bio, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a managed user
#
# DELETE /v2/oauth-clients/{clientId}/users/{userId}
# operationId: OAuthClientUsersController_deleteUser
export def "oauth-clients-users delete" [
  clientId: string
  userId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: record<id: float, email: string, username: string, name: string, bio: string, timeZone: string, weekStart: string, createdDate: string, timeFormat: float, defaultScheduleId: float, locale: string, avatarUrl: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/users/($userId)")
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Force refresh tokens
#
# POST /v2/oauth-clients/{clientId}/users/{userId}/force-refresh
# operationId: OAuthClientUsersController_forceRefresh
export def "oauth-clients-users-force-refresh forceRefresh" [
  userId: float
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: record<accessToken: string, refreshToken: string, accessTokenExpiresAt: float, refreshTokenExpiresAt: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/users/($userId)/force-refresh")
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh managed user tokens
#
# POST /v2/oauth/{clientId}/refresh
# operationId: OAuthFlowController_refreshTokens
export def "oauth-refresh refreshTokens" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key.
  refreshToken: string # Managed user's refresh token.
]: any -> record<status: string, data: record<accessToken: string, refreshToken: string, accessTokenExpiresAt: float, refreshTokenExpiresAt: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth/($clientId)/refresh")
  let body = {refreshToken: $refreshToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a webhook
#
# POST /v2/oauth-clients/{clientId}/webhooks
# operationId: OAuthClientWebhooksController_createOAuthClientWebhook
export def "oauth-clients-webhooks createOAuthClientWebhook" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
  --payloadTemplate: string # The template of the payload that will be sent to the subscriberUrl, check cal.com/docs/core-features/webhooks for more information (e.g. {"content":"A new event has been scheduled","type":"{{type}}","name":"{{title}}","organizer":"{{organizer.name}}","booker":"{{attendees.0.name}}"})
  --active: oneof<nothing, bool>
  subscriberUrl: string
  triggers: list # e.g. [BOOKING_CREATED, BOOKING_RESCHEDULED, BOOKING_CANCELLED, BOOKING_CONFIRMED, BOOKING_REJECTED, BOOKING_COMPLETED, BOOKING_NO_SHOW, BOOKING_REOPENED]
  --secret: string
  --version: string@version-completer # The version of the webhook (e.g. 2021-10-20)
]: any -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, oAuthClientId: string, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/webhooks")
  let body = {payloadTemplate: $payloadTemplate, active: $active, subscriberUrl: $subscriberUrl, triggers: $triggers, secret: $secret, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all webhooks
#
# GET /v2/oauth-clients/{clientId}/webhooks
# operationId: OAuthClientWebhooksController_getOAuthClientWebhooks
export def "oauth-clients-webhooks list" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --take: float # Maximum number of items to return (default: 250, e.g. 25)
  --skip: float # Number of items to skip (default: 0, e.g. 0)
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: table<payloadTemplate: string, triggers: list, oAuthClientId: string, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/webhooks" $qp)
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all webhooks
#
# DELETE /v2/oauth-clients/{clientId}/webhooks
# operationId: OAuthClientWebhooksController_deleteAllOAuthClientWebhooks
export def "oauth-clients-webhooks delete-by-clientId" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/webhooks")
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /v2/oauth-clients/{clientId}/webhooks/{webhookId}
# operationId: OAuthClientWebhooksController_updateOAuthClientWebhook
export def "oauth-clients-webhooks updateOAuthClientWebhook" [
  webhookId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
  --payloadTemplate: string # The template of the payload that will be sent to the subscriberUrl, check cal.com/docs/core-features/webhooks for more information (e.g. {"content":"A new event has been scheduled","type":"{{type}}","name":"{{title}}","organizer":"{{organizer.name}}","booker":"{{attendees.0.name}}"})
  --active: oneof<nothing, bool>
  --subscriberUrl: string
  --triggers: list # e.g. [BOOKING_CREATED, BOOKING_RESCHEDULED, BOOKING_CANCELLED, BOOKING_CONFIRMED, BOOKING_REJECTED, BOOKING_COMPLETED, BOOKING_NO_SHOW, BOOKING_REOPENED]
  --secret: string
  --version: string@version-completer # The version of the webhook (e.g. 2021-10-20)
]: any -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, oAuthClientId: string, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/webhooks/($webhookId)")
  let body = {payloadTemplate: $payloadTemplate, active: $active, subscriberUrl: $subscriberUrl, triggers: $triggers, secret: $secret, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a webhook
#
# GET /v2/oauth-clients/{clientId}/webhooks/{webhookId}
# operationId: OAuthClientWebhooksController_getOAuthClientWebhook
export def "oauth-clients-webhooks get" [
  webhookId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, oAuthClientId: string, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/webhooks/($webhookId)")
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a webhook
#
# DELETE /v2/oauth-clients/{clientId}/webhooks/{webhookId}
# operationId: OAuthClientWebhooksController_deleteOAuthClientWebhook
export def "oauth-clients-webhooks delete-by-webhookId-clientId" [
  webhookId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-cal-secret-key: string # OAuth client secret key
]: nothing -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, oAuthClientId: string, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)/webhooks/($webhookId)")
  let extra_headers = {"x-cal-secret-key": $x_cal_secret_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an OAuth client
#
# POST /v2/oauth-clients
# operationId: OAuthClientsController_createOAuthClient
export def "oauth-clients createOAuthClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
  --logo: string
  name: string
  redirectUris: list
  permissions: list # Array of permission keys like ["BOOKING_READ", "BOOKING_WRITE"]. Use ["*"] to grant all permissions.
  --bookingRedirectUri: string
  --bookingCancelRedirectUri: string
  --bookingRescheduleRedirectUri: string
  --areEmailsEnabled: oneof<nothing, bool>
  --areDefaultEventTypesEnabled: oneof<nothing, bool> # If true, when creating a managed user the managed user will have 4 default event types: 30 and 60 minutes without Cal video, 30 and 60 minutes with Cal video. Set this as false if you want to create a managed user and then manually create event types for the user. (default: false)
  --areCalendarEventsEnabled: oneof<nothing, bool> # If true and if managed user has calendar connected, calendar events will be created. Disable it if you manually create calendar events. Default to true. (default: true)
]: any -> record<status: string, data: record<clientId: string, clientSecret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/oauth-clients")
  let body = {logo: $logo, name: $name, redirectUris: $redirectUris, permissions: $permissions, bookingRedirectUri: $bookingRedirectUri, bookingCancelRedirectUri: $bookingCancelRedirectUri, bookingRescheduleRedirectUri: $bookingRescheduleRedirectUri, areEmailsEnabled: $areEmailsEnabled, areDefaultEventTypesEnabled: $areDefaultEventTypesEnabled, areCalendarEventsEnabled: $areCalendarEventsEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all OAuth clients
#
# GET /v2/oauth-clients
# operationId: OAuthClientsController_getOAuthClients
export def "oauth-clients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
]: nothing -> record<status: string, data: table<id: string, name: string, secret: string, permissions: list, logo: record, redirectUris: list, organizationId: float, createdAt: string, areEmailsEnabled: bool, areDefaultEventTypesEnabled: bool, areCalendarEventsEnabled: bool, bookingRedirectUri: string, bookingCancelRedirectUri: string, bookingRescheduleRedirectUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/oauth-clients")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an OAuth client
#
# GET /v2/oauth-clients/{clientId}
# operationId: OAuthClientsController_getOAuthClientById
export def "oauth-clients get" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
]: nothing -> record<status: string, data: record<id: string, name: string, secret: string, permissions: list<string>, logo: record, redirectUris: list<string>, organizationId: float, createdAt: string, areEmailsEnabled: bool, areDefaultEventTypesEnabled: bool, areCalendarEventsEnabled: bool, bookingRedirectUri: string, bookingCancelRedirectUri: string, bookingRescheduleRedirectUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an OAuth client
#
# PATCH /v2/oauth-clients/{clientId}
# operationId: OAuthClientsController_updateOAuthClient
export def "oauth-clients updateOAuthClient" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
  --logo: string
  --name: string
  --redirectUris: list
  --bookingRedirectUri: string
  --bookingCancelRedirectUri: string
  --bookingRescheduleRedirectUri: string
  --areEmailsEnabled: oneof<nothing, bool>
  --areDefaultEventTypesEnabled: oneof<nothing, bool> # If true, when creating a managed user the managed user will have 4 default event types: 30 and 60 minutes without Cal video, 30 and 60 minutes with Cal video. Set this as false if you want to create a managed user and then manually create event types for the user.
  --areCalendarEventsEnabled: oneof<nothing, bool> # If true and if managed user has calendar connected, calendar events will be created. Disable it if you manually create calendar events. Default to true.
]: any -> record<status: string, data: record<id: string, name: string, secret: string, permissions: list<string>, logo: record, redirectUris: list<string>, organizationId: float, createdAt: string, areEmailsEnabled: bool, areDefaultEventTypesEnabled: bool, areCalendarEventsEnabled: bool, bookingRedirectUri: string, bookingCancelRedirectUri: string, bookingRescheduleRedirectUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)")
  let body = {logo: $logo, name: $name, redirectUris: $redirectUris, bookingRedirectUri: $bookingRedirectUri, bookingCancelRedirectUri: $bookingCancelRedirectUri, bookingRescheduleRedirectUri: $bookingRescheduleRedirectUri, areEmailsEnabled: $areEmailsEnabled, areDefaultEventTypesEnabled: $areDefaultEventTypesEnabled, areCalendarEventsEnabled: $areCalendarEventsEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an OAuth client
#
# DELETE /v2/oauth-clients/{clientId}
# operationId: OAuthClientsController_deleteOAuthClient
export def "oauth-clients delete" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
]: nothing -> record<status: string, data: record<id: string, name: string, secret: string, permissions: list<string>, logo: record, redirectUris: list<string>, organizationId: float, createdAt: string, areEmailsEnabled: bool, areDefaultEventTypesEnabled: bool, areCalendarEventsEnabled: bool, bookingRedirectUri: string, bookingCancelRedirectUri: string, bookingRescheduleRedirectUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/oauth-clients/($clientId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update destination calendars
#
# PUT /v2/destination-calendars
# operationId: DestinationCalendarsController_updateDestinationCalendars
export def "destination-calendars updateDestinationCalendars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  integration: string@integration-completer # The calendar service you want to integrate, as returned by the /calendars endpoint (e.g. apple_calendar)
  externalId: string # Unique identifier used to represent the specific calendar, as returned by the /calendars endpoint (e.g. https://caldav.icloud.com/26962146906/calendars/1644422A-1945-4438-BBC0-4F0Q23A57R7S/)
  --delegationCredentialId: string
]: any -> record<status: string, data: record<userId: float, integration: string, externalId: string, credentialId: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/destination-calendars")
  let body = {integration: $integration, externalId: $externalId, delegationCredentialId: $delegationCredentialId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an event type
#
# POST /v2/event-types
# operationId: EventTypesController_2024_06_14_createEventType
# --color shape: {lightThemeHex: string, darkThemeHex: string}
# --destinationCalendar shape: {integration: string, externalId: string}
export def "event-types createEventType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-06-14. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  lengthInMinutes: float # e.g. 60
  --lengthInMinutesOptions: list # If you want that user can choose between different lengths of the event you can specify them here. Must include the provided `lengthInMinutes`. (e.g. [15, 30, 60])
  title: string # e.g. Learn the secrets of masterchief!
  slug: string # e.g. learn-the-secrets-of-masterchief
  --description: string # e.g. Discover the culinary wonders of the Argentina by making the best flan ever!
  --bookingFields: list # Custom fields that can be added to the booking form when the event is booked by someone. By default booking form has name and email field.
  --disableGuests: oneof<nothing, bool> # If true, person booking this event can't add guests via their emails.
  --slotInterval: float # Number representing length of each slot when event is booked. By default it equal length of the event type.       If event length is 60 minutes then we would have slots 9AM, 10AM, 11AM etc. but if it was changed to 30 minutes then       we would have slots 9AM, 9:30AM, 10AM, 10:30AM etc. as the available times to book the 60 minute event.
  --minimumBookingNotice: float # Minimum number of minutes before the event that a booking can be made.
  --beforeEventBuffer: float # Extra time automatically blocked on your calendar before a meeting starts. This gives you time to prepare, review notes, or transition from your previous activity.
  --afterEventBuffer: float # Extra time automatically blocked on your calendar after a meeting ends. This gives you time to wrap up, add notes, or decompress before your next commitment.
  --scheduleId: float # If you want that this event has different schedule than user's default one you can specify it here.
  --bookingLimitsCount: any # Limit how many times this event can be booked
  --bookerActiveBookingsLimit: any # Limit the number of active bookings a booker can make for this event type.
  --onlyShowFirstAvailableSlot: oneof<nothing, bool> # This will limit your availability for this event type to one slot per day, scheduled at the earliest available time.
  --bookingLimitsDuration: any # Limit total amount of time that this event can be booked
  --bookingWindow: any # Limit how far in the future this event can be booked
  --offsetStart: float # Offset timeslots shown to bookers by a specified number of minutes
  --bookerLayouts: any # Should booker have week, month or column view. Specify default layout and enabled layouts user can pick.
  --confirmationPolicy: any # Specify how the booking needs to be manually confirmed before it is pushed to the integrations and a confirmation mail is sent.
  --recurrence: any # Create a recurring event type.
  --requiresBookerEmailVerification: oneof<nothing, bool>
  --hideCalendarNotes: oneof<nothing, bool>
  --lockTimeZoneToggleOnBookingPage: oneof<nothing, bool>
  --color: record # shape: {lightThemeHex: string, darkThemeHex: string}
  --seats: any # Create an event type with multiple seats.
  --customName: string # Customizable event name with valid variables:       {Event type title}, {Organiser}, {Scheduler}, {Location}, {Organiser first name},       {Scheduler first name}, {Scheduler last name}, {Event duration}, {LOCATION},       {HOST/ATTENDEE}, {HOST}, {ATTENDEE}, {USER} (e.g. {Event type title} between {Organiser} and {Scheduler})
  --destinationCalendar: record # shape: {integration: string, externalId: string}
  --useDestinationCalendarEmail: oneof<nothing, bool>
  --hideCalendarEventDetails: oneof<nothing, bool>
  --successRedirectUrl: string # A valid URL where the booker will redirect to, once the booking is completed successfully (e.g. https://masterchief.com/argentina/flan/video/9129412)
  --hideOrganizerEmail: oneof<nothing, bool> # Boolean to Hide organizer's email address from the booking screen, email notifications, and calendar events
  --calVideoSettings: any # Cal video settings for the event type. Platform customers can't manage this property because currently we have no way of determining if managed user is a host or an attendee.
  --hidden: oneof<nothing, bool>
  --bookingRequiresAuthentication: oneof<nothing, bool> # Boolean to require authentication for booking this event type via api. If true, only authenticated users who are the event-type owner or org/team admin/owner can book this event type. (default: false)
  --disableCancelling: any # Settings for disabling cancelling of this event type. (e.g. {disabled: true})
  --disableRescheduling: any # Settings for disabling rescheduling of this event type. Can be always disabled or disabled when less than X minutes before the meeting. (e.g. {disabled: false, minutesBefore: 60})
  --interfaceLanguage: string@interfaceLanguage-completer # Set preferred language for the booking interface. Use empty string for visitor's browser language (default).
  --allowReschedulingPastBookings: oneof<nothing, bool> # Enabling this option allows for past events to be rescheduled. (default: false)
  --allowReschedulingCancelledBookings: oneof<nothing, bool> # When enabled, users will be able to create a new booking when trying to reschedule a cancelled booking. (default: false)
  --showOptimizedSlots: oneof<nothing, bool> # Arrange time slots to optimize availability. (default: false)
  --locations: list # Locations where the event will take place. If not provided, cal video link will be used as the location. Note: Setting a location to a conferencing app does not install the app - the app must already be installed. Via API, only Google Meet (google-meet), Microsoft Teams (office365-video), and Zoom (zoom) can be installed. Cal Video (cal-video) is installed by default. All other conferencing apps must be connected via the Cal.diy web app and are not available for Platform plan customers. You can only set an event type location to an app that has already been installed or connected.
]: any -> record<status: string, data: record<id: float, lengthInMinutes: float, lengthInMinutesOptions: list<float>, title: string, slug: string, description: string, locations: list<any>, bookingFields: list<any>, disableGuests: bool, slotInterval: record, minimumBookingNotice: float, beforeEventBuffer: float, afterEventBuffer: float, recurrence: record<interval: float, occurrences: float, frequency: string>, metadata: record, price: float, currency: string, lockTimeZoneToggleOnBookingPage: bool, seatsPerTimeSlot: record, forwardParamsSuccessRedirect: record, successRedirectUrl: record, isInstantEvent: bool, seatsShowAvailabilityCount: bool, scheduleId: float, bookingLimitsCount: record, bookerActiveBookingsLimit: record<maximumActiveBookings: float, offerReschedule: bool>, onlyShowFirstAvailableSlot: bool, bookingLimitsDuration: record, bookingWindow: list<any>, bookerLayouts: record<defaultLayout: string, enabledLayouts: list>, confirmationPolicy: record, requiresBookerEmailVerification: bool, hideCalendarNotes: bool, color: record<lightThemeHex: string, darkThemeHex: string>, seats: record<seatsPerTimeSlot: float, showAttendeeInfo: bool, showAvailabilityCount: bool>, offsetStart: float, customName: string, destinationCalendar: record<integration: string, externalId: string>, useDestinationCalendarEmail: bool, hideCalendarEventDetails: bool, hideOrganizerEmail: bool, calVideoSettings: record<disableRecordingForOrganizer: bool, disableRecordingForGuests: bool, redirectUrlOnExit: record, enableAutomaticRecordingForOrganizer: bool, enableAutomaticTranscription: bool, disableTranscriptionForGuests: bool, disableTranscriptionForOrganizer: bool, sendTranscriptionEmails: bool>, hidden: bool, bookingRequiresAuthentication: bool, disableCancelling: record<disabled: bool>, disableRescheduling: record<disabled: bool, minutesBefore: float>, interfaceLanguage: string, allowReschedulingPastBookings: bool, allowReschedulingCancelledBookings: bool, showOptimizedSlots: bool, ownerId: float, users: list<string>, bookingUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/event-types")
  let body = {lengthInMinutes: $lengthInMinutes, lengthInMinutesOptions: $lengthInMinutesOptions, title: $title, slug: $slug, description: $description, bookingFields: $bookingFields, disableGuests: $disableGuests, slotInterval: $slotInterval, minimumBookingNotice: $minimumBookingNotice, beforeEventBuffer: $beforeEventBuffer, afterEventBuffer: $afterEventBuffer, scheduleId: $scheduleId, bookingLimitsCount: $bookingLimitsCount, bookerActiveBookingsLimit: $bookerActiveBookingsLimit, onlyShowFirstAvailableSlot: $onlyShowFirstAvailableSlot, bookingLimitsDuration: $bookingLimitsDuration, bookingWindow: $bookingWindow, offsetStart: $offsetStart, bookerLayouts: $bookerLayouts, confirmationPolicy: $confirmationPolicy, recurrence: $recurrence, requiresBookerEmailVerification: $requiresBookerEmailVerification, hideCalendarNotes: $hideCalendarNotes, lockTimeZoneToggleOnBookingPage: $lockTimeZoneToggleOnBookingPage, color: $color, seats: $seats, customName: $customName, destinationCalendar: $destinationCalendar, useDestinationCalendarEmail: $useDestinationCalendarEmail, hideCalendarEventDetails: $hideCalendarEventDetails, successRedirectUrl: $successRedirectUrl, hideOrganizerEmail: $hideOrganizerEmail, calVideoSettings: $calVideoSettings, hidden: $hidden, bookingRequiresAuthentication: $bookingRequiresAuthentication, disableCancelling: $disableCancelling, disableRescheduling: $disableRescheduling, interfaceLanguage: $interfaceLanguage, allowReschedulingPastBookings: $allowReschedulingPastBookings, allowReschedulingCancelledBookings: $allowReschedulingCancelledBookings, showOptimizedSlots: $showOptimizedSlots, locations: $locations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all event types
#
# GET /v2/event-types
# operationId: EventTypesController_2024_06_14_getEventTypes
export def "event-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --username: string # The username of the user to get event types for. If only username provided will get all event types.
  --eventSlug: string # Slug of event type to return. Notably, if eventSlug is provided then username must be provided too, because multiple users can have event with same slug.
  --usernames: string # Get dynamic event type for multiple usernames separated by comma. e.g `usernames=alice,bob`
  --orgSlug: string # slug of the user's organization if he is in one, orgId is not required if using this parameter
  --orgId: float # ID of the organization of the user you want the get the event-types of, orgSlug is not needed when using this parameter
  --sortCreatedAt: string@sortCreatedAt-completer # Sort event types by creation date. When not provided, no explicit ordering is applied.
  --cal-api-version: string # Must be set to 2024-06-14. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --x-cal-secret-key: string # For platform customers - OAuth client secret key
  --x-cal-client-id: string # For platform customers - OAuth client ID
]: nothing -> record<status: string, data: table<id: float, lengthInMinutes: float, lengthInMinutesOptions: list, title: string, slug: string, description: string, locations: list, bookingFields: list, disableGuests: bool, slotInterval: record, minimumBookingNotice: float, beforeEventBuffer: float, afterEventBuffer: float, recurrence: record, metadata: record, price: float, currency: string, lockTimeZoneToggleOnBookingPage: bool, seatsPerTimeSlot: record, forwardParamsSuccessRedirect: record, successRedirectUrl: record, isInstantEvent: bool, seatsShowAvailabilityCount: bool, scheduleId: float, bookingLimitsCount: record, bookerActiveBookingsLimit: record, onlyShowFirstAvailableSlot: bool, bookingLimitsDuration: record, bookingWindow: list, bookerLayouts: record, confirmationPolicy: record, requiresBookerEmailVerification: bool, hideCalendarNotes: bool, color: record, seats: record, offsetStart: float, customName: string, destinationCalendar: record, useDestinationCalendarEmail: bool, hideCalendarEventDetails: bool, hideOrganizerEmail: bool, calVideoSettings: record, hidden: bool, bookingRequiresAuthentication: bool, disableCancelling: record, disableRescheduling: record, interfaceLanguage: string, allowReschedulingPastBookings: bool, allowReschedulingCancelledBookings: bool, showOptimizedSlots: bool, ownerId: float, users: list, bookingUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "eventSlug" $eventSlug "scalar") (serialize-qp "usernames" $usernames "scalar") (serialize-qp "orgSlug" $orgSlug "scalar") (serialize-qp "orgId" $orgId "scalar") (serialize-qp "sortCreatedAt" $sortCreatedAt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/event-types" $qp)
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization, "x-cal-secret-key": $x_cal_secret_key, "x-cal-client-id": $x_cal_client_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an event type
#
# GET /v2/event-types/{eventTypeId}
# operationId: EventTypesController_2024_06_14_getEventTypeById
export def "event-types get" [
  eventTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-06-14. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an event type
#
# PATCH /v2/event-types/{eventTypeId}
# operationId: EventTypesController_2024_06_14_updateEventType
# --color shape: {lightThemeHex: string, darkThemeHex: string}
# --destinationCalendar shape: {integration: string, externalId: string}
export def "event-types updateEventType" [
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-06-14. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --lengthInMinutes: float # e.g. 60
  --lengthInMinutesOptions: list # If you want that user can choose between different lengths of the event you can specify them here. Must include the provided `lengthInMinutes`. (e.g. [15, 30, 60])
  --title: string # e.g. Learn the secrets of masterchief!
  --slug: string # e.g. learn-the-secrets-of-masterchief
  --description: string # e.g. Discover the culinary wonders of the Argentina by making the best flan ever!
  --bookingFields: list # Complete set of booking form fields. This array replaces all existing booking fields. To modify existing fields, first fetch the current event type, then include all desired fields in this array. Sending only one field will remove all other custom fields, keeping only default fields plus the provided one.
  --disableGuests: oneof<nothing, bool> # If true, person booking this event can't add guests via their emails.
  --slotInterval: float # Number representing length of each slot when event is booked. By default it equal length of the event type.       If event length is 60 minutes then we would have slots 9AM, 10AM, 11AM etc. but if it was changed to 30 minutes then       we would have slots 9AM, 9:30AM, 10AM, 10:30AM etc. as the available times to book the 60 minute event.
  --minimumBookingNotice: float # Minimum number of minutes before the event that a booking can be made.
  --beforeEventBuffer: float # Extra time automatically blocked on your calendar before a meeting starts. This gives you time to prepare, review notes, or transition from your previous activity.
  --afterEventBuffer: float # Extra time automatically blocked on your calendar after a meeting ends. This gives you time to wrap up, add notes, or decompress before your next commitment.
  --scheduleId: float # If you want that this event has different schedule than user's default one you can specify it here.
  --bookingLimitsCount: any # Limit how many times this event can be booked
  --bookerActiveBookingsLimit: any # Limit the number of active bookings a booker can make for this event type.
  --onlyShowFirstAvailableSlot: oneof<nothing, bool> # This will limit your availability for this event type to one slot per day, scheduled at the earliest available time.
  --bookingLimitsDuration: any # Limit total amount of time that this event can be booked
  --bookingWindow: any # Limit how far in the future this event can be booked
  --offsetStart: float # Offset timeslots shown to bookers by a specified number of minutes
  --bookerLayouts: any # Should booker have week, month or column view. Specify default layout and enabled layouts user can pick.
  --confirmationPolicy: any # Specify how the booking needs to be manually confirmed before it is pushed to the integrations and a confirmation mail is sent.
  --recurrence: any # Create a recurring event type.
  --requiresBookerEmailVerification: oneof<nothing, bool>
  --hideCalendarNotes: oneof<nothing, bool>
  --lockTimeZoneToggleOnBookingPage: oneof<nothing, bool>
  --color: record # shape: {lightThemeHex: string, darkThemeHex: string}
  --seats: any # Create an event type with multiple seats.
  --customName: string # Customizable event name with valid variables:       {Event type title}, {Organiser}, {Scheduler}, {Location}, {Organiser first name},       {Scheduler first name}, {Scheduler last name}, {Event duration}, {LOCATION},       {HOST/ATTENDEE}, {HOST}, {ATTENDEE}, {USER} (e.g. {Event type title} between {Organiser} and {Scheduler})
  --destinationCalendar: record # shape: {integration: string, externalId: string}
  --useDestinationCalendarEmail: oneof<nothing, bool>
  --hideCalendarEventDetails: oneof<nothing, bool>
  --successRedirectUrl: string # A valid URL where the booker will redirect to, once the booking is completed successfully (e.g. https://masterchief.com/argentina/flan/video/9129412)
  --hideOrganizerEmail: oneof<nothing, bool> # Boolean to Hide organizer's email address from the booking screen, email notifications, and calendar events
  --calVideoSettings: any # Cal video settings for the event type
  --hidden: oneof<nothing, bool>
  --bookingRequiresAuthentication: oneof<nothing, bool> # Boolean to require authentication for booking this event type via api. If true, only authenticated users who are the event-type owner or org/team admin/owner can book this event type. (default: false)
  --disableCancelling: any # Settings for disabling cancelling of this event type. (e.g. {disabled: true})
  --disableRescheduling: any # Settings for disabling rescheduling of this event type. Can be always disabled or disabled when less than X minutes before the meeting. (e.g. {disabled: false, minutesBefore: 60})
  --interfaceLanguage: string@interfaceLanguage-completer # Set preferred language for the booking interface. Use empty string for visitor's browser language (default).
  --allowReschedulingPastBookings: oneof<nothing, bool> # Enabling this option allows for past events to be rescheduled. (default: false)
  --allowReschedulingCancelledBookings: oneof<nothing, bool> # When enabled, users will be able to create a new booking when trying to reschedule a cancelled booking. (default: false)
  --showOptimizedSlots: oneof<nothing, bool> # Arrange time slots to optimize availability. (default: false)
  --locations: list # Locations where the event will take place. If not provided, cal video link will be used as the location. Note: Setting a location to a conferencing app does not install the app - the app must already be installed. Via API, only Google Meet (google-meet), Microsoft Teams (office365-video), and Zoom (zoom) can be installed. Cal Video (cal-video) is installed by default. All other conferencing apps must be connected via the Cal.diy web app and are not available for Platform plan customers. You can only set an event type location to an app that has already been installed or connected.
]: any -> record<status: string, data: record<id: float, lengthInMinutes: float, lengthInMinutesOptions: list<float>, title: string, slug: string, description: string, locations: list<any>, bookingFields: list<any>, disableGuests: bool, slotInterval: record, minimumBookingNotice: float, beforeEventBuffer: float, afterEventBuffer: float, recurrence: record<interval: float, occurrences: float, frequency: string>, metadata: record, price: float, currency: string, lockTimeZoneToggleOnBookingPage: bool, seatsPerTimeSlot: record, forwardParamsSuccessRedirect: record, successRedirectUrl: record, isInstantEvent: bool, seatsShowAvailabilityCount: bool, scheduleId: float, bookingLimitsCount: record, bookerActiveBookingsLimit: record<maximumActiveBookings: float, offerReschedule: bool>, onlyShowFirstAvailableSlot: bool, bookingLimitsDuration: record, bookingWindow: list<any>, bookerLayouts: record<defaultLayout: string, enabledLayouts: list>, confirmationPolicy: record, requiresBookerEmailVerification: bool, hideCalendarNotes: bool, color: record<lightThemeHex: string, darkThemeHex: string>, seats: record<seatsPerTimeSlot: float, showAttendeeInfo: bool, showAvailabilityCount: bool>, offsetStart: float, customName: string, destinationCalendar: record<integration: string, externalId: string>, useDestinationCalendarEmail: bool, hideCalendarEventDetails: bool, hideOrganizerEmail: bool, calVideoSettings: record<disableRecordingForOrganizer: bool, disableRecordingForGuests: bool, redirectUrlOnExit: record, enableAutomaticRecordingForOrganizer: bool, enableAutomaticTranscription: bool, disableTranscriptionForGuests: bool, disableTranscriptionForOrganizer: bool, sendTranscriptionEmails: bool>, hidden: bool, bookingRequiresAuthentication: bool, disableCancelling: record<disabled: bool>, disableRescheduling: record<disabled: bool, minutesBefore: float>, interfaceLanguage: string, allowReschedulingPastBookings: bool, allowReschedulingCancelledBookings: bool, showOptimizedSlots: bool, ownerId: float, users: list<string>, bookingUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)")
  let body = {lengthInMinutes: $lengthInMinutes, lengthInMinutesOptions: $lengthInMinutesOptions, title: $title, slug: $slug, description: $description, bookingFields: $bookingFields, disableGuests: $disableGuests, slotInterval: $slotInterval, minimumBookingNotice: $minimumBookingNotice, beforeEventBuffer: $beforeEventBuffer, afterEventBuffer: $afterEventBuffer, scheduleId: $scheduleId, bookingLimitsCount: $bookingLimitsCount, bookerActiveBookingsLimit: $bookerActiveBookingsLimit, onlyShowFirstAvailableSlot: $onlyShowFirstAvailableSlot, bookingLimitsDuration: $bookingLimitsDuration, bookingWindow: $bookingWindow, offsetStart: $offsetStart, bookerLayouts: $bookerLayouts, confirmationPolicy: $confirmationPolicy, recurrence: $recurrence, requiresBookerEmailVerification: $requiresBookerEmailVerification, hideCalendarNotes: $hideCalendarNotes, lockTimeZoneToggleOnBookingPage: $lockTimeZoneToggleOnBookingPage, color: $color, seats: $seats, customName: $customName, destinationCalendar: $destinationCalendar, useDestinationCalendarEmail: $useDestinationCalendarEmail, hideCalendarEventDetails: $hideCalendarEventDetails, successRedirectUrl: $successRedirectUrl, hideOrganizerEmail: $hideOrganizerEmail, calVideoSettings: $calVideoSettings, hidden: $hidden, bookingRequiresAuthentication: $bookingRequiresAuthentication, disableCancelling: $disableCancelling, disableRescheduling: $disableRescheduling, interfaceLanguage: $interfaceLanguage, allowReschedulingPastBookings: $allowReschedulingPastBookings, allowReschedulingCancelledBookings: $allowReschedulingCancelledBookings, showOptimizedSlots: $showOptimizedSlots, locations: $locations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an event type
#
# DELETE /v2/event-types/{eventTypeId}
# operationId: EventTypesController_2024_06_14_deleteEventType
export def "event-types delete" [
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-06-14. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<id: float, lengthInMinutes: float, title: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)")
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /v2/event-types/{eventTypeId}/webhooks
# operationId: EventTypeWebhooksController_createEventTypeWebhook
export def "event-types-webhooks createEventTypeWebhook" [
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --payloadTemplate: string # The template of the payload that will be sent to the subscriberUrl, check cal.com/docs/core-features/webhooks for more information (e.g. {"content":"A new event has been scheduled","type":"{{type}}","name":"{{title}}","organizer":"{{organizer.name}}","booker":"{{attendees.0.name}}"})
  --active: oneof<nothing, bool>
  subscriberUrl: string
  triggers: list # e.g. [BOOKING_CREATED, BOOKING_RESCHEDULED, BOOKING_CANCELLED, BOOKING_CONFIRMED, BOOKING_REJECTED, BOOKING_COMPLETED, BOOKING_NO_SHOW, BOOKING_REOPENED]
  --secret: string
  --version: string@version-completer # The version of the webhook (e.g. 2021-10-20)
]: any -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, eventTypeId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/webhooks")
  let body = {payloadTemplate: $payloadTemplate, active: $active, subscriberUrl: $subscriberUrl, triggers: $triggers, secret: $secret, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all webhooks
#
# GET /v2/event-types/{eventTypeId}/webhooks
# operationId: EventTypeWebhooksController_getEventTypeWebhooks
export def "event-types-webhooks list" [
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --take: float # Maximum number of items to return (default: 250, e.g. 25)
  --skip: float # Number of items to skip (default: 0, e.g. 0)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<payloadTemplate: string, triggers: list, eventTypeId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/webhooks" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all webhooks
#
# DELETE /v2/event-types/{eventTypeId}/webhooks
# operationId: EventTypeWebhooksController_deleteAllEventTypeWebhooks
export def "event-types-webhooks delete-by-eventTypeId" [
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/webhooks")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /v2/event-types/{eventTypeId}/webhooks/{webhookId}
# operationId: EventTypeWebhooksController_updateEventTypeWebhook
export def "event-types-webhooks updateEventTypeWebhook" [
  webhookId: string
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --payloadTemplate: string # The template of the payload that will be sent to the subscriberUrl, check cal.com/docs/core-features/webhooks for more information (e.g. {"content":"A new event has been scheduled","type":"{{type}}","name":"{{title}}","organizer":"{{organizer.name}}","booker":"{{attendees.0.name}}"})
  --active: oneof<nothing, bool>
  --subscriberUrl: string
  --triggers: list # e.g. [BOOKING_CREATED, BOOKING_RESCHEDULED, BOOKING_CANCELLED, BOOKING_CONFIRMED, BOOKING_REJECTED, BOOKING_COMPLETED, BOOKING_NO_SHOW, BOOKING_REOPENED]
  --secret: string
  --version: string@version-completer # The version of the webhook (e.g. 2021-10-20)
]: any -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, eventTypeId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/webhooks/($webhookId)")
  let body = {payloadTemplate: $payloadTemplate, active: $active, subscriberUrl: $subscriberUrl, triggers: $triggers, secret: $secret, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a webhook
#
# GET /v2/event-types/{eventTypeId}/webhooks/{webhookId}
# operationId: EventTypeWebhooksController_getEventTypeWebhook
export def "event-types-webhooks get" [
  webhookId: string
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, eventTypeId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/webhooks/($webhookId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a webhook
#
# DELETE /v2/event-types/{eventTypeId}/webhooks/{webhookId}
# operationId: EventTypeWebhooksController_deleteEventTypeWebhook
export def "event-types-webhooks delete-by-webhookId-eventTypeId" [
  webhookId: string
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, eventTypeId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/webhooks/($webhookId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a private link for an event type
#
# POST /v2/event-types/{eventTypeId}/private-links
# operationId: EventTypesPrivateLinksController_createPrivateLink
export def "event-types-private-links createPrivateLink" [
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --expiresAt: string # Expiration date for time-based links (format: date-time, e.g. 2024-12-31T23:59:59.000Z)
  --maxUsageCount: float # Maximum number of times the link can be used. If omitted and expiresAt is not provided, defaults to 1 (one time use). (default: 1, e.g. 10)
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/private-links")
  let body = {expiresAt: $expiresAt, maxUsageCount: $maxUsageCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all private links for an event type
#
# GET /v2/event-types/{eventTypeId}/private-links
# operationId: EventTypesPrivateLinksController_getPrivateLinks
export def "event-types-private-links get" [
  eventTypeId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/private-links")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a private link for an event type
#
# PATCH /v2/event-types/{eventTypeId}/private-links/{linkId}
# operationId: EventTypesPrivateLinksController_updatePrivateLink
export def "event-types-private-links updatePrivateLink" [
  eventTypeId: float
  linkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --expiresAt: string # New expiration date for time-based links (format: date-time, e.g. 2024-12-31T23:59:59.000Z)
  --maxUsageCount: float # New maximum number of times the link can be used (e.g. 10)
]: any -> record<status: string, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/private-links/($linkId)")
  let body = {expiresAt: $expiresAt, maxUsageCount: $maxUsageCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a private link for an event type
#
# DELETE /v2/event-types/{eventTypeId}/private-links/{linkId}
# operationId: EventTypesPrivateLinksController_deletePrivateLink
export def "event-types-private-links delete" [
  eventTypeId: float
  linkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<linkId: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/event-types/($eventTypeId)/private-links/($linkId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get my profile
#
# GET /v2/me
# operationId: MeController_getMe
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<id: float, username: string, email: string, name: string, avatarUrl: string, bio: string, timeFormat: float, defaultScheduleId: float, weekStart: string, timeZone: string, organizationId: float, organization: record<isPlatform: bool, id: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/me")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update my profile
#
# PATCH /v2/me
# operationId: MeController_updateMe
export def "me updateMe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --email: string
  --name: string
  --timeFormat: float@timeFormat-completer # Must be 12 or 24 (e.g. 12)
  --defaultScheduleId: float
  --weekStart: string@weekStart-completer # e.g. Monday
  --timeZone: string
  --locale: string@locale-completer # e.g. en
  --avatarUrl: string # URL of the user's avatar image (e.g. https://cal.com/api/avatar/2b735186-b01b-46d3-87da-019b8f61776b.png)
  --bio: string # Bio (e.g. I am a bio)
  --metadata: record # You can store any additional data you want here. Metadata must have at most 50 keys, each key up to 40 characters, and values up to 500 characters. (e.g. {key: value})
]: any -> record<status: string, data: record<id: float, username: string, email: string, name: string, avatarUrl: string, bio: string, timeFormat: float, defaultScheduleId: float, weekStart: string, timeZone: string, organizationId: float, organization: record<isPlatform: bool, id: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/me")
  let body = {email: $email, name: $name, timeFormat: $timeFormat, defaultScheduleId: $defaultScheduleId, weekStart: $weekStart, timeZone: $timeZone, locale: $locale, avatarUrl: $avatarUrl, bio: $bio, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get OAuth2 client
#
# GET /v2/auth/oauth2/clients/{clientId}
# operationId: OAuth2Controller_getClient
export def "auth-oauth2-clients get" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, data: record<client_id: string, redirect_uris: list<string>, name: string, logo: string, is_trusted: bool, client_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/auth/oauth2/clients/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange authorization code or refresh token for tokens
#
# POST /v2/auth/oauth2/token
# operationId: OAuth2Controller_token
export def "auth-oauth2-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # The client identifier (e.g. my-client-id)
  --grant-type: string@grant-type-completer # The grant type — must be 'authorization_code' (e.g. authorization_code)
  --code: string # The authorization code received from the authorize endpoint (e.g. abc123)
  --redirect-uri: string # The redirect URI used in the authorization request (e.g. https://example.com/callback)
  --client-secret: string # The client secret for confidential clients
  --code-verifier: string # PKCE code verifier (required for public clients that used code_challenge)
  --refresh-token: string # The refresh token (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...)
]: any -> record<access_token: string, token_type: string, refresh_token: string, expires_in: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/auth/oauth2/token")
  let body = {client_id: $client_id, grant_type: $grant_type, code: $code, redirect_uri: $redirect_uri, client_secret: $client_secret, code_verifier: $code_verifier, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a schedule
#
# POST /v2/schedules
# operationId: SchedulesController_2024_06_11_createSchedule
# --availability item shape: {days: list, startTime: string, endTime: string}
# --overrides item shape: {date: string, startTime: string, endTime: string}
export def "schedules createSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --cal-api-version: string # Must be set to 2024-06-11. If not set to this value, the endpoint will default to an older version.
  name: string # e.g. Catch up hours
  timeZone: string # Timezone is used to calculate available times when an event using the schedule is booked. (e.g. Europe/Rome)
  --availability: list # Each object contains days and times when the user is available. If not passed, the default availability is Monday to Friday from 09:00 to 17:00. (e.g. [{days: [Monday, Tuesday], startTime: 17:00, endTime: 19:00}, {days: [Wednesday, Thursday], startTime: 16:00, endTime: 20:00}]) — item shape: {days: list, startTime: string, endTime: string}
  --isDefault: oneof<nothing, bool> # Each user should have 1 default schedule. If you specified `timeZone` when creating managed user, then the default schedule will be created with that timezone.     Default schedule means that if an event type is not tied to a specific schedule then the default schedule is used. (e.g. true)
  --overrides: list # Need to change availability for a specific date? Add an override. (e.g. [{date: 2024-05-20, startTime: 18:00, endTime: 21:00}]) — item shape: {date: string, startTime: string, endTime: string}
]: any -> record<status: string, data: record<id: float, ownerId: float, name: string, timeZone: string, availability: list<record>, isDefault: bool, overrides: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedules")
  let body = {name: $name, timeZone: $timeZone, availability: $availability, isDefault: $isDefault, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all schedules
#
# GET /v2/schedules
# operationId: SchedulesController_2024_06_11_getSchedules
export def "schedules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --cal-api-version: string # Must be set to 2024-06-11. If not set to this value, the endpoint will default to an older version.
]: nothing -> record<status: string, data: table<id: float, ownerId: float, name: string, timeZone: string, availability: list, isDefault: bool, overrides: list>, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedules")
  let extra_headers = {"Authorization": $Authorization, "cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default schedule
#
# GET /v2/schedules/default
# operationId: SchedulesController_2024_06_11_getDefaultSchedule
export def "schedules-default get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --cal-api-version: string # Must be set to 2024-06-11. If not set to this value, the endpoint will default to an older version.
]: nothing -> record<status: string, data: record<id: float, ownerId: float, name: string, timeZone: string, availability: list<record>, isDefault: bool, overrides: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/schedules/default")
  let extra_headers = {"Authorization": $Authorization, "cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a schedule
#
# GET /v2/schedules/{scheduleId}
# operationId: SchedulesController_2024_06_11_getSchedule
export def "schedules get" [
  scheduleId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --cal-api-version: string # Must be set to 2024-06-11. If not set to this value, the endpoint will default to an older version.
]: nothing -> record<status: string, data: record<id: float, ownerId: float, name: string, timeZone: string, availability: list<record>, isDefault: bool, overrides: list<record>>, error: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($scheduleId)")
  let extra_headers = {"Authorization": $Authorization, "cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a schedule
#
# PATCH /v2/schedules/{scheduleId}
# operationId: SchedulesController_2024_06_11_updateSchedule
# --availability item shape: {days: list, startTime: string, endTime: string}
# --overrides item shape: {date: string, startTime: string, endTime: string}
export def "schedules updateSchedule" [
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --cal-api-version: string # Must be set to 2024-06-11. If not set to this value, the endpoint will default to an older version.
  --name: string # e.g. One-on-one coaching
  --timeZone: string # e.g. Europe/Rome
  --availability: list # e.g. [{days: [Monday, Tuesday], startTime: 09:00, endTime: 10:00}] — item shape: {days: list, startTime: string, endTime: string}
  --isDefault: oneof<nothing, bool> # e.g. true
  --overrides: list # e.g. [{date: 2024-05-20, startTime: 12:00, endTime: 14:00}] — item shape: {date: string, startTime: string, endTime: string}
]: any -> record<status: string, data: record<id: float, ownerId: float, name: string, timeZone: string, availability: list<record>, isDefault: bool, overrides: list<record>>, error: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($scheduleId)")
  let body = {name: $name, timeZone: $timeZone, availability: $availability, isDefault: $isDefault, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a schedule
#
# DELETE /v2/schedules/{scheduleId}
# operationId: SchedulesController_2024_06_11_deleteSchedule
export def "schedules delete" [
  scheduleId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --cal-api-version: string # Must be set to 2024-06-11. If not set to this value, the endpoint will default to an older version.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/schedules/($scheduleId)")
  let extra_headers = {"Authorization": $Authorization, "cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a selected calendar
#
# POST /v2/selected-calendars
# operationId: SelectedCalendarsController_addSelectedCalendar
export def "selected-calendars addSelectedCalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  integration: string
  externalId: string
  credentialId: float
  --delegationCredentialId: string
]: any -> record<status: string, data: record<userId: float, integration: string, externalId: string, credentialId: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/selected-calendars")
  let body = {integration: $integration, externalId: $externalId, credentialId: $credentialId, delegationCredentialId: $delegationCredentialId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a selected calendar
#
# DELETE /v2/selected-calendars
# operationId: SelectedCalendarsController_deleteSelectedCalendar
export def "selected-calendars delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integration: string
  --externalId: string
  --credentialId: string
  --delegationCredentialId: string
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<userId: float, integration: string, externalId: string, credentialId: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "integration" $integration "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "credentialId" $credentialId "scalar") (serialize-qp "delegationCredentialId" $delegationCredentialId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/selected-calendars" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available time slots for an event type
#
# GET /v2/slots
# operationId: SlotsController_2024_09_04_getAvailableSlots
export def "slots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookingUidToReschedule: string # The unique identifier of the booking being rescheduled. When provided will ensure that the original booking time appears within the returned available slots when rescheduling. (e.g. abc123def456)
  --start: string #        Time starting from which available slots should be checked.        Must be in UTC timezone as ISO 8601 datestring.        You can pass date without hours which defaults to start of day or specify hours:       2024-08-13 (will have hours 00:00:00 aka at very beginning of the date) or you can specify hours manually like 2024-08-13T09:00:00Z. (e.g. 2050-09-05)
  --end: string #      Time until which available slots should be checked.      Must be in UTC timezone as ISO 8601 datestring.      You can pass date without hours which defaults to end of day or specify hours:     2024-08-20 (will have hours 23:59:59 aka at the very end of the date) or you can specify hours manually like 2024-08-20T18:00:00Z. (e.g. 2050-09-06)
  --organizationSlug: string # The slug of the organization to which user with username belongs or team with teamSlug belongs. (e.g. org-slug)
  --teamSlug: string # The slug of the team who owns event type with eventTypeSlug - used when slots are checked for team event type. (e.g. team-slug)
  --username: string # The username of the user who owns event type with eventTypeSlug - used when slots are checked for individual user event type. (e.g. bob)
  --eventTypeSlug: string # The slug of the event type for which available slots should be checked. If slug is provided then username or teamSlug must be provided too and if relevant organizationSlug too. (e.g. event-type-slug)
  --eventTypeId: float # The ID of the event type for which available slots should be checked. (e.g. 100)
  --usernames: string # The usernames for which available slots should be checked separated by a comma.      Checking slots by usernames is used mainly for dynamic events where there is no specific event but we just want to know when 2 or more people are available.      Must contain at least 2 usernames. (e.g. alice,bob)
  --format: string # Format of slot times in response. Use 'range' to get start and end times. Use 'time' or omit this query parameter to get only start time. (e.g. range)
  --duration: float # If event type has multiple possible durations then you can specify the desired duration here. Also, if you are fetching slots for a dynamic event then you can specify the duration her which defaults to 30, meaning that returned slots will be each 30 minutes long. (e.g. 60)
  --timeZone: string # Time zone in which the available slots should be returned. Defaults to UTC. (e.g. Europe/Rome)
  --cal-api-version: string # Must be set to 2024-09-04. If not set to this value, the endpoint will default to an older version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bookingUidToReschedule" $bookingUidToReschedule "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "organizationSlug" $organizationSlug "scalar") (serialize-qp "teamSlug" $teamSlug "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "eventTypeSlug" $eventTypeSlug "scalar") (serialize-qp "eventTypeId" $eventTypeId "scalar") (serialize-qp "usernames" $usernames "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "timeZone" $timeZone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/slots" $qp)
  let extra_headers = {"cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reserve a slot
#
# POST /v2/slots/reservations
# operationId: SlotsController_2024_09_04_reserveSlot
export def "slots-reservations reserveSlot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-09-04. If not set to this value, the endpoint will default to an older version.
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  --x-cal-client-id: string # For platform customers - OAuth client ID
  eventTypeId: float # The ID of the event type for which slot should be reserved. (e.g. 1)
  slotStart: string # ISO 8601 datestring in UTC timezone representing available slot. (e.g. 2024-09-04T09:00:00Z)
  --slotDuration: float # By default slot duration is equal to event type length, but if you want to reserve a slot for an event type that has a variable length you can specify it here as a number in minutes. If you don't have this set explicitly that event type can have one of many lengths you can omit this. (e.g. 30)
  --reservationDuration: float # ONLY for authenticated requests with api key, access token or OAuth credentials (ID + secret).              For how many minutes the slot should be reserved - for this long time noone else can book this event type at `start` time. If not provided, defaults to 5 minutes. (e.g. 5)
]: any -> record<status: string, data: record<eventTypeId: float, slotStart: string, slotEnd: string, slotDuration: float, reservationUid: string, reservationDuration: float, reservationUntil: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/slots/reservations")
  let body = {eventTypeId: $eventTypeId, slotStart: $slotStart, slotDuration: $slotDuration, reservationDuration: $reservationDuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version, "Authorization": $Authorization, "x-cal-client-id": $x_cal_client_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get reserved slot
#
# GET /v2/slots/reservations/{uid}
# operationId: SlotsController_2024_09_04_getReservedSlot
export def "slots-reservations get" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-09-04. If not set to this value, the endpoint will default to an older version.
]: nothing -> record<status: string, data: record<status: string, data: record<status: string, data: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/slots/reservations/($uid)")
  let extra_headers = {"cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a reserved slot
#
# PATCH /v2/slots/reservations/{uid}
# operationId: SlotsController_2024_09_04_updateReservedSlot
export def "slots-reservations updateReservedSlot" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-09-04. If not set to this value, the endpoint will default to an older version.
  eventTypeId: float # The ID of the event type for which slot should be reserved. (e.g. 1)
  slotStart: string # ISO 8601 datestring in UTC timezone representing available slot. (e.g. 2024-09-04T09:00:00Z)
  --slotDuration: float # By default slot duration is equal to event type length, but if you want to reserve a slot for an event type that has a variable length you can specify it here as a number in minutes. If you don't have this set explicitly that event type can have one of many lengths you can omit this. (e.g. 30)
  --reservationDuration: float # ONLY for authenticated requests with api key, access token or OAuth credentials (ID + secret).              For how many minutes the slot should be reserved - for this long time noone else can book this event type at `start` time. If not provided, defaults to 5 minutes. (e.g. 5)
]: any -> record<status: string, data: record<eventTypeId: float, slotStart: string, slotEnd: string, slotDuration: float, reservationUid: string, reservationDuration: float, reservationUntil: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/slots/reservations/($uid)")
  let body = {eventTypeId: $eventTypeId, slotStart: $slotStart, slotDuration: $slotDuration, reservationDuration: $reservationDuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a reserved slot
#
# DELETE /v2/slots/reservations/{uid}
# operationId: SlotsController_2024_09_04_deleteReservedSlot
export def "slots-reservations delete" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cal-api-version: string # Must be set to 2024-09-04. If not set to this value, the endpoint will default to an older version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/slots/reservations/($uid)")
  let extra_headers = {"cal-api-version": $cal_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Stripe connect URL
#
# GET /v2/stripe/connect
# operationId: StripeController_redirect
export def "stripe-connect redirect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<authUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/stripe/connect")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save Stripe credentials
#
# GET /v2/stripe/save
# operationId: StripeController_save
export def "stripe-save save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string
  --code: string
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stripe/save" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Stripe connection
#
# GET /v2/stripe/check
# operationId: StripeController_check
export def "stripe-check check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/stripe/check")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request email verification code
#
# POST /v2/verified-resources/emails/verification-code/request
# operationId: UserVerifiedResourcesController_requestEmailVerificationCode
export def "verified-resources-emails-verification-code-request requestEmailVerificationCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  email: string # Email to verify. (e.g. acme@example.com)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/verified-resources/emails/verification-code/request")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request phone number verification code
#
# POST /v2/verified-resources/phones/verification-code/request
# operationId: UserVerifiedResourcesController_requestPhoneVerificationCode
export def "verified-resources-phones-verification-code-request requestPhoneVerificationCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  phone: string # Phone number to verify. (e.g. +372 5555 6666)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/verified-resources/phones/verification-code/request")
  let body = {phone: $phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify an email
#
# POST /v2/verified-resources/emails/verification-code/verify
# operationId: UserVerifiedResourcesController_verifyEmail
export def "verified-resources-emails-verification-code-verify verifyEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  email: string # Email to verify. (e.g. example@acme.com)
  code: string # verification code sent to the email to verify (e.g. 1ABG2C)
]: any -> record<status: string, data: record<id: float, email: string, userId: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/verified-resources/emails/verification-code/verify")
  let body = {email: $email, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify a phone number
#
# POST /v2/verified-resources/phones/verification-code/verify
# operationId: UserVerifiedResourcesController_verifyPhoneNumber
export def "verified-resources-phones-verification-code-verify verifyPhoneNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
  phone: string # phone number to verify. (e.g. +37255556666)
  code: string # verification code sent to the phone number to verify (e.g. 1ABG2C)
]: any -> record<status: string, data: record<id: float, phoneNumber: string, userId: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/verified-resources/phones/verification-code/verify")
  let body = {phone: $phone, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get list of verified emails
#
# GET /v2/verified-resources/emails
# operationId: UserVerifiedResourcesController_getVerifiedEmails
export def "verified-resources-emails list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --take: float # Maximum number of items to return (default: 250, e.g. 25)
  --skip: float # Number of items to skip (default: 0, e.g. 0)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<id: float, email: string, userId: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/verified-resources/emails" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of verified phone numbers
#
# GET /v2/verified-resources/phones
# operationId: UserVerifiedResourcesController_getVerifiedPhoneNumbers
export def "verified-resources-phones list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --take: float # Maximum number of items to return (default: 250, e.g. 25)
  --skip: float # Number of items to skip (default: 0, e.g. 0)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: table<id: float, phoneNumber: string, userId: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/verified-resources/phones" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get verified email by id
#
# GET /v2/verified-resources/emails/{id}
# operationId: UserVerifiedResourcesController_getVerifiedEmailById
export def "verified-resources-emails get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<id: float, email: string, userId: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/verified-resources/emails/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get verified phone number by id
#
# GET /v2/verified-resources/phones/{id}
# operationId: UserVerifiedResourcesController_getVerifiedPhoneById
export def "verified-resources-phones get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_ or managed user access token
]: nothing -> record<status: string, data: record<id: float, phoneNumber: string, userId: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/verified-resources/phones/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /v2/webhooks
# operationId: WebhooksController_createWebhook
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
  --payloadTemplate: string # The template of the payload that will be sent to the subscriberUrl, check cal.com/docs/core-features/webhooks for more information (e.g. {"content":"A new event has been scheduled","type":"{{type}}","name":"{{title}}","organizer":"{{organizer.name}}","booker":"{{attendees.0.name}}"})
  --active: oneof<nothing, bool>
  subscriberUrl: string
  triggers: list # e.g. [BOOKING_CREATED, BOOKING_RESCHEDULED, BOOKING_CANCELLED, BOOKING_CONFIRMED, BOOKING_REJECTED, BOOKING_COMPLETED, BOOKING_NO_SHOW, BOOKING_REOPENED]
  --secret: string
  --version: string@version-completer # The version of the webhook (e.g. 2021-10-20)
]: any -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, userId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/webhooks")
  let body = {payloadTemplate: $payloadTemplate, active: $active, subscriberUrl: $subscriberUrl, triggers: $triggers, secret: $secret, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all webhooks
#
# GET /v2/webhooks
# operationId: WebhooksController_getWebhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --take: float # Maximum number of items to return (default: 250, e.g. 25)
  --skip: float # Number of items to skip (default: 0, e.g. 0)
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
]: nothing -> record<status: string, data: table<payloadTemplate: string, triggers: list, userId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/webhooks" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /v2/webhooks/{webhookId}
# operationId: WebhooksController_updateWebhook
export def "webhooks updateWebhook" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
  --payloadTemplate: string # The template of the payload that will be sent to the subscriberUrl, check cal.com/docs/core-features/webhooks for more information (e.g. {"content":"A new event has been scheduled","type":"{{type}}","name":"{{title}}","organizer":"{{organizer.name}}","booker":"{{attendees.0.name}}"})
  --active: oneof<nothing, bool>
  --subscriberUrl: string
  --triggers: list # e.g. [BOOKING_CREATED, BOOKING_RESCHEDULED, BOOKING_CANCELLED, BOOKING_CONFIRMED, BOOKING_REJECTED, BOOKING_COMPLETED, BOOKING_NO_SHOW, BOOKING_REOPENED]
  --secret: string
  --version: string@version-completer # The version of the webhook (e.g. 2021-10-20)
]: any -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, userId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)")
  let body = {payloadTemplate: $payloadTemplate, active: $active, subscriberUrl: $subscriberUrl, triggers: $triggers, secret: $secret, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a webhook
#
# GET /v2/webhooks/{webhookId}
# operationId: WebhooksController_getWebhook
export def "webhooks get" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
]: nothing -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, userId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a webhook
#
# DELETE /v2/webhooks/{webhookId}
# operationId: WebhooksController_deleteWebhook
export def "webhooks delete" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # value must be `Bearer <token>` where `<token>` is api key prefixed with cal_
]: nothing -> record<status: string, data: record<payloadTemplate: string, triggers: list<string>, userId: float, id: float, subscriberUrl: string, active: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhookId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
