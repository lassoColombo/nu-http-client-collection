# Auto-generated client for Twilio - Insights v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_insights_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_INSIGHTS_TOKEN

const BASE_URL = "https://insights.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_INSIGHTS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://insights.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def processing-state-completer [] { ["all" "completed" "partial" "started"] }
def sort-by-completer [] { ["end_time" "start_time"] }
def answered-by-completer [] { ["fax" "human" "machine_end_beep" "machine_end_other" "machine_end_silence" "machine_start" "unknown"] }
def answered-by-completer-1 [] { ["human" "machine" "unknown_answered_by"] }
def connectivity-issue-completer [] { ["caller_id" "dropped_call" "invalid_number" "no_connectivity_issue" "number_reachability" "unknown_connectivity_issue"] }
def edge-completer [] { ["carrier_edge" "client_edge" "sdk_edge" "sip_edge" "unknown_edge"] }
def direction-completer [] { ["both" "inbound" "outbound" "unknown"] }
def processing-state-completer-1 [] { ["complete" "partial"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "conferences list" } } | get name | first)
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

# Retrieve a list of Conferences.
#
# GET /v1/Conferences
# operationId: ListConference
export def "conferences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conference-sid: string # The SID of the conference.
  --friendly-name: string # Custom label for the conference resource, up to 64 characters.
  --status: string # Conference status.
  --created-after: string # Conferences created after the provided timestamp specified in ISO 8601 format
  --created-before: string # Conferences created before the provided timestamp specified in ISO 8601 format.
  --mixer-region: string # Twilio region where the conference media was mixed.
  --tags: string # Tags applied by Twilio for common potential configuration, quality, or performance issues.
  --subaccount: string # Account SID for the subaccount whose resources you wish to retrieve.
  --detected-issues: string # Potential configuration, behavior, or performance issues detected during the conference.
  --end-reason: string # Conference end reason; e.g. last participant left, modified by API, etc.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conferences: table<account_sid: string, conference_sid: string, connect_duration_seconds: int, create_time: string, detected_issues: any, duration_seconds: int, end_reason: string, end_time: string, ended_by: string, friendly_name: string, links: record, max_concurrent_participants: int, max_participants: int, mixer_region: string, mixer_region_requested: string, processing_state: string, recording_enabled: bool, start_time: string, status: string, tag_info: any, tags: list, unique_participants: int, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "ConferenceSid" $conference_sid "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "CreatedAfter" $created_after "scalar") (serialize-qp "CreatedBefore" $created_before "scalar") (serialize-qp "MixerRegion" $mixer_region "scalar") (serialize-qp "Tags" $tags "scalar") (serialize-qp "Subaccount" $subaccount "scalar") (serialize-qp "DetectedIssues" $detected_issues "scalar") (serialize-qp "EndReason" $end_reason "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Conferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Conference.
