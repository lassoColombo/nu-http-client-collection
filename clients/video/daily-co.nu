# Auto-generated client for Daily API v1.1.1
# Source: https://docs.daily.co/openapi.json
# Auth: --token flag or $env.DAILY_API_TOKEN

const BASE_URL = "https://api.daily.co/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DAILY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.daily.co/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mergeStrategy-completer [] { ["replace" "shallow-merge"] }
def type-completer [] { ["cloud" "cloud-audio-only" "raw-tracks"] }
def type-completer-1 [] { ["pin_dialin" "pinless_dialin"] }
def retryType-completer [] { ["circuit-breaker" "exponential"] }
def logLevel-completer [] { ["DEBUG" "ERROR" "INFO"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rooms ListRooms" } } | get name | first)
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

# /rooms
#
# GET /rooms
# operationId: ListRooms
export def "rooms ListRooms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Sets the number of rooms listed (format: int32)
  --ending-before: string # Returns room objects created before a provided room  id
  --starting-after: string # Returns room objects created after a provided room id
]: nothing -> record<total_count: int, data: table<id: string, name: string, api_created: bool, privacy: string, url: string, created_at: string, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rooms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /rooms
#
# POST /rooms
# operationId: CreateRoom
# --properties shape: {nbf?: int, exp?: int, max_participants?: int, enable_people_ui?: bool, enable_cpu_warning_notifications?: bool, enable_pip_ui?: bool, enable_emoji_reactions?: bool, enable_hand_raising?: bool, enable_prejoin_ui?: bool, enable_live_captions_ui?: bool, enable_network_ui?: bool, enable_noise_cancellation_ui?: bool, enable_breakout_rooms?: bool, enable_knocking?: bool, enable_screenshare?: bool, enable_video_processing_ui?: bool, enable_chat?: bool, enable_shared_chat_history?: bool, start_video_off?: bool, start_audio_off?: bool, enable_recording?: any, eject_at_room_exp?: bool, eject_after_elapsed?: int, enable_advanced_chat?: bool, enable_hidden_participants?: bool, enable_mesh_sfu?: bool, sfu_switchover?: float, enable_adaptive_simulcast?: bool, enable_multiparty_adaptive_simulcast?: bool, enforce_unique_user_ids?: bool, experimental_optimize_large_calls?: bool, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", meeting_join_hook?: string, geo?: string, rtmp_geo?: string, disable_rtmp_geo_fallback?: bool, recordings_bucket?: record, enable_terse_logging?: bool, auto_transcription_settings?: record, enable_transcription_storage?: bool, transcription_bucket?: record, recordings_template?: string, transcription_template?: string, enable_dialout?: bool, dialout_config?: record, streaming_endpoints?: list, permissions?: record, sip?: record}
export def "rooms CreateRoom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --privacy: string
  --properties: record # shape: {nbf?: int, exp?: int, max_participants?: int, enable_people_ui?: bool, enable_cpu_warning_notifications?: bool, enable_pip_ui?: bool, enable_emoji_reactions?: bool, enable_hand_raising?: bool, enable_prejoin_ui?: bool, enable_live_captions_ui?: bool, enable_network_ui?: bool, enable_noise_cancellation_ui?: bool, enable_breakout_rooms?: bool, enable_knocking?: bool, enable_screenshare?: bool, enable_video_processing_ui?: bool, enable_chat?: bool, enable_shared_chat_history?: bool, start_video_off?: bool, start_audio_off?: bool, enable_recording?: any, eject_at_room_exp?: bool, eject_after_elapsed?: int, enable_advanced_chat?: bool, enable_hidden_participants?: bool, enable_mesh_sfu?: bool, sfu_switchover?: float, enable_adaptive_simulcast?: bool, enable_multiparty_adaptive_simulcast?: bool, enforce_unique_user_ids?: bool, experimental_optimize_large_calls?: bool, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", meeting_join_hook?: string, geo?: string, rtmp_geo?: string, disable_rtmp_geo_fallback?: bool, recordings_bucket?: record, enable_terse_logging?: bool, auto_transcription_settings?: record, enable_transcription_storage?: bool, transcription_bucket?: record, recordings_template?: string, transcription_template?: string, enable_dialout?: bool, dialout_config?: record, streaming_endpoints?: list, permissions?: record, sip?: record}
]: any -> record<id: string, name: string, api_created: bool, privacy: string, url: string, created_at: string, config: record<id: string, name: string, api_created: bool, privacy: string, url: string, created_at: string, config: record<nbf: int, exp: int, max_participants: int, enable_people_ui: bool, enable_cpu_warning_notifications: bool, enable_pip_ui: bool, enable_emoji_reactions: bool, enable_hand_raising: bool, enable_prejoin_ui: bool, enable_live_captions_ui: bool, enable_network_ui: bool, enable_noise_cancellation_ui: bool, enable_breakout_rooms: bool, enable_knocking: bool, enable_screenshare: bool, enable_video_processing_ui: bool, enable_chat: bool, enable_shared_chat_history: bool, start_video_off: bool, start_audio_off: bool, enable_recording: any, eject_at_room_exp: bool, eject_after_elapsed: int, enable_advanced_chat: bool, enable_hidden_participants: bool, enable_mesh_sfu: bool, sfu_switchover: float, enable_adaptive_simulcast: bool, enable_multiparty_adaptive_simulcast: bool, enforce_unique_user_ids: bool, experimental_optimize_large_calls: bool, lang: string, meeting_join_hook: string, geo: string, rtmp_geo: string, disable_rtmp_geo_fallback: bool, recordings_bucket: record, enable_terse_logging: bool, auto_transcription_settings: record, enable_transcription_storage: bool, transcription_bucket: record, recordings_template: string, transcription_template: string, enable_dialout: bool, dialout_config: record, streaming_endpoints: list, permissions: record, sip_uri: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms")
  let body = {name: $name, privacy: $privacy, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name
#
# GET /rooms/{room_name}
# operationId: GetRoomConfig
export def "rooms GetRoomConfig" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, api_created: bool, privacy: string, url: string, created_at: string, config: record<nbf: int, exp: int, max_participants: int, enable_people_ui: bool, enable_cpu_warning_notifications: bool, enable_pip_ui: bool, enable_emoji_reactions: bool, enable_hand_raising: bool, enable_prejoin_ui: bool, enable_live_captions_ui: bool, enable_network_ui: bool, enable_noise_cancellation_ui: bool, enable_breakout_rooms: bool, enable_knocking: bool, enable_screenshare: bool, enable_video_processing_ui: bool, enable_chat: bool, enable_shared_chat_history: bool, start_video_off: bool, start_audio_off: bool, enable_recording: any, eject_at_room_exp: bool, eject_after_elapsed: int, enable_advanced_chat: bool, enable_hidden_participants: bool, enable_mesh_sfu: bool, sfu_switchover: float, enable_adaptive_simulcast: bool, enable_multiparty_adaptive_simulcast: bool, enforce_unique_user_ids: bool, experimental_optimize_large_calls: bool, lang: string, meeting_join_hook: string, geo: string, rtmp_geo: string, disable_rtmp_geo_fallback: bool, recordings_bucket: record<bucket_name: string, bucket_region: string, assume_role_arn: string, allow_api_access: bool, allow_streaming_from_bucket: bool>, enable_terse_logging: bool, auto_transcription_settings: record, enable_transcription_storage: bool, transcription_bucket: record<bucket_name: string, bucket_region: string, assume_role_arn: string, allow_api_access: bool>, recordings_template: string, transcription_template: string, enable_dialout: bool, dialout_config: record<allow_room_start: bool, dialout_geo: string, max_idle_timeout_sec: float>, streaming_endpoints: list<record>, permissions: record<hasPresence: bool, canSend: any, canReceive: record, canAdmin: any>, sip_uri: record<endpoint: string, extra_endpoints: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# rooms/:name
#
# POST /rooms/{room_name}
# operationId: SetRoomConfig
# --properties shape: {nbf?: int, exp?: int, max_participants?: int, enable_people_ui?: bool, enable_cpu_warning_notifications?: bool, enable_pip_ui?: bool, enable_emoji_reactions?: bool, enable_hand_raising?: bool, enable_prejoin_ui?: bool, enable_live_captions_ui?: bool, enable_network_ui?: bool, enable_noise_cancellation_ui?: bool, enable_breakout_rooms?: bool, enable_knocking?: bool, enable_screenshare?: bool, enable_video_processing_ui?: bool, enable_chat?: bool, enable_shared_chat_history?: bool, start_video_off?: bool, start_audio_off?: bool, enable_recording?: any, eject_at_room_exp?: bool, eject_after_elapsed?: int, enable_advanced_chat?: bool, enable_hidden_participants?: bool, enable_mesh_sfu?: bool, sfu_switchover?: float, enable_adaptive_simulcast?: bool, enable_multiparty_adaptive_simulcast?: bool, enforce_unique_user_ids?: bool, experimental_optimize_large_calls?: bool, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", meeting_join_hook?: string, geo?: string, rtmp_geo?: string, disable_rtmp_geo_fallback?: bool, recordings_bucket?: record, enable_terse_logging?: bool, auto_transcription_settings?: record, enable_transcription_storage?: bool, transcription_bucket?: record, recordings_template?: string, transcription_template?: string, enable_dialout?: bool, dialout_config?: record, streaming_endpoints?: list, permissions?: record, sip?: record}
export def "rooms SetRoomConfig" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --privacy: string
  --properties: record # shape: {nbf?: int, exp?: int, max_participants?: int, enable_people_ui?: bool, enable_cpu_warning_notifications?: bool, enable_pip_ui?: bool, enable_emoji_reactions?: bool, enable_hand_raising?: bool, enable_prejoin_ui?: bool, enable_live_captions_ui?: bool, enable_network_ui?: bool, enable_noise_cancellation_ui?: bool, enable_breakout_rooms?: bool, enable_knocking?: bool, enable_screenshare?: bool, enable_video_processing_ui?: bool, enable_chat?: bool, enable_shared_chat_history?: bool, start_video_off?: bool, start_audio_off?: bool, enable_recording?: any, eject_at_room_exp?: bool, eject_after_elapsed?: int, enable_advanced_chat?: bool, enable_hidden_participants?: bool, enable_mesh_sfu?: bool, sfu_switchover?: float, enable_adaptive_simulcast?: bool, enable_multiparty_adaptive_simulcast?: bool, enforce_unique_user_ids?: bool, experimental_optimize_large_calls?: bool, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", meeting_join_hook?: string, geo?: string, rtmp_geo?: string, disable_rtmp_geo_fallback?: bool, recordings_bucket?: record, enable_terse_logging?: bool, auto_transcription_settings?: record, enable_transcription_storage?: bool, transcription_bucket?: record, recordings_template?: string, transcription_template?: string, enable_dialout?: bool, dialout_config?: record, streaming_endpoints?: list, permissions?: record, sip?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)")
  let body = {privacy: $privacy, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name
#
# DELETE /rooms/{room_name}
# operationId: DeleteRoom
export def "rooms DeleteRoom" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# rooms/:name/presence
#
# GET /rooms/{room_name}/presence
# operationId: GetRoomPresence
export def "rooms-presence GetRoomPresence" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Sets the number of participants returned. (format: int32)
  --userId: string # Returns presence for the user with the given userId, if available. The userId is specified via a [meeting token](/products/rest-api/meeting-tokens/config#user_id).
  --userName: string # Returns presence for the user with the given name, if available.
]: nothing -> record<total_count: int, data: table<id: string, room: string, userId: string, userName: string, mtgSessionId: string, joinTime: string, duration: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "userName" $userName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rooms/($room_name)/presence" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# rooms/:name/send-app-message
#
# POST /rooms/{room_name}/send-app-message
# operationId: SendAppMessage
export def "rooms-send-app-message SendAppMessage" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A javascript object that can be serialized into JSON. Data sent must be within the 4kb size limit.
  --recipient: string # Determines who will recieve the message. It can be either a participant session_id, or `*`. The `*` value is the default, and means that the message is a "broadcast" message intended for all participants. (default: *)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/send-app-message")
  let body = {data: $data, recipient: $recipient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/get-session-data
#
# GET /rooms/{room_name}/get-session-data
# operationId: GetSessionData
export def "rooms-get-session-data GetSessionData" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/get-session-data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# rooms/:name/set-session-data
#
# POST /rooms/{room_name}/set-session-data
# operationId: SetSessionData
export def "rooms-set-session-data SetSessionData" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # A javascript object that can be serialized into JSON. Defaults to `{}`.
  --mergeStrategy: string@mergeStrategy-completer # `replace` to replace the existing meeting session data object or `shallow-merge` to merge with it. (default: replace)
  --keysToDelete: list # Optional list of keys to delete from the existing meeting session data object when using `shallow-merge`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/set-session-data")
  let body = {data: $data, mergeStrategy: $mergeStrategy, keysToDelete: $keysToDelete} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/eject
#
# POST /rooms/{room_name}/eject
# operationId: Eject
export def "rooms-eject Eject" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # List of participant ids (max 100) to eject from the existing meeting session.
  --user-ids: list # List of user_ids (max 100) to eject from the existing meeting session.
  --ban: oneof<nothing, bool> # If true, participants are prevented from (re)joining with the given user_ids. (default: false)
]: any -> record<ejectedIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/eject")
  let body = {ids: $ids, user_ids: $user_ids, ban: $ban} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/update-permissions
#
# POST /rooms/{room_name}/update-permissions
# operationId: UpdatePermissions
export def "rooms-update-permissions UpdatePermissions" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/update-permissions")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/recordings/start
#
# POST /rooms/{room_name}/recordings/start
# operationId: RoomRecordingsStart
export def "rooms-recordings-start RoomRecordingsStart" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: float # Property that specifies the output width of the given stream.
  --height: float # Property that specifies the output height of the given stream.
  --fps: float # Property that specifies the video frame rate per second.
  --videoBitrate: float # Property that specifies the video bitrate for the output video in kilobits per second (kbps).
  --audioBitrate: float # Property that specifies the audio bitrate for the output audio in kilobits per second (kbps).
  --minIdleTimeOut: float # Amount of time in seconds to wait before ending a recording or live stream when the room is idle (e.g. when all users have muted video and audio). Default: 300 (seconds). Note: Once the timeout has been reached, it typically takes an additional 1-3 minutes for the recording or live stream to be shut down.
  --maxDuration: float # Maximum duration in seconds after which recording/streaming is forcefully stopped. Default: \`15000\` seconds (3 hours). This is a preventive circuit breaker to prevent billing surprises in case a user starts recording/streaming and leaves the room.
  --backgroundColor: string # Specifies the background color of the stream, formatted as \#rrggbb or \#aarrggbb string.
  --instanceId: string # UUID for a streaming or recording session. Used when multiple streaming or recording sessions are running for single room.
  --type: string@type-completer # The type of recording that will be started. (default: cloud)
  --layout: any
  --dataOutputs: list # Specifies the types of recording-associated data outputs ("event-json", "transcript-webvtt", "chat-webvtt") to start. Value must be an array listing the requested data outputs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/recordings/start")
  let body = {width: $width, height: $height, fps: $fps, videoBitrate: $videoBitrate, audioBitrate: $audioBitrate, minIdleTimeOut: $minIdleTimeOut, maxDuration: $maxDuration, backgroundColor: $backgroundColor, instanceId: $instanceId, type: $type, layout: $layout, dataOutputs: $dataOutputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/recordings/update
#
# POST /rooms/{room_name}/recordings/update
# operationId: RoomRecordingsUpdate
export def "rooms-recordings-update RoomRecordingsUpdate" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: float # Property that specifies the output width of the given stream.
  --height: float # Property that specifies the output height of the given stream.
  --fps: float # Property that specifies the video frame rate per second.
  --videoBitrate: float # Property that specifies the video bitrate for the output video in kilobits per second (kbps).
  --audioBitrate: float # Property that specifies the audio bitrate for the output audio in kilobits per second (kbps).
  --minIdleTimeOut: float # Amount of time in seconds to wait before ending a recording or live stream when the room is idle (e.g. when all users have muted video and audio). Default: 300 (seconds). Note: Once the timeout has been reached, it typically takes an additional 1-3 minutes for the recording or live stream to be shut down.
  --maxDuration: float # Maximum duration in seconds after which recording/streaming is forcefully stopped. Default: \`15000\` seconds (3 hours). This is a preventive circuit breaker to prevent billing surprises in case a user starts recording/streaming and leaves the room.
  --backgroundColor: string # Specifies the background color of the stream, formatted as \#rrggbb or \#aarrggbb string.
  --instanceId: string # UUID for a streaming or recording session. Used when multiple streaming or recording sessions are running for single room.
  --type: string # specify type of recording (`cloud`, `raw-tracks`, `local`) to start. Particular recording type must be enabled for the room or domain with enable_recording property.
  --layout: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/recordings/update")
  let body = {width: $width, height: $height, fps: $fps, videoBitrate: $videoBitrate, audioBitrate: $audioBitrate, minIdleTimeOut: $minIdleTimeOut, maxDuration: $maxDuration, backgroundColor: $backgroundColor, instanceId: $instanceId, type: $type, layout: $layout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/recordings/stop
#
# POST /rooms/{room_name}/recordings/stop
# operationId: RoomRecordingsStop
export def "rooms-recordings-stop RoomRecordingsStop" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/recordings/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# rooms/:name/live-streaming/start
#
# POST /rooms/{room_name}/live-streaming/start
# operationId: RoomLivestreamingStart
# --endpoints item shape: {endpoint: string}
export def "rooms-live-streaming-start RoomLivestreamingStart" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: float # Property that specifies the output width of the given stream.
  --height: float # Property that specifies the output height of the given stream.
  --fps: float # Property that specifies the video frame rate per second.
  --videoBitrate: float # Property that specifies the video bitrate for the output video in kilobits per second (kbps).
  --audioBitrate: float # Property that specifies the audio bitrate for the output audio in kilobits per second (kbps).
  --minIdleTimeOut: float # Amount of time in seconds to wait before ending a recording or live stream when the room is idle (e.g. when all users have muted video and audio). Default: 300 (seconds). Note: Once the timeout has been reached, it typically takes an additional 1-3 minutes for the recording or live stream to be shut down.
  --maxDuration: float # Maximum duration in seconds after which recording/streaming is forcefully stopped. Default: \`15000\` seconds (3 hours). This is a preventive circuit breaker to prevent billing surprises in case a user starts recording/streaming and leaves the room.
  --backgroundColor: string # Specifies the background color of the stream, formatted as \#rrggbb or \#aarrggbb string.
  --instanceId: string # UUID for a streaming or recording session. Used when multiple streaming or recording sessions are running for single room.
  --type: string@type-completer # The type of recording that will be started. (default: cloud)
  --layout: any
  --dataOutputs: list # Specifies the types of recording-associated data outputs ("event-json", "transcript-webvtt", "chat-webvtt") to start. Value must be an array listing the requested data outputs.
  --rtmpUrl: any
  --endpoints: list # item shape: {endpoint: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/live-streaming/start")
  let body = {width: $width, height: $height, fps: $fps, videoBitrate: $videoBitrate, audioBitrate: $audioBitrate, minIdleTimeOut: $minIdleTimeOut, maxDuration: $maxDuration, backgroundColor: $backgroundColor, instanceId: $instanceId, type: $type, layout: $layout, dataOutputs: $dataOutputs, rtmpUrl: $rtmpUrl, endpoints: $endpoints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/live-streaming/update
#
# POST /rooms/{room_name}/live-streaming/update
# operationId: RoomLivestreamingUpdate
# --endpoints item shape: {endpoint: string}
export def "rooms-live-streaming-update RoomLivestreamingUpdate" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: float # Property that specifies the output width of the given stream.
  --height: float # Property that specifies the output height of the given stream.
  --fps: float # Property that specifies the video frame rate per second.
  --videoBitrate: float # Property that specifies the video bitrate for the output video in kilobits per second (kbps).
  --audioBitrate: float # Property that specifies the audio bitrate for the output audio in kilobits per second (kbps).
  --minIdleTimeOut: float # Amount of time in seconds to wait before ending a recording or live stream when the room is idle (e.g. when all users have muted video and audio). Default: 300 (seconds). Note: Once the timeout has been reached, it typically takes an additional 1-3 minutes for the recording or live stream to be shut down.
  --maxDuration: float # Maximum duration in seconds after which recording/streaming is forcefully stopped. Default: \`15000\` seconds (3 hours). This is a preventive circuit breaker to prevent billing surprises in case a user starts recording/streaming and leaves the room.
  --backgroundColor: string # Specifies the background color of the stream, formatted as \#rrggbb or \#aarrggbb string.
  --instanceId: string # UUID for a streaming or recording session. Used when multiple streaming or recording sessions are running for single room.
  --type: string@type-completer # The type of recording that will be started. (default: cloud)
  --layout: any
  --dataOutputs: list # Specifies the types of recording-associated data outputs ("event-json", "transcript-webvtt", "chat-webvtt") to start. Value must be an array listing the requested data outputs.
  --rtmpUrl: any
  --endpoints: list # item shape: {endpoint: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/live-streaming/update")
  let body = {width: $width, height: $height, fps: $fps, videoBitrate: $videoBitrate, audioBitrate: $audioBitrate, minIdleTimeOut: $minIdleTimeOut, maxDuration: $maxDuration, backgroundColor: $backgroundColor, instanceId: $instanceId, type: $type, layout: $layout, dataOutputs: $dataOutputs, rtmpUrl: $rtmpUrl, endpoints: $endpoints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/live-streaming/stop
#
# POST /rooms/{room_name}/live-streaming/stop
# operationId: RoomLivestreamingStop
export def "rooms-live-streaming-stop RoomLivestreamingStop" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/live-streaming/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# rooms/:name/transcription/start
#
# POST /rooms/{room_name}/transcription/start
# operationId: RoomTranscriptionStart
export def "rooms-transcription-start RoomTranscriptionStart" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # See Deepgram's documentation for [`language`](https://developers.deepgram.com/docs/language)
  --model: string # See Deepgram's documentation for [`model`](https://developers.deepgram.com/docs/model)
  --tier: string # This field is deprecated, use `model` instead
  --profanity-filter: oneof<nothing, bool> # See Deepgram's documentation for [`profanity filter`](https://developers.deepgram.com/docs/profanity-filter)
  --punctuate: oneof<nothing, bool> # See Deepgram's documentation for [`punctuate`](https://developers.deepgram.com/docs/punctuation)
  --endpointing: any # See Deepgram's documentation for [`endpointing`](https://developers.deepgram.com/docs/endpointing)
  --redact: any # See Deepgram's documentation for [`redact`](https://developers.deepgram.com/docs/redaction)
  --extra: record # Specify any Deepgram parameters. See Deepgram's documentation for [available streaming options](https://developers.deepgram.com/docs/features-overview)
  --includeRawResponse: oneof<nothing, bool> # Whether Deepgram's raw response should be included in all transcription messages
  --instanceId: string # A developer provided ID of an instance, which is used for multi-instance transcription.
  --participants: list # A list of participant IDs to be transcribed. Only the participant IDs included in this array will be processed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/transcription/start")
  let body = {language: $language, model: $model, tier: $tier, profanity_filter: $profanity_filter, punctuate: $punctuate, endpointing: $endpointing, redact: $redact, extra: $extra, includeRawResponse: $includeRawResponse, instanceId: $instanceId, participants: $participants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/transcription/update
#
# POST /rooms/{room_name}/transcription/update
# operationId: RoomTranscriptionUpdate
export def "rooms-transcription-update RoomTranscriptionUpdate" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --instanceId: string # instanceId to be updated.
  --participants: list # A list of participant IDs to be transcribed. Only the participant IDs included in this array will be processed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/transcription/update")
  let body = {instanceId: $instanceId, participants: $participants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/transcription/stop
#
# POST /rooms/{room_name}/transcription/stop
# operationId: RoomTranscriptionStop
export def "rooms-transcription-stop RoomTranscriptionStop" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --instanceId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/transcription/stop")
  let body = {instanceId: $instanceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/dialOut/start
#
# POST /rooms/{room_name}/dialOut/start
# operationId: RoomDialOutStart
# --videoSettings shape: {width?: int, height?: int, fps?: int, videoBitrate?: int}
# --codecs shape: {audio?: list, video?: list}
export def "rooms-dial-out-start RoomDialOutStart" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sipUri: string # sipUri to call. uri should start with `sip:`. Query parameters appended to the sipUri will appear as SIP Headers in the INTIVE message at the remote SIP endpoint. Headers must start with "X-", e.g. to append a header "myexampleHeader" it is appended to sipUri as "sip:<dialout_sip_uri>?X-header-1=val-1&X-header-2=val-2".
  --phoneNumber: string # phone number to call. number must start with country code e.g `+1`
  --extension: string # the extension to dial after dialed number is connected. e.g. `1234`
  --waitBeforeExtensionDialSec: int # number of seconds to wait before dialing the extension, once dialed number is connected. (default: 0)
  --displayName: string # The sipUri or The phone participant is shown with this name in the web UI.
  --userId: string # userId to assign to the participant. default `userId` is null.
  --callerId: string # determine the phone number used for outbound call (i.e. phone number displayed on the called phone). [purchased phone](/products/rest-api/phone-numbers/purchased-phone-numbers)
  --video: oneof<nothing, bool> # Enable SIP video in the room, only available for sipUri.
  --videoSettings: record # Video encoding settings. Only applicable when `video` is `true`. — shape: {width?: int, height?: int, fps?: int, videoBitrate?: int}
  --codecs: record # Specify the codecs to use for dial-out. — shape: {audio?: list, video?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/dialOut/start")
  let body = {sipUri: $sipUri, phoneNumber: $phoneNumber, extension: $extension, waitBeforeExtensionDialSec: $waitBeforeExtensionDialSec, displayName: $displayName, userId: $userId, callerId: $callerId, video: $video, videoSettings: $videoSettings, codecs: $codecs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/dialOut/sendDTMF
#
# POST /rooms/{room_name}/dialOut/sendDTMF
# operationId: RoomDialOutSendDTMF
export def "rooms-dial-out-send-dtmf RoomDialOutSendDTMF" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sessionId: string # The participant ID of the dialOut session
  tones: string # Combined string of DTMF tones to send (e.g., "1234#"). Maximum 20 characters.
  --digitDurationMs: int # Duration in milliseconds, represents the duration between each DTMF digit. Must be between 50 and 2000. The default duration is 500ms.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/dialOut/sendDTMF")
  let body = {sessionId: $sessionId, tones: $tones, digitDurationMs: $digitDurationMs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/dialOut/stop
#
# POST /rooms/{room_name}/dialOut/stop
# operationId: RoomDialOutStop
export def "rooms-dial-out-stop RoomDialOutStop" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sessionId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/dialOut/stop")
  let body = {sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/sipCallTransfer
#
# POST /rooms/{room_name}/sipCallTransfer
# operationId: RoomSipCallTransfer
export def "rooms-sip-call-transfer RoomSipCallTransfer" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sessionId: string
  --toEndPoint: string # the SIP/phoneNumber endpoint to transfer the call to.
  --callerId: string # determine the phone number used for outbound call (i.e. phone number displayed on the called phone). [purchased phone](/products/rest-api/phone-numbers/purchased-phone-numbers)
  --waitBeforeExtensionDialSec: int # number of seconds to wait before dialing the extension, once dialed number is connected. (default: 0)
  --extension: string # the extension to dial after dialed number is connected. e.g. `1234` (e.g. 1234)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/sipCallTransfer")
  let body = {sessionId: $sessionId, toEndPoint: $toEndPoint, callerId: $callerId, waitBeforeExtensionDialSec: $waitBeforeExtensionDialSec, extension: $extension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# rooms/:name/sipRefer
#
# POST /rooms/{room_name}/sipRefer
# operationId: RoomSipRefer
export def "rooms-sip-refer RoomSipRefer" [
  room_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sessionId: string
  --toEndPoint: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rooms/($room_name)/sipRefer")
  let body = {sessionId: $sessionId, toEndPoint: $toEndPoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# meeting-tokens
#
# POST /meeting-tokens
# operationId: CreateMeetingToken
# --properties shape: {room_name?: string, eject_at_token_exp?: bool, eject_after_elapsed?: int, nbf?: int, exp?: int, is_owner?: bool, user_name?: string, user_id?: string, enable_screenshare?: bool, start_video_off?: bool, start_audio_off?: bool, enable_recording?: any, enable_prejoin_ui?: bool, enable_live_captions_ui?: bool, enable_recording_ui?: bool, enable_terse_logging?: bool, knocking?: bool, start_cloud_recording?: bool, start_cloud_recording_opts?: record, auto_start_transcription?: bool, close_tab_on_exit?: bool, redirect_on_meeting_exit?: string, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", permissions?: record}
export def "meeting-tokens CreateMeetingToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {room_name?: string, eject_at_token_exp?: bool, eject_after_elapsed?: int, nbf?: int, exp?: int, is_owner?: bool, user_name?: string, user_id?: string, enable_screenshare?: bool, start_video_off?: bool, start_audio_off?: bool, enable_recording?: any, enable_prejoin_ui?: bool, enable_live_captions_ui?: bool, enable_recording_ui?: bool, enable_terse_logging?: bool, knocking?: bool, start_cloud_recording?: bool, start_cloud_recording_opts?: record, auto_start_transcription?: bool, close_tab_on_exit?: bool, redirect_on_meeting_exit?: string, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", permissions?: record}
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/meeting-tokens")
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# meeting-tokens/:meeting_token
#
# GET /meeting-tokens/{meeting_token}
# operationId: ValidateMeetingToken
export def "meeting-tokens ValidateMeetingToken" [
  meeting_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignoreNbf: oneof<nothing, bool> # Ignore the `nbf` in a JWT, if given
]: nothing -> record<room_name: string, is_owner: bool, user_name: string, start_video_off: bool, start_audio_off: bool, lang: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoreNbf" $ignoreNbf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/meeting-tokens/($meeting_token)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /recordings
#
# GET /recordings
# operationId: ListRecordings
export def "recordings ListRecordings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --ending-before: string
  --starting-after: string
  --room-name: string
]: nothing -> record<total_count: int, data: table<id: string, start_ts: int, status: string, max_participants: int, share_token: string, s3key: string, mtgSessionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "room_name" $room_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# recordings/:id
#
# GET /recordings/{recording_id}
# operationId: GetRecordingInfo
export def "recordings GetRecordingInfo" [
  recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, room_name: string, start_ts: int, status: string, max_participants: int, duration: int, share_token: string, s3key: string, mtgSessionId: string, tracks: table<size: int, type: string, s3key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recordings/($recording_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# recordings/:id
#
# DELETE /recordings/{recording_id}
# operationId: DeleteRecording
export def "recordings DeleteRecording" [
  recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool, id: string, s3_bucket: string, s3_region: string, s3_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recordings/($recording_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# recordings/:id/access-link
#
# GET /recordings/{recording_id}/access-link
# operationId: GetRecordingLink
export def "recordings-access-link GetRecordingLink" [
  recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<download_link: string, expires: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recordings/($recording_id)/access-link")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /transcript
#
# GET /transcript
# operationId: ListTranscript
export def "transcript ListTranscript" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --ending-before: string
  --starting-after: string
  --roomId: string
  --mtgSessionId: string
]: nothing -> record<total_count: int, data: table<transcriptId: string, domainId: string, roomId: string, mtgSessionId: string, status: string, isVttAvailable: bool, duration: int, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "roomId" $roomId "scalar") (serialize-qp "mtgSessionId" $mtgSessionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transcript" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# transcript/:transcriptId
#
# GET /transcript/{transcriptId}
# operationId: GetTranscriptInfo
export def "transcript GetTranscriptInfo" [
  transcriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcriptId: string, domainId: string, roomId: string, mtgSessionId: string, status: string, isVttAvailable: bool, duration: int, outParams: record<s3key: string, bucket: string, region: string>, error: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transcript/($transcriptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# transcript/:id
#
# DELETE /transcript/{transcriptId}
# operationId: DeleteTranscript
export def "transcript DeleteTranscript" [
  transcriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcriptId: string, domainId: string, roomId: string, mtgSessionId: string, status: string, isVttAvailable: bool, duration: int, outParams: record<s3key: string, bucket: string, region: string>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transcript/($transcriptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# transcript/:id/access-link
#
# GET /transcript/{transcriptId}/access-link
# operationId: GetTranscriptLink
export def "transcript-access-link GetTranscriptLink" [
  transcriptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transcriptId: string, link: string, outParams: record<s3key: string, bucket: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transcript/($transcriptId)/access-link")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /domain-dialin-config
#
# GET /domain-dialin-config
# operationId: ListDomainDialinConfigs
export def "domain-dialin-config ListDomainDialinConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --ending-before: string
  --starting-after: string
  --phone-number: string
  --phone-numbers: string # a comma separated list of phone numbers to filter by. The filter will match any phone number that contains the provided numbers as a substring (partial match).
  --sip-username: string # The sip username associated with this dialin config (only the username part of the sip uri)
  --name-prefix: string
  --type: string # The type of dialin config. It can be pinless_dialin or pin_dialin.
]: nothing -> record<total_count: int, data: table<id: string, type: string, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "phone_number" $phone_number "scalar") (serialize-qp "phone_numbers" $phone_numbers "scalar") (serialize-qp "sip_username" $sip_username "scalar") (serialize-qp "name_prefix" $name_prefix "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domain-dialin-config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create new config
#
# POST /domain-dialin-config
# operationId: CreateDomainDialConfigInfo
# --timeout_config shape: {message?: string}
# --ivr_greeting shape: {message?: string}
export def "domain-dialin-config CreateDomainDialConfigInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-1 # The type of dial-in configuration to create.
  phone_number: string # The phone number to configure for pinless_dialin or pin_dialin, in E.164 format (e.g. "+18058700061"). If the same number is used by any other config then the API will fail. Required for pinless_dialin, optional for pin_dialin. (e.g. +12555599999)
  --name-prefix: string # friendly name for the configuration. (e.g. my-identifier-prefix)
  --hmac: string # The [HMAC signature](/guides/products/dial-in-dial-out/dialin-pinless#hmac) used to verify the webhook called to "room_creation_api". (only for pinless_dialin type) (e.g. 9jyatvPWQfBymCGDOYPYKF/TRZXR+08Gj4bvPF78pH0=)
  --room-creation-api: string # The API to request when a call is received on configured phoneNumber or sip_uri. (only for pinless_dialin type). flow is described [here](/guides/products/dial-in-dial-out/dialin-pinless#quick-overview) (e.g. https://mydomain.com/api/create-room)
  --hold-music-url: string # The URL to the hold music to play when the call is received, (only for pinless_dialin type). The hold music must be a publicly accessible URL in MP3 format. The hold music must be less than 10MB in size and less than 60 seconds in duration. In pinless_dialin, the hold music will be played twice. (e.g. https://mydomain.com/hold-music.mp3)
  --timeout-config: record # The timeout configuration for the dialin config. — shape: {message?: string}
  --ivr-greeting: record # configuration when the call is received on phone number (only for pin_dialin). — shape: {message?: string}
]: any -> record<id: string, type: string, config: record<type: string, phone_number: string, name_prefix: string, hmac: string, room_creation_api: string, hold_music_url: string, timeout_config: record<message: string>, ivr_greeting: record<message: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domain-dialin-config")
  let body = {type: $type, phone_number: $phone_number, name_prefix: $name_prefix, hmac: $hmac, room_creation_api: $room_creation_api, hold_music_url: $hold_music_url, timeout_config: $timeout_config, ivr_greeting: $ivr_greeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# domain-dialin-config/:id
#
# GET /domain-dialin-config/{id}
# operationId: GetDomainDialinConfigInfo
export def "domain-dialin-config GetDomainDialinConfigInfo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, config: record<type: string, phone_number: string, name_prefix: string, hmac: string, room_creation_api: string, hold_music_url: string, timeout_config: record<message: string>, ivr_greeting: record<message: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domain-dialin-config/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# domain-dialin-config/:id
#
# PUT /domain-dialin-config/{id}
# operationId: UpdateDomainDialConfigInfo
# --timeout_config shape: {message?: string}
# --ivr_greeting shape: {message?: string}
export def "domain-dialin-config UpdateDomainDialConfigInfo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-number: string # The phone number to update to the existing dialin config, in E.164 format (e.g. "+18058700061"). If the same number is used by any other config then the API will fail. (e.g. +12555599999)
  --name-prefix: string # Update the name_prefix of an existing config. (e.g. my-identifier-prefix)
  --hmac: string # The [HMAC signature](/guides/products/dial-in-dial-out/dialin-pinless#hmac) used to verify the webhook called to "room_creation_api". (only for pinless_dialin type). (e.g. 9jyatvPWQfBymCGDOYPYKF/TRZXR+08Gj4bvPF78pH0=)
  --room-creation-api: string # The URL to call when a call is received on configured phoneNumber or sip_uri. (only for pinless_dialin type). flow is described [here](/guides/products/dial-in-dial-out/dialin-pinless#quick-overview) (e.g. https://mydomain.com/api/create-room)
  --hold-music-url: string # The URL to the hold music to play when the call is received, (only for pinless_dialin type). The hold music must be a publicly accessible URL in MP3 format. The hold music must be less than 10MB in size and less than 60 seconds in duration. In pinless_dialin, the hold music will be played twice. (e.g. https://mydomain.com/hold-music.mp3)
  --timeout-config: record # The timeout configuration for the dialin config. — shape: {message?: string}
  --ivr-greeting: record # configuration when the call is received on phone number (only for pin_dialin). — shape: {message?: string}
]: any -> record<id: string, type: string, config: record<type: string, phone_number: string, name_prefix: string, hmac: string, room_creation_api: string, hold_music_url: string, timeout_config: record<message: string>, ivr_greeting: record<message: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domain-dialin-config/($id)")
  let body = {phone_number: $phone_number, name_prefix: $name_prefix, hmac: $hmac, room_creation_api: $room_creation_api, hold_music_url: $hold_music_url, timeout_config: $timeout_config, ivr_greeting: $ivr_greeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# domain-dialin-config/:id
#
# DELETE /domain-dialin-config/{id}
# operationId: DeleteDomainDialinConfig
export def "domain-dialin-config DeleteDomainDialinConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domain-dialin-config/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /webhooks
#
# GET /webhooks
# operationId: GetWebhooks
export def "webhooks GetWebhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<uuid: string, url: string, hmac: string, basicAuth: string, retryType: string, eventTypes: list<string>, state: string, failedCount: float, lastMomentPushed: string, domainId: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /webhooks
#
# POST /webhooks
# operationId: CreateWebhook
export def "webhooks CreateWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The webhook server endpoint that was provided.
  --basicAuth: string # The basic auth credentials that will be used to POST to the webhook URL.
  --retryType: string@retryType-completer # The retry configuration for this webhook endpoint to use. The default is circuit-breaker.
  --eventTypes: list # The set of event types this webhook is subscribed to.
  --hmac: string # A secret that can be used to verify the signature of the webhook. If not provided, an hmac will be provisioned for you and returned.
]: any -> record<uuid: string, url: string, hmac: string, basicAuth: string, retryType: string, eventTypes: list<string>, state: string, failedCount: float, lastMomentPushed: string, domainId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {url: $body_url, basicAuth: $basicAuth, retryType: $retryType, eventTypes: $eventTypes, hmac: $hmac} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# webhooks/:id
#
# GET /webhooks/{id}
# operationId: GetWebhookConfig
export def "webhooks GetWebhookConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<uuid: string, url: string, hmac: string, basicAuth: string, retryType: string, eventTypes: list<string>, state: string, failedCount: float, lastMomentPushed: string, domainId: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# webhooks/:id
#
# POST /webhooks/{id}
# operationId: UpdateWebhookConfig
export def "webhooks UpdateWebhookConfig" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The webhook server endpoint that was provided.
  --basicAuth: string # The basic auth credentials that will be used to POST to the webhook URL.
  --retryType: string@retryType-completer # The retry configuration for this webhook endpoint to use. The default is circuit-breaker.
  --eventTypes: list # The set of event types this webhook is subscribed to.
  --hmac: string # A secret that can be used to verify the signature of the webhook.
]: any -> record<uuid: string, url: string, hmac: string, basicAuth: string, retryType: string, eventTypes: list<string>, state: string, failedCount: float, lastMomentPushed: string, domainId: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let body = {url: $body_url, basicAuth: $basicAuth, retryType: $retryType, eventTypes: $eventTypes, hmac: $hmac} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# webhooks/:id
#
# DELETE /webhooks/{id}
# operationId: DeleteWebhook
export def "webhooks DeleteWebhook" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /meetings
#
# GET /meetings
# operationId: GetMeetingInfo
export def "meetings GetMeetingInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --room: string
  --timeframe-start: int # format: int32
  --timeframe-end: int # format: int32
  --limit: int # format: int32
  --starting-after: string
  --ending-before: string
  --ongoing: oneof<nothing, bool>
  --no-participants: oneof<nothing, bool>
]: nothing -> record<total_count: int, data: table<id: string, room: string, start_time: int, duration: int, ongoing: bool, max_participants: int, participants: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "room" $room "scalar") (serialize-qp "timeframe_start" $timeframe_start "scalar") (serialize-qp "timeframe_end" $timeframe_end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "ongoing" $ongoing "scalar") (serialize-qp "no_participants" $no_participants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/meetings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /meetings/:meeting
#
# GET /meetings/{meeting}
# operationId: GetIndividualMeetingInfo
export def "meetings GetIndividualMeetingInfo" [
  meeting: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, room: string, start_time: int, duration: int, ongoing: bool, max_participants: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/meetings/($meeting)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /meetings/:meeting/participants
#
# GET /meetings/{meeting}/participants
# operationId: GetMeetingParticipants
export def "meetings-participants GetMeetingParticipants" [
  meeting: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # the largest number of participant records to return (format: int32)
  --joined-after: string # limit to participants who joined after the given participant, identified by `participant_id`
  --joined-before: string # limit to participants who joined before the given participant, identified by `participant_id`
]: nothing -> record<data: table<id: string, room: string, start_time: int, duration: int, ongoing: bool, max_participants: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "joined_after" $joined_after "scalar") (serialize-qp "joined_before" $joined_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/meetings/($meeting)/participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /logs
#
# GET /logs
# operationId: ListLogs
export def "logs ListLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeLogs: oneof<nothing, bool> # If true, you get a "logs" array in the results (default: true)
  --includeMetrics: oneof<nothing, bool> # If true, results have "metrics" array (default: false)
  --userSessionId: string # Filters by this user ID (aka "participant ID"). Required if `mtgSessionId` is not present in the request
  --mtgSessionId: string # Filters by this Session ID. Required if `userSessionId` is not present in the request
  --logLevel: string@logLevel-completer # Filters by the given log level name
  --order: string # ASC or DESC, case insensitive (default: DESC)
  --startTime: int # A JS timestamp (ms since epoch in UTC) (format: int32)
  --endTime: int # A JS timestamp (ms since epoch), defaults to the current time (format: int32)
  --limit: int # Limit the number of logs and/or metrics returned (format: i32, default: 20)
  --offset: int # Number of records to skip before returning results (format: i32, default: 0)
]: nothing -> record<logs: table<time: string, clientTime: string, message: string, mtgSessionId: string, userSessionId: string, peerId: string, domainName: string, level: int, code: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeLogs" $includeLogs "scalar") (serialize-qp "includeMetrics" $includeMetrics "scalar") (serialize-qp "userSessionId" $userSessionId "scalar") (serialize-qp "mtgSessionId" $mtgSessionId "scalar") (serialize-qp "logLevel" $logLevel "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /logs/api
#
# GET /logs/api
# operationId: ListAPILogs
export def "logs ListAPILogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --starting-after: string # Given the log ID, will return all records after that ID. See [pagination docs](../../rest-api#pagination)
  --ending-before: string # Given the log ID, will return all records before that ID. See [pagination docs](../../rest-api#pagination)
  --limit: int # Limit the number of logs and/or metrics returned (format: i32, default: 20)
  --qp-source: string # The source of the given logs, either `"api"` or `"webhook"` (default: api)
  --qp-url: string # Either the webhook server URL, or the API endpoint that was logged
]: nothing -> table<id: string, userId: string, domainId: string, source: string, ip: string, method: string, url: string, status: int, createdAt: string, request: string, response: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs/api" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /presence
#
# GET /presence
# operationId: GetPresence
export def "presence GetPresence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/presence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /batch/rooms
#
# POST /batch/rooms
# operationId: BatchRoomCreate
# --rooms item shape: {name?: string, privacy?: string, properties?: record}
export def "batch-rooms BatchRoomCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rooms: list # item shape: {name?: string, privacy?: string, properties?: record}
]: any -> table<id: string, name: string, api_created: bool, privacy: string, url: string, created_at: string, config: record<nbf: int, exp: int, max_participants: int, enable_people_ui: bool, enable_cpu_warning_notifications: bool, enable_pip_ui: bool, enable_emoji_reactions: bool, enable_hand_raising: bool, enable_prejoin_ui: bool, enable_live_captions_ui: bool, enable_network_ui: bool, enable_noise_cancellation_ui: bool, enable_breakout_rooms: bool, enable_knocking: bool, enable_screenshare: bool, enable_video_processing_ui: bool, enable_chat: bool, enable_shared_chat_history: bool, start_video_off: bool, start_audio_off: bool, enable_recording: any, eject_at_room_exp: bool, eject_after_elapsed: int, enable_advanced_chat: bool, enable_hidden_participants: bool, enable_mesh_sfu: bool, sfu_switchover: float, enable_adaptive_simulcast: bool, enable_multiparty_adaptive_simulcast: bool, enforce_unique_user_ids: bool, experimental_optimize_large_calls: bool, lang: string, meeting_join_hook: string, geo: string, rtmp_geo: string, disable_rtmp_geo_fallback: bool, recordings_bucket: record, enable_terse_logging: bool, auto_transcription_settings: record, enable_transcription_storage: bool, transcription_bucket: record, recordings_template: string, transcription_template: string, enable_dialout: bool, dialout_config: record, streaming_endpoints: list, permissions: record, sip_uri: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch/rooms")
  let body = {rooms: $rooms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# /batch/rooms
#
# DELETE /batch/rooms
# operationId: BatchRoomDelete
export def "batch-rooms BatchRoomDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch/rooms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /list-available-numbers
#
# GET /list-available-numbers
# operationId: ListAvailableNumbers
export def "list-available-numbers ListAvailableNumbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --areacode: string # An areacode to search within.
  --region: string # A region or state to search within. Must be an ISO 3166-2 alpha-2 code, i.e. CA for California. Cannot be used in combination with areacode.
  --city: string # A specific City to search within. Example, New York. The string must be url encoded because it is a url parameter. Must be used in combination with region. Cannot be used in combination with areacode, starts_with, contains, or ends_with.
  --contains: string # A string of 3 to 7 digits that should appear somewhere in the number.
  --starts-with: string # A string of 3 to 7 digits that should be used as the start of a number. Cannot be used in combination with contains or ends_with.
  --ends-with: string # A string of 3 to 7 digits that should be used as the end of a number. Cannot be used in combination with starts_with or contains.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "areacode" $areacode "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "contains" $contains "scalar") (serialize-qp "starts_with" $starts_with "scalar") (serialize-qp "ends_with" $ends_with "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/list-available-numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /purchased-phone-numbers
#
# GET /purchased-phone-numbers
# operationId: PurchasedPhoneNumbers
export def "purchased-phone-numbers PurchasedPhoneNumbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int32
  --ending-before: string
  --starting-after: string
  --filter-name: string
  --filter-number: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "ending_before" $ending_before "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "filter_name" $filter_name "scalar") (serialize-qp "filter_number" $filter_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/purchased-phone-numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /buy-phone-number
#
# POST /buy-phone-number
# operationId: BuyPhoneNumber
export def "buy-phone-number BuyPhoneNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: string # The phone number to purchase, in E.164 format (e.g. "+18058700061"). If not provided, a random US number will be purchased. (e.g. +18058700061)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/buy-phone-number")
  let body = {number: $number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# release-phone-number/:id
#
# DELETE /release-phone-number/{id}
# operationId: ReleasePhoneNumber
export def "release-phone-number ReleasePhoneNumber" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/release-phone-number/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /dialin/pinlessCallUpdate
#
# POST /dialin/pinlessCallUpdate
# operationId: PinlessCallUpdate
export def "dialin-pinless-call-update PinlessCallUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callId: string # CallId is represented by UUID and represents the sessionId in the SIP Network. This is obtained from the [webhook payload](/guides/features/dial-in-dial-out/sip-interconnect-pinless).
  --callDomain: string # Call Domain is represented by UUID and represents your Daily Domain on the SIP Network. This is obtained from the [webhook payload](/guides/features/dial-in-dial-out/sip-interconnect-pinless).
  --sipUri: string # This SIP URI is associated to the Daily Room that you want to forward the SIP Interconnect call to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dialin/pinlessCallUpdate")
  let body = {callId: $callId, callDomain: $callDomain, sipUri: $sipUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get domain configuration
#
# GET /
# operationId: GetDomainConfig
export def "domain GetDomainConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_name: string, domain_id: string, config: record<hide_daily_branding: bool, redirect_on_meeting_exit: string, meeting_join_hook: string, hipaa: bool, intercom_auto_record: bool, intercom_manual_record: string, sfu_impl: string, sfu_switchover: int, switchover_impl: string, lang: string, webhook_meeting_end: string, recordings_bucket: record<bucket_name: string, bucket_region: string>, max_live_streams: float, max_streaming_instances_per_room: float, enable_daily_logger: bool, enable_prejoin_ui: bool, enable_live_captions_ui: bool, enable_network_ui: bool, disable_rate_limiting: bool, attach_callobject_to_window: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set domain configuration
#
# POST /
# operationId: SetDomainConfig
# --properties shape: {enable_advanced_chat?: bool, enable_people_ui?: bool, enable_cpu_warning_notifications?: bool, enable_pip_ui?: bool, enable_emoji_reactions?: bool, enable_hand_raising?: bool, enable_prejoin_ui?: bool, enable_breakout_rooms?: bool, enable_live_captions_ui?: bool, enable_network_ui?: bool, enable_noise_cancellation_ui?: bool, enable_video_processing_ui?: bool, hide_daily_branding?: bool, redirect_on_meeting_exit?: string, hipaa?: bool, intercom_auto_record?: bool, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", meeting_join_hook?: string, geo?: string, rtmp_geo?: string, disable_rtmp_geo_fallback?: bool, enable_terse_logging?: bool, enable_transcription_storage?: bool, transcription_bucket?: record, recordings_template?: string, transcription_template?: string, enable_mesh_sfu?: bool, sfu_switchover?: float, enable_adaptive_simulcast?: bool, enable_multiparty_adaptive_simulcast?: bool, enforce_unique_user_ids?: bool, recordings_bucket?: record, permissions?: record, batch_processor_bucket?: record, enable_opus_fec?: bool, pinless_dialin?: list, pin_dialin?: list}
export def "domain SetDomainConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {enable_advanced_chat?: bool, enable_people_ui?: bool, enable_cpu_warning_notifications?: bool, enable_pip_ui?: bool, enable_emoji_reactions?: bool, enable_hand_raising?: bool, enable_prejoin_ui?: bool, enable_breakout_rooms?: bool, enable_live_captions_ui?: bool, enable_network_ui?: bool, enable_noise_cancellation_ui?: bool, enable_video_processing_ui?: bool, hide_daily_branding?: bool, redirect_on_meeting_exit?: string, hipaa?: bool, intercom_auto_record?: bool, lang?: "da"|"de"|"en"|"es"|"fi"|"fr"|"it"|"jp"|"ka"|"nl"|"no"|"pt"|"pt-BR"|"pl"|"ru"|"sv"|"tr"|"user", meeting_join_hook?: string, geo?: string, rtmp_geo?: string, disable_rtmp_geo_fallback?: bool, enable_terse_logging?: bool, enable_transcription_storage?: bool, transcription_bucket?: record, recordings_template?: string, transcription_template?: string, enable_mesh_sfu?: bool, sfu_switchover?: float, enable_adaptive_simulcast?: bool, enable_multiparty_adaptive_simulcast?: bool, enforce_unique_user_ids?: bool, recordings_bucket?: record, permissions?: record, batch_processor_bucket?: record, enable_opus_fec?: bool, pinless_dialin?: list, pin_dialin?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
