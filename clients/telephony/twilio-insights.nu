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
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def ProcessingState-completer [] { ["all" "completed" "partial" "started"] }
def SortBy-completer [] { ["end_time" "start_time"] }
def AnsweredBy-completer [] { ["fax" "human" "machine_end_beep" "machine_end_other" "machine_end_silence" "machine_start" "unknown"] }
def AnsweredBy-completer-1 [] { ["human" "machine" "unknown_answered_by"] }
def ConnectivityIssue-completer [] { ["caller_id" "dropped_call" "invalid_number" "no_connectivity_issue" "number_reachability" "unknown_connectivity_issue"] }
def Edge-completer [] { ["carrier_edge" "client_edge" "sdk_edge" "sip_edge" "unknown_edge"] }
def Direction-completer [] { ["both" "inbound" "outbound" "unknown"] }
def ProcessingState-completer-1 [] { ["complete" "partial"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "conferences ListConference" } } | get name | first)
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
export def "conferences ListConference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ConferenceSid: string # The SID of the conference.
  --FriendlyName: string # Custom label for the conference resource, up to 64 characters.
  --Status: string # Conference status.
  --CreatedAfter: string # Conferences created after the provided timestamp specified in ISO 8601 format
  --CreatedBefore: string # Conferences created before the provided timestamp specified in ISO 8601 format.
  --MixerRegion: string # Twilio region where the conference media was mixed.
  --Tags: string # Tags applied by Twilio for common potential configuration, quality, or performance issues.
  --Subaccount: string # Account SID for the subaccount whose resources you wish to retrieve.
  --DetectedIssues: string # Potential configuration, behavior, or performance issues detected during the conference.
  --EndReason: string # Conference end reason; e.g. last participant left, modified by API, etc.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<conferences: table<account_sid: string, conference_sid: string, connect_duration_seconds: int, create_time: string, detected_issues: any, duration_seconds: int, end_reason: string, end_time: string, ended_by: string, friendly_name: string, links: record, max_concurrent_participants: int, max_participants: int, mixer_region: string, mixer_region_requested: string, processing_state: string, recording_enabled: bool, start_time: string, status: string, tag_info: any, tags: list, unique_participants: int, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "ConferenceSid" $ConferenceSid "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "CreatedAfter" $CreatedAfter "scalar") (serialize-qp "CreatedBefore" $CreatedBefore "scalar") (serialize-qp "MixerRegion" $MixerRegion "scalar") (serialize-qp "Tags" $Tags "scalar") (serialize-qp "Subaccount" $Subaccount "scalar") (serialize-qp "DetectedIssues" $DetectedIssues "scalar") (serialize-qp "EndReason" $EndReason "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Conferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Conference.