#
# GET /v1/Conferences/{ConferenceSid}
# operationId: FetchConference
export def "conferences get" [
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, conference_sid: string, connect_duration_seconds: int, create_time: string, detected_issues: any, duration_seconds: int, end_reason: string, end_time: string, ended_by: string, friendly_name: string, links: record, max_concurrent_participants: int, max_participants: int, mixer_region: string, mixer_region_requested: string, processing_state: string, recording_enabled: bool, start_time: string, status: string, tag_info: any, tags: list<string>, unique_participants: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base ({conference_sid: (encode-path-segment $conference_sid)} | format pattern "/v1/Conferences/{conference_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Conference Participants.
#
# GET /v1/Conferences/{ConferenceSid}/Participants
# operationId: ListConferenceParticipant
export def "conferences-participants list" [
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --participant-sid: string # The unique SID identifier of the Participant.
  --label: string # User-specified label for a participant.
  --events: string # Conference events generated by application or participant activity; e.g. `hold`, `mute`, etc.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, call_direction: string, call_sid: string, call_status: string, call_type: string, coached_participants: list, conference_region: string, conference_sid: string, country_code: string, duration_seconds: int, events: any, from: string, is_coach: bool, is_moderator: bool, jitter_buffer_size: string, join_time: string, label: string, leave_time: string, metrics: any, outbound_queue_length: int, outbound_time_in_queue: int, participant_region: string, participant_sid: string, processing_state: string, properties: any, to: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "ParticipantSid" $participant_sid "scalar") (serialize-qp "Label" $label "scalar") (serialize-qp "Events" $events "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conference_sid: (encode-path-segment $conference_sid)} | format pattern "/v1/Conferences/{conference_sid}/Participants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Conference Participant Summary.
#
# GET /v1/Conferences/{ConferenceSid}/Participants/{ParticipantSid}
# operationId: FetchConferenceParticipant
export def "conferences-participants get" [
  conference_sid: string
  participant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: string # Conference events generated by application or participant activity; e.g. `hold`, `mute`, etc.
  --metrics: string # Object. Contains participant call quality metrics.
]: nothing -> record<account_sid: string, call_direction: string, call_sid: string, call_status: string, call_type: string, coached_participants: list<string>, conference_region: string, conference_sid: string, country_code: string, duration_seconds: int, events: any, from: string, is_coach: bool, is_moderator: bool, jitter_buffer_size: string, join_time: string, label: string, leave_time: string, metrics: any, outbound_queue_length: int, outbound_time_in_queue: int, participant_region: string, participant_sid: string, processing_state: string, properties: any, to: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "Events" $events "scalar") (serialize-qp "Metrics" $metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conference_sid: (encode-path-segment $conference_sid), participant_sid: (encode-path-segment $participant_sid)} | format pattern "/v1/Conferences/{conference_sid}/Participants/{participant_sid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of Programmable Video Rooms.
#
# GET /v1/Video/Rooms
# operationId: ListVideoRoomSummary
export def "video-rooms list-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --room-type: list<string> # Type of room. Can be `go`, `peer_to_peer`, `group`, or `group_small`.
  --codec: list<string> # Codecs used by participants in the room. Can be `VP8`, `H264`, or `VP9`.
  --room-name: string # Room friendly name.
  --created-after: string # Only read rooms that started on or after this ISO 8601 timestamp. (format: date-time)
  --created-before: string # Only read rooms that started before this ISO 8601 timestamp. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rooms: table<account_sid: string, codecs: list, concurrent_participants: int, create_time: string, created_method: string, duration_sec: int, edge_location: string, end_reason: string, end_time: string, links: record, max_concurrent_participants: int, max_participants: int, media_region: string, processing_state: string, recording_enabled: bool, room_name: string, room_sid: string, room_status: string, room_type: string, status_callback: string, status_callback_method: string, total_participant_duration_sec: int, total_recording_duration_sec: int, unique_participant_identities: int, unique_participants: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "RoomType" $room_type "multi") (serialize-qp "Codec" $codec "multi") (serialize-qp "RoomName" $room_name "scalar") (serialize-qp "CreatedAfter" $created_after "scalar") (serialize-qp "CreatedBefore" $created_before "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Video/Rooms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Video Log Analyzer data for a Room.
#
# GET /v1/Video/Rooms/{RoomSid}
# operationId: FetchVideoRoomSummary
export def "video-rooms get-summary" [
  room_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, codecs: list<string>, concurrent_participants: int, create_time: string, created_method: string, duration_sec: int, edge_location: string, end_reason: string, end_time: string, links: record, max_concurrent_participants: int, max_participants: int, media_region: string, processing_state: string, recording_enabled: bool, room_name: string, room_sid: string, room_status: string, room_type: string, status_callback: string, status_callback_method: string, total_participant_duration_sec: int, total_recording_duration_sec: int, unique_participant_identities: int, unique_participants: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid)} | format pattern "/v1/Video/Rooms/{room_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of room participants.
#
# GET /v1/Video/Rooms/{RoomSid}/Participants
# operationId: ListVideoParticipantSummary
export def "video-rooms-participants list-summary" [
  room_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, codecs: list, duration_sec: int, edge_location: string, end_reason: string, error_code: int, error_code_url: string, join_time: string, leave_time: string, media_region: string, participant_identity: string, participant_sid: string, properties: any, publisher_info: any, room_sid: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid)} | format pattern "/v1/Video/Rooms/{room_sid}/Participants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Video Log Analyzer data for a Room Participant.