#
# GET /v1/Conferences/{ConferenceSid}
# operationId: FetchConference
export def "conferences FetchConference" [
  ConferenceSid: string
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
  let full_url = (build-url $base $"/v1/Conferences/($ConferenceSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Conference Participants.
#
# GET /v1/Conferences/{ConferenceSid}/Participants
# operationId: ListConferenceParticipant
export def "conferences-participants ListConferenceParticipant" [
  ConferenceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ParticipantSid: string # The unique SID identifier of the Participant.
  --Label: string # User-specified label for a participant.
  --Events: string # Conference events generated by application or participant activity; e.g. `hold`, `mute`, etc.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, call_direction: string, call_sid: string, call_status: string, call_type: string, coached_participants: list, conference_region: string, conference_sid: string, country_code: string, duration_seconds: int, events: any, from: string, is_coach: bool, is_moderator: bool, jitter_buffer_size: string, join_time: string, label: string, leave_time: string, metrics: any, outbound_queue_length: int, outbound_time_in_queue: int, participant_region: string, participant_sid: string, processing_state: string, properties: any, to: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "ParticipantSid" $ParticipantSid "scalar") (serialize-qp "Label" $Label "scalar") (serialize-qp "Events" $Events "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Conferences/($ConferenceSid)/Participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Conference Participant Summary.
#
# GET /v1/Conferences/{ConferenceSid}/Participants/{ParticipantSid}
# operationId: FetchConferenceParticipant
export def "conferences-participants FetchConferenceParticipant" [
  ConferenceSid: string
  ParticipantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Events: string # Conference events generated by application or participant activity; e.g. `hold`, `mute`, etc.
  --Metrics: string # Object. Contains participant call quality metrics.
]: nothing -> record<account_sid: string, call_direction: string, call_sid: string, call_status: string, call_type: string, coached_participants: list<string>, conference_region: string, conference_sid: string, country_code: string, duration_seconds: int, events: any, from: string, is_coach: bool, is_moderator: bool, jitter_buffer_size: string, join_time: string, label: string, leave_time: string, metrics: any, outbound_queue_length: int, outbound_time_in_queue: int, participant_region: string, participant_sid: string, processing_state: string, properties: any, to: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "Events" $Events "scalar") (serialize-qp "Metrics" $Metrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Conferences/($ConferenceSid)/Participants/($ParticipantSid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of Programmable Video Rooms.
#
# GET /v1/Video/Rooms
# operationId: ListVideoRoomSummary
export def "video-rooms ListVideoRoomSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --RoomType: list # Type of room. Can be `go`, `peer_to_peer`, `group`, or `group_small`.
  --Codec: list # Codecs used by participants in the room. Can be `VP8`, `H264`, or `VP9`.
  --RoomName: string # Room friendly name.
  --CreatedAfter: string # Only read rooms that started on or after this ISO 8601 timestamp. (format: date-time)
  --CreatedBefore: string # Only read rooms that started before this ISO 8601 timestamp. (format: date-time)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rooms: table<account_sid: string, codecs: list, concurrent_participants: int, create_time: string, created_method: string, duration_sec: int, edge_location: string, end_reason: string, end_time: string, links: record, max_concurrent_participants: int, max_participants: int, media_region: string, processing_state: string, recording_enabled: bool, room_name: string, room_sid: string, room_status: string, room_type: string, status_callback: string, status_callback_method: string, total_participant_duration_sec: int, total_recording_duration_sec: int, unique_participant_identities: int, unique_participants: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "RoomType" $RoomType "multi") (serialize-qp "Codec" $Codec "multi") (serialize-qp "RoomName" $RoomName "scalar") (serialize-qp "CreatedAfter" $CreatedAfter "scalar") (serialize-qp "CreatedBefore" $CreatedBefore "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Video/Rooms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Video Log Analyzer data for a Room.
#
# GET /v1/Video/Rooms/{RoomSid}
# operationId: FetchVideoRoomSummary
export def "video-rooms FetchVideoRoomSummary" [
  RoomSid: string
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
  let full_url = (build-url $base $"/v1/Video/Rooms/($RoomSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of room participants.
#
# GET /v1/Video/Rooms/{RoomSid}/Participants
# operationId: ListVideoParticipantSummary
export def "video-rooms-participants ListVideoParticipantSummary" [
  RoomSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, codecs: list, duration_sec: int, edge_location: string, end_reason: string, error_code: int, error_code_url: string, join_time: string, leave_time: string, media_region: string, participant_identity: string, participant_sid: string, properties: any, publisher_info: any, room_sid: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Video/Rooms/($RoomSid)/Participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Video Log Analyzer data for a Room Participant.
#
# GET /v1/Video/Rooms/{RoomSid}/Participants/{ParticipantSid}
# operationId: FetchVideoParticipantSummary
export def "video-rooms-participants FetchVideoParticipantSummary" [
  RoomSid: string
  ParticipantSid: string
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
  let full_url = (build-url $base $"/v1/Video/Rooms/($RoomSid)/Participants/($ParticipantSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/Settings
#
# operationId: FetchAccountSettings
export def "voice-settings FetchAccountSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SubaccountSid: string
]: nothing -> record<account_sid: string, advanced_features: bool, url: string, voice_trace: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "SubaccountSid" $SubaccountSid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Voice/Settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Voice/Settings
#
# operationId: UpdateAccountSettings
export def "voice-settings UpdateAccountSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AdvancedFeatures: oneof<nothing, bool>
  --SubaccountSid: string
  --VoiceTrace: oneof<nothing, bool>
]: any -> record<account_sid: string, advanced_features: bool, url: string, voice_trace: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base "/v1/Voice/Settings")
  let body = {AdvancedFeatures: $AdvancedFeatures, SubaccountSid: $SubaccountSid, VoiceTrace: $VoiceTrace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Voice/Summaries
#
# operationId: ListCallSummaries
export def "voice-summaries ListCallSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --From: string
  --To: string
  --FromCarrier: string
  --ToCarrier: string
  --FromCountryCode: string
  --ToCountryCode: string
  --Branded: oneof<nothing, bool>
  --VerifiedCaller: oneof<nothing, bool>
  --HasTag: oneof<nothing, bool>
  --StartTime: string
  --EndTime: string
  --CallType: string
  --CallState: string
  --Direction: string
  --ProcessingState: string@ProcessingState-completer
  --SortBy: string@SortBy-completer
  --Subaccount: string
  --AbnormalSession: oneof<nothing, bool>
  --AnsweredBy: string@AnsweredBy-completer
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<call_summaries: table<account_sid: string, answered_by: string, attributes: any, call_sid: string, call_state: string, call_type: string, carrier_edge: any, client_edge: any, connect_duration: int, created_time: string, duration: int, end_time: string, from: any, processing_state: string, properties: any, sdk_edge: any, sip_edge: any, start_time: string, tags: list, to: any, trust: any, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "From" $From "scalar") (serialize-qp "To" $To "scalar") (serialize-qp "FromCarrier" $FromCarrier "scalar") (serialize-qp "ToCarrier" $ToCarrier "scalar") (serialize-qp "FromCountryCode" $FromCountryCode "scalar") (serialize-qp "ToCountryCode" $ToCountryCode "scalar") (serialize-qp "Branded" $Branded "scalar") (serialize-qp "VerifiedCaller" $VerifiedCaller "scalar") (serialize-qp "HasTag" $HasTag "scalar") (serialize-qp "StartTime" $StartTime "scalar") (serialize-qp "EndTime" $EndTime "scalar") (serialize-qp "CallType" $CallType "scalar") (serialize-qp "CallState" $CallState "scalar") (serialize-qp "Direction" $Direction "scalar") (serialize-qp "ProcessingState" $ProcessingState "scalar") (serialize-qp "SortBy" $SortBy "scalar") (serialize-qp "Subaccount" $Subaccount "scalar") (serialize-qp "AbnormalSession" $AbnormalSession "scalar") (serialize-qp "AnsweredBy" $AnsweredBy "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Voice/Summaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Annotation.
#
# GET /v1/Voice/{CallSid}/Annotation
# operationId: FetchAnnotation
export def "voice-annotation FetchAnnotation" [
  CallSid: string
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
  let full_url = (build-url $base $"/v1/Voice/($CallSid)/Annotation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/Update the annotation for the call
#
# POST /v1/Voice/{CallSid}/Annotation
# operationId: UpdateAnnotation
export def "voice-annotation UpdateAnnotation" [
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AnsweredBy: string@AnsweredBy-completer-1
  --CallScore: int # Specify the call score. This is of type integer. Use a range of 1-5 to indicate the call experience score, with the following mapping as a reference for rating the call [5: Excellent, 4: Good, 3 : Fair, 2 : Poor, 1: Bad]. (nullable)
  --Comment: string # Specify any comments pertaining to the call. This of type string with a max limit of 100 characters. Twilio does not treat this field as PII, so don’t put any PII in here.
  --ConnectivityIssue: string@ConnectivityIssue-completer
  --Incident: string # Associate this call with an incident or support ticket. This is of type string with a max limit of 100 characters. Twilio does not treat this field as PII, so don’t put any PII in here.
  --QualityIssues: string # Specify if the call had any subjective quality issues. Possible values, one or more of:  no_quality_issue, low_volume, choppy_robotic, echo, dtmf, latency, owa, static_noise. Use comma separated values to indicate multiple quality issues for the same call
  --Spam: oneof<nothing, bool> # Specify if the call was a spam call. Use this to provide feedback on whether calls placed from your account were marked as spam, or if inbound calls received by your account were unwanted spam. Is of type Boolean: true, false. Use true if the call was a spam call.
]: any -> record<account_sid: string, answered_by: string, call_score: int, call_sid: string, comment: string, connectivity_issue: string, incident: string, quality_issues: list<string>, spam: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let full_url = (build-url $base $"/v1/Voice/($CallSid)/Annotation")
  let body = {AnsweredBy: $AnsweredBy, CallScore: $CallScore, Comment: $Comment, ConnectivityIssue: $ConnectivityIssue, Incident: $Incident, QualityIssues: $QualityIssues, Spam: $Spam} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Voice/{CallSid}/Events
#
# operationId: ListEvent
export def "voice-events ListEvent" [
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Edge: string@Edge-completer
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<events: table<account_sid: string, call_sid: string, carrier_edge: any, client_edge: any, edge: string, group: string, level: string, name: string, sdk_edge: any, sip_edge: any, timestamp: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "Edge" $Edge "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Voice/($CallSid)/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/{CallSid}/Metrics
#
# operationId: ListMetric
export def "voice-metrics ListMetric" [
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Edge: string@Edge-completer
  --Direction: string@Direction-completer
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, metrics: table<account_sid: string, call_sid: string, carrier_edge: any, client_edge: any, direction: string, edge: string, sdk_edge: any, sip_edge: any, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "Edge" $Edge "scalar") (serialize-qp "Direction" $Direction "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Voice/($CallSid)/Metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/{CallSid}/Summary
#
# operationId: FetchSummary
export def "voice-summary FetchSummary" [
  CallSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ProcessingState: string@ProcessingState-completer-1
]: nothing -> record<account_sid: string, annotation: any, answered_by: string, attributes: any, call_sid: string, call_state: string, call_type: string, carrier_edge: any, client_edge: any, connect_duration: int, created_time: string, duration: int, end_time: string, from: any, processing_state: string, properties: any, sdk_edge: any, sip_edge: any, start_time: string, tags: list<string>, to: any, trust: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://insights.twilio.com")
  let qp = [(serialize-qp "ProcessingState" $ProcessingState "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Voice/($CallSid)/Summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Voice/{Sid}
#
# operationId: FetchCall
export def "voice FetchCall" [
  Sid: string
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
  let full_url = (build-url $base $"/v1/Voice/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