#
# GET /v1/Video/Rooms/{RoomSid}/Participants/{ParticipantSid}
# operationId: FetchVideoParticipantSummary
export def "video-rooms-participants get-summary" [
  room_sid: string
  participant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, codecs: list<string>, duration_sec: int, edge_location: string, end_reason: string, error_code: int, error_code_url: string, join_time: string, leave_time: string, media_region: string, participant_identity: string, participant_sid: string, properties: any, publisher_info: any, room_sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), participant_sid: (encode-path-segment $participant_sid)} | format pattern "/v1/Video/Rooms/{room_sid}/Participants/{participant_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/Settings
#
# operationId: FetchAccountSettings
export def "voice-settings get-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subaccount-sid: string
]: nothing -> record<account_sid: string, advanced_features: bool, url: string, voice_trace: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "SubaccountSid" $subaccount_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Voice/Settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Voice/Settings
#
# operationId: UpdateAccountSettings
export def "voice-settings update-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advanced-features: oneof<nothing, bool>
  --subaccount-sid: string
  --voice-trace: oneof<nothing, bool>
]: any -> record<account_sid: string, advanced_features: bool, url: string, voice_trace: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base "/v1/Voice/Settings")
  let req_body = {"AdvancedFeatures": $advanced_features, "SubaccountSid": $subaccount_sid, "VoiceTrace": $voice_trace} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v1/Voice/Summaries
#
# operationId: ListCallSummaries
export def "voice-summaries list-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string
  --qp-to: string
  --from-carrier: string
  --to-carrier: string
  --from-country-code: string
  --to-country-code: string
  --branded: oneof<nothing, bool>
  --verified-caller: oneof<nothing, bool>
  --has-tag: oneof<nothing, bool>
  --start-time: string
  --end-time: string
  --call-type: string
  --call-state: string
  --direction: string
  --processing-state: string@processing-state-completer
  --sort-by: string@sort-by-completer
  --subaccount: string
  --abnormal-session: oneof<nothing, bool>
  --answered-by: string@answered-by-completer
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<call_summaries: table<account_sid: string, answered_by: string, attributes: any, call_sid: string, call_state: string, call_type: string, carrier_edge: any, client_edge: any, connect_duration: int, created_time: string, duration: int, end_time: string, from: any, processing_state: string, properties: any, sdk_edge: any, sip_edge: any, start_time: string, tags: list, to: any, trust: any, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "From" $qp_from "scalar") (serialize-qp "To" $qp_to "scalar") (serialize-qp "FromCarrier" $from_carrier "scalar") (serialize-qp "ToCarrier" $to_carrier "scalar") (serialize-qp "FromCountryCode" $from_country_code "scalar") (serialize-qp "ToCountryCode" $to_country_code "scalar") (serialize-qp "Branded" $branded "scalar") (serialize-qp "VerifiedCaller" $verified_caller "scalar") (serialize-qp "HasTag" $has_tag "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "CallType" $call_type "scalar") (serialize-qp "CallState" $call_state "scalar") (serialize-qp "Direction" $direction "scalar") (serialize-qp "ProcessingState" $processing_state "scalar") (serialize-qp "SortBy" $sort_by "scalar") (serialize-qp "Subaccount" $subaccount "scalar") (serialize-qp "AbnormalSession" $abnormal_session "scalar") (serialize-qp "AnsweredBy" $answered_by "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Voice/Summaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Annotation.
#
# GET /v1/Voice/{CallSid}/Annotation
# operationId: FetchAnnotation
export def "voice-annotation get" [
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, answered_by: string, call_score: int, call_sid: string, comment: string, connectivity_issue: string, incident: string, quality_issues: list<string>, spam: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base ({call_sid: (encode-path-segment $call_sid)} | format pattern "/v1/Voice/{call_sid}/Annotation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/Update the annotation for the call
#
# POST /v1/Voice/{CallSid}/Annotation
# operationId: UpdateAnnotation
export def "voice-annotation update" [
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --answered-by: string@answered-by-completer-1
  --call-score: int # Specify the call score. This is of type integer. Use a range of 1-5 to indicate the call experience score, with the following mapping as a reference for rating the call [5: Excellent, 4: Good, 3 : Fair, 2 : Poor, 1: Bad]. (nullable)
  --comment: string # Specify any comments pertaining to the call. This of type string with a max limit of 100 characters. Twilio does not treat this field as PII, so don’t put any PII in here.
  --connectivity-issue: string@connectivity-issue-completer
  --incident: string # Associate this call with an incident or support ticket. This is of type string with a max limit of 100 characters. Twilio does not treat this field as PII, so don’t put any PII in here.
  --quality-issues: string # Specify if the call had any subjective quality issues. Possible values, one or more of: no_quality_issue, low_volume, choppy_robotic, echo, dtmf, latency, owa, static_noise. Use comma separated values to indicate multiple quality issues for the same call
  --spam: oneof<nothing, bool> # Specify if the call was a spam call. Use this to provide feedback on whether calls placed from your account were marked as spam, or if inbound calls received by your account were unwanted spam. Is of type Boolean: true, false. Use true if the call was a spam call.
]: any -> record<account_sid: string, answered_by: string, call_score: int, call_sid: string, comment: string, connectivity_issue: string, incident: string, quality_issues: list<string>, spam: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base ({call_sid: (encode-path-segment $call_sid)} | format pattern "/v1/Voice/{call_sid}/Annotation"))
  let req_body = {"AnsweredBy": $answered_by, "CallScore": $call_score, "Comment": $comment, "ConnectivityIssue": $connectivity_issue, "Incident": $incident, "QualityIssues": $quality_issues, "Spam": $spam} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v1/Voice/{CallSid}/Events
#
# operationId: ListEvent
export def "voice-events list" [
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --edge: string@edge-completer
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<events: table<account_sid: string, call_sid: string, carrier_edge: any, client_edge: any, edge: string, group: string, level: string, name: string, sdk_edge: any, sip_edge: any, timestamp: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "Edge" $edge "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({call_sid: (encode-path-segment $call_sid)} | format pattern "/v1/Voice/{call_sid}/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/{CallSid}/Metrics
#
# operationId: ListMetric
export def "voice-metrics list" [
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --edge: string@edge-completer
  --direction: string@direction-completer
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, metrics: table<account_sid: string, call_sid: string, carrier_edge: any, client_edge: any, direction: string, edge: string, sdk_edge: any, sip_edge: any, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "Edge" $edge "scalar") (serialize-qp "Direction" $direction "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({call_sid: (encode-path-segment $call_sid)} | format pattern "/v1/Voice/{call_sid}/Metrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/{CallSid}/Summary
#
# operationId: FetchSummary
export def "voice-summary get" [
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --processing-state: string@processing-state-completer-1
]: nothing -> record<account_sid: string, annotation: any, answered_by: string, attributes: any, call_sid: string, call_state: string, call_type: string, carrier_edge: any, client_edge: any, connect_duration: int, created_time: string, duration: int, end_time: string, from: any, processing_state: string, properties: any, sdk_edge: any, sip_edge: any, start_time: string, tags: list<string>, to: any, trust: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "ProcessingState" $processing_state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({call_sid: (encode-path-segment $call_sid)} | format pattern "/v1/Voice/{call_sid}/Summary") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/{Sid}
#
# operationId: FetchCall
export def "voice get-call" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Voice/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
