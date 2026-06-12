# Auto-generated client for ElevenLabs API Documentation v1.0
# Source: https://api.elevenlabs.io/openapi.json
# Auth: --token flag or $env.ELEVENLABS_API_DOCUMENTATION_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ELEVENLABS_API_DOCUMENTATION_TOKEN | default "" }
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
def output-format-completer [] { ["alaw_8000" "mp3_22050_32" "mp3_24000_48" "mp3_44100_128" "mp3_44100_192" "mp3_44100_32" "mp3_44100_64" "mp3_44100_96" "opus_48000_128" "opus_48000_192" "opus_48000_32" "opus_48000_64" "opus_48000_96" "pcm_16000" "pcm_22050" "pcm_24000" "pcm_32000" "pcm_44100" "pcm_48000" "pcm_8000" "ulaw_8000"] }
def output-format-completer-1 [] { ["alaw_8000" "mp3_22050_32" "mp3_24000_48" "mp3_44100_128" "mp3_44100_192" "mp3_44100_32" "mp3_44100_64" "mp3_44100_96" "opus_48000_128" "opus_48000_192" "opus_48000_32" "opus_48000_64" "opus_48000_96" "pcm_16000" "pcm_22050" "pcm_24000" "pcm_32000" "pcm_44100" "pcm_48000" "pcm_8000" "ulaw_8000" "wav_16000" "wav_22050" "wav_24000" "wav_32000" "wav_44100" "wav_48000" "wav_8000"] }
def apply-text-normalization-completer [] { ["auto" "off" "on"] }
def model-id-completer [] { ["eleven_multilingual_ttv_v2" "eleven_ttv_v3"] }
def quality-preset-completer [] { ["high" "standard" "ultra" "ultra_lossless"] }
def duration-scale-completer [] { ["default" "long" "short"] }
def model-id-completer-1 [] { ["music_v1"] }
def render-type-completer [] { ["aac" "aaf" "clips_zip" "mp3" "mp4" "tracks_zip" "wav" "zip"] }
def dubbing-status-completer [] { ["dubbed" "dubbing" "failed"] }
def filter-by-creator-completer [] { ["all" "others" "personal"] }
def order-direction-completer [] { ["ASCENDING" "DESCENDING"] }
def mode-completer [] { ["automatic" "manual"] }
def accept-completer [] { ["audio/mpeg" "video/mp4"] }
def format-type-completer [] { ["json" "srt" "webvtt"] }
def accept-completer-1 [] { ["application/json" "text/plain"] }
def category-completer [] { ["famous" "high_quality" "professional"] }
def breakdown-type-completer [] { ["all_api_keys" "api_keys" "groups" "has_api_key" "model" "none" "product_type" "region" "reporting_workspace_id" "request_queue" "request_source" "resource" "subresource_id" "user" "voice" "voice_multiplier"] }
def aggregation-interval-completer [] { ["cumulative" "day" "hour" "month" "week"] }
def metric-completer [] { ["concurrency" "concurrency_average" "credits" "fiat_units_spent" "minutes_used" "request_count" "ttfb_avg" "ttfb_p95" "tts_characters"] }
def algorithm-completer [] { ["HS256" "HS384" "HS512" "RS256" "RS384" "RS512"] }
def token-response-field-completer [] { ["access_token" "id_token"] }
def resource-type-completer [] { ["assets" "avatar_video_generations" "avatars" "content_generations" "content_templates" "convai_agent_branches" "convai_agent_drafts" "convai_agent_response_tests" "convai_agent_versions" "convai_agent_versions_deployments" "convai_agents" "convai_api_integration_connections" "convai_api_integration_trigger_connections" "convai_batch_calls" "convai_coaching_proposals" "convai_crawl_jobs" "convai_crawl_tasks" "convai_knowledge_base_documents" "convai_mcp_servers" "convai_memory_entries" "convai_phone_numbers" "convai_secrets" "convai_settings" "convai_templates" "convai_test_suite_invocations" "convai_tools" "convai_whatsapp_accounts" "dashboard" "dashboard_configuration" "dubbing" "project" "pronunciation_dictionary" "resource_collection" "resource_locators" "songs" "studio_projects" "transcription_tasks" "voice" "voice_collection" "workspace_auth_connections"] }
def role-completer [] { ["admin" "commenter" "editor" "viewer"] }
def model-id-completer-2 [] { ["scribe_v1" "scribe_v2"] }
def timestamps-granularity-completer [] { ["character" "none" "word"] }
def file-format-completer [] { ["other" "pcm_s16le_16"] }
def direction-completer [] { ["inbound" "outbound"] }
def sort-direction-completer [] { ["asc" "desc"] }
def sort-mode-completer [] { ["default" "folders_first"] }
def sharing-mode-completer [] { ["all" "shared_with_me"] }
def summary-mode-completer [] { ["exclude" "include"] }
def sort-by-completer [] { ["conversation_count" "last_contact_unix_secs"] }
def format-completer [] { ["json" "opentelemetry"] }
def sort-by-completer-1 [] { ["created_at" "search_score"] }
def api-subdomain-completer [] { ["api.exotel.com" "api.in.exotel.com"] }
def model-completer [] { ["e5_mistral_7b_instruct" "multilingual_e5_large_instruct"] }
def dependent-type-completer [] { ["all" "direct" "transitive"] }
def embedding-model-completer [] { ["e5_mistral_7b_instruct" "multilingual_e5_large_instruct"] }
def default-livekit-stack-completer [] { ["standard" "static"] }
def approval-policy-completer [] { ["auto_approve_all" "require_approval_all" "require_approval_per_tool"] }
def approval-policy-completer-1 [] { ["auto_approved" "requires_approval"] }
def type-completer [] { ["auth_connection" "secret" "string"] }
def model-style-prefix-completer [] { ["music" "sfx"] }
def stem-variation-id-completer [] { ["six_stems_v1" "two_stems_v1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "history history" } } | get name | first)
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

# List Generated Items
#
# GET /v1/history
# operationId: get_speech_history
export def "history history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many history items to return at maximum. Can not exceed 1000, defaults to 100. (default: 100)
  --start-after-history-item-id: string # After which ID to start fetching, use this parameter to paginate across a large collection of history items. In case this parameter is not provided history items will be fetched starting from the most recently created one ordered descending by their creation date.
  --voice-id: string # Voice ID to be filtered for, you can use GET https://api.elevenlabs.io/v1/voices to receive a list of voices and their IDs.
  --model-id: string # Model ID to filter history items by.
  --date-before-unix: string # Unix timestamp to filter history items before this date (exclusive).
  --date-after-unix: string # Unix timestamp to filter history items after this date (inclusive).
  --sort-direction: string # Sort direction for the results. (default: desc)
  --search: string # search term used for filtering
  --qp-source: string # Source of the generated history item
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<history: table<history_item_id: string, request_id: any, voice_id: any, model_id: any, voice_name: any, voice_category: any, text: any, date_unix: int, character_count_change_from: int, character_count_change_to: int, content_type: string, state: string, settings: any, feedback: any, share_link_id: any, source: any, alignments: any, dialogue: any, output_format: any>, last_history_item_id: any, has_more: bool, scanned_until: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "start_after_history_item_id" $start_after_history_item_id "scalar") (serialize-qp "voice_id" $voice_id "scalar") (serialize-qp "model_id" $model_id "scalar") (serialize-qp "date_before_unix" $date_before_unix "scalar") (serialize-qp "date_after_unix" $date_after_unix "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/history" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get History Item
#
# GET /v1/history/{history_item_id}
# operationId: get_speech_history_item_by_id
export def "history id" [
  history_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<history_item_id: string, request_id: any, voice_id: any, model_id: any, voice_name: any, voice_category: any, text: any, date_unix: int, character_count_change_from: int, character_count_change_to: int, content_type: string, state: string, settings: any, feedback: any, share_link_id: any, source: any, alignments: any, dialogue: any, output_format: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/history/($history_item_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete History Item
#
# DELETE /v1/history/{history_item_id}
# operationId: delete_speech_history_item
export def "history item" [
  history_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/history/($history_item_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Audio From History Item
#
# GET /v1/history/{history_item_id}/audio
# operationId: get_audio_full_from_speech_history_item
export def "history-audio item" [
  history_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/history/($history_item_id)/audio")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download History Items
#
# POST /v1/history/download
# operationId: download_speech_history_items
export def "history-download items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  history_item_ids: list # A list of history items to download, you can get IDs of history items and other metadata using the GET https://api.elevenlabs.io/v1/history endpoint.
  --output-format: any # Output format to transcode the audio file, can be wav or default.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/history/download")
  let body = {history_item_ids: $history_item_ids, output_format: $output_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sound Generation
#
# POST /v1/sound-generation
# operationId: sound_generation
export def "sound-generation generation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  text: string # The text that will get converted into a sound effect.
  --body-loop: oneof<nothing, bool> # Whether to create a sound effect that loops smoothly. Only available for the 'eleven_text_to_sound_v2 model'. (default: false)
  --duration-seconds: any # The duration of the sound which will be generated in seconds. Must be at least 0.5 and at most 30. If set to None we will guess the optimal duration using the prompt. Defaults to None.
  --prompt-influence: any # A higher prompt influence makes your generation follow the prompt more closely while also making generations less variable. Must be a value between 0 and 1. Defaults to 0.3. (default: 0.3)
  --model-id: string # The model ID to use for the sound generation. (default: eleven_text_to_sound_v2)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sound-generation" $qp)
  let body = {text: $text, loop: $body_loop, duration_seconds: $duration_seconds, prompt_influence: $prompt_influence, model_id: $model_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Audio Isolation
#
# POST /v1/audio-isolation
# operationId: audio_isolation
export def "audio-isolation isolation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  audio: string # The audio file from which vocals/speech will be isolated from. (format: binary)
  --file-format: any # The format of input audio. Options are 'pcm_s16le_16' or 'other' For `pcm_s16le_16`, the input audio must be 16-bit PCM at a 16kHz sample rate, single channel (mono), and little-endian byte order. Latency will be lower than with passing an encoded waveform. (default: other)
  --preview-b64: any # Optional preview image base64 for tracking this generation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio-isolation")
  let body = {audio: $audio, file_format: $file_format, preview_b64: $preview_b64} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Audio Isolation History
#
# GET /v1/audio-isolation/history
# operationId: get_audio_isolation_history
export def "audio-isolation-history history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many history items to return at maximum. Defaults to 100. (default: 100)
  --page: int # Page number for search pagination (1-based). Only used when search is provided. (default: 1)
  --search: string # Optional search term used for filtering audio isolation history (title/text).
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<items: table<id: string, title: any, created_at_unix: int, format: string, duration_seconds: any, download_url: any, icon_url: any, source_video_url: any, supports_video: bool, processing: bool, video_processing_failed: bool, preview_b64: any>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/audio-isolation/history" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Audio Isolation History Item
#
# DELETE /v1/audio-isolation/history/{history_item_id}
# operationId: delete_audio_isolation_history_item
export def "audio-isolation-history item" [
  history_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audio-isolation/history/($history_item_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Audio Isolation Stream
#
# POST /v1/audio-isolation/stream
# operationId: audio_isolation_stream
export def "audio-isolation-stream stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  audio: string # The audio file from which vocals/speech will be isolated from. (format: binary)
  --file-format: any # The format of input audio. Options are 'pcm_s16le_16' or 'other' For `pcm_s16le_16`, the input audio must be 16-bit PCM at a 16kHz sample rate, single channel (mono), and little-endian byte order. Latency will be lower than with passing an encoded waveform. (default: other)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio-isolation/stream")
  let body = {audio: $audio, file_format: $file_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete Sample
#
# DELETE /v1/voices/{voice_id}/samples/{sample_id}
# operationId: delete_sample
export def "voices-samples sample" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)/samples/($sample_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Audio From Sample
#
# GET /v1/voices/{voice_id}/samples/{sample_id}/audio
# operationId: get_audio_from_sample
export def "voices-samples-audio sample" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)/samples/($sample_id)/audio")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Text To Speech
#
# POST /v1/text-to-speech/{voice_id}
# operationId: text_to_speech_full
@deprecated --flag optimize-streaming-latency
@deprecated --flag use-pvc-as-ivc
export def "text-to-speech full" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --optimize-streaming-latency: string # You can turn on latency optimizations at some cost of quality. The best possible final latency varies by model. Possible values: 0 - default mode (no latency optimizations) 1 - normal latency optimizations (about 50% of possible latency improvement of option 3) 2 - strong latency optimizations (about 75% of possible latency improvement of option 3) 3 - max latency optimizations 4 - max latency optimizations, but also with text normalizer turned off for even more latency savings (best latency, but can mispronounce eg numbers and dates).  Defaults to None.  (DEPRECATED)
  --output-format: string@output-format-completer-1 # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM and WAV formats with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  text: string # The text that will get converted into speech.
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_multilingual_v2)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --voice-settings: any # Voice settings overriding stored settings for the given voice. They are applied only on the given request.
  --pronunciation-dictionary-locators: any # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --previous-text: any # The text that came before the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --next-text: any # The text that comes after the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --previous-request-ids: any # A list of request_id of the samples that were generated before this generation. Can be used to improve the speech's continuity when splitting up a large task into multiple requests. The results will be best when the same model is used across the generations. In case both previous_text and previous_request_ids is send, previous_text will be ignored. A maximum of 3 request_ids can be send.
  --next-request-ids: any # A list of request_id of the samples that come after this generation. next_request_ids is especially useful for maintaining the speech's continuity when regenerating a sample that has had some audio quality issues. For example, if you have generated 3 speech clips, and you want to improve clip 2, passing the request id of clip 3 as a next_request_id (and that of clip 1 as a previous_request_id) will help maintain natural flow in the combined speech. The results will be best when the same model is used across the generations. In case both next_text and next_request_ids is send, next_text will be ignored. A maximum of 3 request_ids can be send.
  --use-pvc-as-ivc: oneof<nothing, bool> # If true, we won't use PVC version of the voice for the generation but the IVC version. This is a temporary workaround for higher latency in PVC versions. (DEPRECATED, default: false)
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
  --apply-language-text-normalization: oneof<nothing, bool> # This parameter controls language text normalization. This helps with proper pronunciation of text in some supported languages. WARNING: This parameter can heavily increase the latency of the request. Currently only supported for Japanese. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logging" $enable_logging "scalar") (serialize-qp "optimize_streaming_latency" $optimize_streaming_latency "scalar") (serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/text-to-speech/($voice_id)" $qp)
  let body = {text: $text, model_id: $model_id, language_code: $language_code, voice_settings: $voice_settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, previous_text: $previous_text, next_text: $next_text, previous_request_ids: $previous_request_ids, next_request_ids: $next_request_ids, use_pvc_as_ivc: $use_pvc_as_ivc, apply_text_normalization: $apply_text_normalization, apply_language_text_normalization: $apply_language_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Speech With Timestamps
#
# POST /v1/text-to-speech/{voice_id}/with-timestamps
# operationId: text_to_speech_full_with_timestamps
# --pronunciation_dictionary_locators item shape: {pronunciation_dictionary_id: string, version_id?: any}
@deprecated --flag optimize-streaming-latency
@deprecated --flag use-pvc-as-ivc
export def "text-to-speech-with-timestamps timestamps" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --optimize-streaming-latency: string # You can turn on latency optimizations at some cost of quality. The best possible final latency varies by model. Possible values: 0 - default mode (no latency optimizations) 1 - normal latency optimizations (about 50% of possible latency improvement of option 3) 2 - strong latency optimizations (about 75% of possible latency improvement of option 3) 3 - max latency optimizations 4 - max latency optimizations, but also with text normalizer turned off for even more latency savings (best latency, but can mispronounce eg numbers and dates).  Defaults to None.  (DEPRECATED)
  --output-format: string@output-format-completer-1 # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM and WAV formats with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  text: string # The text that will get converted into speech.
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_multilingual_v2)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --voice-settings: any # Voice settings overriding stored settings for the given voice. They are applied only on the given request.
  --pronunciation-dictionary-locators: list # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request — item shape: {pronunciation_dictionary_id: string, version_id?: any}
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --previous-text: any # The text that came before the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --next-text: any # The text that comes after the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --previous-request-ids: list # A list of request_id of the samples that were generated before this generation. Can be used to improve the speech's continuity when splitting up a large task into multiple requests. The results will be best when the same model is used across the generations. In case both previous_text and previous_request_ids is send, previous_text will be ignored. A maximum of 3 request_ids can be send.
  --next-request-ids: list # A list of request_id of the samples that come after this generation. next_request_ids is especially useful for maintaining the speech's continuity when regenerating a sample that has had some audio quality issues. For example, if you have generated 3 speech clips, and you want to improve clip 2, passing the request id of clip 3 as a next_request_id (and that of clip 1 as a previous_request_id) will help maintain natural flow in the combined speech. The results will be best when the same model is used across the generations. In case both next_text and next_request_ids is send, next_text will be ignored. A maximum of 3 request_ids can be send.
  --use-pvc-as-ivc: oneof<nothing, bool> # If true, we won't use PVC version of the voice for the generation but the IVC version. This is a temporary workaround for higher latency in PVC versions. (DEPRECATED, default: false)
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
  --apply-language-text-normalization: oneof<nothing, bool> # This parameter controls language text normalization. This helps with proper pronunciation of text in some supported languages. WARNING: This parameter can heavily increase the latency of the request. Currently only supported for Japanese. (default: false)
]: any -> record<audio_base64: string, alignment: any, normalized_alignment: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logging" $enable_logging "scalar") (serialize-qp "optimize_streaming_latency" $optimize_streaming_latency "scalar") (serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/text-to-speech/($voice_id)/with-timestamps" $qp)
  let body = {text: $text, model_id: $model_id, language_code: $language_code, voice_settings: $voice_settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, previous_text: $previous_text, next_text: $next_text, previous_request_ids: $previous_request_ids, next_request_ids: $next_request_ids, use_pvc_as_ivc: $use_pvc_as_ivc, apply_text_normalization: $apply_text_normalization, apply_language_text_normalization: $apply_language_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Speech Streaming
#
# POST /v1/text-to-speech/{voice_id}/stream
# operationId: text_to_speech_stream
@deprecated --flag optimize-streaming-latency
@deprecated --flag use-pvc-as-ivc
export def "text-to-speech-stream stream" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --optimize-streaming-latency: string # You can turn on latency optimizations at some cost of quality. The best possible final latency varies by model. Possible values: 0 - default mode (no latency optimizations) 1 - normal latency optimizations (about 50% of possible latency improvement of option 3) 2 - strong latency optimizations (about 75% of possible latency improvement of option 3) 3 - max latency optimizations 4 - max latency optimizations, but also with text normalizer turned off for even more latency savings (best latency, but can mispronounce eg numbers and dates).  Defaults to None.  (DEPRECATED)
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  text: string # The text that will get converted into speech.
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_multilingual_v2)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --voice-settings: any # Voice settings overriding stored settings for the given voice. They are applied only on the given request.
  --pronunciation-dictionary-locators: any # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --previous-text: any # The text that came before the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --next-text: any # The text that comes after the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --previous-request-ids: any # A list of request_id of the samples that were generated before this generation. Can be used to improve the speech's continuity when splitting up a large task into multiple requests. The results will be best when the same model is used across the generations. In case both previous_text and previous_request_ids is send, previous_text will be ignored. A maximum of 3 request_ids can be send.
  --next-request-ids: any # A list of request_id of the samples that come after this generation. next_request_ids is especially useful for maintaining the speech's continuity when regenerating a sample that has had some audio quality issues. For example, if you have generated 3 speech clips, and you want to improve clip 2, passing the request id of clip 3 as a next_request_id (and that of clip 1 as a previous_request_id) will help maintain natural flow in the combined speech. The results will be best when the same model is used across the generations. In case both next_text and next_request_ids is send, next_text will be ignored. A maximum of 3 request_ids can be send.
  --use-pvc-as-ivc: oneof<nothing, bool> # If true, we won't use PVC version of the voice for the generation but the IVC version. This is a temporary workaround for higher latency in PVC versions. (DEPRECATED, default: false)
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
  --apply-language-text-normalization: oneof<nothing, bool> # This parameter controls language text normalization. This helps with proper pronunciation of text in some supported languages. WARNING: This parameter can heavily increase the latency of the request. Currently only supported for Japanese. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logging" $enable_logging "scalar") (serialize-qp "optimize_streaming_latency" $optimize_streaming_latency "scalar") (serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/text-to-speech/($voice_id)/stream" $qp)
  let body = {text: $text, model_id: $model_id, language_code: $language_code, voice_settings: $voice_settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, previous_text: $previous_text, next_text: $next_text, previous_request_ids: $previous_request_ids, next_request_ids: $next_request_ids, use_pvc_as_ivc: $use_pvc_as_ivc, apply_text_normalization: $apply_text_normalization, apply_language_text_normalization: $apply_language_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Speech Streaming With Timestamps
#
# POST /v1/text-to-speech/{voice_id}/stream/with-timestamps
# operationId: text_to_speech_stream_with_timestamps
@deprecated --flag optimize-streaming-latency
@deprecated --flag use-pvc-as-ivc
export def "text-to-speech-stream-with-timestamps timestamps" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --optimize-streaming-latency: string # You can turn on latency optimizations at some cost of quality. The best possible final latency varies by model. Possible values: 0 - default mode (no latency optimizations) 1 - normal latency optimizations (about 50% of possible latency improvement of option 3) 2 - strong latency optimizations (about 75% of possible latency improvement of option 3) 3 - max latency optimizations 4 - max latency optimizations, but also with text normalizer turned off for even more latency savings (best latency, but can mispronounce eg numbers and dates).  Defaults to None.  (DEPRECATED)
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  text: string # The text that will get converted into speech.
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_multilingual_v2)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --voice-settings: any # Voice settings overriding stored settings for the given voice. They are applied only on the given request.
  --pronunciation-dictionary-locators: any # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --previous-text: any # The text that came before the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --next-text: any # The text that comes after the text of the current request. Can be used to improve the speech's continuity when concatenating together multiple generations or to influence the speech's continuity in the current generation.
  --previous-request-ids: any # A list of request_id of the samples that were generated before this generation. Can be used to improve the speech's continuity when splitting up a large task into multiple requests. The results will be best when the same model is used across the generations. In case both previous_text and previous_request_ids is send, previous_text will be ignored. A maximum of 3 request_ids can be send.
  --next-request-ids: any # A list of request_id of the samples that come after this generation. next_request_ids is especially useful for maintaining the speech's continuity when regenerating a sample that has had some audio quality issues. For example, if you have generated 3 speech clips, and you want to improve clip 2, passing the request id of clip 3 as a next_request_id (and that of clip 1 as a previous_request_id) will help maintain natural flow in the combined speech. The results will be best when the same model is used across the generations. In case both next_text and next_request_ids is send, next_text will be ignored. A maximum of 3 request_ids can be send.
  --use-pvc-as-ivc: oneof<nothing, bool> # If true, we won't use PVC version of the voice for the generation but the IVC version. This is a temporary workaround for higher latency in PVC versions. (DEPRECATED, default: false)
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
  --apply-language-text-normalization: oneof<nothing, bool> # This parameter controls language text normalization. This helps with proper pronunciation of text in some supported languages. WARNING: This parameter can heavily increase the latency of the request. Currently only supported for Japanese. (default: false)
]: any -> record<audio_base64: string, alignment: any, normalized_alignment: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logging" $enable_logging "scalar") (serialize-qp "optimize_streaming_latency" $optimize_streaming_latency "scalar") (serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/text-to-speech/($voice_id)/stream/with-timestamps" $qp)
  let body = {text: $text, model_id: $model_id, language_code: $language_code, voice_settings: $voice_settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, previous_text: $previous_text, next_text: $next_text, previous_request_ids: $previous_request_ids, next_request_ids: $next_request_ids, use_pvc_as_ivc: $use_pvc_as_ivc, apply_text_normalization: $apply_text_normalization, apply_language_text_normalization: $apply_language_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Dialogue (Multi-Voice)
#
# POST /v1/text-to-dialogue
# operationId: text_to_dialogue
# --inputs item shape: {text: string, voice_id: string}
export def "text-to-dialogue dialogue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer-1 # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM and WAV formats with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  inputs: list # A list of dialogue inputs, each containing text and a voice ID which will be converted into speech. The maximum number of unique voice IDs is 10. For reliable generation, keep the total character count across all `inputs[].text` values at or below 2,000 characters per request. Longer requests can terminate early in streaming responses or return a validation error. — item shape: {text: string, voice_id: string}
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_v3)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --settings: any # Settings controlling the dialogue generation.
  --pronunciation-dictionary-locators: any # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar") (serialize-qp "enable_logging" $enable_logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/text-to-dialogue" $qp)
  let body = {inputs: $inputs, model_id: $model_id, language_code: $language_code, settings: $settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, apply_text_normalization: $apply_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Dialogue (Multi-Voice) Streaming
#
# POST /v1/text-to-dialogue/stream
# operationId: text_to_dialogue_stream
# --inputs item shape: {text: string, voice_id: string}
export def "text-to-dialogue-stream stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  inputs: list # A list of dialogue inputs, each containing text and a voice ID which will be converted into speech. The maximum number of unique voice IDs is 10. For reliable generation, keep the total character count across all `inputs[].text` values at or below 2,000 characters per request. Longer requests can terminate early in streaming responses or return a validation error. — item shape: {text: string, voice_id: string}
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_v3)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --settings: any # Settings controlling the dialogue generation.
  --pronunciation-dictionary-locators: any # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar") (serialize-qp "enable_logging" $enable_logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/text-to-dialogue/stream" $qp)
  let body = {inputs: $inputs, model_id: $model_id, language_code: $language_code, settings: $settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, apply_text_normalization: $apply_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Dialogue Streaming With Timestamps
#
# POST /v1/text-to-dialogue/stream/with-timestamps
# operationId: text_to_dialogue_stream_with_timestamps
# --inputs item shape: {text: string, voice_id: string}
export def "text-to-dialogue-stream-with-timestamps timestamps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  inputs: list # A list of dialogue inputs, each containing text and a voice ID which will be converted into speech. The maximum number of unique voice IDs is 10. For reliable generation, keep the total character count across all `inputs[].text` values at or below 2,000 characters per request. Longer requests can terminate early in streaming responses or return a validation error. — item shape: {text: string, voice_id: string}
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_v3)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --settings: any # Settings controlling the dialogue generation.
  --pronunciation-dictionary-locators: any # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
]: any -> record<audio_base64: string, alignment: any, normalized_alignment: any, voice_segments: table<voice_id: string, start_time_seconds: float, end_time_seconds: float, character_start_index: int, character_end_index: int, dialogue_input_index: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar") (serialize-qp "enable_logging" $enable_logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/text-to-dialogue/stream/with-timestamps" $qp)
  let body = {inputs: $inputs, model_id: $model_id, language_code: $language_code, settings: $settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, apply_text_normalization: $apply_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Dialogue With Timestamps
#
# POST /v1/text-to-dialogue/with-timestamps
# operationId: text_to_dialogue_full_with_timestamps
# --inputs item shape: {text: string, voice_id: string}
export def "text-to-dialogue-with-timestamps timestamps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer-1 # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM and WAV formats with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  inputs: list # A list of dialogue inputs, each containing text and a voice ID which will be converted into speech. The maximum number of unique voice IDs is 10. For reliable generation, keep the total character count across all `inputs[].text` values at or below 2,000 characters per request. Longer requests can terminate early in streaming responses or return a validation error. — item shape: {text: string, voice_id: string}
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for text to speech, you can check this using the can_do_text_to_speech property. (default: eleven_v3)
  --language-code: any # Language code (ISO 639-1) used to enforce a language for the model and text normalization. If the model does not support provided language code, an error will be returned.
  --settings: any # Settings controlling the dialogue generation.
  --pronunciation-dictionary-locators: any # A list of pronunciation dictionary locators (id, version_id) to be applied to the text. They will be applied in order. You may have up to 3 locators per request
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --apply-text-normalization: string@apply-text-normalization-completer # This parameter controls text normalization with three modes: 'auto', 'on', and 'off'. When set to 'auto', the system will automatically decide whether to apply text normalization (e.g., spelling out numbers). With 'on', text normalization will always be applied, while with 'off', it will be skipped. (default: auto)
]: any -> record<audio_base64: string, alignment: any, normalized_alignment: any, voice_segments: table<voice_id: string, start_time_seconds: float, end_time_seconds: float, character_start_index: int, character_end_index: int, dialogue_input_index: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar") (serialize-qp "enable_logging" $enable_logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/text-to-dialogue/with-timestamps" $qp)
  let body = {inputs: $inputs, model_id: $model_id, language_code: $language_code, settings: $settings, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, seed: $seed, apply_text_normalization: $apply_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Speech To Speech
#
# POST /v1/speech-to-speech/{voice_id}
# operationId: speech_to_speech_full
@deprecated --flag optimize-streaming-latency
export def "speech-to-speech full" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --optimize-streaming-latency: string # You can turn on latency optimizations at some cost of quality. The best possible final latency varies by model. Possible values: 0 - default mode (no latency optimizations) 1 - normal latency optimizations (about 50% of possible latency improvement of option 3) 2 - strong latency optimizations (about 75% of possible latency improvement of option 3) 3 - max latency optimizations 4 - max latency optimizations, but also with text normalizer turned off for even more latency savings (best latency, but can mispronounce eg numbers and dates).  Defaults to None.  (DEPRECATED)
  --output-format: string@output-format-completer-1 # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM and WAV formats with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  audio: string # The audio file which holds the content and emotion that will control the generated speech. (format: binary)
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for speech to speech, you can check this using the can_do_voice_conversion property. (default: eleven_english_sts_v2)
  --voice-settings: any # Voice settings overriding stored settings for the given voice. They are applied only on the given request. Needs to be send as a JSON encoded string.
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --remove-background-noise: oneof<nothing, bool> # If set, will remove the background noise from your audio input using our audio isolation model. Only applies to Voice Changer. (default: false)
  --file-format: any # The format of input audio. Options are 'pcm_s16le_16' or 'other' For `pcm_s16le_16`, the input audio must be 16-bit PCM at a 16kHz sample rate, single channel (mono), and little-endian byte order. Latency will be lower than with passing an encoded waveform. (default: other)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logging" $enable_logging "scalar") (serialize-qp "optimize_streaming_latency" $optimize_streaming_latency "scalar") (serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/speech-to-speech/($voice_id)" $qp)
  let body = {audio: $audio, model_id: $model_id, voice_settings: $voice_settings, seed: $seed, remove_background_noise: $remove_background_noise, file_format: $file_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Speech To Speech Streaming
#
# POST /v1/speech-to-speech/{voice_id}/stream
# operationId: speech_to_speech_stream
@deprecated --flag optimize-streaming-latency
export def "speech-to-speech-stream stream" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean history features are unavailable for this request, including request stitching. Zero retention mode may only be used by enterprise customers. (default: true)
  --optimize-streaming-latency: string # You can turn on latency optimizations at some cost of quality. The best possible final latency varies by model. Possible values: 0 - default mode (no latency optimizations) 1 - normal latency optimizations (about 50% of possible latency improvement of option 3) 2 - strong latency optimizations (about 75% of possible latency improvement of option 3) 3 - max latency optimizations 4 - max latency optimizations, but also with text normalizer turned off for even more latency savings (best latency, but can mispronounce eg numbers and dates).  Defaults to None.  (DEPRECATED)
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs. (default: mp3_44100_128)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  audio: string # The audio file which holds the content and emotion that will control the generated speech. (format: binary)
  --model-id: string # Identifier of the model that will be used, you can query them using GET /v1/models. The model needs to have support for speech to speech, you can check this using the can_do_voice_conversion property. (default: eleven_english_sts_v2)
  --voice-settings: any # Voice settings overriding stored settings for the given voice. They are applied only on the given request. Needs to be send as a JSON encoded string.
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be integer between 0 and 4294967295.
  --remove-background-noise: oneof<nothing, bool> # If set, will remove the background noise from your audio input using our audio isolation model. Only applies to Voice Changer. (default: false)
  --file-format: any # The format of input audio. Options are 'pcm_s16le_16' or 'other' For `pcm_s16le_16`, the input audio must be 16-bit PCM at a 16kHz sample rate, single channel (mono), and little-endian byte order. Latency will be lower than with passing an encoded waveform. (default: other)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logging" $enable_logging "scalar") (serialize-qp "optimize_streaming_latency" $optimize_streaming_latency "scalar") (serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/speech-to-speech/($voice_id)/stream" $qp)
  let body = {audio: $audio, model_id: $model_id, voice_settings: $voice_settings, seed: $seed, remove_background_noise: $remove_background_noise, file_format: $file_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# [Deprecated] Generate A Voice Preview From Description
#
# POST /v1/text-to-voice/create-previews
# DEPRECATED
# operationId: text_to_voice
@deprecated
export def "text-to-voice-create-previews voice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  voice_description: string # Description to use for the created voice.
  --text: any # Text to generate, text length has to be between 100 and 1000.
  --auto-generate-text: oneof<nothing, bool> # Whether to automatically generate a text suitable for the voice description. (default: false)
  --loudness: float # Controls the volume level of the generated voice. -1 is quietest, 1 is loudest, 0 corresponds to roughly -24 LUFS. (default: 0.5)
  --quality: float # Higher quality results in better voice output but less variety. (default: 0.9)
  --seed: any # Random number that controls the voice generation. Same seed with same inputs produces same voice.
  --guidance-scale: float # Controls how closely the AI follows the prompt. Lower numbers give the AI more freedom to be creative, while higher numbers force it to stick more to the prompt. High numbers can cause voice to sound artificial or robotic. We recommend to use longer, more detailed prompts at lower Guidance Scale. (default: 5)
  --should-enhance: oneof<nothing, bool> # Whether to enhance the voice description using AI to add more detail and improve voice generation quality. When enabled, the system will automatically expand simple prompts into more detailed voice descriptions. Defaults to False (default: false)
]: any -> record<previews: table<audio_base_64: string, generated_voice_id: string, media_type: string, duration_secs: float, language: any>, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/text-to-voice/create-previews" $qp)
  let body = {voice_description: $voice_description, text: $text, auto_generate_text: $auto_generate_text, loudness: $loudness, quality: $quality, seed: $seed, guidance_scale: $guidance_scale, should_enhance: $should_enhance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create A New Voice From Voice Preview
#
# POST /v1/text-to-voice
# operationId: create_voice
export def "text-to-voice voice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  voice_name: string # Name to use for the created voice.
  voice_description: string # Description to use for the created voice.
  generated_voice_id: string # The generated_voice_id to create; obtain it from POST /v1/text-to-voice/design, POST /v1/text-to-voice/:voice_id/remix, or the response headers when generating previews.
  --labels: any # Optional, metadata to add to the created voice. Defaults to None.
  --played-not-selected-voice-ids: any # List of voice ids that the user has played but not selected. Used for RLHF.
]: any -> record<voice_id: string, name: string, samples: any, category: string, fine_tuning: any, labels: record, description: any, preview_url: any, available_for_tiers: list<string>, settings: any, sharing: any, high_quality_base_model_ids: list<string>, verified_languages: any, collection_ids: any, safety_control: any, voice_verification: any, permission_on_resource: any, is_owner: any, is_legacy: bool, is_mixed: bool, favorited_at_unix: any, created_at_unix: any, is_bookmarked: any, recording_quality: any, labelling_status: any, recording_quality_reason: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/text-to-voice")
  let body = {voice_name: $voice_name, voice_description: $voice_description, generated_voice_id: $generated_voice_id, labels: $labels, played_not_selected_voice_ids: $played_not_selected_voice_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Design A Voice.
#
# POST /v1/text-to-voice/design
# operationId: text_to_voice_design
export def "text-to-voice-design design" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  voice_description: string # Description to use for the created voice.
  --model-id: string@model-id-completer # Model to use for the voice generation. Possible values: eleven_multilingual_ttv_v2, eleven_ttv_v3. (default: eleven_multilingual_ttv_v2)
  --text: any # Text to generate, text length has to be between 100 and 1000.
  --auto-generate-text: oneof<nothing, bool> # Whether to automatically generate a text suitable for the voice description. (default: false)
  --loudness: float # Controls the volume level of the generated voice. -1 is quietest, 1 is loudest, 0 corresponds to roughly -24 LUFS. (default: 0.5)
  --seed: any # Random number that controls the voice generation. Same seed with same inputs produces same voice.
  --guidance-scale: float # Controls how closely the AI follows the prompt. Lower numbers give the AI more freedom to be creative, while higher numbers force it to stick more to the prompt. High numbers can cause voice to sound artificial or robotic. We recommend to use longer, more detailed prompts at lower Guidance Scale. (default: 5)
  --stream-previews: oneof<nothing, bool> # Determines whether the Text to Voice previews should be included in the response. If true, only the generated IDs will be returned which can then be streamed via the /v1/text-to-voice/:generated_voice_id/stream endpoint. (default: false)
  --should-enhance: oneof<nothing, bool> # Whether to enhance the voice description using AI to add more detail and improve voice generation quality. When enabled, the system will automatically expand simple prompts into more detailed voice descriptions. Defaults to False (default: false)
  --remixing-session-id: any # The remixing session id.
  --remixing-session-iteration-id: any # The id of the remixing session iteration where these generations should be attached to. If not provided, a new iteration will be created.
  --quality: any # Higher quality results in better voice output but less variety.
  --reference-audio-base64: any # Reference audio to use for the voice generation. The audio should be base64 encoded. Only supported when using the  eleven_ttv_v3 model.
  --prompt-strength: any # Controls the balance of prompt versus reference audio when generating voice samples. 0 means almost no prompt influence, 1 means almost no reference audio influence. Only supported when using the eleven_ttv_v3 model.
]: any -> record<previews: table<audio_base_64: string, generated_voice_id: string, media_type: string, duration_secs: float, language: any>, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/text-to-voice/design" $qp)
  let body = {voice_description: $voice_description, model_id: $model_id, text: $text, auto_generate_text: $auto_generate_text, loudness: $loudness, seed: $seed, guidance_scale: $guidance_scale, stream_previews: $stream_previews, should_enhance: $should_enhance, remixing_session_id: $remixing_session_id, remixing_session_iteration_id: $remixing_session_iteration_id, quality: $quality, reference_audio_base64: $reference_audio_base64, prompt_strength: $prompt_strength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remix A Voice.
#
# POST /v1/text-to-voice/{voice_id}/remix
# operationId: text_to_voice_remix
export def "text-to-voice-remix remix" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  voice_description: string # Description of the changes to make to the voice.
  --text: any # Text to generate, text length has to be between 100 and 1000.
  --auto-generate-text: oneof<nothing, bool> # Whether to automatically generate a text suitable for the voice description. (default: false)
  --loudness: float # Controls the volume level of the generated voice. -1 is quietest, 1 is loudest, 0 corresponds to roughly -24 LUFS. (default: 0.5)
  --seed: any # Random number that controls the voice generation. Same seed with same inputs produces same voice.
  --guidance-scale: float # Controls how closely the AI follows the prompt. Lower numbers give the AI more freedom to be creative, while higher numbers force it to stick more to the prompt. High numbers can cause voice to sound artificial or robotic. We recommend to use longer, more detailed prompts at lower Guidance Scale. (default: 2)
  --stream-previews: oneof<nothing, bool> # Determines whether the Text to Voice previews should be included in the response. If true, only the generated IDs will be returned which can then be streamed via the /v1/text-to-voice/:generated_voice_id/stream endpoint. (default: false)
  --remixing-session-id: any # The remixing session id.
  --remixing-session-iteration-id: any # The id of the remixing session iteration where these generations should be attached to. If not provided, a new iteration will be created.
  --prompt-strength: any # Controls the balance of prompt versus reference audio when generating voice samples. 0 means almost no prompt influence, 1 means almost no reference audio influence. Only supported when using the eleven_ttv_v3 model.
]: any -> record<previews: table<audio_base_64: string, generated_voice_id: string, media_type: string, duration_secs: float, language: any>, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/text-to-voice/($voice_id)/remix" $qp)
  let body = {voice_description: $voice_description, text: $text, auto_generate_text: $auto_generate_text, loudness: $loudness, seed: $seed, guidance_scale: $guidance_scale, stream_previews: $stream_previews, remixing_session_id: $remixing_session_id, remixing_session_iteration_id: $remixing_session_iteration_id, prompt_strength: $prompt_strength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text To Voice Preview Streaming
#
# GET /v1/text-to-voice/{generated_voice_id}/stream
# operationId: text_to_voice_preview_stream
export def "text-to-voice-stream stream" [
  generated_voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/text-to-voice/($generated_voice_id)/stream")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Info
#
# GET /v1/user
# operationId: get_user_info
export def "user info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<user_id: string, subscription: record<tier: string, character_count: int, character_limit: int, max_character_limit_extension: any, max_credit_limit_extension: any, can_extend_character_limit: bool, allowed_to_extend_character_limit: bool, next_character_count_reset_unix: any, voice_slots_used: int, professional_voice_slots_used: int, voice_limit: int, max_voice_add_edits: any, voice_add_edit_counter: int, professional_voice_limit: int, can_extend_voice_limit: bool, can_use_instant_voice_cloning: bool, can_use_professional_voice_cloning: bool, currency: any, current_overage: record<amount: string, currency: string>, status: string, billing_period: any, character_refresh_period: any>, is_new_user: bool, xi_api_key: any, can_use_delayed_payment_methods: bool, is_onboarding_completed: bool, is_onboarding_checklist_completed: bool, show_compliance_terms: bool, first_name: any, is_api_key_hashed: bool, xi_api_key_preview: any, referral_link_code: any, partnerstack_partner_default_link: any, created_at: int, seat_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Subscription Info
#
# GET /v1/user/subscription
# operationId: get_user_subscription_info
export def "user-subscription info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<tier: string, character_count: int, character_limit: int, max_character_limit_extension: any, max_credit_limit_extension: any, can_extend_character_limit: bool, allowed_to_extend_character_limit: bool, next_character_count_reset_unix: any, voice_slots_used: int, professional_voice_slots_used: int, voice_limit: int, max_voice_add_edits: any, voice_add_edit_counter: int, professional_voice_limit: int, can_extend_voice_limit: bool, can_use_instant_voice_cloning: bool, can_use_professional_voice_cloning: bool, currency: any, current_overage: record<amount: string, currency: string>, status: string, billing_period: any, character_refresh_period: any, next_invoice: any, open_invoices: table<amount_due_cents: int, subtotal_cents: any, tax_cents: any, discount_percent_off: any, discount_amount_off: any, discounts: list, next_payment_attempt_unix: int, payment_intent_status: any, payment_intent_statusses: list>, has_open_invoices: bool, pending_change: any, has_used_starter_coupon_on_account: bool, has_used_creator_coupon_on_account: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user/subscription")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Default Voice Settings.
#
# GET /v1/voices/settings/default
# operationId: get_voice_settings_default
export def "voices-settings-default default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stability: any, use_speaker_boost: any, similarity_boost: any, style: any, speed: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/voices/settings/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Voice Settings
#
# GET /v1/voices/{voice_id}/settings
# operationId: get_voice_settings
export def "voices-settings settings" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<stability: any, use_speaker_boost: any, similarity_boost: any, style: any, speed: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)/settings")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit Voice Settings
#
# POST /v1/voices/{voice_id}/settings/edit
# operationId: edit_voice_settings
export def "voices-settings-edit settings" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --stability: any # Determines how stable the voice is and the randomness between each generation. Lower values introduce broader emotional range for the voice. Higher values can result in a monotonous voice with limited emotion. (default: 0.5)
  --use-speaker-boost: any # This setting boosts the similarity to the original speaker. Using this setting requires a slightly higher computational load, which in turn increases latency. (default: true)
  --similarity-boost: any # Determines how closely the AI should adhere to the original voice when attempting to replicate it. (default: 0.75)
  --style: any # Determines the style exaggeration of the voice. This setting attempts to amplify the style of the original speaker. It does consume additional computational resources and might increase latency if set to anything other than 0. (default: 0.0)
  --speed: any # Adjusts the speed of the voice. A value of 1.0 is the default speed, while values less than 1.0 slow down the speech, and values greater than 1.0 speed it up. (default: 1.0)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)/settings/edit")
  let body = {stability: $stability, use_speaker_boost: $use_speaker_boost, similarity_boost: $similarity_boost, style: $style, speed: $speed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Voice
#
# GET /v1/voices/{voice_id}
# operationId: get_voice_by_id
@deprecated --flag with-settings
export def "voices id" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-settings: oneof<nothing, bool> # This parameter is now deprecated. It is ignored and will be removed in a future version. (DEPRECATED, default: true)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<voice_id: string, name: string, samples: any, category: string, fine_tuning: any, labels: record, description: any, preview_url: any, available_for_tiers: list<string>, settings: any, sharing: any, high_quality_base_model_ids: list<string>, verified_languages: any, collection_ids: any, safety_control: any, voice_verification: any, permission_on_resource: any, is_owner: any, is_legacy: bool, is_mixed: bool, favorited_at_unix: any, created_at_unix: any, is_bookmarked: any, recording_quality: any, labelling_status: any, recording_quality_reason: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_settings" $with_settings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/voices/($voice_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Voice
#
# DELETE /v1/voices/{voice_id}
# operationId: delete_voice
export def "voices voice" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Voices
#
# GET /v1/voices
# operationId: get_voices
export def "voices voices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-legacy: string # If set to true, legacy premade voices will be included in responses from /v1/voices (default: false)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<voices: table<voice_id: string, name: string, samples: any, category: string, fine_tuning: any, labels: record, description: any, preview_url: any, available_for_tiers: list, settings: any, sharing: any, high_quality_base_model_ids: list, verified_languages: any, collection_ids: any, safety_control: any, voice_verification: any, permission_on_resource: any, is_owner: any, is_legacy: bool, is_mixed: bool, favorited_at_unix: any, created_at_unix: any, is_bookmarked: any, recording_quality: any, labelling_status: any, recording_quality_reason: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_legacy" $show_legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/voices" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Voices V2
#
# GET /v2/voices
# operationId: get_user_voices_v2
export def "voices v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --next-page-token: string # The next page token to use for pagination. Returned from the previous request. Use this in combination with the has_more flag for reliable pagination.
  --page-size: int # How many voices to return at maximum. Can not exceed 100, defaults to 10. Page 0 may include more voices due to default voices being included. (default: 10)
  --search: string # Search term to filter voices by. Searches in name, description, labels, category.
  --qp-sort: string # Which field to sort by, one of 'created_at_unix' or 'name'. 'created_at_unix' may not be available for older voices.
  --sort-direction: string # Which direction to sort the voices in. 'asc' or 'desc'.
  --voice-type: string # Type of the voice to filter by. One of 'personal', 'community', 'default', 'workspace', 'non-default', 'non-community', 'saved'. 'non-default' is equal to all but 'default'. 'non-community' is equal to 'personal' and 'workspace' combined (excludes library copies). 'saved' is equal to non-default, but includes default voices if they have been added to a collection.
  --category: string # Category of the voice to filter by. One of 'premade', 'cloned', 'generated', 'professional'
  --fine-tuning-state: string # State of the voice's fine tuning to filter by. Applicable only to professional voices clones. One of 'draft', 'not_verified', 'not_started', 'queued', 'fine_tuning', 'fine_tuned', 'failed', 'delayed'
  --collection-id: string # Collection ID to filter voices by.
  --include-total-count: oneof<nothing, bool> # Whether to include the total count of voices found in the response. NOTE: The total_count value is a live snapshot and may change between requests as users create, modify, or delete voices. For pagination, rely on the has_more flag instead. Only enable this when you actually need the total count (e.g., for display purposes), as it incurs a performance cost. (default: true)
  --voice-ids: string # Voice IDs to lookup by. Maximum 100 voice IDs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<voices: table<voice_id: string, name: string, samples: any, category: string, fine_tuning: any, labels: record, description: any, preview_url: any, available_for_tiers: list, settings: any, sharing: any, high_quality_base_model_ids: list, verified_languages: any, collection_ids: any, safety_control: any, voice_verification: any, permission_on_resource: any, is_owner: any, is_legacy: bool, is_mixed: bool, favorited_at_unix: any, created_at_unix: any, is_bookmarked: any, recording_quality: any, labelling_status: any, recording_quality_reason: any>, has_more: bool, total_count: int, next_page_token: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next_page_token" $next_page_token "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "voice_type" $voice_type "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "fine_tuning_state" $fine_tuning_state "scalar") (serialize-qp "collection_id" $collection_id "scalar") (serialize-qp "include_total_count" $include_total_count "scalar") (serialize-qp "voice_ids" $voice_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/voices" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Voice
#
# POST /v1/voices/add
# operationId: add_voice
export def "voices-add voice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name that identifies this voice. This will be displayed in the dropdown of the website.
  files: list # A list of file paths to audio recordings intended for voice cloning.
  --remove-background-noise: oneof<nothing, bool> # If set will remove background noise for voice samples using our audio isolation model. If the samples do not include background noise, it can make the quality worse. (default: false)
  --description: any # A description of the voice.
  --labels: any # Labels for the voice. Keys can be language, accent, gender, or age.
]: any -> record<voice_id: string, requires_verification: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/voices/add")
  let body = {name: $name, files: $files, remove_background_noise: $remove_background_noise, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Edit Voice
#
# POST /v1/voices/{voice_id}/edit
# operationId: edit_voice
export def "voices-edit voice" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name that identifies this voice. This will be displayed in the dropdown of the website.
  --files: list # Audio files to add to the voice
  --remove-background-noise: oneof<nothing, bool> # If set will remove background noise for voice samples using our audio isolation model. If the samples do not include background noise, it can make the quality worse. (default: false)
  --description: any # A description of the voice.
  --labels: any # Labels for the voice. Keys can be language, accent, gender, or age.
  --moderate-metadata: oneof<nothing, bool> # Run synchronous LLM moderation over the voice name and description when they change. Has no effect unless the voice_library_metadata_moderation feature flag is enabled for the user. (default: false)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/($voice_id)/edit")
  let body = {name: $name, files: $files, remove_background_noise: $remove_background_noise, description: $description, labels: $labels, moderate_metadata: $moderate_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Add Shared Voice
#
# POST /v1/voices/add/{public_user_id}/{voice_id}
# operationId: add_sharing_voice
export def "voices-add voice-by-public_user_id-voice_id" [
  public_user_id: string
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  new_name: string # The name that identifies this voice. This will be displayed in the dropdown of the website.
  --bookmarked: oneof<nothing, bool> # default: true
]: any -> record<voice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/add/($public_user_id)/($voice_id)")
  let body = {new_name: $new_name, bookmarked: $bookmarked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Podcast
#
# POST /v1/studio/podcasts
# operationId: create_podcast
export def "studio-podcasts podcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --safety-identifier: string # Used for moderation. Your workspace must be allowlisted to use this feature.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  model_id: string # The ID of the model to be used for this Studio project, you can query GET /v1/models to list all available models.
  mode: any # The type of podcast to generate. Can be 'conversation', an interaction between two voices, or 'bulletin', a monologue.
  --body-source: any # The source content for the Podcast.
  --quality-preset: string@quality-preset-completer # default: standard
  --duration-scale: string@duration-scale-completer # Duration of the generated podcast. Must be one of: short - produces podcasts shorter than 3 minutes. default - produces podcasts roughly between 3-7 minutes. long - produces podcasts longer than 7 minutes.  (default: default)
  --language: any # An optional language of the Studio project. Two-letter language code (ISO 639-1).
  --intro: any # The intro text that will always be added to the beginning of the podcast.
  --outro: any # The outro text that will always be added to the end of the podcast.
  --instructions-prompt: any # Additional instructions prompt for the podcast generation used to adjust the podcast's style and tone.
  --highlights: any # A brief summary or highlights of the Studio project's content, providing key points or themes. This should be between 10 and 70 characters.
  --callback-url: any #      A url that will be called by our service when the Studio project is converted. Request will contain a json blob containing the status of the conversion     Messages:     1. When project was converted successfully:     {       type: "project_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         conversion_status: "success",         project_snapshot_id: "22m00Tcm4TlvDq8ikMAT",         error_details: None,       }     }     2. When project conversion failed:     {       type: "project_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         conversion_status: "error",         project_snapshot_id: None,         error_details: "Error details if conversion failed"       }     }      3. When chapter was converted successfully:     {       type: "chapter_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         chapter_id: "22m00Tcm4TlvDq8ikMAT",         conversion_status: "success",         chapter_snapshot_id: "23m00Tcm4TlvDq8ikMAV",         error_details: None,       }     }     4. When chapter conversion failed:     {       type: "chapter_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         chapter_id: "22m00Tcm4TlvDq8ikMAT",         conversion_status: "error",         chapter_snapshot_id: None,         error_details: "Error details if conversion failed"       }     }     
  --apply-text-normalization: any #      This parameter controls text normalization with four modes: 'auto', 'on', 'apply_english' and 'off'.     When set to 'auto', the system will automatically decide whether to apply text normalization     (e.g., spelling out numbers). With 'on', text normalization will always be applied, while     with 'off', it will be skipped. 'apply_english' is the same as 'on' but will assume that text is in English.     
]: any -> record<project: record<project_id: string, name: string, create_date_unix: int, created_by_user_id: any, default_title_voice_ref_id: string, default_paragraph_voice_ref_id: string, default_model_id: string, last_conversion_date_unix: any, can_be_downloaded: bool, title: any, author: any, description: any, genres: any, cover_image_url: any, target_audience: any, language: any, content_type: any, original_publication_date: any, mature_content: any, isbn_number: any, volume_normalization: bool, state: string, access_level: string, fiction: any, quality_check_on: bool, quality_check_on_when_bulk_convert: bool, creation_meta: any, source_type: any, chapters_enabled: any, captions_enabled: any, caption_style: any, caption_style_template_overrides: any, public_share_id: any, aspect_ratio: any, agent_settings: any, default_title_voice_id: string, default_paragraph_voice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/studio/podcasts")
  let body = {model_id: $model_id, mode: $mode, source: $body_source, quality_preset: $quality_preset, duration_scale: $duration_scale, language: $language, intro: $intro, outro: $outro, instructions_prompt: $instructions_prompt, highlights: $highlights, callback_url: $callback_url, apply_text_normalization: $apply_text_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"safety-identifier": $safety_identifier, "xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Video To Music
#
# POST /v1/music/video-to-music
# operationId: video_to_music
export def "music-video-to-music music" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  videos: list #              One or more video files sent via FormData array (multipart/form-data). They will be combined into one codec in order.             A maximum of 10 videos is allowed, where the total size of the combined video is limited to 200MB.             In total, the video can be up to 600 seconds long. Note that combining multiple videos may increase the request duration significantly. If possible, combine the videos beforehand.             
  --description: any # Optional text description of the music you want. A maximum of 1000 characters is allowed.
  --tags: list # Optional list of style tags (e.g. ['upbeat', 'cinematic']). A maximum of 10 tags is allowed. (default: [])
  --model-id: string@model-id-completer-1 # The model to use for the generation. (default: music_v1)
  --sign-with-c2pa: oneof<nothing, bool> # Whether to sign the generated song with C2PA. Applicable only for mp3 files. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/music/video-to-music" $qp)
  let body = {videos: $videos, description: $description, tags: $tags, model_id: $model_id, sign_with_c2pa: $sign_with_c2pa} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create Pronunciation Dictionaries
#
# POST /v1/studio/projects/{project_id}/pronunciation-dictionaries
# operationId: update_pronunciation_dictionaries
# --pronunciation_dictionary_locators item shape: {pronunciation_dictionary_id: string, version_id: any}
export def "studio-projects-pronunciation-dictionaries dictionaries" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  pronunciation_dictionary_locators: list # A list of pronunciation dictionary locators (pronunciation_dictionary_id, version_id) encoded as a list of JSON strings for pronunciation dictionaries to be applied to the text. A list of json encoded strings is required as adding projects may occur through formData as opposed to jsonBody. To specify multiple dictionaries use multiple --form lines in your curl, such as --form 'pronunciation_dictionary_locators="{\"pronunciation_dictionary_id\":\"Vmd4Zor6fplcA7WrINey\",\"version_id\":\"hRPaxjlTdR7wFMhV4w0b\"}"' --form 'pronunciation_dictionary_locators="{\"pronunciation_dictionary_id\":\"JzWtcGQMJ6bnlWwyMo7e\",\"version_id\":\"lbmwxiLu4q6txYxgdZqn\"}"'. — item shape: {pronunciation_dictionary_id: string, version_id: any}
  --invalidate-affected-text: oneof<nothing, bool> # This will automatically mark text in this project for reconversion when the new dictionary applies or the old one no longer does. (default: true)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/pronunciation-dictionaries")
  let body = {pronunciation_dictionary_locators: $pronunciation_dictionary_locators, invalidate_affected_text: $invalidate_affected_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Studio Projects
#
# GET /v1/studio/projects
# operationId: get_projects
export def "studio-projects projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<projects: table<project_id: string, name: string, create_date_unix: int, created_by_user_id: any, default_title_voice_ref_id: string, default_paragraph_voice_ref_id: string, default_model_id: string, last_conversion_date_unix: any, can_be_downloaded: bool, title: any, author: any, description: any, genres: any, cover_image_url: any, target_audience: any, language: any, content_type: any, original_publication_date: any, mature_content: any, isbn_number: any, volume_normalization: bool, state: string, access_level: string, fiction: any, quality_check_on: bool, quality_check_on_when_bulk_convert: bool, creation_meta: any, source_type: any, chapters_enabled: any, captions_enabled: any, caption_style: any, caption_style_template_overrides: any, public_share_id: any, aspect_ratio: any, agent_settings: any, default_title_voice_id: string, default_paragraph_voice_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/studio/projects")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Studio Project
#
# POST /v1/studio/projects
# operationId: add_project
export def "studio-projects project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name of the Studio project, used for identification only.
  --default-title-voice-id: any # The voice_id that corresponds to the default voice used for new titles.
  --default-paragraph-voice-id: any # The voice_id that corresponds to the default voice used for new paragraphs.
  --default-model-id: any # The ID of the model to be used for this Studio project, you can query GET /v1/models to list all available models.
  --from-url: any # An optional URL from which we will extract content to initialize the Studio project. If this is set, 'from_url' and 'from_content' must be null. If neither 'from_url', 'from_document', 'from_content' are provided we will initialize the Studio project as blank.
  --from-document: any # An optional .epub, .pdf, .txt or similar file can be provided. If provided, we will initialize the Studio project with its content. If this is set, 'from_url' and 'from_content' must be null. If neither 'from_url', 'from_document', 'from_content' are provided we will initialize the Studio project as blank.
  --from-content-json: string #      An optional content to initialize the Studio project with. If this is set, 'from_url' and 'from_document' must be null. If neither 'from_url', 'from_document', 'from_content' are provided we will initialize the Studio project as blank.      Example:     [{"name": "Chapter A", "blocks": [{"sub_type": "p", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "A", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "B", "type": "tts_node"}]}, {"sub_type": "h1", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "C", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "D", "type": "tts_node"}]}]}, {"name": "Chapter B", "blocks": [{"sub_type": "p", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "E", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "F", "type": "tts_node"}]}, {"sub_type": "h2", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "G", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "H", "type": "tts_node"}]}]}]     
  --quality-preset: string@quality-preset-completer # default: standard
  --title: any # An optional name of the author of the Studio project, this will be added as metadata to the mp3 file on Studio project or chapter download.
  --author: any # An optional name of the author of the Studio project, this will be added as metadata to the mp3 file on Studio project or chapter download.
  --description: any # An optional description of the Studio project.
  --genres: list # An optional list of genres associated with the Studio project.
  --target-audience: any # An optional target audience of the Studio project.
  --language: any # An optional language of the Studio project. Two-letter language code (ISO 639-1).
  --content-type: any # An optional content type of the Studio project.
  --original-publication-date: any # An optional original publication date of the Studio project, in the format YYYY-MM-DD or YYYY.
  --mature-content: any # An optional specification of whether this Studio project contains mature content. (default: false)
  --isbn-number: any # An optional ISBN number of the Studio project you want to create, this will be added as metadata to the mp3 file on Studio project or chapter download.
  --acx-volume-normalization: oneof<nothing, bool> # [Deprecated] When the Studio project is downloaded, should the returned audio have postprocessing in order to make it compliant with audiobook normalized volume requirements (default: false)
  --volume-normalization: oneof<nothing, bool> # When the Studio project is downloaded, should the returned audio have postprocessing in order to make it compliant with audiobook normalized volume requirements (default: false)
  --pronunciation-dictionary-locators: list # A list of pronunciation dictionary locators (pronunciation_dictionary_id, version_id) encoded as a list of JSON strings for pronunciation dictionaries to be applied to the text. A list of json encoded strings is required as adding projects may occur through formData as opposed to jsonBody. To specify multiple dictionaries use multiple --form lines in your curl, such as --form 'pronunciation_dictionary_locators="{\"pronunciation_dictionary_id\":\"Vmd4Zor6fplcA7WrINey\",\"version_id\":\"hRPaxjlTdR7wFMhV4w0b\"}"' --form 'pronunciation_dictionary_locators="{\"pronunciation_dictionary_id\":\"JzWtcGQMJ6bnlWwyMo7e\",\"version_id\":\"lbmwxiLu4q6txYxgdZqn\"}"'.
  --callback-url: any #      A url that will be called by our service when the Studio project is converted. Request will contain a json blob containing the status of the conversion     Messages:     1. When project was converted successfully:     {       type: "project_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         conversion_status: "success",         project_snapshot_id: "22m00Tcm4TlvDq8ikMAT",         error_details: None,       }     }     2. When project conversion failed:     {       type: "project_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         conversion_status: "error",         project_snapshot_id: None,         error_details: "Error details if conversion failed"       }     }      3. When chapter was converted successfully:     {       type: "chapter_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         chapter_id: "22m00Tcm4TlvDq8ikMAT",         conversion_status: "success",         chapter_snapshot_id: "23m00Tcm4TlvDq8ikMAV",         error_details: None,       }     }     4. When chapter conversion failed:     {       type: "chapter_conversion_status",       event_timestamp: 1234567890,       data: {         request_id: "1234567890",         project_id: "21m00Tcm4TlvDq8ikWAM",         chapter_id: "22m00Tcm4TlvDq8ikMAT",         conversion_status: "error",         chapter_snapshot_id: None,         error_details: "Error details if conversion failed"       }     }     
  --fiction: any # An optional specification of whether the content of this Studio project is fiction.
  --apply-text-normalization: any #      This parameter controls text normalization with four modes: 'auto', 'on', 'apply_english' and 'off'.     When set to 'auto', the system will automatically decide whether to apply text normalization     (e.g., spelling out numbers). With 'on', text normalization will always be applied, while     with 'off', it will be skipped. 'apply_english' is the same as 'on' but will assume that text is in English.     
  --auto-convert: oneof<nothing, bool> # Whether to auto convert the Studio project to audio or not. (default: false)
  --auto-assign-voices: any # [Alpha Feature] Whether automatically assign voices to phrases in the create Project. (default: false)
  --source-type: any # The type of Studio project to create.
  --voice-settings: list #     Optional voice settings overrides for the project, encoded as a list of JSON strings.      Example:     ["{\"voice_id\": \"21m00Tcm4TlvDq8ikWAM\", \"stability\": 0.7, \"similarity_boost\": 0.8, \"style\": 0.5, \"speed\": 1.0, \"use_speaker_boost\": true}"]     
  --create-publishing-read: any # If true, creates a corresponding read for direct publishing in draft state (default: false)
]: any -> record<project: record<project_id: string, name: string, create_date_unix: int, created_by_user_id: any, default_title_voice_ref_id: string, default_paragraph_voice_ref_id: string, default_model_id: string, last_conversion_date_unix: any, can_be_downloaded: bool, title: any, author: any, description: any, genres: any, cover_image_url: any, target_audience: any, language: any, content_type: any, original_publication_date: any, mature_content: any, isbn_number: any, volume_normalization: bool, state: string, access_level: string, fiction: any, quality_check_on: bool, quality_check_on_when_bulk_convert: bool, creation_meta: any, source_type: any, chapters_enabled: any, captions_enabled: any, caption_style: any, caption_style_template_overrides: any, public_share_id: any, aspect_ratio: any, agent_settings: any, default_title_voice_id: string, default_paragraph_voice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/studio/projects")
  let body = {name: $name, default_title_voice_id: $default_title_voice_id, default_paragraph_voice_id: $default_paragraph_voice_id, default_model_id: $default_model_id, from_url: $from_url, from_document: $from_document, from_content_json: $from_content_json, quality_preset: $quality_preset, title: $title, author: $author, description: $description, genres: $genres, target_audience: $target_audience, language: $language, content_type: $content_type, original_publication_date: $original_publication_date, mature_content: $mature_content, isbn_number: $isbn_number, acx_volume_normalization: $acx_volume_normalization, volume_normalization: $volume_normalization, pronunciation_dictionary_locators: $pronunciation_dictionary_locators, callback_url: $callback_url, fiction: $fiction, apply_text_normalization: $apply_text_normalization, auto_convert: $auto_convert, auto_assign_voices: $auto_assign_voices, source_type: $source_type, voice_settings: $voice_settings, create_publishing_read: $create_publishing_read} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update Studio Project
#
# POST /v1/studio/projects/{project_id}
# operationId: edit_project
export def "studio-projects project-by-project_id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name of the Studio project, used for identification only.
  default_title_voice_id: string # The voice_id that corresponds to the default voice used for new titles.
  default_paragraph_voice_id: string # The voice_id that corresponds to the default voice used for new paragraphs.
  --title: any # An optional name of the author of the Studio project, this will be added as metadata to the mp3 file on Studio project or chapter download.
  --author: any # An optional name of the author of the Studio project, this will be added as metadata to the mp3 file on Studio project or chapter download.
  --isbn-number: any # An optional ISBN number of the Studio project you want to create, this will be added as metadata to the mp3 file on Studio project or chapter download.
  --volume-normalization: oneof<nothing, bool> # When the Studio project is downloaded, should the returned audio have postprocessing in order to make it compliant with audiobook normalized volume requirements (default: false)
]: any -> record<project: record<project_id: string, name: string, create_date_unix: int, created_by_user_id: any, default_title_voice_ref_id: string, default_paragraph_voice_ref_id: string, default_model_id: string, last_conversion_date_unix: any, can_be_downloaded: bool, title: any, author: any, description: any, genres: any, cover_image_url: any, target_audience: any, language: any, content_type: any, original_publication_date: any, mature_content: any, isbn_number: any, volume_normalization: bool, state: string, access_level: string, fiction: any, quality_check_on: bool, quality_check_on_when_bulk_convert: bool, creation_meta: any, source_type: any, chapters_enabled: any, captions_enabled: any, caption_style: any, caption_style_template_overrides: any, public_share_id: any, aspect_ratio: any, agent_settings: any, default_title_voice_id: string, default_paragraph_voice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)")
  let body = {name: $name, default_title_voice_id: $default_title_voice_id, default_paragraph_voice_id: $default_paragraph_voice_id, title: $title, author: $author, isbn_number: $isbn_number, volume_normalization: $volume_normalization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Studio Project
#
# GET /v1/studio/projects/{project_id}
# operationId: get_project_by_id
export def "studio-projects id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --share-id: string # The share ID of the project
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<project_id: string, name: string, create_date_unix: int, created_by_user_id: any, default_title_voice_ref_id: string, default_paragraph_voice_ref_id: string, default_model_id: string, last_conversion_date_unix: any, can_be_downloaded: bool, title: any, author: any, description: any, genres: any, cover_image_url: any, target_audience: any, language: any, content_type: any, original_publication_date: any, mature_content: any, isbn_number: any, volume_normalization: bool, state: string, access_level: string, fiction: any, quality_check_on: bool, quality_check_on_when_bulk_convert: bool, creation_meta: any, source_type: any, chapters_enabled: any, captions_enabled: any, caption_style: any, caption_style_template_overrides: any, public_share_id: any, aspect_ratio: any, agent_settings: any, quality_preset: string, chapters: table<chapter_id: string, name: string, last_conversion_date_unix: any, conversion_progress: any, can_be_downloaded: bool, state: string, has_video: any, has_visual_content: any, voice_ids: any, statistics: any, last_conversion_error: any>, pronunciation_dictionary_versions: table<version_id: string, version_rules_num: int, pronunciation_dictionary_id: string, dictionary_name: string, version_name: string, permission_on_resource: any, created_by: string, creation_time_unix: int, archived_time_unix: any>, pronunciation_dictionary_locators: table<pronunciation_dictionary_id: string, version_id: any>, apply_text_normalization: string, experimental: record, assets: list<any>, voices: table<project_voice_ref_id: string, voice_id: string, alias: string, stability: float, similarity_boost: float, style: float, is_pinned: bool, use_speaker_boost: bool, volume_gain: float, speed: float>, base_voices: any, publishing_read: any, default_title_voice_id: string, default_paragraph_voice_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "share_id" $share_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Studio Project
#
# DELETE /v1/studio/projects/{project_id}
# operationId: delete_project
export def "studio-projects project-by-project_id-1" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Studio Project Content
#
# POST /v1/studio/projects/{project_id}/content
# operationId: edit_project_content
export def "studio-projects-content content" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --from-url: any # An optional URL from which we will extract content to initialize the Studio project. If this is set, 'from_url' and 'from_content' must be null. If neither 'from_url', 'from_document', 'from_content' are provided we will initialize the Studio project as blank.
  --from-document: any # An optional .epub, .pdf, .txt or similar file can be provided. If provided, we will initialize the Studio project with its content. If this is set, 'from_url' and 'from_content' must be null. If neither 'from_url', 'from_document', 'from_content' are provided we will initialize the Studio project as blank.
  --from-content-json: string #      An optional content to initialize the Studio project with. If this is set, 'from_url' and 'from_document' must be null. If neither 'from_url', 'from_document', 'from_content' are provided we will initialize the Studio project as blank.      Example:     [{"name": "Chapter A", "blocks": [{"sub_type": "p", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "A", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "B", "type": "tts_node"}]}, {"sub_type": "h1", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "C", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "D", "type": "tts_node"}]}]}, {"name": "Chapter B", "blocks": [{"sub_type": "p", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "E", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "F", "type": "tts_node"}]}, {"sub_type": "h2", "nodes": [{"voice_id": "6lCwbsX1yVjD49QmpkT0", "text": "G", "type": "tts_node"}, {"voice_id": "6lCwbsX1yVjD49QmpkT1", "text": "H", "type": "tts_node"}]}]}]     
  --auto-convert: oneof<nothing, bool> # Whether to auto convert the Studio project to audio or not. (default: false)
]: any -> record<project: record<project_id: string, name: string, create_date_unix: int, created_by_user_id: any, default_title_voice_ref_id: string, default_paragraph_voice_ref_id: string, default_model_id: string, last_conversion_date_unix: any, can_be_downloaded: bool, title: any, author: any, description: any, genres: any, cover_image_url: any, target_audience: any, language: any, content_type: any, original_publication_date: any, mature_content: any, isbn_number: any, volume_normalization: bool, state: string, access_level: string, fiction: any, quality_check_on: bool, quality_check_on_when_bulk_convert: bool, creation_meta: any, source_type: any, chapters_enabled: any, captions_enabled: any, caption_style: any, caption_style_template_overrides: any, public_share_id: any, aspect_ratio: any, agent_settings: any, default_title_voice_id: string, default_paragraph_voice_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/content")
  let body = {from_url: $from_url, from_document: $from_document, from_content_json: $from_content_json, auto_convert: $auto_convert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Convert Studio Project
#
# POST /v1/studio/projects/{project_id}/convert
# operationId: convert_project_endpoint
export def "studio-projects-convert endpoint" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/convert")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Studio Project Snapshots
#
# GET /v1/studio/projects/{project_id}/snapshots
# operationId: get_project_snapshots
export def "studio-projects-snapshots snapshots" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<snapshots: table<project_snapshot_id: string, project_id: string, created_at_unix: int, name: string, audio_upload: any, zip_upload: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/snapshots")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Project Snapshot
#
# GET /v1/studio/projects/{project_id}/snapshots/{project_snapshot_id}
# operationId: get_project_snapshot_endpoint
export def "studio-projects-snapshots endpoint" [
  project_id: string
  project_snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<project_snapshot_id: string, project_id: string, created_at_unix: int, name: string, audio_upload: any, zip_upload: any, character_alignments: table<characters: list, character_start_times_seconds: list, character_end_times_seconds: list>, audio_duration_secs: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/snapshots/($project_snapshot_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stream Studio Project Audio
#
# POST /v1/studio/projects/{project_id}/snapshots/{project_snapshot_id}/stream
# operationId: stream_project_snapshot_audio_endpoint
export def "studio-projects-snapshots-stream endpoint" [
  project_id: string
  project_snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --convert-to-mpeg: oneof<nothing, bool> # Whether to convert the audio to mpeg format. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/snapshots/($project_snapshot_id)/stream")
  let body = {convert_to_mpeg: $convert_to_mpeg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stream Archive With Studio Project Audio
#
# POST /v1/studio/projects/{project_id}/snapshots/{project_snapshot_id}/archive
# operationId: stream_project_snapshot_archive_endpoint
export def "studio-projects-snapshots-archive endpoint" [
  project_id: string
  project_snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/snapshots/($project_snapshot_id)/archive")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/x-zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Chapters
#
# GET /v1/studio/projects/{project_id}/chapters
# operationId: get_chapters
export def "studio-projects-chapters chapters" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<chapters: table<chapter_id: string, name: string, last_conversion_date_unix: any, conversion_progress: any, can_be_downloaded: bool, state: string, has_video: any, has_visual_content: any, voice_ids: any, statistics: any, last_conversion_error: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Chapter
#
# POST /v1/studio/projects/{project_id}/chapters
# operationId: add_chapter
export def "studio-projects-chapters chapter-by-project_id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name of the chapter, used for identification only.
  --from-url: any # An optional URL from which we will extract content to initialize the Studio project. If this is set, 'from_url' and 'from_content' must be null. If neither 'from_url', 'from_document', 'from_content' are provided we will initialize the Studio project as blank.
]: any -> record<chapter: record<chapter_id: string, name: string, last_conversion_date_unix: any, conversion_progress: any, can_be_downloaded: bool, state: string, has_video: any, has_visual_content: any, voice_ids: any, statistics: any, last_conversion_error: any, content: record<blocks: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters")
  let body = {name: $name, from_url: $from_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Chapter
#
# GET /v1/studio/projects/{project_id}/chapters/{chapter_id}
# operationId: get_chapter_by_id_endpoint
export def "studio-projects-chapters endpoint-by-project_id-chapter_id" [
  project_id: string
  chapter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<chapter_id: string, name: string, last_conversion_date_unix: any, conversion_progress: any, can_be_downloaded: bool, state: string, has_video: any, has_visual_content: any, voice_ids: any, statistics: any, last_conversion_error: any, content: record<blocks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters/($chapter_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Chapter
#
# POST /v1/studio/projects/{project_id}/chapters/{chapter_id}
# operationId: edit_chapter
export def "studio-projects-chapters chapter-by-project_id-chapter_id" [
  project_id: string
  chapter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: any # The name of the chapter, used for identification only.
  --content: any # The chapter content to use.
]: any -> record<chapter: record<chapter_id: string, name: string, last_conversion_date_unix: any, conversion_progress: any, can_be_downloaded: bool, state: string, has_video: any, has_visual_content: any, voice_ids: any, statistics: any, last_conversion_error: any, content: record<blocks: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters/($chapter_id)")
  let body = {name: $name, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Chapter
#
# DELETE /v1/studio/projects/{project_id}/chapters/{chapter_id}
# operationId: delete_chapter_endpoint
export def "studio-projects-chapters endpoint-by-project_id-chapter_id-1" [
  project_id: string
  chapter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters/($chapter_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Convert Chapter
#
# POST /v1/studio/projects/{project_id}/chapters/{chapter_id}/convert
# operationId: convert_chapter_endpoint
export def "studio-projects-chapters-convert endpoint" [
  project_id: string
  chapter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters/($chapter_id)/convert")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Chapter Snapshots
#
# GET /v1/studio/projects/{project_id}/chapters/{chapter_id}/snapshots
# operationId: get_chapter_snapshots
export def "studio-projects-chapters-snapshots snapshots" [
  project_id: string
  chapter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<snapshots: table<chapter_snapshot_id: string, project_id: string, chapter_id: string, created_at_unix: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters/($chapter_id)/snapshots")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Chapter Snapshot
#
# GET /v1/studio/projects/{project_id}/chapters/{chapter_id}/snapshots/{chapter_snapshot_id}
# operationId: get_chapter_snapshot_endpoint
export def "studio-projects-chapters-snapshots endpoint" [
  project_id: string
  chapter_id: string
  chapter_snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<chapter_snapshot_id: string, project_id: string, chapter_id: string, created_at_unix: int, name: string, character_alignments: table<characters: list, character_start_times_seconds: list, character_end_times_seconds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters/($chapter_id)/snapshots/($chapter_snapshot_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stream Chapter Audio
#
# POST /v1/studio/projects/{project_id}/chapters/{chapter_id}/snapshots/{chapter_snapshot_id}/stream
# operationId: stream_chapter_snapshot_audio
export def "studio-projects-chapters-snapshots-stream audio" [
  project_id: string
  chapter_id: string
  chapter_snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --convert-to-mpeg: oneof<nothing, bool> # Whether to convert the audio to mpeg format. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/chapters/($chapter_id)/snapshots/($chapter_snapshot_id)/stream")
  let body = {convert_to_mpeg: $convert_to_mpeg} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Project Muted Tracks
#
# GET /v1/studio/projects/{project_id}/muted-tracks
# operationId: get_project_muted_tracks_endpoint
export def "studio-projects-muted-tracks endpoint" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<chapter_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/studio/projects/($project_id)/muted-tracks")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get The Dubbing Resource For An Id.
#
# GET /v1/dubbing/resource/{dubbing_id}
# DEPRECATED
# operationId: get_dubbing_resource
@deprecated
export def "dubbing-resource resource" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, version: int, source_language: string, target_languages: list<string>, input: record<src: string, content_type: string, bucket_name: string, random_path_slug: string, duration_secs: float, is_audio: bool, url: string>, background: any, foreground: any, speaker_tracks: record, speaker_segments: record, renders: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add A Language To The Resource
#
# POST /v1/dubbing/resource/{dubbing_id}/language
# DEPRECATED
# operationId: add_language
@deprecated
export def "dubbing-resource-language language" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  language: any # The Target language.
]: any -> record<version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/language")
  let body = {language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create A Segment For The Speaker
#
# POST /v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}/segment
# DEPRECATED
# operationId: create_clip
@deprecated
export def "dubbing-resource-speaker-segment clip" [
  dubbing_id: string
  speaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  start_time: float
  end_time: float
  --text: any
  --translations: any
]: any -> record<version: int, new_segment: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/speaker/($speaker_id)/segment")
  let body = {start_time: $start_time, end_time: $end_time, text: $text, translations: $translations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modify A Single Segment
#
# PATCH /v1/dubbing/resource/{dubbing_id}/segment/{segment_id}/{language}
# DEPRECATED
# operationId: update_segment_language
@deprecated
export def "dubbing-resource-segment language" [
  dubbing_id: string
  segment_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --start-time: any
  --end-time: any
  --text: any
]: any -> record<version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/segment/($segment_id)/($language)")
  let body = {start_time: $start_time, end_time: $end_time, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move Segments Between Speakers
#
# POST /v1/dubbing/resource/{dubbing_id}/migrate-segments
# DEPRECATED
# operationId: migrate_segments
@deprecated
export def "dubbing-resource-migrate-segments segments" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  segment_ids: list
  speaker_id: string
]: any -> record<version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/migrate-segments")
  let body = {segment_ids: $segment_ids, speaker_id: $speaker_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes A Single Segment
#
# DELETE /v1/dubbing/resource/{dubbing_id}/segment/{segment_id}
# DEPRECATED
# operationId: delete_segment
@deprecated
export def "dubbing-resource-segment segment" [
  dubbing_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/segment/($segment_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transcribes Segments
#
# POST /v1/dubbing/resource/{dubbing_id}/transcribe
# DEPRECATED
# operationId: transcribe
@deprecated
export def "dubbing-resource-transcribe transcribe" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  segments: list # Transcribe this specific list of segments.
]: any -> record<version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/transcribe")
  let body = {segments: $segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Translates All Or Some Segments And Languages
#
# POST /v1/dubbing/resource/{dubbing_id}/translate
# DEPRECATED
# operationId: translate
@deprecated
export def "dubbing-resource-translate translate" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  segments: list # Translate only this list of segments.
  languages: any # Translate only these languages for each segment.
]: any -> record<version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/translate")
  let body = {segments: $segments, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Dubs All Or Some Segments And Languages
#
# POST /v1/dubbing/resource/{dubbing_id}/dub
# DEPRECATED
# operationId: dub
@deprecated
export def "dubbing-resource-dub dub" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  segments: list # Dub only this list of segments.
  languages: any # Dub only these languages for each segment.
]: any -> record<version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/dub")
  let body = {segments: $segments, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Metadata For A Speaker
#
# PATCH /v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}
# DEPRECATED
# operationId: update_speaker
@deprecated
export def "dubbing-resource-speaker speaker-by-dubbing_id-speaker_id" [
  dubbing_id: string
  speaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --speaker-name: any # Name to attribute to this speaker.
  --voice-id: any # Either the identifier of a voice from the ElevenLabs voice library, or one of ['track-clone', 'clip-clone'].
  --voice-stability: any # For models that support it, the voice similarity value to use. This will default to 0.65, with a valid range of [0.0, 1.0].
  --voice-similarity: any # For models that support it, the voice similarity value to use. This will default to 1.0, with a valid range of [0.0, 1.0].
  --voice-style: any # For models that support it, the voice style value to use. This will default to 1.0, with a valid range of [0.0, 1.0].
  --languages: any # Languages to apply these changes to. If empty, will apply to all languages.
]: any -> record<version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/speaker/($speaker_id)")
  let body = {speaker_name: $speaker_name, voice_id: $voice_id, voice_stability: $voice_stability, voice_similarity: $voice_similarity, voice_style: $voice_style, languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create A New Speaker
#
# POST /v1/dubbing/resource/{dubbing_id}/speaker
# DEPRECATED
# operationId: create_speaker
@deprecated
export def "dubbing-resource-speaker speaker-by-dubbing_id" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --speaker-name: any # Name to attribute to this speaker.
  --voice-id: any # Either the identifier of a voice from the ElevenLabs voice library, or one of ['track-clone', 'clip-clone'].
  --voice-stability: any # For models that support it, the voice similarity value to use. This will default to 0.65, with a valid range of [0.0, 1.0].
  --voice-similarity: any # For models that support it, the voice similarity value to use. This will default to 1.0, with a valid range of [0.0, 1.0].
  --voice-style: any # For models that support it, the voice style value to use. This will default to 1.0, with a valid range of [0.0, 1.0].
]: any -> record<version: int, speaker_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/speaker")
  let body = {speaker_name: $speaker_name, voice_id: $voice_id, voice_stability: $voice_stability, voice_similarity: $voice_similarity, voice_style: $voice_style} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search The Elevenlabs Library For Voices Similar To A Speaker.
#
# GET /v1/dubbing/resource/{dubbing_id}/speaker/{speaker_id}/similar-voices
# DEPRECATED
# operationId: get_similar_voices_for_speaker
@deprecated
export def "dubbing-resource-speaker-similar-voices speaker" [
  dubbing_id: string
  speaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<voices: table<voice_id: string, name: string, category: string, description: any, preview_url: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/speaker/($speaker_id)/similar-voices")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Render Audio Or Video For The Given Language
#
# POST /v1/dubbing/resource/{dubbing_id}/render/{language}
# DEPRECATED
# operationId: render
@deprecated
export def "dubbing-resource-render render" [
  dubbing_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  render_type: string@render-type-completer
  --normalize-volume: any # Whether to normalize the volume of the rendered audio. (default: false)
]: any -> record<version: int, render_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/resource/($dubbing_id)/render/($language)")
  let body = {render_type: $render_type, normalize_volume: $normalize_volume} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Dubs
#
# GET /v1/dubbing
# operationId: list_dubs
export def "dubbing dubs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --page-size: int # How many dubs to return at maximum. Can not exceed 200, defaults to 100. (default: 100)
  --dubbing-status: string@dubbing-status-completer # What state the dub is currently in.
  --filter-by-creator: string@filter-by-creator-completer # Filters who created the resources being listed, whether it was the user running the request or someone else that shared the resource with them. (default: all)
  --order-by: string # The field to use for ordering results from this query. (default: created_at)
  --order-direction: string@order-direction-completer # The order direction to use for results from this query. (default: DESCENDING)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<dubs: table<dubbing_id: string, name: string, status: string, source_language: any, target_languages: list, editable: bool, created_at: string, media_metadata: any, error: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "dubbing_status" $dubbing_status "scalar") (serialize-qp "filter_by_creator" $filter_by_creator "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_direction" $order_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dubbing" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dub A Video Or An Audio File
#
# POST /v1/dubbing
# operationId: create_dubbing
export def "dubbing dubbing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --file: any # A list of file paths to audio recordings intended for voice cloning
  --csv-file: any # CSV file containing transcription/translation metadata
  --foreground-audio-file: any # For use only with csv input
  --background-audio-file: any # For use only with csv input
  --name: any # Name of the dubbing project.
  --source-url: any # URL of the source video/audio file.
  --source-lang: string # Source language. Expects a valid iso639-1 or iso639-3 language code. (default: auto)
  --target-lang: any # The Target language to dub the content into. Expects a valid iso639-1 or iso639-3 language code.
  --target-accent: any # [Experimental] An accent to apply when selecting voices from the library and to use to inform translation of the dialect to prefer.
  --num-speakers: int # Number of speakers to use for the dubbing. Set to 0 to automatically detect the number of speakers (default: 0)
  --watermark: oneof<nothing, bool> # Whether to apply watermark to the output video. (default: false)
  --start-time: any # Start time of the source video/audio file.
  --end-time: any # End time of the source video/audio file.
  --highest-resolution: oneof<nothing, bool> # Whether to use the highest resolution available. (default: false)
  --drop-background-audio: oneof<nothing, bool> # An advanced setting. Whether to drop background audio from the final dub. This can improve dub quality where it's known that audio shouldn't have a background track such as for speeches or monologues. (default: false)
  --use-profanity-filter: any # [BETA] Whether transcripts should have profanities censored with the words '[censored]'
  --dubbing-studio: oneof<nothing, bool> # Whether to prepare dub for edits in dubbing studio or edits as a dubbing resource. (default: false)
  --disable-voice-cloning: oneof<nothing, bool> # Instead of using a voice clone in dubbing, use a similar voice from the ElevenLabs Voice Library. Voices used from the library will contribute towards a workspace's custom voices limit, and if there aren't enough available slots the dub will fail. Using this feature requires the caller to have the 'add_voice_from_voice_library' permission on their workspace to access new voices. (default: false)
  --mode: string@mode-completer # The mode in which to run this Dubbing job. Defaults to automatic, use manual if specifically providing a CSV transcript to use. Note that manual mode is experimental and production use is strongly discouraged. (default: automatic)
  --csv-fps: any # Frames per second to use when parsing a CSV file for dubbing. If not provided, FPS will be inferred from timecodes.
]: any -> record<dubbing_id: string, expected_duration_sec: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dubbing")
  let body = {file: $file, csv_file: $csv_file, foreground_audio_file: $foreground_audio_file, background_audio_file: $background_audio_file, name: $name, source_url: $source_url, source_lang: $source_lang, target_lang: $target_lang, target_accent: $target_accent, num_speakers: $num_speakers, watermark: $watermark, start_time: $start_time, end_time: $end_time, highest_resolution: $highest_resolution, drop_background_audio: $drop_background_audio, use_profanity_filter: $use_profanity_filter, dubbing_studio: $dubbing_studio, disable_voice_cloning: $disable_voice_cloning, mode: $mode, csv_fps: $csv_fps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Dubbing
#
# GET /v1/dubbing/{dubbing_id}
# operationId: get_dubbed_metadata
export def "dubbing metadata" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<dubbing_id: string, name: string, status: string, source_language: any, target_languages: list<string>, editable: bool, created_at: string, media_metadata: any, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/($dubbing_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Dubbing
#
# DELETE /v1/dubbing/{dubbing_id}
# operationId: delete_dubbing
export def "dubbing dubbing-by-dubbing_id" [
  dubbing_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/($dubbing_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dubbed File
#
# GET /v1/dubbing/{dubbing_id}/audio/{language_code}
# operationId: get_dubbed_file
export def "dubbing-audio file" [
  dubbing_id: string
  language_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/($dubbing_id)/audio/($language_code)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "audio/mpeg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dubbed Transcript
#
# GET /v1/dubbing/{dubbing_id}/transcript/{language_code}
# DEPRECATED
# operationId: get_dubbed_transcript_file
@deprecated
export def "dubbing-transcript file" [
  dubbing_id: string
  language_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --format-type: string@format-type-completer # Format to return transcript in. For subtitles use either 'srt' or 'webvtt', and for a full transcript use 'json'. The 'json' format is not yet supported for Dubbing Studio. (default: srt)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format_type" $format_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/dubbing/($dubbing_id)/transcript/($language_code)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve A Transcript
#
# GET /v1/dubbing/{dubbing_id}/transcripts/{language_code}/format/{format_type}
# operationId: get_dubbing_transcripts
export def "dubbing-transcripts-format transcripts" [
  dubbing_id: string
  language_code: string
  format_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<transcript_format: string, srt: any, webvtt: any, json: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dubbing/($dubbing_id)/transcripts/($language_code)/format/($format_type)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Models
#
# GET /v1/models
# operationId: get_models
export def "models models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> table<model_id: string, name: string, can_be_finetuned: bool, can_do_text_to_speech: bool, can_do_voice_conversion: bool, can_use_style: bool, can_use_speaker_boost: bool, serves_pro_voices: bool, token_cost_factor: float, description: string, requires_alpha_access: bool, max_characters_request_free_user: int, max_characters_request_subscribed_user: int, maximum_text_length_per_request: int, languages: list<record>, model_rates: record<character_cost_multiplier: float, cost_discount_multiplier: float>, concurrency_group: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/models")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates Audio Native Enabled Project.
#
# POST /v1/audio-native
# operationId: create_audio_native_project
@deprecated --flag image
@deprecated --flag small
@deprecated --flag sessionization
export def "audio-native project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # Project name.
  --image: any # (Deprecated) Image URL used in the player. If not provided, default image set in the Player settings is used. (DEPRECATED)
  --author: any # Author used in the player and inserted at the start of the uploaded article. If not provided, the default author set in the Player settings is used.
  --title: any # Title used in the player and inserted at the top of the uploaded article. If not provided, the default title set in the Player settings is used.
  --small: oneof<nothing, bool> # (Deprecated) Whether to use small player or not. If not provided, default value set in the Player settings is used. (DEPRECATED, default: false)
  --text-color: any # Text color used in the player. If not provided, default text color set in the Player settings is used.
  --background-color: any # Background color used in the player. If not provided, default background color set in the Player settings is used.
  --sessionization: int # (Deprecated) Specifies for how many minutes to persist the session across page reloads. If not provided, default sessionization set in the Player settings is used. (DEPRECATED, default: 0)
  --voice-id: any # Voice ID used to voice the content. If not provided, default voice ID set in the Player settings is used.
  --model-id: any # TTS Model ID used in the player. If not provided, default model ID set in the Player settings is used.
  --file: string # Either txt or HTML input file containing the article content. HTML should be formatted as follows '&lt;html&gt;&lt;body&gt;&lt;div&gt;&lt;p&gt;Your content&lt;/p&gt;&lt;h3&gt;More of your content&lt;/h3&gt;&lt;p&gt;Some more of your content&lt;/p&gt;&lt;/div&gt;&lt;/body&gt;&lt;/html&gt;' (format: binary)
  --auto-convert: oneof<nothing, bool> # Whether to auto convert the project to audio or not. (default: false)
  --apply-text-normalization: any #      This parameter controls text normalization with four modes: 'auto', 'on', 'apply_english' and 'off'.     When set to 'auto', the system will automatically decide whether to apply text normalization     (e.g., spelling out numbers). With 'on', text normalization will always be applied, while     with 'off', it will be skipped. 'apply_english' is the same as 'on' but will assume that text is in English.     
  --pronunciation-dictionary-locators: list # A list of pronunciation dictionary locators (pronunciation_dictionary_id, version_id) encoded as a list of JSON strings for pronunciation dictionaries to be applied to the text. A list of json encoded strings is required as adding projects may occur through formData as opposed to jsonBody. To specify multiple dictionaries use multiple --form lines in your curl, such as --form 'pronunciation_dictionary_locators="{\"pronunciation_dictionary_id\":\"Vmd4Zor6fplcA7WrINey\",\"version_id\":\"hRPaxjlTdR7wFMhV4w0b\"}"' --form 'pronunciation_dictionary_locators="{\"pronunciation_dictionary_id\":\"JzWtcGQMJ6bnlWwyMo7e\",\"version_id\":\"lbmwxiLu4q6txYxgdZqn\"}"'.
]: any -> record<project_id: string, converting: bool, html_snippet: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio-native")
  let body = {name: $name, image: $image, author: $author, title: $title, small: $small, text_color: $text_color, background_color: $background_color, sessionization: $sessionization, voice_id: $voice_id, model_id: $model_id, file: $file, auto_convert: $auto_convert, apply_text_normalization: $apply_text_normalization, pronunciation_dictionary_locators: $pronunciation_dictionary_locators} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Audio Native Project Settings
#
# GET /v1/audio-native/{project_id}/settings
# operationId: get_audio_native_project_settings_endpoint
export def "audio-native-settings endpoint" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<enabled: bool, snapshot_id: any, settings: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audio-native/($project_id)/settings")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Audio-Native Project Content
#
# POST /v1/audio-native/{project_id}/content
# operationId: audio_native_project_update_content_endpoint
export def "audio-native-content endpoint" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --file: string # Either txt or HTML input file containing the article content. HTML should be formatted as follows '&lt;html&gt;&lt;body&gt;&lt;div&gt;&lt;p&gt;Your content&lt;/p&gt;&lt;h5&gt;More of your content&lt;/h5&gt;&lt;p&gt;Some more of your content&lt;/p&gt;&lt;/div&gt;&lt;/body&gt;&lt;/html&gt;' (format: binary)
  --auto-convert: oneof<nothing, bool> # Whether to auto convert the project to audio or not. (default: false)
  --auto-publish: oneof<nothing, bool> # Whether to auto publish the new project snapshot after it's converted. (default: false)
]: any -> record<project_id: string, converting: bool, publishing: bool, html_snippet: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audio-native/($project_id)/content")
  let body = {file: $file, auto_convert: $auto_convert, auto_publish: $auto_publish} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update Audio-Native Content From Url
#
# POST /v1/audio-native/content
# operationId: audio_native_update_content_from_url
export def "audio-native-content url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --body-url: string # URL of the page to extract content from.
  --author: any # Author used in the player and inserted at the start of the uploaded article. If not provided, the default author set in the Player settings is used.
  --title: any # Title used in the player and inserted at the top of the uploaded article. If not provided, the default title set in the Player settings is used.
]: any -> record<project_id: string, converting: bool, publishing: bool, html_snippet: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio-native/content")
  let body = {url: $body_url, author: $author, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Voices
#
# GET /v1/shared-voices
# operationId: get_library_voices
export def "shared-voices voices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many shared voices to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --category: string@category-completer # Voice category used for filtering
  --gender: string # Gender used for filtering
  --age: string # Age used for filtering
  --accent: string # Accent used for filtering
  --language: string # Language used for filtering
  --locale: string # Locale used for filtering
  --search: string # Search term used for filtering
  --use-cases: string # Use-case used for filtering
  --descriptives: string # Search term used for filtering
  --featured: oneof<nothing, bool> # Filter featured voices (default: false)
  --min-notice-period-days: string # Filter voices with a minimum notice period of the given number of days.
  --include-custom-rates: string # Include/exclude voices with custom rates
  --include-live-moderated: string # Include/exclude voices that are live moderated
  --reader-app-enabled: oneof<nothing, bool> # Filter voices that are enabled for the reader app (default: false)
  --owner-id: string # Filter voices by public owner ID
  --qp-sort: string # Sort criteria
  --page: int # default: 0
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<voices: table<public_owner_id: string, voice_id: string, date_unix: int, name: string, accent: string, gender: string, age: string, descriptive: string, use_case: string, category: string, language: any, locale: any, description: any, preview_url: any, usage_character_count_1y: int, usage_character_count_7d: int, play_api_usage_character_count_1y: int, cloned_by_count: int, rate: any, fiat_rate: any, free_users_allowed: bool, live_moderation_enabled: bool, featured: bool, verified_languages: any, notice_period: any, instagram_username: any, twitter_username: any, youtube_username: any, tiktok_username: any, image_url: any, is_added_by_user: any, is_bookmarked: any>, has_more: bool, total_count: int, last_sort_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "age" $age "scalar") (serialize-qp "accent" $accent "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "use_cases" $use_cases "scalar") (serialize-qp "descriptives" $descriptives "scalar") (serialize-qp "featured" $featured "scalar") (serialize-qp "min_notice_period_days" $min_notice_period_days "scalar") (serialize-qp "include_custom_rates" $include_custom_rates "scalar") (serialize-qp "include_live_moderated" $include_live_moderated "scalar") (serialize-qp "reader_app_enabled" $reader_app_enabled "scalar") (serialize-qp "owner_id" $owner_id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/shared-voices" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Similar Library Voices
#
# POST /v1/similar-voices
# operationId: get_similar_library_voices
export def "similar-voices voices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --audio-file: string # format: binary
  --similarity-threshold: any # Threshold for voice similarity between provided sample and library voices. Values range from 0 to 2. The smaller the value the more similar voices will be returned.
  --top-k: any # Number of most similar voices to return. If similarity_threshold is provided, less than this number of voices may be returned. Values range from 1 to 100.
]: any -> record<voices: table<public_owner_id: string, voice_id: string, date_unix: int, name: string, accent: string, gender: string, age: string, descriptive: string, use_case: string, category: string, language: any, locale: any, description: any, preview_url: any, usage_character_count_1y: int, usage_character_count_7d: int, play_api_usage_character_count_1y: int, cloned_by_count: int, rate: any, fiat_rate: any, free_users_allowed: bool, live_moderation_enabled: bool, featured: bool, verified_languages: any, notice_period: any, instagram_username: any, twitter_username: any, youtube_username: any, tiktok_username: any, image_url: any, is_added_by_user: any, is_bookmarked: any>, has_more: bool, total_count: int, last_sort_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/similar-voices")
  let body = {audio_file: $audio_file, similarity_threshold: $similarity_threshold, top_k: $top_k} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Characters Usage Metrics (Deprecated)
#
# GET /v1/usage/character-stats
# DEPRECATED
# operationId: usage_characters
@deprecated
export def "usage-character-stats characters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-unix: int # UTC Unix timestamp for the start of the usage window, in milliseconds. To include the first day of the window, the timestamp should be at 00:00:00 of that day.
  --end-unix: int # UTC Unix timestamp for the end of the usage window, in milliseconds. To include the last day of the window, the timestamp should be at 23:59:59 of that day.
  --include-workspace-metrics: oneof<nothing, bool> # Whether or not to include the statistics of the entire workspace. (default: false)
  --breakdown-type: string@breakdown-type-completer # How to break down the information. Cannot be "user" if include_workspace_metrics is False.
  --aggregation-interval: string@aggregation-interval-completer # How to aggregate usage data over time. Can be "hour", "day", "week", "month", or "cumulative".
  --aggregation-bucket-size: string # Aggregation bucket size in seconds. Overrides the aggregation interval.
  --metric: string@metric-completer # Which metric to aggregate.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<time: list<int>, usage: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_unix" $start_unix "scalar") (serialize-qp "end_unix" $end_unix "scalar") (serialize-qp "include_workspace_metrics" $include_workspace_metrics "scalar") (serialize-qp "breakdown_type" $breakdown_type "scalar") (serialize-qp "aggregation_interval" $aggregation_interval "scalar") (serialize-qp "aggregation_bucket_size" $aggregation_bucket_size "scalar") (serialize-qp "metric" $metric "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/usage/character-stats" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add A Pronunciation Dictionary
#
# POST /v1/pronunciation-dictionaries/add-from-file
# operationId: add_from_file
export def "pronunciation-dictionaries-add-from-file file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name of the pronunciation dictionary, used for identification only.
  --file: any # A lexicon .pls file which we will use to initialize the project with.
  --description: any # A description of the pronunciation dictionary, used for identification only.
  --workspace-access: any # Should be one of 'admin', 'editor' or 'viewer'. If not provided, defaults to no access.
]: any -> record<id: string, name: string, created_by: string, creation_time_unix: int, version_id: string, version_rules_num: int, description: any, permission_on_resource: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pronunciation-dictionaries/add-from-file")
  let body = {name: $name, file: $file, description: $description, workspace_access: $workspace_access} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Add A Pronunciation Dictionary
#
# POST /v1/pronunciation-dictionaries/add-from-rules
# operationId: add_from_rules
export def "pronunciation-dictionaries-add-from-rules rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  rules: list # List of pronunciation rules. Rule can be either:     an alias rule: {'string_to_replace': 'a', 'type': 'alias', 'alias': 'b', }     or a phoneme rule: {'string_to_replace': 'a', 'type': 'phoneme', 'phoneme': 'b', 'alphabet': 'ipa' }
  name: string # The name of the pronunciation dictionary, used for identification only.
  --description: any # A description of the pronunciation dictionary, used for identification only.
  --workspace-access: any # Should be one of 'admin', 'editor' or 'viewer'. If not provided, defaults to no access.
]: any -> record<id: string, name: string, created_by: string, creation_time_unix: int, version_id: string, version_rules_num: int, description: any, permission_on_resource: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pronunciation-dictionaries/add-from-rules")
  let body = {rules: $rules, name: $name, description: $description, workspace_access: $workspace_access} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Pronunciation Dictionary
#
# PATCH /v1/pronunciation-dictionaries/{pronunciation_dictionary_id}
# operationId: patch_pronunciation_dictionary
export def "pronunciation-dictionaries dictionary" [
  pronunciation_dictionary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --archived: oneof<nothing, bool> # Whether to archive the pronunciation dictionary.
  --name: string # The name of the pronunciation dictionary, used for identification only.
]: any -> record<id: string, latest_version_id: string, latest_version_rules_num: int, name: string, permission_on_resource: any, created_by: string, creation_time_unix: int, archived_time_unix: any, description: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pronunciation-dictionaries/($pronunciation_dictionary_id)")
  let body = {archived: $archived, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Metadata For A Pronunciation Dictionary
#
# GET /v1/pronunciation-dictionaries/{pronunciation_dictionary_id}
# operationId: get_pronunciation_dictionary_metadata
export def "pronunciation-dictionaries metadata" [
  pronunciation_dictionary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, latest_version_id: string, latest_version_rules_num: int, name: string, permission_on_resource: any, created_by: string, creation_time_unix: int, archived_time_unix: any, description: any, rules: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pronunciation-dictionaries/($pronunciation_dictionary_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Rules On The Pronunciation Dictionary
#
# POST /v1/pronunciation-dictionaries/{pronunciation_dictionary_id}/set-rules
# operationId: set_rules
export def "pronunciation-dictionaries-set-rules rules" [
  pronunciation_dictionary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  rules: list # List of pronunciation rules. Rule can be either:     an alias rule: {'string_to_replace': 'a', 'type': 'alias', 'alias': 'b', }     or a phoneme rule: {'string_to_replace': 'a', 'type': 'phoneme', 'phoneme': 'b', 'alphabet': 'ipa' }
]: any -> record<id: string, version_id: string, version_rules_num: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pronunciation-dictionaries/($pronunciation_dictionary_id)/set-rules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Rules To The Pronunciation Dictionary
#
# POST /v1/pronunciation-dictionaries/{pronunciation_dictionary_id}/add-rules
# operationId: add_rules
export def "pronunciation-dictionaries-add-rules rules" [
  pronunciation_dictionary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  rules: list # List of pronunciation rules. Rule can be either:     an alias rule: {'string_to_replace': 'a', 'type': 'alias', 'alias': 'b', }     or a phoneme rule: {'string_to_replace': 'a', 'type': 'phoneme', 'phoneme': 'b', 'alphabet': 'ipa' }
]: any -> record<id: string, version_id: string, version_rules_num: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pronunciation-dictionaries/($pronunciation_dictionary_id)/add-rules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Rules From The Pronunciation Dictionary
#
# POST /v1/pronunciation-dictionaries/{pronunciation_dictionary_id}/remove-rules
# operationId: remove_rules
export def "pronunciation-dictionaries-remove-rules rules" [
  pronunciation_dictionary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  rule_strings: list # List of strings to remove from the pronunciation dictionary.
]: any -> record<id: string, version_id: string, version_rules_num: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pronunciation-dictionaries/($pronunciation_dictionary_id)/remove-rules")
  let body = {rule_strings: $rule_strings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get A Pls File With A Pronunciation Dictionary Version Rules
#
# GET /v1/pronunciation-dictionaries/{dictionary_id}/{version_id}/download
# operationId: get_pronunciation_dictionary_version_pls
export def "pronunciation-dictionaries-download pls" [
  dictionary_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/pronunciation-dictionaries/($dictionary_id)/($version_id)/download")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pronunciation Dictionaries
#
# GET /v1/pronunciation-dictionaries
# operationId: get_pronunciation_dictionaries_metadata
export def "pronunciation-dictionaries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --page-size: int # How many pronunciation dictionaries to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --qp-sort: string # Which field to sort by, one of 'created_at_unix' or 'name'. (default: creation_time_unix)
  --sort-direction: string # Which direction to sort the voices in. 'ascending' or 'descending'. (default: DESCENDING)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<pronunciation_dictionaries: table<id: string, latest_version_id: string, latest_version_rules_num: int, name: string, permission_on_resource: any, created_by: string, creation_time_unix: int, archived_time_unix: any, description: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/pronunciation-dictionaries" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Api Key
#
# POST /v1/workspaces/api-keys/disable
# operationId: disable
export def "workspaces-api-keys-disable disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-key-name: string # Must be set to `self` to disable the API key used to authenticate this request. Required as an explicit confirmation to avoid accidentally disabling the wrong key.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key_name" $api_key_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workspaces/api-keys/disable" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Service Account Api Keys Route
#
# GET /v1/service-accounts/{service_account_user_id}/api-keys
# operationId: get_service_account_api_keys_route
export def "service-accounts-api-keys route" [
  service_account_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<api_keys: table<name: string, hint: string, key_id: string, service_account_user_id: string, created_at_unix: any, is_disabled: bool, permissions: any, character_limit: any, character_count: any, hashed_xi_api_key: string, allowed_ips: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service-accounts/($service_account_user_id)/api-keys")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Service Account Api Key
#
# POST /v1/service-accounts/{service_account_user_id}/api-keys
# operationId: create_service_account_api_key
export def "service-accounts-api-keys key-by-service_account_user_id" [
  service_account_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string
  permissions: any # The permissions of the XI API.
  --character-limit: any # The character limit of the XI API key. If provided this will limit the usage of this api key to n characters per month where n is the chosen value. Requests that incur charges will fail after reaching this monthly limit.
  --allowed-ips: any # List of IP addresses or CIDR ranges allowed to use this API key. Each entry may be a CIDR range (e.g. '10.0.0.0/24') or a bare IP address (normalized to /32 or /128). On create, omit or pass null to allow all IPs. On update, omit to leave the whitelist unchanged, or pass "clear" to remove it.
]: any -> record<xi_api_key: string, key_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service-accounts/($service_account_user_id)/api-keys")
  let body = {name: $name, permissions: $permissions, character_limit: $character_limit, allowed_ips: $allowed_ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit Service Account Api Key
#
# PATCH /v1/service-accounts/{service_account_user_id}/api-keys/{api_key_id}
# operationId: edit_service_account_api_key
export def "service-accounts-api-keys key-by-service_account_user_id-api_key_id" [
  service_account_user_id: string
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --is-enabled: any # Whether to enable or disable the API key. (default: no_update)
  --name: any # The name of the XI API key to use (used for identification purposes only).
  --permissions: any # The permissions of the XI API. (default: no_update)
  --character-limit: any # The character limit of the XI API key. If provided this will limit the usage of this api key to n characters per month where n is the chosen value. Requests that incur charges will fail after reaching this monthly limit. (default: no_update)
  --allowed-ips: any # List of IP addresses or CIDR ranges allowed to use this API key. Each entry may be a CIDR range (e.g. '10.0.0.0/24') or a bare IP address (normalized to /32 or /128). On create, omit or pass null to allow all IPs. On update, omit to leave the whitelist unchanged, or pass "clear" to remove it. (default: no_update)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service-accounts/($service_account_user_id)/api-keys/($api_key_id)")
  let body = {is_enabled: $is_enabled, name: $name, permissions: $permissions, character_limit: $character_limit, allowed_ips: $allowed_ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Service Account Api Key
#
# DELETE /v1/service-accounts/{service_account_user_id}/api-keys/{api_key_id}
# operationId: delete_service_account_api_key
export def "service-accounts-api-keys key-by-service_account_user_id-api_key_id-1" [
  service_account_user_id: string
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/service-accounts/($service_account_user_id)/api-keys/($api_key_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Workspace Audit Logs
#
# GET /v1/workspace/audit-logs
# operationId: get_workspace_audit_logs
export def "workspace-audit-logs logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of entries per page (default: 50)
  --cursor: string # Cursor for the next page (from previous response)
  --time-from-unix-ms: string # Only include entries at or after this time (ms since epoch)
  --time-to-unix-ms: string # Only include entries at or before this time (ms since epoch)
  --actor-uid: string # Filter by actor user ID
  --class-name: string # Filter by OCSF event class name (e.g. Account Change)
  --activity-name: string # Filter by audit activity name (e.g. Subscription Creation)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<entries: table<metadata: record, time: int, activity_id: any, activity_name: string, category_name: string, category_uid: int, class_name: string, class_uid: int, severity_id: int, status_id: int, actor: record, device: any, http_request: any, message: string, unmapped: record, id: string, time_dt: string, type_uid: int, type_name: string>, has_more: bool, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "time_from_unix_ms" $time_from_unix_ms "scalar") (serialize-qp "time_to_unix_ms" $time_to_unix_ms "scalar") (serialize-qp "actor_uid" $actor_uid "scalar") (serialize-qp "class_name" $class_name "scalar") (serialize-qp "activity_name" $activity_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workspace/audit-logs" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Workspace Auth Connection
#
# POST /v1/workspace/auth-connections
# Discriminator (response): auth_type = oauth2_client_credentials, basic_auth, bearer_auth, oauth2_jwt, private_key_jwt, mtls, custom_header_auth, api_integration_oauth2_auth_code, api_integration_oauth2_custom_app, whatsapp_auth, slack_bot_auth, url_secret
# operationId: create_auth_connection
export def "workspace-auth-connections connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: string
  --auth-type: string # default: oauth2_client_credentials
  --provider: string
  --client-id: string
  --token-url: string
  --scopes: list # default: []
  --extra-params: record # default: {}
  --basic-auth-in-header: oneof<nothing, bool> # If True, send client credentials in Authorization header as Basic Auth instead of request body (default: false)
  --client-secret: string
  --custom-headers: record # default: {}
  --header-name: string # The name of the header to use for authentication (e.g., 'x-api-key')
  --body-token: string
  --username: string
  --password: string
  --algorithm: string@algorithm-completer # JWT signing algorithm (default: HS256)
  --key-id: any # Key ID (kid) for JWT header - useful for key rotation
  --issuer: string # JWT issuer (iss claim)
  --audience: string # JWT audience (aud claim)
  --subject: string # JWT subject (sub claim)
  --expiration-seconds: int # Token expiration time in seconds (default: 3600)
  --token-response-field: string@token-response-field-completer # Token field to extract from the token endpoint response. (default: access_token)
  --secret-key: string
  --client-certificate: string
  --client-key: string
  --ca-certificate: any
  --key-passphrase: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/auth-connections")
  let body = {name: $name, auth_type: $auth_type, provider: $provider, client_id: $client_id, token_url: $token_url, scopes: $scopes, extra_params: $extra_params, basic_auth_in_header: $basic_auth_in_header, client_secret: $client_secret, custom_headers: $custom_headers, header_name: $header_name, token: $body_token, username: $username, password: $password, algorithm: $algorithm, key_id: $key_id, issuer: $issuer, audience: $audience, subject: $subject, expiration_seconds: $expiration_seconds, token_response_field: $token_response_field, secret_key: $secret_key, client_certificate: $client_certificate, client_key: $client_key, ca_certificate: $ca_certificate, key_passphrase: $key_passphrase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Workspace Auth Connections
#
# GET /v1/workspace/auth-connections
# operationId: list_auth_connections
export def "workspace-auth-connections connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<auth_connections: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/auth-connections")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Workspace Auth Connection
#
# PATCH /v1/workspace/auth-connections/{auth_connection_id}
# Discriminator (response): auth_type = oauth2_client_credentials, basic_auth, bearer_auth, oauth2_jwt, private_key_jwt, mtls, custom_header_auth, api_integration_oauth2_auth_code, api_integration_oauth2_custom_app, whatsapp_auth, slack_bot_auth, url_secret
# operationId: update_auth_connection
export def "workspace-auth-connections connection-by-auth_connection_id" [
  auth_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --auth-type: string # default: oauth2_client_credentials
  --provider: any
  --client-id: any
  --scopes: any
  --extra-params: any
  --basic-auth-in-header: any
  --client-secret: any
  --custom-headers: any
  --username: any
  --password: any
  --algorithm: any
  --key-id: any
  --issuer: any
  --audience: any
  --subject: any
  --expiration-seconds: any
  --token-response-field: any
  --secret-key: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/auth-connections/($auth_connection_id)")
  let body = {auth_type: $auth_type, provider: $provider, client_id: $client_id, scopes: $scopes, extra_params: $extra_params, basic_auth_in_header: $basic_auth_in_header, client_secret: $client_secret, custom_headers: $custom_headers, username: $username, password: $password, algorithm: $algorithm, key_id: $key_id, issuer: $issuer, audience: $audience, subject: $subject, expiration_seconds: $expiration_seconds, token_response_field: $token_response_field, secret_key: $secret_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Workspace Auth Connection
#
# DELETE /v1/workspace/auth-connections/{auth_connection_id}
# operationId: delete_auth_connection
export def "workspace-auth-connections connection-by-auth_connection_id-1" [
  auth_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/auth-connections/($auth_connection_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Workspace Service Accounts
#
# GET /v1/service-accounts
# operationId: get_workspace_service_accounts
export def "service-accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<service_accounts: table<service_account_user_id: string, name: string, created_at_unix: any, api_keys: list, default_sharing_groups: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/service-accounts")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Groups
#
# GET /v1/workspace/groups
# operationId: get_groups_endpoint
export def "workspace-groups endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/groups")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search User Groups
#
# GET /v1/workspace/groups/search
# operationId: search_groups
export def "workspace-groups-search groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the target group.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> table<name: string, id: string, members_emails: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workspace/groups/search" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Member From User Group
#
# POST /v1/workspace/groups/{group_id}/members/remove
# operationId: remove_member
export def "workspace-groups-members-remove member" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  email: string # The email of the target workspace member.
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/groups/($group_id)/members/remove")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Member To User Group
#
# POST /v1/workspace/groups/{group_id}/members
# operationId: add_member
export def "workspace-groups-members member" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  email: string # The email of the target workspace member.
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/groups/($group_id)/members")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invite User
#
# POST /v1/workspace/invites/add
# operationId: invite_user
@deprecated --flag workspace-permission
export def "workspace-invites-add user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  email: string # The email of the customer
  --workspace-permission: any # The workspace permission of the user. This is deprecated, use `seat_type` instead. (DEPRECATED)
  --seat-type: any # The seat type of the user
  --group-ids: any # The group ids of the user
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/invites/add")
  let body = {email: $email, workspace_permission: $workspace_permission, seat_type: $seat_type, group_ids: $group_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invite Multiple Users
#
# POST /v1/workspace/invites/add-bulk
# operationId: invite_users_bulk
export def "workspace-invites-add-bulk bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  emails: list # The email of the customer
  --seat-type: any # The seat type of the user
  --group-ids: any # The group ids of the user
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/invites/add-bulk")
  let body = {emails: $emails, seat_type: $seat_type, group_ids: $group_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Existing Invitation
#
# DELETE /v1/workspace/invites
# operationId: delete_invite
export def "workspace-invites invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  email: string # The email of the customer
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/invites")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Member
#
# POST /v1/workspace/members
# operationId: update_workspace_member
@deprecated --flag workspace-role
export def "workspace-members member" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  email: string # Email of the target user.
  --is-locked: any # Whether to lock or unlock the user account.
  --workspace-role: any # The workspace role of the user. This is deprecated, use `workspace_seat_type` instead. (DEPRECATED)
  --workspace-seat-type: any # The workspace seat type
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/members")
  let body = {email: $email, is_locked: $is_locked, workspace_role: $workspace_role, workspace_seat_type: $workspace_seat_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Resource
#
# GET /v1/workspace/resources/{resource_id}
# operationId: get_resource_metadata
export def "workspace-resources metadata" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resource-type: string@resource-type-completer # Resource type of the target resource.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<resource_id: string, resource_name: any, resource_type: string, creator_user_id: any, anonymous_access_level_override: any, role_to_group_ids: record, share_options: table<name: string, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workspace/resources/($resource_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Share Workspace Resource
#
# POST /v1/workspace/resources/{resource_id}/share
# operationId: share_resource_endpoint
export def "workspace-resources-share endpoint" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  role: string@role-completer # Role to grant to the target: one of 'admin', 'editor', 'commenter', or 'viewer'.
  resource_type: string@resource-type-completer # Resource types that can be shared in the workspace. The name always need to match the collection names
  --user-email: any # The email of the user or service account.
  --group-id: any # The ID of the target group. Use 'default' to set the resource's baseline role — every workspace member receives this role unless they hold a higher one through a direct user grant, group membership, or workspace (service account) API key.
  --workspace-api-key-id: any # The ID of the target workspace (service account) API key. This is not the API key string itself that you pass in the header for authentication — it is the key's ID, which workspace admins can find under Developers → Service Accounts.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/resources/($resource_id)/share")
  let body = {role: $role, resource_type: $resource_type, user_email: $user_email, group_id: $group_id, workspace_api_key_id: $workspace_api_key_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unshare Workspace Resource
#
# POST /v1/workspace/resources/{resource_id}/unshare
# operationId: unshare_resource_endpoint
export def "workspace-resources-unshare endpoint" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  resource_type: string@resource-type-completer # Resource types that can be shared in the workspace. The name always need to match the collection names
  --user-email: any # The email of the user or service account.
  --group-id: any # The ID of the target group. Use 'default' to set the resource's baseline role — every workspace member receives this role unless they hold a higher one through a direct user grant, group membership, or workspace (service account) API key.
  --workspace-api-key-id: any # The ID of the target workspace (service account) API key. This is not the API key string itself that you pass in the header for authentication — it is the key's ID, which workspace admins can find under Developers → Service Accounts.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/resources/($resource_id)/unshare")
  let body = {resource_type: $resource_type, user_email: $user_email, group_id: $group_id, workspace_api_key_id: $workspace_api_key_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Workspace Webhooks
#
# GET /v1/workspace/webhooks
# operationId: get_workspace_webhooks_route
export def "workspace-webhooks route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-usages: oneof<nothing, bool> # Whether to include active usages of the webhook, only usable by admins (default: false)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<webhooks: table<name: string, webhook_id: string, webhook_url: string, is_disabled: bool, is_auto_disabled: bool, created_at_unix: int, auth_type: string, usage: any, most_recent_failure_error_code: any, most_recent_failure_timestamp: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_usages" $include_usages "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workspace/webhooks" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Workspace Webhook
#
# POST /v1/workspace/webhooks
# operationId: create_workspace_webhook_route
# --settings shape: {auth_type: string, name: string, webhook_url: string, request_headers?: any}
export def "workspace-webhooks route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  settings: record # Settings for creating an HMAC-authenticated webhook — shape: {auth_type: string, name: string, webhook_url: string, request_headers?: any}
]: any -> record<webhook_id: string, webhook_secret: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/webhooks")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Workspace Webhook
#
# PATCH /v1/workspace/webhooks/{webhook_id}
# operationId: edit_workspace_webhook_route
export def "workspace-webhooks route-by-webhook_id" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --is-disabled: oneof<nothing, bool> # Whether to disable or enable the webhook
  name: string # The display name of the webhook (used for display purposes only).
  --retry-enabled: any # Whether to enable automatic retries for transient failures (5xx, 429, timeout)
  --request-headers: any # A list of request headers to include with the webhook delivery (optional)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/webhooks/($webhook_id)")
  let body = {is_disabled: $is_disabled, name: $name, retry_enabled: $retry_enabled, request_headers: $request_headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Workspace Webhook
#
# DELETE /v1/workspace/webhooks/{webhook_id}
# operationId: delete_workspace_webhook_route
export def "workspace-webhooks route-by-webhook_id-1" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workspace/webhooks/($webhook_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Speech To Text
#
# POST /v1/speech-to-text
# operationId: speech_to_text
@deprecated --flag cloud-storage-url
export def "speech-to-text text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-logging: oneof<nothing, bool> # When enable_logging is set to false zero retention mode will be used for the request. This will mean log and transcript storage features are unavailable for this request. Zero retention mode may only be used by enterprise customers. (default: true)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  model_id: string@model-id-completer-2 # The ID of the model to use for transcription.
  --file: any # The file to transcribe (100ms minimum audio length). All major audio and video formats are supported. Exactly one of the file or cloud_storage_url parameters must be provided. The file size must be less than 5.0GB.
  --language-code: any # An ISO-639-1 or ISO-639-3 language_code corresponding to the language of the audio file. Can sometimes improve transcription performance if known beforehand. Defaults to null, in this case the language is predicted automatically.
  --tag-audio-events: oneof<nothing, bool> # Whether to tag audio events like (laughter), (footsteps), etc. in the transcription. (default: true)
  --num-speakers: any # The maximum amount of speakers talking in the uploaded file. Can help with predicting who speaks when. The maximum amount of speakers that can be predicted is 32. Defaults to null, in this case the amount of speakers is set to the maximum value the model supports.
  --timestamps-granularity: string@timestamps-granularity-completer # The granularity of the timestamps in the transcription. 'word' provides word-level timestamps and 'character' provides character-level timestamps per word. (default: word)
  --diarize: oneof<nothing, bool> # Whether to annotate which speaker is currently talking in the uploaded file. (default: false)
  --diarization-threshold: any # Diarization threshold to apply during speaker diarization. A higher value means there will be a lower chance of one speaker being diarized as two different speakers but also a higher chance of two different speakers being diarized as one speaker (less total speakers predicted). A low value means there will be a higher chance of one speaker being diarized as two different speakers but also a lower chance of two different speakers being diarized as one speaker (more total speakers predicted). Can only be set when diarize=True and num_speakers=None. Defaults to None, in which case we will choose a threshold based on the model_id (0.22 usually).
  --additional-formats: list
  --file-format: string@file-format-completer # The format of input audio. Options are 'pcm_s16le_16' or 'other' For `pcm_s16le_16`, the input audio must be 16-bit PCM at a 16kHz sample rate, single channel (mono), and little-endian byte order. Latency will be lower than with passing an encoded waveform. (default: other)
  --cloud-storage-url: any # [Deprecated] This parameter is deprecated and will be removed in the future. Use 'source_url' instead.The HTTPS URL of the file to transcribe. Exactly one of the file or cloud_storage_url parameters must be provided. The file must be accessible via HTTPS and the file size must be less than 2GB. Any valid HTTPS URL is accepted, including URLs from cloud storage providers (AWS S3, Google Cloud Storage, Cloudflare R2, etc.), CDNs, or any other HTTPS source. URLs can be pre-signed or include authentication tokens in query parameters. (DEPRECATED)
  --source-url: any # The URL of an audio or video file to transcribe. Supports hosted video or audio files, YouTube video URLs, TikTok video URLs, and other video hosting services.
  --webhook: oneof<nothing, bool> # Whether to send the transcription result to configured speech-to-text webhooks.  If set the request will return early without the transcription, which will be delivered later via webhook. (default: false)
  --webhook-id: any # Optional specific webhook ID to send the transcription result to. Only valid when webhook is set to true. If not provided, transcription will be sent to all configured speech-to-text webhooks.
  --temperature: any # Controls the randomness of the transcription output. Accepts values between 0.0 and 2.0, where higher values result in more diverse and less deterministic results. If omitted, we will use a temperature based on the model you selected which is usually 0.
  --seed: any # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed. Must be an integer between 0 and 2147483647.
  --use-multi-channel: oneof<nothing, bool> # Whether the audio file contains multiple channels where each channel contains a single speaker. When enabled, each channel will be transcribed independently and the results will be combined. Each word in the response will include a 'channel_index' field indicating which channel it was spoken on. A maximum of 5 channels is supported. Each channel is billed independently at the full audio duration, so cost scales linearly with the number of channels. (default: false)
  --webhook-metadata: any # Optional metadata to be included in the webhook response. This should be a JSON string representing an object with a maximum depth of 2 levels and maximum size of 16KB. Useful for tracking internal IDs, job references, or other contextual information.
  --entity-detection: any # Detect entities in the transcript. Can be 'all' to detect all entities, a single entity type or category string, or a list of entity types/categories. Categories include 'pii', 'phi', 'pci', 'other', 'offensive_language'. When enabled, detected entities will be returned in the 'entities' field with their text, type, and character positions. Usage of this parameter will incur an additional 30% surcharge on the base transcription cost.
  --no-verbatim: oneof<nothing, bool> # If true, the transcription will not have any filler words, false starts and non-speech sounds. Only supported with scribe_v2 model. (default: false)
  --detect-speaker-roles: oneof<nothing, bool> # Whether to detect speaker roles (agent vs customer). Requires diarize=true. Cannot be used with use_multi_channel=true. When enabled, speaker_id values will be 'agent' and 'customer' instead of 'speaker_0', 'speaker_1', etc. Usage incurs an additional 10% surcharge on base transcription cost. (default: false)
  --entity-redaction: any # Redact entities from the transcript text. Accepts the same format as entity_detection: 'all', a category ('pii', 'phi'), or specific entity types. Must be a subset of entity_detection. When redaction is enabled, the entities field will not be returned. Usage of this parameter will incur an additional 30% surcharge on the base transcription cost.
  --entity-redaction-mode: string # How to format redacted entities. 'redacted' replaces with {REDACTED}, 'entity_type' replaces with {ENTITY_TYPE}, 'enumerated_entity_type' replaces with {ENTITY_TYPE_N} where N enumerates each occurrence. Only used when entity_redaction is set. (default: enumerated_entity_type)
  --keyterms: list # A list of keyterms to bias the transcription towards.           The keyterms are words or phrases you want the model to recognise more accurately.           The number of keyterms cannot exceed 1000.           The length of each keyterm must be less than 50 characters.           Keyterms can contain at most 5 words (after normalisation).           For example ["hello", "world", "technical term"].           The following characters are not supported: `<`, `>`, `{`, `}`, `[`, `]`, `\`.           Usage of this parameter will incur an additional 20% surcharge on the base transcription cost.           When more than 100 keyterms are provided, a minimum billable duration of 20 seconds applies per request. (default: [])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_logging" $enable_logging "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/speech-to-text" $qp)
  let body = {model_id: $model_id, file: $file, language_code: $language_code, tag_audio_events: $tag_audio_events, num_speakers: $num_speakers, timestamps_granularity: $timestamps_granularity, diarize: $diarize, diarization_threshold: $diarization_threshold, additional_formats: $additional_formats, file_format: $file_format, cloud_storage_url: $cloud_storage_url, source_url: $source_url, webhook: $webhook, webhook_id: $webhook_id, temperature: $temperature, seed: $seed, use_multi_channel: $use_multi_channel, webhook_metadata: $webhook_metadata, entity_detection: $entity_detection, no_verbatim: $no_verbatim, detect_speaker_roles: $detect_speaker_roles, entity_redaction: $entity_redaction, entity_redaction_mode: $entity_redaction_mode, keyterms: $keyterms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Transcript By Id
#
# GET /v1/speech-to-text/transcripts/{transcription_id}
# operationId: get_transcript_by_id
export def "speech-to-text-transcripts id-by-transcription_id" [
  transcription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/speech-to-text/transcripts/($transcription_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Transcript By Id
#
# DELETE /v1/speech-to-text/transcripts/{transcription_id}
# operationId: delete_transcript_by_id
export def "speech-to-text-transcripts id-by-transcription_id-1" [
  transcription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/speech-to-text/transcripts/($transcription_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Single Use Token
#
# POST /v1/single-use-token/{token_type}
# operationId: get_single_use_token
export def "single-use-token token" [
  token_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/single-use-token/($token_type)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Forced Alignment
#
# POST /v1/forced-alignment
# operationId: forced_alignment
export def "forced-alignment alignment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  file: string # The file to align. All major audio formats are supported. The file size must be less than 1GB. (format: binary)
  text: string # The text to align with the audio. The input text can be in any format, however diarization is not supported at this time.
]: any -> record<characters: table<text: string, start: float, end: float>, words: table<text: string, start: float, end: float, loss: float>, loss: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/forced-alignment")
  let body = {file: $file, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Signed Url
#
# GET /v1/convai/conversation/get-signed-url
# operationId: get_conversation_signed_link
export def "convai-conversation-get-signed-url link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # Agent id (agent_…) or speech engine external id (seng_), resolved to the same underlying resource.
  --include-conversation-id: oneof<nothing, bool> # Whether to include a conversation_id with the response. If included, the conversation_signature cannot be used again. (default: false)
  --branch-id: string # The ID of the branch to use
  --environment: string # The environment to use for resolving environment variables (e.g. 'production', 'staging'). Defaults to 'production'.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<signed_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "include_conversation_id" $include_conversation_id "scalar") (serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/conversation/get-signed-url" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Signed Url
#
# GET /v1/convai/conversation/get_signed_url
# DEPRECATED
# operationId: get_signed_url_deprecated
@deprecated
export def "convai-conversation-get-signed-url deprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # Agent id (agent_…) or speech engine external id (seng_), resolved to the same underlying resource.
  --include-conversation-id: oneof<nothing, bool> # Whether to include a conversation_id with the response. If included, the conversation_signature cannot be used again. (default: false)
  --branch-id: string # The ID of the branch to use
  --environment: string # The environment to use for resolving environment variables (e.g. 'production', 'staging'). Defaults to 'production'.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<signed_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "include_conversation_id" $include_conversation_id "scalar") (serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/conversation/get_signed_url" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webrtc Token
#
# GET /v1/convai/conversation/token
# operationId: get_livekit_token
export def "convai-conversation-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # Agent id (agent_…) or speech engine external id (seng_), resolved to the same underlying resource.
  --participant-name: string # Optional custom participant name. If not provided, user ID will be used
  --branch-id: string # The ID of the branch to use
  --environment: string # The environment to use for resolving environment variables (e.g. 'production', 'staging'). Defaults to 'production'.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "participant_name" $participant_name "scalar") (serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "environment" $environment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/conversation/token" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Handle An Outbound Call Via Twilio
#
# POST /v1/convai/twilio/outbound-call
# operationId: handle_twilio_outbound_call
# --telephony_call_config shape: {ringing_timeout_secs?: int}
export def "convai-twilio-outbound-call call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  agent_id: string
  agent_phone_number_id: string
  to_number: string
  --conversation-initiation-client-data: any
  --call-recording-enabled: any # Whether let Twilio record the call.
  --telephony-call-config: record # shape: {ringing_timeout_secs?: int}
]: any -> record<success: bool, message: string, conversation_id: any, callSid: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/twilio/outbound-call")
  let body = {agent_id: $agent_id, agent_phone_number_id: $agent_phone_number_id, to_number: $to_number, conversation_initiation_client_data: $conversation_initiation_client_data, call_recording_enabled: $call_recording_enabled, telephony_call_config: $telephony_call_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register A Twilio Call And Return Twiml
#
# POST /v1/convai/twilio/register-call
# operationId: register_twilio_call
export def "convai-twilio-register-call call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  agent_id: string
  from_number: string
  to_number: string
  --direction: string@direction-completer # default: inbound
  --conversation-initiation-client-data: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/twilio/register-call")
  let body = {agent_id: $agent_id, from_number: $from_number, to_number: $to_number, direction: $direction, conversation_initiation_client_data: $conversation_initiation_client_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Handle An Outbound Call Via Exotel
#
# POST /v1/convai/exotel/outbound-call
# operationId: handle_exotel_outbound_call
# --telephony_call_config shape: {ringing_timeout_secs?: int}
export def "convai-exotel-outbound-call call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  agent_id: string
  agent_phone_number_id: string
  to_number: string
  --conversation-initiation-client-data: any
  --telephony-call-config: record # shape: {ringing_timeout_secs?: int}
]: any -> record<success: bool, message: string, conversation_id: any, callSid: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/exotel/outbound-call")
  let body = {agent_id: $agent_id, agent_phone_number_id: $agent_phone_number_id, to_number: $to_number, conversation_initiation_client_data: $conversation_initiation_client_data, telephony_call_config: $telephony_call_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Make An Outbound Call Via Whatsapp
#
# POST /v1/convai/whatsapp/outbound-call
# operationId: whatsapp_outbound_call
export def "convai-whatsapp-outbound-call call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  whatsapp_phone_number_id: string
  whatsapp_user_id: string
  whatsapp_call_permission_request_template_name: string
  whatsapp_call_permission_request_template_language_code: string
  agent_id: string
  --conversation-initiation-client-data: any
]: any -> record<success: bool, message: string, conversation_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/whatsapp/outbound-call")
  let body = {whatsapp_phone_number_id: $whatsapp_phone_number_id, whatsapp_user_id: $whatsapp_user_id, whatsapp_call_permission_request_template_name: $whatsapp_call_permission_request_template_name, whatsapp_call_permission_request_template_language_code: $whatsapp_call_permission_request_template_language_code, agent_id: $agent_id, conversation_initiation_client_data: $conversation_initiation_client_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send An Outbound Message Via Whatsapp
#
# POST /v1/convai/whatsapp/outbound-message
# operationId: whatsapp_outbound_message
export def "convai-whatsapp-outbound-message message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  whatsapp_phone_number_id: string
  whatsapp_user_id: string
  template_name: string
  template_language_code: string
  template_params: list
  agent_id: string
  --conversation-initiation-client-data: any
]: any -> record<conversation_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/whatsapp/outbound-message")
  let body = {whatsapp_phone_number_id: $whatsapp_phone_number_id, whatsapp_user_id: $whatsapp_user_id, template_name: $template_name, template_language_code: $template_language_code, template_params: $template_params, agent_id: $agent_id, conversation_initiation_client_data: $conversation_initiation_client_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Agent
#
# POST /v1/convai/agents/create
# operationId: create_agent_route
# --conversation_config shape: {asr?: record, turn?: record, tts?: record, conversation?: record, language_presets?: record, vad?: record, agent?: record}
# --workflow shape: {edges?: record, nodes?: record, prevent_subagent_loops?: bool}
@deprecated --flag enable-versioning
export def "convai-agents-create route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-versioning: oneof<nothing, bool> # Deprecated: all agents are versioned. This parameter is ignored. (DEPRECATED, default: true)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  conversation_config: record # shape: {asr?: record, turn?: record, tts?: record, conversation?: record, language_presets?: record, vad?: record, agent?: record}
  --platform-settings: any # Platform settings for the agent are all settings that aren't related to the conversation orchestration and content.
  --workflow: record # e.g. {edges: {entry_to_tool_a: {forward_condition: {condition: Tool A condition}, source: entry_node, target: tool_node_a}, start_to_entry: {forward_condition: {}, source: start_node, target: entry_node}, tool_a_to_failure: {forward_condition: {successful: false}, source: tool_node_a, target: failure_node}, tool_a_to_tool_b: {forward_condition: {successful: true}, source: tool_node_a, target: tool_node_b}, tool_b_to_agent_transfer: {forward_condition: {}, source: tool_node_b, target: success_transfer}, tool_b_to_conversation: {forward_condition: {condition: Conversation condition}, source: tool_node_b, target: success_conversation}, tool_b_to_end: {forward_condition: {condition: End condition}, source: tool_node_b, target: success_end}, tool_b_to_phone: {forward_condition: {expression: {children: [{name: force_phone_transfer}, {prompt: Phone condition, value_schema: {description: Phone condition, type: boolean}}, {left: {name: mode}, right: {value: dev}}]}}, source: tool_node_b, target: success_phone}}, nodes: {entry_node: {conversation_config: {}, edge_order: [entry_to_tool_a], label: Entry}, failure_node: {conversation_config: {}, label: Failure}, start_node: {edge_order: [start_to_entry]}, success_conversation: {conversation_config: {}, label: Success A}, success_end: {}, success_phone: {transfer_destination: {phone_number: +1234567890}}, success_transfer: {agent_id: success_transfer_agent}, tool_node_a: {edge_order: [tool_a_to_failure, tool_a_to_tool_b], tools: [{tool_id: tool_a}, {tool_id: tool_b}]}, tool_node_b: {edge_order: [tool_b_to_conversation, tool_b_to_end, tool_b_to_phone, tool_b_to_agent_transfer], tools: [{tool_id: tool_a}]}}} — shape: {edges?: record, nodes?: record, prevent_subagent_loops?: bool}
  --name: any # A name to make the agent easier to find
  --tags: any # Tags to help classify and filter the agent
]: any -> record<agent_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_versioning" $enable_versioning "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/agents/create" $qp)
  let body = {conversation_config: $conversation_config, platform_settings: $platform_settings, workflow: $workflow, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Agent Summaries
#
# GET /v1/convai/agents/summaries
# operationId: get_agent_summaries_route
export def "convai-agents-summaries route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-ids: list # List of agent IDs to fetch summaries for
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_ids" $agent_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/agents/summaries" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Agent
#
# GET /v1/convai/agents/{agent_id}
# operationId: get_agent_route
export def "convai-agents route-by-agent_id" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version-id: string # The ID of the agent version to use
  --branch-id: string # The ID of the branch to use
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agent_id: string, name: string, conversation_config: record<asr: record<quality: string, provider: string, user_input_audio_format: string, keywords: list>, turn: record<turn_timeout: float, initial_wait_time: any, silence_end_call_timeout: float, mode: string, turn_eagerness: string, spelling_patience: string, speculative_turn: bool, retranscribe_on_turn_timeout: bool, turn_model: string, soft_timeout_config: record>, tts: record<model_id: string, voice_id: string, supported_voices: list, expressive_mode: bool, suggested_audio_tags: list, agent_output_audio_format: string, optimize_streaming_latency: int, stability: float, speed: float, similarity_boost: float, text_normalisation_type: string, pronunciation_dictionary_locators: list>, conversation: record<text_only: bool, max_duration_seconds: int, client_events: list, file_input: record, monitoring_enabled: bool, monitoring_events: list, source_attribution: bool>, language_presets: record, vad: record<background_voice_detection: bool>, agent: record<first_message: string, language: string, hinglish_mode: bool, dynamic_variables: record, disable_first_message_interruptions: bool, max_conversation_duration_message: string, text_behavior_overrides: any, prompt: record>>, metadata: record<created_at_unix_secs: int, updated_at_unix_secs: int>, platform_settings: record<evaluation: record<criteria: list>, widget: record<variant: string, placement: string, expandable: string, avatar: any, feedback_mode: string, end_feedback: any, bg_color: string, text_color: string, btn_color: string, btn_text_color: string, border_color: string, focus_color: string, border_radius: any, btn_radius: any, action_text: any, start_call_text: any, end_call_text: any, expand_text: any, listening_text: any, speaking_text: any, shareable_page_text: any, shareable_page_show_terms: bool, terms_text: any, terms_html: any, terms_key: any, show_avatar_when_collapsed: any, disable_banner: bool, override_link: any, markdown_link_allowed_hosts: list, markdown_link_include_www: bool, markdown_link_allow_http: bool, mic_muting_enabled: bool, transcript_enabled: bool, text_input_enabled: bool, conversation_mode_toggle_enabled: bool, default_expanded: bool, always_expanded: bool, dismissible: bool, show_agent_status: bool, show_conversation_id: bool, strip_audio_tags: bool, syntax_highlight_theme: any, text_contents: record, styles: record, language_selector: bool, supports_text_only: bool, custom_avatar_path: any, language_presets: record>, data_collection: record, data_collection_scopes: record, overrides: record<conversation_config_override: record, custom_llm_extra_body: bool, enable_conversation_initiation_client_data_from_webhook: bool, enable_starting_workflow_node_id_from_client: bool>, workspace_overrides: record<conversation_initiation_client_data_webhook: any, webhooks: record>, testing: record<attached_tests: list>, archived: bool, guardrails: record<version: string, focus: record, prompt_injection: record, content: record, moderation: any, custom: record>, summary_language: any, auth: record<enable_auth: bool, allowlist: list, require_origin_header: bool, shareable_token: any>, call_limits: record<agent_concurrency_limit: int, daily_limit: int, bursting_enabled: bool>, privacy: record<record_voice: bool, retention_days: int, delete_transcript_and_pii: bool, delete_audio: bool, apply_to_existing_conversations: bool, zero_retention_mode: bool, conversation_history_redaction: record>, trust_context: string, analysis_llm: string, safety: record<is_blocked_ivc: bool, is_blocked_non_ivc: bool, ignore_safety_evaluation: bool>>, phone_numbers: list<any>, whatsapp_accounts: table<business_account_id: string, phone_number_id: string, business_account_name: string, phone_number_name: string, phone_number: string, assigned_agent_id: any, enable_messaging: bool, enable_audio_message_response: bool, assigned_agent_name: any, is_token_expired: bool>, workflow: record<edges: record, nodes: record, prevent_subagent_loops: bool>, access_info: any, tags: list<string>, version_id: any, branch_id: any, main_branch_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version_id" $version_id "scalar") (serialize-qp "branch_id" $branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patches An Agent Settings
#
# PATCH /v1/convai/agents/{agent_id}
# operationId: patch_agent_settings_route
# --workflow shape: {edges?: record, nodes?: record, prevent_subagent_loops?: bool}
@deprecated --flag enable-versioning-if-not-enabled
export def "convai-agents route-by-agent_id-1" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable-versioning-if-not-enabled: oneof<nothing, bool> # Deprecated: all agents are versioned. This parameter is ignored. (DEPRECATED, default: true)
  --branch-id: string # The ID of the branch to use
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --conversation-config: any # Conversation configuration for an agent
  --platform-settings: any # Platform settings for the agent are all settings that aren't related to the conversation orchestration and content.
  --workflow: record # e.g. {edges: {entry_to_tool_a: {forward_condition: {condition: Tool A condition}, source: entry_node, target: tool_node_a}, start_to_entry: {forward_condition: {}, source: start_node, target: entry_node}, tool_a_to_failure: {forward_condition: {successful: false}, source: tool_node_a, target: failure_node}, tool_a_to_tool_b: {forward_condition: {successful: true}, source: tool_node_a, target: tool_node_b}, tool_b_to_agent_transfer: {forward_condition: {}, source: tool_node_b, target: success_transfer}, tool_b_to_conversation: {forward_condition: {condition: Conversation condition}, source: tool_node_b, target: success_conversation}, tool_b_to_end: {forward_condition: {condition: End condition}, source: tool_node_b, target: success_end}, tool_b_to_phone: {forward_condition: {expression: {children: [{name: force_phone_transfer}, {prompt: Phone condition, value_schema: {description: Phone condition, type: boolean}}, {left: {name: mode}, right: {value: dev}}]}}, source: tool_node_b, target: success_phone}}, nodes: {entry_node: {conversation_config: {}, edge_order: [entry_to_tool_a], label: Entry}, failure_node: {conversation_config: {}, label: Failure}, start_node: {edge_order: [start_to_entry]}, success_conversation: {conversation_config: {}, label: Success A}, success_end: {}, success_phone: {transfer_destination: {phone_number: +1234567890}}, success_transfer: {agent_id: success_transfer_agent}, tool_node_a: {edge_order: [tool_a_to_failure, tool_a_to_tool_b], tools: [{tool_id: tool_a}, {tool_id: tool_b}]}, tool_node_b: {edge_order: [tool_b_to_conversation, tool_b_to_end, tool_b_to_phone, tool_b_to_agent_transfer], tools: [{tool_id: tool_a}]}}} — shape: {edges?: record, nodes?: record, prevent_subagent_loops?: bool}
  --name: any # A name to make the agent easier to find
  --tags: any # Tags to help classify and filter the agent
  --version-description: any # Description for this version when publishing changes (only applicable for versioned agents)
]: any -> record<agent_id: string, name: string, conversation_config: record<asr: record<quality: string, provider: string, user_input_audio_format: string, keywords: list>, turn: record<turn_timeout: float, initial_wait_time: any, silence_end_call_timeout: float, mode: string, turn_eagerness: string, spelling_patience: string, speculative_turn: bool, retranscribe_on_turn_timeout: bool, turn_model: string, soft_timeout_config: record>, tts: record<model_id: string, voice_id: string, supported_voices: list, expressive_mode: bool, suggested_audio_tags: list, agent_output_audio_format: string, optimize_streaming_latency: int, stability: float, speed: float, similarity_boost: float, text_normalisation_type: string, pronunciation_dictionary_locators: list>, conversation: record<text_only: bool, max_duration_seconds: int, client_events: list, file_input: record, monitoring_enabled: bool, monitoring_events: list, source_attribution: bool>, language_presets: record, vad: record<background_voice_detection: bool>, agent: record<first_message: string, language: string, hinglish_mode: bool, dynamic_variables: record, disable_first_message_interruptions: bool, max_conversation_duration_message: string, text_behavior_overrides: any, prompt: record>>, metadata: record<created_at_unix_secs: int, updated_at_unix_secs: int>, platform_settings: record<evaluation: record<criteria: list>, widget: record<variant: string, placement: string, expandable: string, avatar: any, feedback_mode: string, end_feedback: any, bg_color: string, text_color: string, btn_color: string, btn_text_color: string, border_color: string, focus_color: string, border_radius: any, btn_radius: any, action_text: any, start_call_text: any, end_call_text: any, expand_text: any, listening_text: any, speaking_text: any, shareable_page_text: any, shareable_page_show_terms: bool, terms_text: any, terms_html: any, terms_key: any, show_avatar_when_collapsed: any, disable_banner: bool, override_link: any, markdown_link_allowed_hosts: list, markdown_link_include_www: bool, markdown_link_allow_http: bool, mic_muting_enabled: bool, transcript_enabled: bool, text_input_enabled: bool, conversation_mode_toggle_enabled: bool, default_expanded: bool, always_expanded: bool, dismissible: bool, show_agent_status: bool, show_conversation_id: bool, strip_audio_tags: bool, syntax_highlight_theme: any, text_contents: record, styles: record, language_selector: bool, supports_text_only: bool, custom_avatar_path: any, language_presets: record>, data_collection: record, data_collection_scopes: record, overrides: record<conversation_config_override: record, custom_llm_extra_body: bool, enable_conversation_initiation_client_data_from_webhook: bool, enable_starting_workflow_node_id_from_client: bool>, workspace_overrides: record<conversation_initiation_client_data_webhook: any, webhooks: record>, testing: record<attached_tests: list>, archived: bool, guardrails: record<version: string, focus: record, prompt_injection: record, content: record, moderation: any, custom: record>, summary_language: any, auth: record<enable_auth: bool, allowlist: list, require_origin_header: bool, shareable_token: any>, call_limits: record<agent_concurrency_limit: int, daily_limit: int, bursting_enabled: bool>, privacy: record<record_voice: bool, retention_days: int, delete_transcript_and_pii: bool, delete_audio: bool, apply_to_existing_conversations: bool, zero_retention_mode: bool, conversation_history_redaction: record>, trust_context: string, analysis_llm: string, safety: record<is_blocked_ivc: bool, is_blocked_non_ivc: bool, ignore_safety_evaluation: bool>>, phone_numbers: list<any>, whatsapp_accounts: table<business_account_id: string, phone_number_id: string, business_account_name: string, phone_number_name: string, phone_number: string, assigned_agent_id: any, enable_messaging: bool, enable_audio_message_response: bool, assigned_agent_name: any, is_token_expired: bool>, workflow: record<edges: record, nodes: record, prevent_subagent_loops: bool>, access_info: any, tags: list<string>, version_id: any, branch_id: any, main_branch_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enable_versioning_if_not_enabled" $enable_versioning_if_not_enabled "scalar") (serialize-qp "branch_id" $branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)" $qp)
  let body = {conversation_config: $conversation_config, platform_settings: $platform_settings, workflow: $workflow, name: $name, tags: $tags, version_description: $version_description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Agent
#
# DELETE /v1/convai/agents/{agent_id}
# operationId: delete_agent_route
export def "convai-agents route-by-agent_id-2" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Agent Widget Config
#
# GET /v1/convai/agents/{agent_id}/widget
# operationId: get_agent_widget_route
export def "convai-agents-widget route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --conversation-signature: string # An expiring token that enables a websocket conversation to start. These can be generated for an agent using the /v1/convai/conversation/get-signed-url endpoint
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agent_id: string, widget_config: record<variant: string, placement: string, expandable: string, avatar: any, feedback_mode: string, end_feedback: any, bg_color: string, text_color: string, btn_color: string, btn_text_color: string, border_color: string, focus_color: string, border_radius: any, btn_radius: any, action_text: any, start_call_text: any, end_call_text: any, expand_text: any, listening_text: any, speaking_text: any, shareable_page_text: any, shareable_page_show_terms: bool, terms_text: any, terms_html: any, terms_key: any, show_avatar_when_collapsed: any, disable_banner: bool, override_link: any, markdown_link_allowed_hosts: list<record>, markdown_link_include_www: bool, markdown_link_allow_http: bool, mic_muting_enabled: bool, transcript_enabled: bool, text_input_enabled: bool, conversation_mode_toggle_enabled: bool, default_expanded: bool, always_expanded: bool, dismissible: bool, show_agent_status: bool, show_conversation_id: bool, strip_audio_tags: bool, syntax_highlight_theme: any, text_contents: record<main_label: any, start_call: any, start_chat: any, new_call: any, end_call: any, mute_microphone: any, change_language: any, collapse: any, expand: any, copied: any, accept_terms: any, dismiss_terms: any, listening_status: any, speaking_status: any, connecting_status: any, chatting_status: any, input_label: any, input_placeholder: any, input_placeholder_text_only: any, input_placeholder_new_conversation: any, user_ended_conversation: any, agent_ended_conversation: any, conversation_id: any, error_occurred: any, copy_id: any, initiate_feedback: any, request_follow_up_feedback: any, thanks_for_feedback: any, thanks_for_feedback_details: any, follow_up_feedback_placeholder: any, submit: any, go_back: any, send_message: any, text_mode: any, voice_mode: any, switched_to_text_mode: any, switched_to_voice_mode: any, copy: any, download: any, wrap: any, agent_working: any, agent_done: any, agent_error: any>, styles: record<base: any, base_hover: any, base_active: any, base_border: any, base_subtle: any, base_primary: any, base_error: any, accent: any, accent_hover: any, accent_active: any, accent_border: any, accent_subtle: any, accent_primary: any, overlay_padding: any, button_radius: any, input_radius: any, bubble_radius: any, sheet_radius: any, compact_sheet_radius: any, dropdown_sheet_radius: any>, language: string, supported_language_overrides: any, language_presets: record, text_only: bool, supports_text_only: bool, first_message: any, use_rtc: any, file_input_config: record<enabled: bool, max_files_per_conversation: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conversation_signature" $conversation_signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/widget" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shareable Agent Link
#
# GET /v1/convai/agents/{agent_id}/link
# operationId: get_agent_link_route
export def "convai-agents-link route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agent_id: string, token: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/link")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post Agent Avatar
#
# POST /v1/convai/agents/{agent_id}/avatar
# operationId: post_agent_avatar_route
export def "convai-agents-avatar route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  avatar_file: string # An image file to be used as the agent's avatar. (format: binary)
]: any -> record<agent_id: string, avatar_url: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/avatar")
  let body = {avatar_file: $avatar_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Agents
#
# GET /v1/convai/agents
# operationId: get_agents_route
@deprecated --flag show-only-owned-agents
export def "convai-agents route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many Agents to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --search: string # Search by agents name.
  --archived: string # Filter agents by archived status (default: false)
  --show-only-owned-agents: oneof<nothing, bool> # If set to true, the endpoint will omit any agents that were shared with you by someone else and include only the ones you own. Deprecated: use created_by_user_id instead. (DEPRECATED, default: false)
  --created-by-user-id: string # Filter agents by creator user ID. When set, only agents created by this user are returned. Takes precedence over show_only_owned_agents. Use '@me' to refer to the authenticated user.
  --sort-direction: string@sort-direction-completer # The direction to sort the results
  --sort-by: string # The field to sort the results by
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agents: table<agent_id: string, name: string, tags: list, created_at_unix_secs: int, access_info: record, last_call_time_unix_secs: any, archived: bool>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "show_only_owned_agents" $show_only_owned_agents "scalar") (serialize-qp "created_by_user_id" $created_by_user_id "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/agents" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns The Size Of The Agent'S Knowledge Base
#
# GET /v1/convai/agent/{agent_id}/knowledge-base/size
# operationId: get_agent_knowledge_base_size
export def "convai-agent-knowledge-base-size size" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<number_of_pages: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agent/($agent_id)/knowledge-base/size")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Calculate Expected Llm Usage For An Agent
#
# POST /v1/convai/agent/{agent_id}/llm-usage/calculate
# operationId: get_agent_llm_expected_cost_calculation
export def "convai-agent-llm-usage-calculate calculation" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --prompt-length: any # Length of the prompt in characters.
  --number-of-pages: any # Pages of content in pdf documents OR urls in agent's Knowledge Base.
  --rag-enabled: any # Whether RAG is enabled.
]: any -> record<llm_prices: table<llm: string, price_per_minute: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agent/($agent_id)/llm-usage/calculate")
  let body = {prompt_length: $prompt_length, number_of_pages: $number_of_pages, rag_enabled: $rag_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Duplicate Agent
#
# POST /v1/convai/agents/{agent_id}/duplicate
# operationId: duplicate_agent_route
export def "convai-agents-duplicate route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: any # A name to make the agent easier to find
]: any -> record<agent_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/duplicate")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulates A Conversation
#
# POST /v1/convai/agents/{agent_id}/simulate-conversation
# operationId: run_conversation_simulation_route
# --simulation_specification shape: {simulated_user_config: record, tool_mock_config?: record, partial_conversation_history?: list, dynamic_variables?: record}
export def "convai-agents-simulate-conversation route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  simulation_specification: record # A specification that will be used to simulate a conversation between an agent and an AI user. — shape: {simulated_user_config: record, tool_mock_config?: record, partial_conversation_history?: list, dynamic_variables?: record}
  --extra-evaluation-criteria: any # A list of evaluation criteria to test
  --new-turns-limit: int # Maximum number of new turns to generate in the conversation simulation (default: 10000)
]: any -> record<simulated_conversation: table<role: string, agent_metadata: any, message: any, multivoice_message: any, tool_calls: list, tool_results: list, feedback: any, llm_override: any, time_in_call_secs: int, conversation_turn_metrics: any, rag_retrieval_info: any, llm_usage: any, interrupted: bool, original_message: any, source_medium: any, source_event_id: any, used_static_kb_document_ids: list, file_input: any, contextual_update_info: any>, analysis: record<evaluation_criteria_results: record, data_collection_results: record, evaluation_criteria_results_list: list<record>, data_collection_results_list: list<record>, call_successful: string, transcript_summary: string, call_summary_title: any, scoped: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/simulate-conversation")
  let body = {simulation_specification: $simulation_specification, extra_evaluation_criteria: $extra_evaluation_criteria, new_turns_limit: $new_turns_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulates A Conversation (Stream)
#
# POST /v1/convai/agents/{agent_id}/simulate-conversation/stream
# operationId: run_conversation_simulation_route_stream
# --simulation_specification shape: {simulated_user_config: record, tool_mock_config?: record, partial_conversation_history?: list, dynamic_variables?: record}
export def "convai-agents-simulate-conversation-stream stream" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  simulation_specification: record # A specification that will be used to simulate a conversation between an agent and an AI user. — shape: {simulated_user_config: record, tool_mock_config?: record, partial_conversation_history?: list, dynamic_variables?: record}
  --extra-evaluation-criteria: any # A list of evaluation criteria to test
  --new-turns-limit: int # Maximum number of new turns to generate in the conversation simulation (default: 10000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/simulate-conversation/stream")
  let body = {simulation_specification: $simulation_specification, extra_evaluation_criteria: $extra_evaluation_criteria, new_turns_limit: $new_turns_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Agent Response Test
#
# POST /v1/convai/agent-testing/create
# operationId: create_agent_response_test_route
# --chat_history item shape: {role: "user"|"agent", agent_metadata?: any, message?: any, multivoice_message?: any, tool_calls?: list, tool_results?: list, feedback?: any, llm_override?: any, time_in_call_secs: int, conversation_turn_metrics?: any, rag_retrieval_info?: any, llm_usage?: any, interrupted?: bool, original_message?: any, source_medium?: any, source_event_id?: any, used_static_kb_document_ids?: list}
# --success_examples item shape: {response: string, type: string}
# --failure_examples item shape: {response: string, type: string}
# --tool_mock_config shape: {mocking_strategy?: "all"|"selected"|"none", fallback_strategy?: "call_real_tool"|"raise_error", mocked_tool_ids?: list}
export def "convai-agent-testing-create route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --from-conversation-metadata: any # Metadata of a conversation this test was created from (if applicable).
  --dynamic-variables: record # Dynamic variables to replace in the agent config during testing
  --chat-history: list # item shape: {role: "user"|"agent", agent_metadata?: any, message?: any, multivoice_message?: any, tool_calls?: list, tool_results?: list, feedback?: any, llm_override?: any, time_in_call_secs: int, conversation_turn_metrics?: any, rag_retrieval_info?: any, llm_usage?: any, interrupted?: bool, original_message?: any, source_medium?: any, source_event_id?: any, used_static_kb_document_ids?: list}
  --conversation-initiation-source: any # Simulate the test as if the conversation originated from this channel.
  --type: string # default: llm
  --success-condition: string # A prompt that evaluates whether the agent's response is successful. Should return True or False. (default: )
  --success-examples: list # Non-empty list of example responses that should be considered successful — item shape: {response: string, type: string}
  --failure-examples: list # Non-empty list of example responses that should be considered failures — item shape: {response: string, type: string}
  --name: string
  --parent-folder-id: any # The ID of the parent folder. If not provided, the test will be created at the root level.
  --tool-call-parameters: any # How to evaluate the agent's tool call (if any). If empty, the tool call is not evaluated.
  --check-any-tool-matches: any # If set to True this test will pass if any tool call returned by the LLM matches the criteria. Otherwise it will fail if more than one tool is returned by the agent.
  --simulation-scenario: string # Description of the simulation scenario and user persona for simulation tests. (default: )
  --simulation-max-turns: int # Maximum number of conversation turns for simulation tests. (default: 5)
  --simulation-environment: any # The environment to use when running this simulation test. If not provided, defaults to 'production'.
  --tool-mock-config: record # Simulation/preview-side config: tools are identified by IDs, resolved to names at runtime. — shape: {mocking_strategy?: "all"|"selected"|"none", fallback_strategy?: "call_real_tool"|"raise_error", mocked_tool_ids?: list}
  --evaluation-model: any # LLM model to use for evaluating simulation results. Defaults to Claude Sonnet 4.6.
  --simulated-user-model: any # LLM model for the simulated user. Defaults to Claude Sonnet 4.6.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/agent-testing/create")
  let body = {from_conversation_metadata: $from_conversation_metadata, dynamic_variables: $dynamic_variables, chat_history: $chat_history, conversation_initiation_source: $conversation_initiation_source, type: $type, success_condition: $success_condition, success_examples: $success_examples, failure_examples: $failure_examples, name: $name, parent_folder_id: $parent_folder_id, tool_call_parameters: $tool_call_parameters, check_any_tool_matches: $check_any_tool_matches, simulation_scenario: $simulation_scenario, simulation_max_turns: $simulation_max_turns, simulation_environment: $simulation_environment, tool_mock_config: $tool_mock_config, evaluation_model: $evaluation_model, simulated_user_model: $simulated_user_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Agent Test Folder
#
# POST /v1/convai/agent-testing/folders
# operationId: create_agent_test_folder_route
export def "convai-agent-testing-folders route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name of the folder to create
  --parent-folder-id: any # The ID of the parent folder. If not provided, the folder will be created at the root level.
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/agent-testing/folders")
  let body = {name: $name, parent_folder_id: $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Agent Test Folder By Id
#
# GET /v1/convai/agent-testing/folders/{folder_id}
# operationId: get_agent_test_folder_route
export def "convai-agent-testing-folders route-by-folder_id" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, name: string, folder_path: table<id: string, name: string>, children_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agent-testing/folders/($folder_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Agent Test Folder
#
# PATCH /v1/convai/agent-testing/folders/{folder_id}
# operationId: update_agent_test_folder_route
export def "convai-agent-testing-folders route-by-folder_id-1" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The new name for the folder
]: any -> record<id: string, name: string, folder_path: table<id: string, name: string>, children_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agent-testing/folders/($folder_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Agent Test Folder
#
# DELETE /v1/convai/agent-testing/folders/{folder_id}
# operationId: delete_agent_test_folder_route
export def "convai-agent-testing-folders route-by-folder_id-2" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Force delete. Required for deleting non-empty folders. (default: false)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agent-testing/folders/($folder_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Move Tests To Folder
#
# POST /v1/convai/agent-testing/bulk-move
# operationId: agent_testing_bulk_move_route
export def "convai-agent-testing-bulk-move route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  entity_ids: list # The IDs of tests or folders to move.
  --move-to: any # The folder to move the entities to. If not set, the entities will be moved to the root folder.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/agent-testing/bulk-move")
  let body = {entity_ids: $entity_ids, move_to: $move_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Agent Response Test By Id
#
# GET /v1/convai/agent-testing/{test_id}
# Discriminator (response): type = llm, tool, simulation
# operationId: get_agent_response_test_route
export def "convai-agent-testing route-by-test_id" [
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agent-testing/($test_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Agent Response Test
#
# PUT /v1/convai/agent-testing/{test_id}
# Discriminator (response): type = llm, tool, simulation
# operationId: update_agent_response_test_route
# --chat_history item shape: {role: "user"|"agent", agent_metadata?: any, message?: any, multivoice_message?: any, tool_calls?: list, tool_results?: list, feedback?: any, llm_override?: any, time_in_call_secs: int, conversation_turn_metrics?: any, rag_retrieval_info?: any, llm_usage?: any, interrupted?: bool, original_message?: any, source_medium?: any, source_event_id?: any, used_static_kb_document_ids?: list}
# --success_examples item shape: {response: string, type: string}
# --failure_examples item shape: {response: string, type: string}
# --tool_mock_config shape: {mocking_strategy?: "all"|"selected"|"none", fallback_strategy?: "call_real_tool"|"raise_error", mocked_tool_ids?: list}
export def "convai-agent-testing route-by-test_id-1" [
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --from-conversation-metadata: any # Metadata of a conversation this test was created from (if applicable).
  --dynamic-variables: record # Dynamic variables to replace in the agent config during testing
  --chat-history: list # item shape: {role: "user"|"agent", agent_metadata?: any, message?: any, multivoice_message?: any, tool_calls?: list, tool_results?: list, feedback?: any, llm_override?: any, time_in_call_secs: int, conversation_turn_metrics?: any, rag_retrieval_info?: any, llm_usage?: any, interrupted?: bool, original_message?: any, source_medium?: any, source_event_id?: any, used_static_kb_document_ids?: list}
  --conversation-initiation-source: any # Simulate the test as if the conversation originated from this channel.
  --type: string # default: llm
  --success-condition: string # A prompt that evaluates whether the agent's response is successful. Should return True or False. (default: )
  --success-examples: list # Non-empty list of example responses that should be considered successful — item shape: {response: string, type: string}
  --failure-examples: list # Non-empty list of example responses that should be considered failures — item shape: {response: string, type: string}
  --name: string
  --parent-folder-id: any # The ID of the parent folder. If not provided, the test will be moved to the root level.
  --tool-call-parameters: any # How to evaluate the agent's tool call (if any). If empty, the tool call is not evaluated.
  --check-any-tool-matches: any # If set to True this test will pass if any tool call returned by the LLM matches the criteria. Otherwise it will fail if more than one tool is returned by the agent.
  --simulation-scenario: string # Description of the simulation scenario and user persona for simulation tests. (default: )
  --simulation-max-turns: int # Maximum number of conversation turns for simulation tests. (default: 5)
  --simulation-environment: any # The environment to use when running this simulation test. If not provided, defaults to 'production'.
  --tool-mock-config: record # Simulation/preview-side config: tools are identified by IDs, resolved to names at runtime. — shape: {mocking_strategy?: "all"|"selected"|"none", fallback_strategy?: "call_real_tool"|"raise_error", mocked_tool_ids?: list}
  --evaluation-model: any # LLM model to use for evaluating simulation results. Defaults to Claude Sonnet 4.6.
  --simulated-user-model: any # LLM model for the simulated user. Defaults to Claude Sonnet 4.6.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agent-testing/($test_id)")
  let body = {from_conversation_metadata: $from_conversation_metadata, dynamic_variables: $dynamic_variables, chat_history: $chat_history, conversation_initiation_source: $conversation_initiation_source, type: $type, success_condition: $success_condition, success_examples: $success_examples, failure_examples: $failure_examples, name: $name, parent_folder_id: $parent_folder_id, tool_call_parameters: $tool_call_parameters, check_any_tool_matches: $check_any_tool_matches, simulation_scenario: $simulation_scenario, simulation_max_turns: $simulation_max_turns, simulation_environment: $simulation_environment, tool_mock_config: $tool_mock_config, evaluation_model: $evaluation_model, simulated_user_model: $simulated_user_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Agent Response Test
#
# DELETE /v1/convai/agent-testing/{test_id}
# operationId: delete_chat_response_test_route
export def "convai-agent-testing route-by-test_id-2" [
  test_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agent-testing/($test_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Agent Response Test Summaries By Ids
#
# POST /v1/convai/agent-testing/summaries
# operationId: get_agent_response_tests_summaries_route
export def "convai-agent-testing-summaries route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  test_ids: list # List of test IDs to fetch. No duplicates allowed.
]: any -> record<tests: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/agent-testing/summaries")
  let body = {test_ids: $test_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Agent Response Tests
#
# GET /v1/convai/agent-testing
# operationId: list_chat_response_tests_route
@deprecated --flag include-folders
export def "convai-agent-testing route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --page-size: int # How many Tests to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --search: string # Search query to filter tests by name.
  --parent-folder-id: string # Filter by parent folder ID. Use 'root' to get items in the root folder.
  --types: string # If present, the endpoint will return only tests/folders of the given types.
  --include-folders: string # Deprecated. Use the `types` query param and include `folder` instead. (DEPRECATED)
  --sort-mode: string@sort-mode-completer # Sort mode for listing tests. Use 'folders_first' to place folders before tests. (default: default)
  --sharing-mode: string@sharing-mode-completer # Filter test visibility. Use `shared_with_me` to return only tests/folders shared with the current user that they did not create.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<tests: table<id: string, name: string, access_info: any, created_at_unix_secs: int, last_updated_at_unix_secs: int, type: string, entity_type: string, folder_parent_id: any, folder_path: list, children_count: any, conversation_initiation_source: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "parent_folder_id" $parent_folder_id "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "include_folders" $include_folders "scalar") (serialize-qp "sort_mode" $sort_mode "scalar") (serialize-qp "sharing_mode" $sharing_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/agent-testing" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Test Invocations
#
# GET /v1/convai/test-invocations
# operationId: list_test_invocations_route
export def "convai-test-invocations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # Filter by agent ID
  --page-size: int # How many Tests to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<meta: record<total: any, page: any, page_size: any>, results: table<id: string, agent_id: any, branch_id: any, created_at_unix_secs: int, test_run_count: int, passed_count: int, failed_count: int, pending_count: int, title: string, access_info: any, repeat_count: int>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/test-invocations" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run Tests On The Agent
#
# POST /v1/convai/agents/{agent_id}/run-tests
# operationId: run_agent_test_suite_route
# --tests item shape: {test_id: string, workflow_node_id?: any, root_folder_id?: any, root_folder_name?: any}
export def "convai-agents-run-tests route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  tests: list # List of tests to run on the agent — item shape: {test_id: string, workflow_node_id?: any, root_folder_id?: any, root_folder_name?: any}
  --agent-config-override: any # Configuration overrides to use for testing. If not provided, the agent's default configuration will be used.
  --branch-id: any # ID of the branch to run the tests on. If not provided, the tests will be run on the agent default configuration.
  --repeat-count: int # Number of times to run each test. When greater than 1, results are grouped and summarized. (default: 1)
]: any -> record<id: string, agent_id: any, branch_id: any, created_at: int, folder_id: any, repeat_count: int, bucketing_status: any, result_groups: table<test_id: string, test_name: string, workflow_node_id: any, buckets: list>, test_runs: table<test_run_id: string, test_info: any, test_invocation_id: string, agent_id: string, branch_id: any, workflow_node_id: any, status: string, agent_responses: any, test_id: string, test_name: string, condition_result: any, last_updated_at_unix: int, metadata: any, root_folder_id: any, root_folder_name: any, environment: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/run-tests")
  let body = {tests: $tests, agent_config_override: $agent_config_override, branch_id: $branch_id, repeat_count: $repeat_count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Test Invocation
#
# GET /v1/convai/test-invocations/{test_invocation_id}
# operationId: get_test_invocation_route
export def "convai-test-invocations route" [
  test_invocation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, agent_id: any, branch_id: any, created_at: int, folder_id: any, repeat_count: int, bucketing_status: any, result_groups: table<test_id: string, test_name: string, workflow_node_id: any, buckets: list>, test_runs: table<test_run_id: string, test_info: any, test_invocation_id: string, agent_id: string, branch_id: any, workflow_node_id: any, status: string, agent_responses: any, test_id: string, test_name: string, condition_result: any, last_updated_at_unix: int, metadata: any, root_folder_id: any, root_folder_name: any, environment: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/test-invocations/($test_invocation_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resubmit Tests
#
# POST /v1/convai/test-invocations/{test_invocation_id}/resubmit
# operationId: resubmit_tests_route
export def "convai-test-invocations-resubmit route" [
  test_invocation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  test_run_ids: list # List of test run IDs to resubmit
  --agent-config-override: any # Configuration overrides to use for testing. If not provided, the agent's default configuration will be used.
  agent_id: string # Agent ID to resubmit tests for
  --branch-id: any # ID of the branch to run the tests on. If not provided, the tests will be run on the agent default configuration.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/test-invocations/($test_invocation_id)/resubmit")
  let body = {test_run_ids: $test_run_ids, agent_config_override: $agent_config_override, agent_id: $agent_id, branch_id: $branch_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Conversations
#
# GET /v1/convai/conversations
# operationId: get_conversation_histories_route
@deprecated --flag search
export def "convai-conversations route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --agent-id: string # Agent id (agent_…) or speech engine external id (seng_), resolved to the same underlying resource.
  --call-successful: string # The result of the success evaluation
  --call-start-before-unix: string # Unix timestamp (in seconds) to filter conversations up to this start date.
  --call-start-after-unix: string # Unix timestamp (in seconds) to filter conversations after to this start date.
  --call-duration-min-secs: string # Minimum call duration in seconds.
  --call-duration-max-secs: string # Maximum call duration in seconds.
  --rating-max: string # Maximum overall rating (1-5).
  --rating-min: string # Minimum overall rating (1-5).
  --has-feedback-comment: string # Filter conversations with user feedback comments.
  --user-id: string # Filter conversations by the user ID who initiated them.
  --evaluation-params: string # Evaluation filters. Repeat param. Format: criteria_id:result. Example: eval=value_framing:success
  --data-collection-params: string # Data collection filters. Repeat param. Format: id:op:value where op is one of eq|neq|gt|gte|lt|lte|in|exists|missing. For in, pipe-delimit values.
  --tool-names: string # Filter conversations by tool names used during the call.
  --tool-names-successful: string # Filter conversations by tool names that had successful calls.
  --tool-names-errored: string # Filter conversations by tool names that had errored calls.
  --main-languages: string # Filter conversations by detected main language (language code).
  --page-size: int # How many conversations to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --summary-mode: string@summary-mode-completer # Whether to include transcript summaries in the response. (default: exclude)
  --search: string # Full-text or fuzzy search over transcript messages (DEPRECATED)
  --conversation-initiation-source: string
  --text-only: string
  --branch-id: string # Filter conversations by branch ID.
  --topic-ids: string # Filter conversations by topic IDs assigned during topic discovery.
  --exclude-statuses: string # Exclude conversations with the given statuses. Useful for hiding in-progress / processing conversations from list views.
  --tag-ids: string # Filter conversations by conversation tag IDs assigned via the conversation-tags endpoints.
  --workflow-node-entered-id: string # Filter conversations to only those that entered the given node.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<conversations: table<agent_id: string, branch_id: any, version_id: any, agent_name: any, conversation_id: string, start_time_unix_secs: int, call_duration_secs: int, message_count: int, status: string, termination_reason: string, call_successful: string, transcript_summary: any, call_summary_title: any, main_language: any, conversation_initiation_source: any, tool_names: any, direction: any, rating: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "call_successful" $call_successful "scalar") (serialize-qp "call_start_before_unix" $call_start_before_unix "scalar") (serialize-qp "call_start_after_unix" $call_start_after_unix "scalar") (serialize-qp "call_duration_min_secs" $call_duration_min_secs "scalar") (serialize-qp "call_duration_max_secs" $call_duration_max_secs "scalar") (serialize-qp "rating_max" $rating_max "scalar") (serialize-qp "rating_min" $rating_min "scalar") (serialize-qp "has_feedback_comment" $has_feedback_comment "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "evaluation_params" $evaluation_params "scalar") (serialize-qp "data_collection_params" $data_collection_params "scalar") (serialize-qp "tool_names" $tool_names "scalar") (serialize-qp "tool_names_successful" $tool_names_successful "scalar") (serialize-qp "tool_names_errored" $tool_names_errored "scalar") (serialize-qp "main_languages" $main_languages "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "summary_mode" $summary_mode "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "conversation_initiation_source" $conversation_initiation_source "scalar") (serialize-qp "text_only" $text_only "scalar") (serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "topic_ids" $topic_ids "scalar") (serialize-qp "exclude_statuses" $exclude_statuses "scalar") (serialize-qp "tag_ids" $tag_ids "scalar") (serialize-qp "workflow_node_entered_id" $workflow_node_entered_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/conversations" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Conversation Users
#
# GET /v1/convai/users
# operationId: get_conversation_users_route
export def "convai-users route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # Agent id (agent_…) or speech engine external id (seng_), resolved to the same underlying resource.
  --branch-id: string # Filter conversations by branch ID.
  --call-start-before-unix: string # Unix timestamp (in seconds) to filter conversations up to this start date.
  --call-start-after-unix: string # Unix timestamp (in seconds) to filter conversations after to this start date.
  --search: string # Search/filter by user ID (exact match).
  --page-size: int # How many users to return at maximum. Defaults to 30. (default: 30)
  --sort-by: string@sort-by-completer # The field to sort the results by. Defaults to last_contact_unix_secs.
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<users: table<user_id: string, last_contact_unix_secs: int, first_contact_unix_secs: int, conversation_count: int, last_contact_agent_id: any, last_contact_conversation_id: string, last_contact_agent_name: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "call_start_before_unix" $call_start_before_unix "scalar") (serialize-qp "call_start_after_unix" $call_start_after_unix "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/users" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Conversation Details
#
# GET /v1/convai/conversations/{conversation_id}
# operationId: get_conversation_history_route
export def "convai-conversations route-by-conversation_id" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Response format. Defaults to 'json'. Set to 'opentelemetry' for an OTLP-compatible trace payload using the same structure as the post-call webhook. (default: json)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agent_id: string, agent_name: any, conversation_product: string, status: string, user_id: any, branch_id: any, version_id: any, metadata: record<start_time_unix_secs: int, accepted_time_unix_secs: any, call_duration_secs: int, cost: any, deletion_settings: record<deletion_time_unix_secs: any, deleted_logs_at_time_unix_secs: any, deleted_audio_at_time_unix_secs: any, deleted_transcript_at_time_unix_secs: any, delete_transcript_and_pii: bool, delete_audio: bool>, feedback: record<type: any, overall_score: any, likes: int, dislikes: int, rating: any, comment: any>, authorization_method: string, charging: record<dev_discount: bool, is_burst: bool, tier: any, llm_usage: record, llm_price: any, llm_charge: any, call_charge: any, free_minutes_consumed: float, free_llm_dollars_consumed: float, tts_usage: any, asr_usage: any>, phone_call: any, batch_call: any, termination_reason: string, error: any, warnings: list<string>, main_language: any, rag_usage: any, text_only: bool, features_usage: record<language_detection: record, transfer_to_agent: record, transfer_to_number: record, multivoice: record, dtmf_tones: record, external_mcp_servers: record, pii_zrm_workspace: bool, pii_zrm_agent: bool, tool_dynamic_variable_updates: record, is_livekit: bool, voicemail_detection: record, dtmf_input: record, workflow: record, agent_testing: record, versioning: record, file_input: record>, eleven_assistant: record<is_eleven_assistant: bool>, initiator_id: any, conversation_initiation_source: string, conversation_initiation_source_version: any, timezone: any, async_metadata: any, whatsapp: any, sms: any, agent_created_from: string, agent_last_updated_from: string, voice_rewards: list<record>>, analysis: any, visited_agents: table<agent_id: string, branch_id: any>, conversation_initiation_client_data: record<conversation_config_override: record<asr: any, turn: any, tts: any, conversation: any, agent: any>, custom_llm_extra_body: record, user_id: any, source_info: record<source: any, version: any>, branch_id: any, environment: any, starting_workflow_node_id: any, dynamic_variables: record>, environment: string, conversation_id: string, has_audio: bool, has_user_audio: bool, has_response_audio: bool, transcript: table<role: string, agent_metadata: any, message: any, multivoice_message: any, tool_calls: list, tool_results: list, feedback: any, llm_override: any, time_in_call_secs: int, conversation_turn_metrics: any, rag_retrieval_info: any, llm_usage: any, interrupted: bool, original_message: any, source_medium: any, source_event_id: any, used_static_kb_document_ids: list, file_input: any, contextual_update_info: any>, tag_ids: list<string>, otlp_traces: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Conversation
#
# DELETE /v1/convai/conversations/{conversation_id}
# operationId: delete_conversation_route
export def "convai-conversations route-by-conversation_id-1" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sip Messages For A Conversation
#
# GET /v1/convai/conversations/{conversation_id}/sip-messages
# operationId: get_conversation_sip_messages
export def "convai-conversations-sip-messages messages" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # default: 20
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<sip_messages: table<call_id: string, phone_numbers: list, local_address: string, remote_address: string, transport: string, raw_message: string, error_message: string, direction: string, created_at_unix_micro: int>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/sip-messages" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Conversation Audio
#
# GET /v1/convai/conversations/{conversation_id}/audio
# operationId: get_conversation_audio_route
export def "convai-conversations-audio route" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/audio")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Conversation Feedback
#
# POST /v1/convai/conversations/{conversation_id}/feedback
# operationId: post_conversation_feedback_route
export def "convai-conversations-feedback route" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feedback: any # Either 'like' or 'dislike' to indicate the feedback for the conversation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/feedback")
  let body = {feedback: $feedback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Text Search Conversation Messages
#
# GET /v1/convai/conversations/messages/text-search
# operationId: text_search_conversation_messages_route
export def "convai-conversations-messages-text-search route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text-query: string # The search query text for full-text and fuzzy matching
  --agent-id: string # Agent id (agent_…) or speech engine external id (seng_), resolved to the same underlying resource.
  --call-successful: string # The result of the success evaluation
  --call-start-before-unix: string # Unix timestamp (in seconds) to filter conversations up to this start date.
  --call-start-after-unix: string # Unix timestamp (in seconds) to filter conversations after to this start date.
  --call-duration-min-secs: string # Minimum call duration in seconds.
  --call-duration-max-secs: string # Maximum call duration in seconds.
  --rating-max: string # Maximum overall rating (1-5).
  --rating-min: string # Minimum overall rating (1-5).
  --has-feedback-comment: string # Filter conversations with user feedback comments.
  --user-id: string # Filter conversations by the user ID who initiated them.
  --evaluation-params: string # Evaluation filters. Repeat param. Format: criteria_id:result. Example: eval=value_framing:success
  --data-collection-params: string # Data collection filters. Repeat param. Format: id:op:value where op is one of eq|neq|gt|gte|lt|lte|in|exists|missing. For in, pipe-delimit values.
  --tool-names: string # Filter conversations by tool names used during the call.
  --tool-names-successful: string # Filter conversations by tool names that had successful calls.
  --tool-names-errored: string # Filter conversations by tool names that had errored calls.
  --main-languages: string # Filter conversations by detected main language (language code).
  --page-size: int # Number of results per page. Max 50. (default: 20)
  --summary-mode: string@summary-mode-completer # Whether to include transcript summaries in the response. (default: exclude)
  --conversation-initiation-source: string
  --text-only: string
  --branch-id: string # Filter conversations by branch ID.
  --topic-ids: string # Filter conversations by topic IDs assigned during topic discovery.
  --sort-by: string@sort-by-completer-1 # Sort order for search results. 'search_score' sorts by search score, 'created_at' sorts by conversation start time.
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<meta: record<total: any, page: any, page_size: any>, results: table<conversation_id: string, agent_id: string, agent_name: any, transcript_index: int, chunk_text: string, chunk_highlights: any, score: float, conversation_start_time_unix_secs: int>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text_query" $text_query "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "call_successful" $call_successful "scalar") (serialize-qp "call_start_before_unix" $call_start_before_unix "scalar") (serialize-qp "call_start_after_unix" $call_start_after_unix "scalar") (serialize-qp "call_duration_min_secs" $call_duration_min_secs "scalar") (serialize-qp "call_duration_max_secs" $call_duration_max_secs "scalar") (serialize-qp "rating_max" $rating_max "scalar") (serialize-qp "rating_min" $rating_min "scalar") (serialize-qp "has_feedback_comment" $has_feedback_comment "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "evaluation_params" $evaluation_params "scalar") (serialize-qp "data_collection_params" $data_collection_params "scalar") (serialize-qp "tool_names" $tool_names "scalar") (serialize-qp "tool_names_successful" $tool_names_successful "scalar") (serialize-qp "tool_names_errored" $tool_names_errored "scalar") (serialize-qp "main_languages" $main_languages "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "summary_mode" $summary_mode "scalar") (serialize-qp "conversation_initiation_source" $conversation_initiation_source "scalar") (serialize-qp "text_only" $text_only "scalar") (serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "topic_ids" $topic_ids "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/conversations/messages/text-search" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Smart Search Conversation Messages
#
# GET /v1/convai/conversations/messages/smart-search
# operationId: smart_search_conversation_messages_route
export def "convai-conversations-messages-smart-search route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text-query: string # The search query text for semantic similarity matching
  --agent-id: string # Agent id (agent_…) or speech engine external id (seng_), resolved to the same underlying resource.
  --page-size: int # Number of results per page. Max 50. (default: 20)
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<meta: record<total: any, page: any, page_size: any>, results: table<conversation_id: string, agent_id: string, agent_name: any, transcript_index: int, chunk_text: string, chunk_highlights: any, score: float, conversation_start_time_unix_secs: int>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text_query" $text_query "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/conversations/messages/smart-search" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign Conversation Tags
#
# POST /v1/convai/conversations/{conversation_id}/tags
# operationId: assign_conversation_tags_route
export def "convai-conversations-tags route-by-conversation_id" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  tag_ids: list # Tag IDs to add to the conversation. Re-assigning an existing tag is a no-op.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/tags")
  let body = {tag_ids: $tag_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign Conversation Tag
#
# DELETE /v1/convai/conversations/{conversation_id}/tags/{tag_id}
# operationId: unassign_conversation_tag_route
export def "convai-conversations-tags route-by-conversation_id-tag_id" [
  conversation_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/tags/($tag_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Conversation Tags
#
# GET /v1/convai/tags
# operationId: list_conversation_tags_route
export def "convai-tags route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many conversation tags to return. Can not exceed 100. (default: 100)
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<conversation_tags: table<tag_id: string, workspace_id: string, owner_user_id: string, title: string, description: any, created_at_unix_secs: int>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/tags" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Conversation Tag
#
# POST /v1/convai/tags
# operationId: create_conversation_tag_route
export def "convai-tags route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  title: string # Display title of the tag.
  --description: any # Optional free-text description.
]: any -> record<tag_id: string, workspace_id: string, owner_user_id: string, title: string, description: any, created_at_unix_secs: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/tags")
  let body = {title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Conversation Tag
#
# GET /v1/convai/tags/{tag_id}
# operationId: get_conversation_tag_route
export def "convai-tags route-by-tag_id" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<tag_id: string, workspace_id: string, owner_user_id: string, title: string, description: any, created_at_unix_secs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/tags/($tag_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Conversation Tag
#
# PATCH /v1/convai/tags/{tag_id}
# operationId: update_conversation_tag_route
export def "convai-tags route-by-tag_id-1" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --title: any # If provided, replaces the tag title. Omit to leave unchanged.
  --description: any # If provided, replaces the tag description. Omit to leave unchanged.
]: any -> record<tag_id: string, workspace_id: string, owner_user_id: string, title: string, description: any, created_at_unix_secs: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/tags/($tag_id)")
  let body = {title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Conversation Tag
#
# DELETE /v1/convai/tags/{tag_id}
# operationId: delete_conversation_tag_route
export def "convai-tags route-by-tag_id-2" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/tags/($tag_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import Phone Number
#
# POST /v1/convai/phone-numbers
# operationId: create_phone_number_route
@deprecated --flag supports-inbound
@deprecated --flag supports-outbound
export def "convai-phone-numbers route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --phone-number: string # Phone number
  --label: string # Label for the phone number
  --supports-inbound: oneof<nothing, bool> # This field is deprecated and will be removed in the future. Whether this phone number supports inbound calls (DEPRECATED, default: true)
  --supports-outbound: oneof<nothing, bool> # This field is deprecated and will be removed in the future. Whether this phone number supports outbound calls (DEPRECATED, default: true)
  --provider: string # default: twilio
  --sid: string # Twilio Account SID
  --body-token: string # Twilio Auth Token
  --region-config: any # Twilio Additional Region Configuration
  --account-sid: string # Exotel Account SID
  --api-key: string # Exotel API Key
  --api-token: string # Exotel API Token
  --api-subdomain: string@api-subdomain-completer
  --app-id: string # Exotel applet identifier used in Calls/connect
  --applet-url: any # Optional full applet URL override. Defaults to Exotel start_voice URL derived from account SID and app ID.
  --inbound-trunk-config: any
  --outbound-trunk-config: any
]: any -> record<phone_number_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/phone-numbers")
  let body = {phone_number: $phone_number, label: $label, supports_inbound: $supports_inbound, supports_outbound: $supports_outbound, provider: $provider, sid: $sid, token: $body_token, region_config: $region_config, account_sid: $account_sid, api_key: $api_key, api_token: $api_token, api_subdomain: $api_subdomain, app_id: $app_id, applet_url: $applet_url, inbound_trunk_config: $inbound_trunk_config, outbound_trunk_config: $outbound_trunk_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Phone Numbers
#
# GET /v1/convai/phone-numbers
# operationId: list_phone_numbers_route
export def "convai-phone-numbers route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --provider: string # Filter by telephony provider
  --agent-id: string # Filter by assigned agent ID
  --branch-id: string # Filter by assigned branch ID
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider" $provider "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "branch_id" $branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/phone-numbers" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Phone Number
#
# GET /v1/convai/phone-numbers/{phone_number_id}
# Discriminator (response): provider = twilio, exotel, sip_trunk
# operationId: get_phone_number_route
export def "convai-phone-numbers route-by-phone_number_id" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/phone-numbers/($phone_number_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Phone Number
#
# DELETE /v1/convai/phone-numbers/{phone_number_id}
# operationId: delete_phone_number_route
export def "convai-phone-numbers route-by-phone_number_id-1" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/phone-numbers/($phone_number_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Phone Number
#
# PATCH /v1/convai/phone-numbers/{phone_number_id}
# Discriminator (response): provider = twilio, exotel, sip_trunk
# operationId: update_phone_number_route
export def "convai-phone-numbers route-by-phone_number_id-2" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --agent-id: any
  --label: any
  --inbound-trunk-config: any
  --outbound-trunk-config: any
  --livekit-stack: any
  --store-sip-messages: any
  --environment: any # Environment to use for resolving environment variables on calls to this number.
  --branch-id: any # Agent branch to use for calls to this number.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/phone-numbers/($phone_number_id)")
  let body = {agent_id: $agent_id, label: $label, inbound_trunk_config: $inbound_trunk_config, outbound_trunk_config: $outbound_trunk_config, livekit_stack: $livekit_stack, store_sip_messages: $store_sip_messages, environment: $environment, branch_id: $branch_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Sip Messages For A Phone Number
#
# GET /v1/convai/phone-numbers/{phone_number_id}/sip-messages
# operationId: list_sip_messages
export def "convai-phone-numbers-sip-messages messages" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # default: 20
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<sip_messages: table<call_id: string, phone_numbers: list, local_address: string, remote_address: string, transport: string, raw_message: string, error_message: string, direction: string, created_at_unix_micro: int>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/phone-numbers/($phone_number_id)/sip-messages" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Calculate Expected Llm Usage
#
# POST /v1/convai/llm-usage/calculate
# operationId: get_public_llm_expected_cost_calculation
export def "convai-llm-usage-calculate calculation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prompt_length: int # Length of the prompt in characters.
  number_of_pages: int # Pages of content in PDF documents or URLs in the agent's knowledge base.
  --rag-enabled: oneof<nothing, bool> # Whether RAG is enabled.
]: any -> record<llm_prices: table<llm: string, price_per_minute: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/llm-usage/calculate")
  let body = {prompt_length: $prompt_length, number_of_pages: $number_of_pages, rag_enabled: $rag_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Available Llms
#
# GET /v1/convai/llm/list
# operationId: list_available_llms
export def "convai-llm-list llms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<llms: table<llm: string, is_checkpoint: bool, max_tokens_limit: int, max_context_limit: int, supports_image_input: bool, supports_document_input: bool, supports_parallel_tool_calls: bool, available_reasoning_efforts: any, deprecation_info: any, regional_processing_surcharge: any>, default_deprecation_config: record<warning_start_days: int, fallback_start_days: int, fallback_complete_days: int, fallback_start_percentage: int, fallback_complete_percentage: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/llm/list")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload File
#
# POST /v1/convai/conversations/{conversation_id}/files
# operationId: upload_file_route
export def "convai-conversations-files route-by-conversation_id" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  file: string # Image or PDF file to upload (format: binary)
]: any -> record<file_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/files")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete File Upload
#
# DELETE /v1/convai/conversations/{conversation_id}/files/{file_id}
# operationId: cancel_file_upload_route
export def "convai-conversations-files route-by-file_id-conversation_id" [
  file_id: string
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<file_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/files/($file_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Live Count
#
# GET /v1/convai/analytics/live-count
# operationId: get_live_count
export def "convai-analytics-live-count count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # The id of an agent to restrict the analytics to.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/analytics/live-count" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Knowledge Base Summaries By Ids
#
# GET /v1/convai/knowledge-base/summaries
# operationId: get_agent_knowledge_base_summaries_route
export def "convai-knowledge-base-summaries route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --document-ids: list # The ids of knowledge base documents.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "document_ids" $document_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/knowledge-base/summaries" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add To Knowledge Base
#
# POST /v1/convai/knowledge-base
# DEPRECATED
# operationId: add_documentation_to_knowledge_base
@deprecated
export def "convai-knowledge-base base" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # default: 
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: any # A custom, human-readable name for the document.
  --body-url: string # URL to a page of documentation that the agent will have access to in order to interact with users.
  --file: string # Documentation that the agent will have access to in order to interact with users. (format: binary)
]: any -> record<id: string, name: string, folder_path: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/knowledge-base" $qp)
  let body = {name: $name, url: $body_url, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Knowledge Base List
#
# GET /v1/convai/knowledge-base
# operationId: get_knowledge_base_list_route
@deprecated --flag show-only-owned-documents
export def "convai-knowledge-base route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many documents to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --search: string # If specified, the endpoint returns only such knowledge base documents whose names start with this string.
  --show-only-owned-documents: oneof<nothing, bool> # If set to true, the endpoint will return only documents owned by you (and not shared from somebody else). Deprecated: use created_by_user_id instead. (DEPRECATED, default: false)
  --created-by-user-id: string # Filter documents by creator user ID. When set, only documents created by this user are returned. Takes precedence over show_only_owned_documents. Use '@me' to refer to the authenticated user.
  --types: string # If present, the endpoint will return only documents of the given types.
  --parent-folder-id: string # If set, the endpoint will return only documents that are direct children of the given folder.
  --ancestor-folder-id: string # If set, the endpoint will return only documents that are descendants of the given folder.
  --folders-first: oneof<nothing, bool> # Whether folders should be returned first in the list of documents. (default: false)
  --sort-direction: string@sort-direction-completer # The direction to sort the results
  --sort-by: string # The field to sort the results by
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<documents: list<any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "show_only_owned_documents" $show_only_owned_documents "scalar") (serialize-qp "created_by_user_id" $created_by_user_id "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "parent_folder_id" $parent_folder_id "scalar") (serialize-qp "ancestor_folder_id" $ancestor_folder_id "scalar") (serialize-qp "folders_first" $folders_first "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/knowledge-base" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Url Document
#
# POST /v1/convai/knowledge-base/url
# operationId: create_url_document_route
export def "convai-knowledge-base-url route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --body-url: string # URL to a page of documentation that the agent will have access to in order to interact with users.
  --name: any # A custom, human-readable name for the document.
  --parent-folder-id: any # If set, the created document or folder will be placed inside the given folder.
  --enable-auto-sync: oneof<nothing, bool> # Whether to enable auto-sync for this URL document. (default: false)
  --auto-remove: oneof<nothing, bool> # Whether to automatically remove the document if the URL becomes unavailable. Only applicable when auto-sync is enabled. (default: false)
]: any -> record<id: string, name: string, folder_path: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/knowledge-base/url")
  let body = {url: $body_url, name: $name, parent_folder_id: $parent_folder_id, enable_auto_sync: $enable_auto_sync, auto_remove: $auto_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create File Document
#
# POST /v1/convai/knowledge-base/file
# operationId: create_file_document_route
export def "convai-knowledge-base-file route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  file: string # Documentation that the agent will have access to in order to interact with users. (format: binary)
  --name: any # A custom, human-readable name for the document.
  --parent-folder-id: any # If set, the created document or folder will be placed inside the given folder.
]: any -> record<id: string, name: string, folder_path: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/knowledge-base/file")
  let body = {file: $file, name: $name, parent_folder_id: $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create Text Document
#
# POST /v1/convai/knowledge-base/text
# operationId: create_text_document_route
export def "convai-knowledge-base-text route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  text: string # Text content to be added to the knowledge base.
  --name: any # A custom, human-readable name for the document.
  --parent-folder-id: any # If set, the created document or folder will be placed inside the given folder.
]: any -> record<id: string, name: string, folder_path: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/knowledge-base/text")
  let body = {text: $text, name: $name, parent_folder_id: $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Folder
#
# POST /v1/convai/knowledge-base/folder
# operationId: create_folder_route
export def "convai-knowledge-base-folder route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # A custom, human-readable name for the document.
  --parent-folder-id: any # If set, the created document or folder will be placed inside the given folder.
  --enable-auto-sync: oneof<nothing, bool> # Whether to enable auto-sync for this URL document. (default: false)
  --auto-remove: oneof<nothing, bool> # Whether to automatically remove the document if the URL becomes unavailable. Only applicable when auto-sync is enabled. (default: false)
]: any -> record<id: string, name: string, folder_path: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/knowledge-base/folder")
  let body = {name: $name, parent_folder_id: $parent_folder_id, enable_auto_sync: $enable_auto_sync, auto_remove: $auto_remove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Document
#
# PATCH /v1/convai/knowledge-base/{documentation_id}
# Discriminator (response): type = url, file, text, folder
# operationId: update_document_route
export def "convai-knowledge-base route-by-documentation_id" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: any # A custom, human-readable name for the document.
  --content: any # Updated content for the document. Only supported for text documents, URL documents with auto-sync disabled, and file documents.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)")
  let body = {name: $name, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Documentation From Knowledge Base
#
# GET /v1/convai/knowledge-base/{documentation_id}
# Discriminator (response): type = url, file, text, folder
# operationId: get_documentation_from_knowledge_base
export def "convai-knowledge-base base-by-documentation_id" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-id: string # default: 
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_id" $agent_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Knowledge Base Document Or Folder
#
# DELETE /v1/convai/knowledge-base/{documentation_id}
# operationId: delete_knowledge_base_document
export def "convai-knowledge-base document" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # If set to true, the document or folder will be deleted regardless of whether it is used by any agents and it will be removed from the dependent agents. For non-empty folders, this will also delete all child documents and folders. (default: false)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update File Document
#
# PATCH /v1/convai/knowledge-base/{documentation_id}/update-file
# Discriminator (response): type = url, file, text, folder
# operationId: update_file_document_route
export def "convai-knowledge-base-update-file route" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  file: string # Documentation that the agent will have access to in order to interact with users. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/update-file")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Compute Rag Indexes In Batch
#
# POST /v1/convai/knowledge-base/rag-index
# operationId: get_or_create_rag_indexes
# --items item shape: {document_id: string, create_if_missing: bool, model: "e5_mistral_7b_instruct"|"multilingual_e5_large_instruct"}
export def "convai-knowledge-base-rag-index indexes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  items: list # List of requested RAG indexes. Minimum 1, maximum 100 items. — item shape: {document_id: string, create_if_missing: bool, model: "e5_mistral_7b_instruct"|"multilingual_e5_large_instruct"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/knowledge-base/rag-index")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Rag Index Overview.
#
# GET /v1/convai/knowledge-base/rag-index
# operationId: get_rag_index_overview
export def "convai-knowledge-base-rag-index overview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<total_used_bytes: int, total_max_bytes: int, models: table<model: string, used_bytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/knowledge-base/rag-index")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh Url Document Content
#
# POST /v1/convai/knowledge-base/{documentation_id}/refresh
# Discriminator (response): type = url, file, text, folder
# operationId: refresh_url_document_route
export def "convai-knowledge-base-refresh route" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/refresh")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Compute Rag Index.
#
# POST /v1/convai/knowledge-base/{documentation_id}/rag-index
# operationId: rag_index_status
export def "convai-knowledge-base-rag-index status" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  model: string@model-completer # default: e5_mistral_7b_instruct
]: any -> record<id: string, model: string, status: string, progress_percentage: float, document_model_index_usage: record<used_bytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/rag-index")
  let body = {model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Rag Indexes Of The Specified Knowledgebase Document.
#
# GET /v1/convai/knowledge-base/{documentation_id}/rag-index
# operationId: get_rag_indexes
export def "convai-knowledge-base-rag-index indexes-by-documentation_id" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<indexes: table<id: string, model: string, status: string, progress_percentage: float, document_model_index_usage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/rag-index")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Rag Index.
#
# DELETE /v1/convai/knowledge-base/{documentation_id}/rag-index/{rag_index_id}
# operationId: delete_rag_index
export def "convai-knowledge-base-rag-index index" [
  documentation_id: string
  rag_index_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, model: string, status: string, progress_percentage: float, document_model_index_usage: record<used_bytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/rag-index/($rag_index_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Knowledge Base Content
#
# GET /v1/convai/knowledge-base/search
# operationId: search_knowledge_base_content_route
export def "convai-knowledge-base-search route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query text
  --page-size: int # How many documents to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --types: string # If present, the endpoint will return only documents of the given types.
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<results: table<document: any, search_snippet: any, score: float>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/knowledge-base/search" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dependent Agents List
#
# GET /v1/convai/knowledge-base/{documentation_id}/dependent-agents
# operationId: get_knowledge_base_dependent_agents
export def "convai-knowledge-base-dependent-agents agents" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dependent-type: string@dependent-type-completer # Type of dependent agents to return.
  --page-size: int # How many documents to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agents: list<any>, branches: table<agent_id: string, agent_name: string, branch_id: string, branch_name: string, is_main: bool>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dependent_type" $dependent_type "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/dependent-agents" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Document Content
#
# GET /v1/convai/knowledge-base/{documentation_id}/content
# operationId: get_knowledge_base_content
export def "convai-knowledge-base-content content" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/content")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Document Source File Url
#
# GET /v1/convai/knowledge-base/{documentation_id}/source-file-url
# operationId: get_knowledge_base_source_file_url
export def "convai-knowledge-base-source-file-url url" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<signed_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/source-file-url")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Documentation Chunk From Knowledge Base
#
# GET /v1/convai/knowledge-base/{documentation_id}/chunk/{chunk_id}
# operationId: get_documentation_chunk_from_knowledge_base
export def "convai-knowledge-base-chunk base" [
  documentation_id: string
  chunk_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --embedding-model: string # The embedding model used to retrieve the chunk.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, name: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embedding_model" $embedding_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/chunk/($chunk_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Rag Chunks For A Document
#
# GET /v1/convai/knowledge-base/{documentation_id}/chunks
# operationId: get_documentation_chunks_from_knowledge_base
export def "convai-knowledge-base-chunks base" [
  documentation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --embedding-model: string@embedding-model-completer # The embedding model used to retrieve the chunk. (default: e5_mistral_7b_instruct)
  --page-size: int # How many documents to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<chunks: table<id: string, name: string, content: string>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embedding_model" $embedding_model "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($documentation_id)/chunks" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move Entity To Folder
#
# POST /v1/convai/knowledge-base/{document_id}/move
# operationId: post_knowledge_base_move_route
export def "convai-knowledge-base-move route" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --move-to: any # The folder to move the entities to. If not set, the entities will be moved to the root folder.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/knowledge-base/($document_id)/move")
  let body = {move_to: $move_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Move Entities To Folder
#
# POST /v1/convai/knowledge-base/bulk-move
# operationId: post_knowledge_base_bulk_move_route
export def "convai-knowledge-base-bulk-move route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  document_ids: list # The ids of documents or folders from the knowledge base.
  --move-to: any # The folder to move the entities to. If not set, the entities will be moved to the root folder.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/knowledge-base/bulk-move")
  let body = {document_ids: $document_ids, move_to: $move_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Agent Conversation Topics
#
# GET /v1/convai/agents/{agent_id}/topics
# operationId: get_agent_topics_route
export def "convai-agents-topics route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<topics: table<topic_id: string, label: string, description: string, conversation_count: int, parent_topic_id: any, x_2d: any, y_2d: any>, window_start_unix_secs: int, window_end_unix_secs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/topics")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Tool
#
# POST /v1/convai/tools
# operationId: add_tool_route
export def "convai-tools route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  tool_config: any # Configuration for the tool
  --response-mocks: any # Mock responses with optional parameter conditions. Evaluated top-to-bottom; first match wins.
]: any -> record<id: string, tool_config: any, access_info: record<is_creator: bool, creator_name: string, creator_email: string, role: string, anonymous_access_level_override: any, access_source: any>, usage_stats: record<total_calls: int, avg_latency_secs: float>, response_mocks: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/tools")
  let body = {tool_config: $tool_config, response_mocks: $response_mocks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Tools
#
# GET /v1/convai/tools
# operationId: get_tools_route
@deprecated --flag show-only-owned-documents
export def "convai-tools route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # If specified, the endpoint returns only tools whose names start with this string.
  --page-size: string # How many documents to return at maximum. Can not exceed 100, defaults to 30.
  --show-only-owned-documents: oneof<nothing, bool> # If set to true, the endpoint will return only tools owned by you (and not shared from somebody else). Deprecated: use created_by_user_id instead. (DEPRECATED, default: false)
  --created-by-user-id: string # Filter tools by creator user ID. When set, only tools created by this user are returned. Takes precedence over show_only_owned_documents. Use '@me' to refer to the authenticated user.
  --types: string # If present, the endpoint will return only tools of the given types.
  --sort-direction: string@sort-direction-completer # The direction to sort the results
  --sort-by: string # The field to sort the results by
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<tools: table<id: string, tool_config: any, access_info: record, usage_stats: record, response_mocks: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "show_only_owned_documents" $show_only_owned_documents "scalar") (serialize-qp "created_by_user_id" $created_by_user_id "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/tools" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tool
#
# GET /v1/convai/tools/{tool_id}
# operationId: get_tool_route
export def "convai-tools route-by-tool_id" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, tool_config: any, access_info: record<is_creator: bool, creator_name: string, creator_email: string, role: string, anonymous_access_level_override: any, access_source: any>, usage_stats: record<total_calls: int, avg_latency_secs: float>, response_mocks: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/tools/($tool_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Tool
#
# PATCH /v1/convai/tools/{tool_id}
# operationId: update_tool_route
export def "convai-tools route-by-tool_id-1" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  tool_config: any # Configuration for the tool
  --response-mocks: any # Mock responses with optional parameter conditions. Evaluated top-to-bottom; first match wins.
]: any -> record<id: string, tool_config: any, access_info: record<is_creator: bool, creator_name: string, creator_email: string, role: string, anonymous_access_level_override: any, access_source: any>, usage_stats: record<total_calls: int, avg_latency_secs: float>, response_mocks: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/tools/($tool_id)")
  let body = {tool_config: $tool_config, response_mocks: $response_mocks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Tool
#
# DELETE /v1/convai/tools/{tool_id}
# operationId: delete_tool_route
export def "convai-tools route-by-tool_id-2" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # If set to true, the tool will be deleted regardless of whether it is used by any agents and it will be removed from the dependent agents and branches. (default: false)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/tools/($tool_id)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dependent Agents List
#
# GET /v1/convai/tools/{tool_id}/dependent-agents
# operationId: get_tool_dependent_agents_route
export def "convai-tools-dependent-agents route" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --page-size: int # How many documents to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agents: list<any>, branches: table<agent_id: string, agent_name: string, branch_id: string, branch_name: string, is_main: bool>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/tools/($tool_id)/dependent-agents" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tool Executions
#
# GET /v1/convai/tools/{tool_id}/executions
# operationId: get_tool_executions_route
export def "convai-tools-executions route" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --page-size: int # How many documents to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --is-error: string # Filter by error status. If not provided, returns all executions.
  --agent-id: string # Filter by agent ID.
  --branch-id: string # Filter by agent branch ID.
  --start-time: string # Filter executions from this Unix timestamp (inclusive).
  --end-time: string # Filter executions until this Unix timestamp (inclusive).
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<executions: table<tool_id: string, tool_request_id: string, conversation_id: string, agent_id: string, branch_id: any, timestamp: float, latency_secs: float, is_error: bool, request_payload: any, response_payload: any, error_message: any, error_type: any, id: string, tool_call_details: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "is_error" $is_error "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "branch_id" $branch_id "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/tools/($tool_id)/executions" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Convai Settings
#
# GET /v1/convai/settings
# operationId: get_settings_route
export def "convai-settings route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<conversation_initiation_client_data_webhook: any, webhooks: record<post_call_webhook_id: any, events: list<string>, transcript_format: string, send_audio: any>, can_use_mcp_servers: bool, rag_retention_period_days: int, conversation_embedding_retention_days: any, default_livekit_stack: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/settings")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Convai Settings
#
# PATCH /v1/convai/settings
# operationId: update_settings_route
# --webhooks shape: {post_call_webhook_id?: any, events?: list, transcript_format?: "json"|"opentelemetry", send_audio?: any}
export def "convai-settings route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --conversation-initiation-client-data-webhook: any
  --webhooks: record # shape: {post_call_webhook_id?: any, events?: list, transcript_format?: "json"|"opentelemetry", send_audio?: any}
  --can-use-mcp-servers: oneof<nothing, bool> # Whether the workspace can use MCP servers (default: false)
  --rag-retention-period-days: int # default: 10
  --conversation-embedding-retention-days: any # Days to retain conversation embeddings. None means use the system default (30 days).
  --default-livekit-stack: string@default-livekit-stack-completer # default: standard
]: any -> record<conversation_initiation_client_data_webhook: any, webhooks: record<post_call_webhook_id: any, events: list<string>, transcript_format: string, send_audio: any>, can_use_mcp_servers: bool, rag_retention_period_days: int, conversation_embedding_retention_days: any, default_livekit_stack: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/settings")
  let body = {conversation_initiation_client_data_webhook: $conversation_initiation_client_data_webhook, webhooks: $webhooks, can_use_mcp_servers: $can_use_mcp_servers, rag_retention_period_days: $rag_retention_period_days, conversation_embedding_retention_days: $conversation_embedding_retention_days, default_livekit_stack: $default_livekit_stack} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Convai Dashboard Settings
#
# GET /v1/convai/settings/dashboard
# operationId: get_dashboard_settings_route
export def "convai-settings-dashboard route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<charts: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/settings/dashboard")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Convai Dashboard Settings
#
# PATCH /v1/convai/settings/dashboard
# operationId: update_dashboard_settings_route
export def "convai-settings-dashboard route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --charts: list
]: any -> record<charts: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/settings/dashboard")
  let body = {charts: $charts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Convai Workspace Secret
#
# POST /v1/convai/secrets
# operationId: create_secret_route
export def "convai-secrets route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  type: string
  name: string
  value: string
]: any -> record<type: string, secret_id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/secrets")
  let body = {type: $type, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Convai Workspace Secrets
#
# GET /v1/convai/secrets
# operationId: get_secrets_route
export def "convai-secrets route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: string # How many documents to return at maximum. Can not exceed 100. If not provided, returns all secrets.
  --dependency-limit: string # Maximum number of dependent resources (tools, agents, phone numbers) to return per secret. Can not exceed 100.
  --search: string # If specified, returns only secrets whose names start with this string.
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<secrets: table<type: string, secret_id: string, name: string, used_by: record>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "dependency_limit" $dependency_limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/secrets" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Convai Workspace Secret
#
# GET /v1/convai/secrets/{secret_id}
# operationId: get_secret_route
export def "convai-secrets route-by-secret_id" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<type: string, secret_id: string, name: string, used_by: record<tools: list<any>, tools_has_more: bool, agents: list<any>, agents_has_more: bool, phone_numbers: list<record>, phone_numbers_has_more: bool, mcp_servers: list<any>, others: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/secrets/($secret_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Convai Workspace Secret
#
# DELETE /v1/convai/secrets/{secret_id}
# operationId: delete_secret_route
export def "convai-secrets route-by-secret_id-1" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/secrets/($secret_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Convai Workspace Secret
#
# PATCH /v1/convai/secrets/{secret_id}
# operationId: update_secret_route
export def "convai-secrets route-by-secret_id-2" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  type: string
  name: string
  value: string
]: any -> record<type: string, secret_id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/secrets/($secret_id)")
  let body = {type: $type, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Secret Dependencies By Type
#
# GET /v1/convai/secrets/{secret_id}/dependencies/{resource_type}
# operationId: get_secret_dependencies_route
export def "convai-secrets-dependencies route" [
  secret_id: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many dependency items to return per page. (default: 20)
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<dependencies: any, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/secrets/($secret_id)/dependencies/($resource_type)" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit A Batch Call Request.
#
# POST /v1/convai/batch-calling/submit
# operationId: create_batch_call
# --recipients item shape: {id?: any, phone_number?: any, whatsapp_user_id?: any, conversation_initiation_client_data?: any}
# --telephony_call_config shape: {ringing_timeout_secs?: int}
export def "convai-batch-calling-submit call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  call_name: string
  agent_id: string
  recipients: list # item shape: {id?: any, phone_number?: any, whatsapp_user_id?: any, conversation_initiation_client_data?: any}
  --scheduled-time-unix: any
  --agent-phone-number-id: any
  --whatsapp-params: any
  --timezone: any
  --branch-id: any
  --environment: any
  --telephony-call-config: record # shape: {ringing_timeout_secs?: int}
  --target-concurrency-limit: any # Maximum number of simultaneous calls for this batch. When set, dispatch is governed by this limit rather than workspace/agent capacity percentages.
]: any -> record<id: string, phone_number_id: any, phone_provider: any, whatsapp_params: any, name: string, agent_id: string, branch_id: any, environment: any, created_at_unix: int, scheduled_time_unix: int, timezone: any, total_calls_dispatched: int, total_calls_scheduled: int, total_calls_finished: int, last_updated_at_unix: int, status: string, retry_count: int, telephony_call_config: record<ringing_timeout_secs: int>, target_concurrency_limit: any, agent_name: string, branch_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/batch-calling/submit")
  let body = {call_name: $call_name, agent_id: $agent_id, recipients: $recipients, scheduled_time_unix: $scheduled_time_unix, agent_phone_number_id: $agent_phone_number_id, whatsapp_params: $whatsapp_params, timezone: $timezone, branch_id: $branch_id, environment: $environment, telephony_call_config: $telephony_call_config, target_concurrency_limit: $target_concurrency_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Batch Calls For A Workspace.
#
# GET /v1/convai/batch-calling/workspace
# operationId: get_workspace_batch_calls
export def "convai-batch-calling-workspace calls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 100
  --last-doc: string
  --agent-id: string # Filter batch calls to a single agent.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<batch_calls: table<id: string, phone_number_id: any, phone_provider: any, whatsapp_params: any, name: string, agent_id: string, branch_id: any, environment: any, created_at_unix: int, scheduled_time_unix: int, timezone: any, total_calls_dispatched: int, total_calls_scheduled: int, total_calls_finished: int, last_updated_at_unix: int, status: string, retry_count: int, telephony_call_config: record, target_concurrency_limit: any, agent_name: string, branch_name: any>, next_doc: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "last_doc" $last_doc "scalar") (serialize-qp "agent_id" $agent_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/batch-calling/workspace" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get A Batch Call By Id.
#
# GET /v1/convai/batch-calling/{batch_id}
# operationId: get_batch_call
export def "convai-batch-calling call-by-batch_id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, phone_number_id: any, phone_provider: any, whatsapp_params: any, name: string, agent_id: string, branch_id: any, environment: any, created_at_unix: int, scheduled_time_unix: int, timezone: any, total_calls_dispatched: int, total_calls_scheduled: int, total_calls_finished: int, last_updated_at_unix: int, status: string, retry_count: int, telephony_call_config: record<ringing_timeout_secs: int>, target_concurrency_limit: any, agent_name: string, branch_name: any, recipients: table<id: string, phone_number: any, whatsapp_user_id: any, status: string, created_at_unix: int, updated_at_unix: int, conversation_id: any, conversation_initiation_client_data: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/batch-calling/($batch_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete A Batch Call.
#
# DELETE /v1/convai/batch-calling/{batch_id}
# operationId: delete_batch_call
export def "convai-batch-calling call-by-batch_id-1" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/batch-calling/($batch_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel A Batch Call.
#
# POST /v1/convai/batch-calling/{batch_id}/cancel
# operationId: cancel_batch_call
export def "convai-batch-calling-cancel call" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, phone_number_id: any, phone_provider: any, whatsapp_params: any, name: string, agent_id: string, branch_id: any, environment: any, created_at_unix: int, scheduled_time_unix: int, timezone: any, total_calls_dispatched: int, total_calls_scheduled: int, total_calls_finished: int, last_updated_at_unix: int, status: string, retry_count: int, telephony_call_config: record<ringing_timeout_secs: int>, target_concurrency_limit: any, agent_name: string, branch_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/batch-calling/($batch_id)/cancel")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry A Batch Call.
#
# POST /v1/convai/batch-calling/{batch_id}/retry
# operationId: retry_batch_call
export def "convai-batch-calling-retry call" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, phone_number_id: any, phone_provider: any, whatsapp_params: any, name: string, agent_id: string, branch_id: any, environment: any, created_at_unix: int, scheduled_time_unix: int, timezone: any, total_calls_dispatched: int, total_calls_scheduled: int, total_calls_finished: int, last_updated_at_unix: int, status: string, retry_count: int, telephony_call_config: record<ringing_timeout_secs: int>, target_concurrency_limit: any, agent_name: string, branch_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/batch-calling/($batch_id)/retry")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Handle An Outbound Call Via Sip Trunk
#
# POST /v1/convai/sip-trunk/outbound-call
# operationId: handle_sip_trunk_outbound_call
# --telephony_call_config shape: {ringing_timeout_secs?: int}
export def "convai-sip-trunk-outbound-call call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  agent_id: string
  agent_phone_number_id: string
  to_number: string
  --conversation-initiation-client-data: any
  --telephony-call-config: record # shape: {ringing_timeout_secs?: int}
]: any -> record<success: bool, message: string, conversation_id: any, sip_call_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/sip-trunk/outbound-call")
  let body = {agent_id: $agent_id, agent_phone_number_id: $agent_phone_number_id, to_number: $to_number, conversation_initiation_client_data: $conversation_initiation_client_data, telephony_call_config: $telephony_call_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Mcp Server
#
# POST /v1/convai/mcp-servers
# operationId: create_mcp_server_route
# --config shape: {approval_policy?: "auto_approve_all"|"require_approval_all"|"require_approval_per_tool", tool_approval_hashes?: list, transport?: "SSE"|"STREAMABLE_HTTP", url: any, secret_token?: any, request_headers?: record, auth_connection?: any, name: string, description?: string, force_pre_tool_speech?: bool, pre_tool_speech?: "auto"|"force"|"off", disable_interruptions?: bool, tool_call_sound?: any, tool_call_sound_behavior?: "auto"|"always", execution_mode?: "immediate"|"post_tool_speech"|"async", response_timeout_secs?: int, tool_config_overrides?: list, disable_compression?: bool}
export def "convai-mcp-servers route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  config: record # shape: {approval_policy?: "auto_approve_all"|"require_approval_all"|"require_approval_per_tool", tool_approval_hashes?: list, transport?: "SSE"|"STREAMABLE_HTTP", url: any, secret_token?: any, request_headers?: record, auth_connection?: any, name: string, description?: string, force_pre_tool_speech?: bool, pre_tool_speech?: "auto"|"force"|"off", disable_interruptions?: bool, tool_call_sound?: any, tool_call_sound_behavior?: "auto"|"always", execution_mode?: "immediate"|"post_tool_speech"|"async", response_timeout_secs?: int, tool_config_overrides?: list, disable_compression?: bool}
]: any -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/mcp-servers")
  let body = {config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Mcp Servers
#
# GET /v1/convai/mcp-servers
# operationId: list_mcp_servers_route
export def "convai-mcp-servers route-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<mcp_servers: table<id: string, config: record, access_info: any, dependent_agents: list, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/mcp-servers")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Mcp Server
#
# GET /v1/convai/mcp-servers/{mcp_server_id}
# operationId: get_mcp_route
export def "convai-mcp-servers route-by-mcp_server_id" [
  mcp_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Mcp Server
#
# DELETE /v1/convai/mcp-servers/{mcp_server_id}
# operationId: delete_mcp_server_route
export def "convai-mcp-servers route-by-mcp_server_id-1" [
  mcp_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Mcp Server Configuration
#
# PATCH /v1/convai/mcp-servers/{mcp_server_id}
# operationId: update_mcp_server_config_route
@deprecated --flag force-pre-tool-speech
export def "convai-mcp-servers route-by-mcp_server_id-2" [
  mcp_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --approval-policy: any # The approval mode to set for the MCP server
  --force-pre-tool-speech: any # DEPRECATED: use `pre_tool_speech` instead. If set, overrides the server's force_pre_tool_speech setting for this tool. (DEPRECATED)
  --pre-tool-speech: any # If set, overrides the server's pre_tool_speech setting for this tool.
  --disable-interruptions: any # If set, overrides the server's disable_interruptions setting for this tool
  --tool-call-sound: any # Predefined tool call sound type to play during tool execution for all tools from this MCP server
  --tool-call-sound-behavior: any # Determines when the tool call sound should play for all tools from this MCP server
  --execution-mode: any # If set, overrides the server's execution_mode setting for this tool
  --response-timeout-secs: any # The maximum time in seconds to wait for each MCP tool call to complete.
  --request-headers: any # The headers to include in requests to the MCP server
  --disable-compression: any # Whether to disable HTTP compression for this MCP server
  --secret-token: any # Optional secret token for authentication with this MCP server
  --auth-connection: any # Optional auth connection to use for authentication with this MCP server
]: any -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)")
  let body = {approval_policy: $approval_policy, force_pre_tool_speech: $force_pre_tool_speech, pre_tool_speech: $pre_tool_speech, disable_interruptions: $disable_interruptions, tool_call_sound: $tool_call_sound, tool_call_sound_behavior: $tool_call_sound_behavior, execution_mode: $execution_mode, response_timeout_secs: $response_timeout_secs, request_headers: $request_headers, disable_compression: $disable_compression, secret_token: $secret_token, auth_connection: $auth_connection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Mcp Server Tools
#
# GET /v1/convai/mcp-servers/{mcp_server_id}/tools
# operationId: list_mcp_server_tools_route
export def "convai-mcp-servers-tools route" [
  mcp_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<success: bool, tools: table<name: string, title: any, description: any, inputSchema: record, outputSchema: any, icons: any, annotations: any, _meta: any, execution: any>, error_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/tools")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Mcp Server Approval Policy
#
# PATCH /v1/convai/mcp-servers/{mcp_server_id}/approval-policy
# DEPRECATED
# operationId: update_mcp_server_approval_policy_route
@deprecated
export def "convai-mcp-servers-approval-policy route" [
  mcp_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  approval_policy: string@approval-policy-completer # Defines the MCP server-level approval policy for tool execution. (default: require_approval_all)
]: any -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/approval-policy")
  let body = {approval_policy: $approval_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Mcp Server Tool Approval
#
# POST /v1/convai/mcp-servers/{mcp_server_id}/tool-approvals
# operationId: add_mcp_server_tool_approval_route
export def "convai-mcp-servers-tool-approvals route-by-mcp_server_id" [
  mcp_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  tool_name: string # The name of the MCP tool
  tool_description: string # The description of the MCP tool
  --input-schema: record # The input schema of the MCP tool (the schema defined on the MCP server before ElevenLabs does any extra processing)
  --approval-policy: string@approval-policy-completer-1 # Defines the tool-level approval policy. (default: requires_approval)
]: any -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/tool-approvals")
  let body = {tool_name: $tool_name, tool_description: $tool_description, input_schema: $input_schema, approval_policy: $approval_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Mcp Server Tool Approval
#
# DELETE /v1/convai/mcp-servers/{mcp_server_id}/tool-approvals/{tool_name}
# operationId: remove_mcp_server_tool_approval_route
export def "convai-mcp-servers-tool-approvals route-by-mcp_server_id-tool_name" [
  mcp_server_id: string
  tool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/tool-approvals/($tool_name)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Mcp Tool Configuration Override
#
# POST /v1/convai/mcp-servers/{mcp_server_id}/tool-configs
# operationId: add_mcp_tool_config_override_route
@deprecated --flag force-pre-tool-speech
export def "convai-mcp-servers-tool-configs route-by-mcp_server_id" [
  mcp_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --force-pre-tool-speech: any # DEPRECATED: use `pre_tool_speech` instead. If set, overrides the server's force_pre_tool_speech setting for this tool. (DEPRECATED)
  --pre-tool-speech: any # If set, overrides the server's pre_tool_speech setting for this tool.
  --disable-interruptions: any # If set, overrides the server's disable_interruptions setting for this tool
  --tool-call-sound: any # If set, overrides the server's tool_call_sound setting for this tool
  --tool-call-sound-behavior: any # If set, overrides the server's tool_call_sound_behavior setting for this tool
  --execution-mode: any # If set, overrides the server's execution_mode setting for this tool
  --response-timeout-secs: any # If set, overrides the server's response timeout for this MCP tool.
  --assignments: any # Dynamic variable assignments for this MCP tool
  --input-overrides: any # Mapping of json path to input override configuration
  --response-mocks: any # Mock responses with optional parameter conditions. Evaluated top-to-bottom; first match wins.
  tool_name: string # The name of the MCP tool
]: any -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/tool-configs")
  let body = {force_pre_tool_speech: $force_pre_tool_speech, pre_tool_speech: $pre_tool_speech, disable_interruptions: $disable_interruptions, tool_call_sound: $tool_call_sound, tool_call_sound_behavior: $tool_call_sound_behavior, execution_mode: $execution_mode, response_timeout_secs: $response_timeout_secs, assignments: $assignments, input_overrides: $input_overrides, response_mocks: $response_mocks, tool_name: $tool_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Mcp Tool Configuration Override
#
# GET /v1/convai/mcp-servers/{mcp_server_id}/tool-configs/{tool_name}
# operationId: get_mcp_tool_config_override_route
export def "convai-mcp-servers-tool-configs route-by-mcp_server_id-tool_name" [
  mcp_server_id: string
  tool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<tool_name: string, force_pre_tool_speech: any, pre_tool_speech: any, disable_interruptions: any, tool_call_sound: any, tool_call_sound_behavior: any, execution_mode: any, response_timeout_secs: any, assignments: table<source: string, dynamic_variable: string, value_path: string, sanitize: bool, preserve_native_type: bool>, input_overrides: any, response_mocks: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/tool-configs/($tool_name)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Mcp Tool Configuration Override
#
# PATCH /v1/convai/mcp-servers/{mcp_server_id}/tool-configs/{tool_name}
# operationId: update_mcp_tool_config_override_route
@deprecated --flag force-pre-tool-speech
export def "convai-mcp-servers-tool-configs route-by-mcp_server_id-tool_name-1" [
  mcp_server_id: string
  tool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --force-pre-tool-speech: any # DEPRECATED: use `pre_tool_speech` instead. If set, overrides the server's force_pre_tool_speech setting for this tool. (DEPRECATED)
  --pre-tool-speech: any # If set, overrides the server's pre_tool_speech setting for this tool.
  --disable-interruptions: any # If set, overrides the server's disable_interruptions setting for this tool
  --tool-call-sound: any # If set, overrides the server's tool_call_sound setting for this tool
  --tool-call-sound-behavior: any # If set, overrides the server's tool_call_sound_behavior setting for this tool
  --execution-mode: any # If set, overrides the server's execution_mode setting for this tool
  --response-timeout-secs: any # If set, overrides the server's response timeout for this MCP tool.
  --assignments: any # Dynamic variable assignments for this MCP tool
  --input-overrides: any # Mapping of json path to input override configuration
  --response-mocks: any # Mock responses with optional parameter conditions. Evaluated top-to-bottom; first match wins.
]: any -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/tool-configs/($tool_name)")
  let body = {force_pre_tool_speech: $force_pre_tool_speech, pre_tool_speech: $pre_tool_speech, disable_interruptions: $disable_interruptions, tool_call_sound: $tool_call_sound, tool_call_sound_behavior: $tool_call_sound_behavior, execution_mode: $execution_mode, response_timeout_secs: $response_timeout_secs, assignments: $assignments, input_overrides: $input_overrides, response_mocks: $response_mocks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Mcp Tool Configuration Override
#
# DELETE /v1/convai/mcp-servers/{mcp_server_id}/tool-configs/{tool_name}
# operationId: remove_mcp_tool_config_override_route
export def "convai-mcp-servers-tool-configs route-by-mcp_server_id-tool_name-2" [
  mcp_server_id: string
  tool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, config: record<approval_policy: string, tool_approval_hashes: list<record>, transport: string, url: any, secret_token: any, request_headers: record, auth_connection: any, name: string, description: string, force_pre_tool_speech: bool, pre_tool_speech: string, disable_interruptions: bool, tool_call_sound: any, tool_call_sound_behavior: string, execution_mode: string, response_timeout_secs: int, tool_config_overrides: list<record>, disable_compression: bool>, access_info: any, dependent_agents: list<any>, metadata: record<created_at: int, owner_user_id: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/mcp-servers/($mcp_server_id)/tool-configs/($tool_name)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Whatsapp Account
#
# GET /v1/convai/whatsapp-accounts/{phone_number_id}
# operationId: get_whatsapp_account
export def "convai-whatsapp-accounts account-by-phone_number_id" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<business_account_id: string, phone_number_id: string, business_account_name: string, phone_number_name: string, phone_number: string, assigned_agent_id: any, enable_messaging: bool, enable_audio_message_response: bool, assigned_agent_name: any, is_token_expired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/whatsapp-accounts/($phone_number_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Whatsapp Account
#
# PATCH /v1/convai/whatsapp-accounts/{phone_number_id}
# operationId: update_whatsapp_account
export def "convai-whatsapp-accounts account-by-phone_number_id-1" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --assigned-agent-id: any
  --enable-messaging: any
  --enable-audio-message-response: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/whatsapp-accounts/($phone_number_id)")
  let body = {assigned_agent_id: $assigned_agent_id, enable_messaging: $enable_messaging, enable_audio_message_response: $enable_audio_message_response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Whatsapp Account
#
# DELETE /v1/convai/whatsapp-accounts/{phone_number_id}
# operationId: delete_whatsapp_account
export def "convai-whatsapp-accounts account-by-phone_number_id-2" [
  phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/whatsapp-accounts/($phone_number_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Whatsapp Accounts
#
# GET /v1/convai/whatsapp-accounts
# operationId: list_whatsapp_accounts
export def "convai-whatsapp-accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<items: table<business_account_id: string, phone_number_id: string, business_account_name: string, phone_number_name: string, phone_number: string, assigned_agent_id: any, enable_messaging: bool, enable_audio_message_response: bool, assigned_agent_name: any, is_token_expired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/whatsapp-accounts")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create A New Branch
#
# POST /v1/convai/agents/{agent_id}/branches
# operationId: create_branch_route
export def "convai-agents-branches route-by-agent_id" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  parent_version_id: string # ID of the version to branch from
  name: string # Name of the branch. It is unique within the agent.
  description: string # Description for the branch
  --conversation-config: any # Changes to apply to conversation config
  --platform-settings: any # Changes to apply to platform settings
  --workflow: any # Updated workflow definition
]: any -> record<created_branch_id: string, created_version_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/branches")
  let body = {parent_version_id: $parent_version_id, name: $name, description: $description, conversation_config: $conversation_config, platform_settings: $platform_settings, workflow: $workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Agent Branches
#
# GET /v1/convai/agents/{agent_id}/branches
# operationId: get_branches_route
export def "convai-agents-branches route-by-agent_id-1" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-archived: oneof<nothing, bool> # Whether archived branches should be included (default: false)
  --limit: int # How many results at most should be returned (default: 100)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<meta: record<total: any, page: any, page_size: any>, results: table<id: string, name: string, agent_id: string, description: string, created_at: int, last_committed_at: int, is_archived: bool, protection_status: string, access_info: any, current_live_percentage: float, parent_branch_id: any, draft_exists: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/branches" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Agent Branch
#
# GET /v1/convai/agents/{agent_id}/branches/{branch_id}
# operationId: get_branch_route
export def "convai-agents-branches route-by-agent_id-branch_id" [
  agent_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, name: string, agent_id: string, description: string, created_at: int, last_committed_at: int, is_archived: bool, protection_status: string, access_info: any, current_live_percentage: float, parent_branch: any, most_recent_versions: table<id: string, agent_id: string, branch_id: string, version_description: string, seq_no_in_branch: int, time_committed_secs: int, parents: record, access_info: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/branches/($branch_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Agent Branch
#
# PATCH /v1/convai/agents/{agent_id}/branches/{branch_id}
# operationId: update_branch_route
export def "convai-agents-branches route-by-agent_id-branch_id-1" [
  agent_id: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: any # New name for the branch. Must be unique within the agent.
  --is-archived: any # Whether the branch should be archived
  --protection-status: any # The protection level for the branch
]: any -> record<id: string, name: string, agent_id: string, description: string, created_at: int, last_committed_at: int, is_archived: bool, protection_status: string, access_info: any, current_live_percentage: float, parent_branch: any, most_recent_versions: table<id: string, agent_id: string, branch_id: string, version_description: string, seq_no_in_branch: int, time_committed_secs: int, parents: record, access_info: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/branches/($branch_id)")
  let body = {name: $name, is_archived: $is_archived, protection_status: $protection_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Agent Version Metadata
#
# GET /v1/convai/agents/{agent_id}/versions/{version_id}
# operationId: get_version_metadata_route
export def "convai-agents-versions route" [
  agent_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<id: string, agent_id: string, branch_id: string, version_description: string, seq_no_in_branch: int, time_committed_secs: int, parents: record<in_branch_parent_id: any, out_of_branch_parent_id: any, merged_into_branch_id: any, merged_from_branch_id: any, merged_from_version_id: any>, access_info: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/versions/($version_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge A Branch Into A Target Branch
#
# POST /v1/convai/agents/{agent_id}/branches/{source_branch_id}/merge
# operationId: merge_branch_into_target
export def "convai-agents-branches-merge target" [
  agent_id: string
  source_branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target-branch-id: string # The ID of the target branch to merge into.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --archive-source-branch: oneof<nothing, bool> # Whether to archive the source branch after merging (default: true)
  --force: oneof<nothing, bool> # Force source branch changes onto the target, overriding timestamp-based conflict resolution (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_branch_id" $target_branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/branches/($source_branch_id)/merge" $qp)
  let body = {archive_source_branch: $archive_source_branch, force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Or Update Deployments
#
# POST /v1/convai/agents/{agent_id}/deployments
# operationId: create_agent_deployment_route
# --deployment_request shape: {requests: list}
export def "convai-agents-deployments route" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  deployment_request: record # shape: {requests: list}
]: any -> record<traffic_percentage_branch_id_map: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/deployments")
  let body = {deployment_request: $deployment_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Agent Draft
#
# POST /v1/convai/agents/{agent_id}/drafts
# operationId: create_agent_draft_route
# --workflow shape: {edges?: record, nodes?: record, prevent_subagent_loops?: bool}
export def "convai-agents-drafts route-by-agent_id" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch-id: string # The ID of the agent branch to use
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  conversation_config: record # Conversation config for the draft
  platform_settings: record # Platform settings for the draft
  workflow: record # e.g. {edges: {entry_to_tool_a: {forward_condition: {condition: Tool A condition}, source: entry_node, target: tool_node_a}, start_to_entry: {forward_condition: {}, source: start_node, target: entry_node}, tool_a_to_failure: {forward_condition: {successful: false}, source: tool_node_a, target: failure_node}, tool_a_to_tool_b: {forward_condition: {successful: true}, source: tool_node_a, target: tool_node_b}, tool_b_to_agent_transfer: {forward_condition: {}, source: tool_node_b, target: success_transfer}, tool_b_to_conversation: {forward_condition: {condition: Conversation condition}, source: tool_node_b, target: success_conversation}, tool_b_to_end: {forward_condition: {condition: End condition}, source: tool_node_b, target: success_end}, tool_b_to_phone: {forward_condition: {expression: {children: [{name: force_phone_transfer}, {prompt: Phone condition, value_schema: {description: Phone condition, type: boolean}}, {left: {name: mode}, right: {value: dev}}]}}, source: tool_node_b, target: success_phone}}, nodes: {entry_node: {conversation_config: {}, edge_order: [entry_to_tool_a], label: Entry}, failure_node: {conversation_config: {}, label: Failure}, start_node: {edge_order: [start_to_entry]}, success_conversation: {conversation_config: {}, label: Success A}, success_end: {}, success_phone: {transfer_destination: {phone_number: +1234567890}}, success_transfer: {agent_id: success_transfer_agent}, tool_node_a: {edge_order: [tool_a_to_failure, tool_a_to_tool_b], tools: [{tool_id: tool_a}, {tool_id: tool_b}]}, tool_node_b: {edge_order: [tool_b_to_conversation, tool_b_to_end, tool_b_to_phone, tool_b_to_agent_transfer], tools: [{tool_id: tool_a}]}}} — shape: {edges?: record, nodes?: record, prevent_subagent_loops?: bool}
  name: string # Name for the draft
  --tags: any # Tags to help classify and filter the agent
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch_id" $branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/drafts" $qp)
  let body = {conversation_config: $conversation_config, platform_settings: $platform_settings, workflow: $workflow, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Agent Draft
#
# DELETE /v1/convai/agents/{agent_id}/drafts
# operationId: delete_agent_draft_route
export def "convai-agents-drafts route-by-agent_id-1" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch-id: string # The ID of the agent branch to use
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch_id" $branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/convai/agents/($agent_id)/drafts" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Speech Engines
#
# GET /v1/speech-engine
# operationId: list_speech_engines
export def "speech-engine engines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # How many Speech Engines to return at maximum. Can not exceed 100, defaults to 30. (default: 30)
  --search: string # Search term to filter Speech Engines by name
  --sort-direction: string@sort-direction-completer # The direction to sort the results
  --sort-by: string # The field to sort the results by
  --cursor: string # Used for fetching next page. Cursor is returned in the response.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<speech_engines: table<speech_engine_id: string, name: string, created_at_unix_secs: int, tags: list, access_info: record>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/speech-engine" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Speech Engine
#
# POST /v1/speech-engine
# operationId: create_speech_engine
# --speech_engine shape: {ws_url: string, request_headers?: record}
# --asr shape: {quality?: "high", provider?: "elevenlabs"|"scribe_realtime", user_input_audio_format?: "pcm_8000"|"pcm_16000"|"pcm_22050"|"pcm_24000"|"pcm_44100"|"pcm_48000"|"ulaw_8000", keywords?: list}
# --tts shape: {model_id?: "eleven_turbo_v2"|"eleven_turbo_v2_5"|"eleven_flash_v2"|"eleven_flash_v2_5"|"eleven_multilingual_v2"|"eleven_v3_conversational", voice_id?: string, supported_voices?: list, expressive_mode?: bool, suggested_audio_tags?: list, agent_output_audio_format?: "pcm_8000"|"pcm_16000"|"pcm_22050"|"pcm_24000"|"pcm_44100"|"pcm_48000"|"ulaw_8000", optimize_streaming_latency?: "0"|"1"|"2"|"3"|"4", stability?: float, speed?: float, similarity_boost?: float, text_normalisation_type?: "system_prompt"|"elevenlabs", pronunciation_dictionary_locators?: list}
# --turn shape: {turn_timeout?: float, initial_wait_time?: any, silence_end_call_timeout?: float, mode?: "silence"|"turn", turn_eagerness?: "patient"|"normal"|"eager", spelling_patience?: "auto"|"off", speculative_turn?: bool, retranscribe_on_turn_timeout?: bool, turn_model?: "turn_v2"|"turn_v3"}
# --conversation shape: {text_only?: bool, max_duration_seconds?: int, client_events?: list, file_input?: record, monitoring_enabled?: bool, monitoring_events?: list, source_attribution?: bool}
# --privacy shape: {record_voice?: bool, retention_days?: int, delete_transcript_and_pii?: bool, delete_audio?: bool, apply_to_existing_conversations?: bool, zero_retention_mode?: bool, conversation_history_redaction?: record}
# --call_limits shape: {agent_concurrency_limit?: int, daily_limit?: int, bursting_enabled?: bool}
# --overrides shape: {first_message?: bool}
export def "speech-engine engine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: string # Name of the speech engine (default: Speech Engine)
  speech_engine: record # shape: {ws_url: string, request_headers?: record}
  --asr: record # e.g. {keywords: [hello, world], provider: scribe_realtime, quality: high, user_input_audio_format: pcm_16000} — shape: {quality?: "high", provider?: "elevenlabs"|"scribe_realtime", user_input_audio_format?: "pcm_8000"|"pcm_16000"|"pcm_22050"|"pcm_24000"|"pcm_44100"|"pcm_48000"|"ulaw_8000", keywords?: list}
  --tts: record # e.g. {agent_output_audio_format: pcm_16000, model_id: eleven_turbo_v2, optimize_streaming_latency: 3, pronunciation_dictionary_locators: [], similarity_boost: 0.8, speed: 1.0, stability: 0.5, voice_id: cjVigY5qzO86Huf0OWal} — shape: {model_id?: "eleven_turbo_v2"|"eleven_turbo_v2_5"|"eleven_flash_v2"|"eleven_flash_v2_5"|"eleven_multilingual_v2"|"eleven_v3_conversational", voice_id?: string, supported_voices?: list, expressive_mode?: bool, suggested_audio_tags?: list, agent_output_audio_format?: "pcm_8000"|"pcm_16000"|"pcm_22050"|"pcm_24000"|"pcm_44100"|"pcm_48000"|"ulaw_8000", optimize_streaming_latency?: "0"|"1"|"2"|"3"|"4", stability?: float, speed?: float, similarity_boost?: float, text_normalisation_type?: "system_prompt"|"elevenlabs", pronunciation_dictionary_locators?: list}
  --turn: record # e.g. {interruption_ignore_terms: [], mode: turn, retranscribe_on_turn_timeout: false, silence_end_call_timeout: -1.0, speculative_turn: false, spelling_patience: auto, turn_eagerness: normal, turn_timeout: 7.0} — shape: {turn_timeout?: float, initial_wait_time?: any, silence_end_call_timeout?: float, mode?: "silence"|"turn", turn_eagerness?: "patient"|"normal"|"eager", spelling_patience?: "auto"|"off", speculative_turn?: bool, retranscribe_on_turn_timeout?: bool, turn_model?: "turn_v2"|"turn_v3"}
  --conversation: record # e.g. {client_events: [audio, interruption], max_duration_seconds: 600} — shape: {text_only?: bool, max_duration_seconds?: int, client_events?: list, file_input?: record, monitoring_enabled?: bool, monitoring_events?: list, source_attribution?: bool}
  --privacy: record # e.g. {apply_to_existing_conversations: false, delete_audio: false, delete_transcript_and_pii: false, record_voice: true, retention_days: -1, zero_retention_mode: false} — shape: {record_voice?: bool, retention_days?: int, delete_transcript_and_pii?: bool, delete_audio?: bool, apply_to_existing_conversations?: bool, zero_retention_mode?: bool, conversation_history_redaction?: record}
  --call-limits: record # e.g. {agent_concurrency_limit: -1, bursting_enabled: true, daily_limit: 100000} — shape: {agent_concurrency_limit?: int, daily_limit?: int, bursting_enabled?: bool}
  --language: string # Language for the speech engine (default: en)
  --tags: list # Tags for categorization
  --overrides: record # shape: {first_message?: bool}
]: any -> record<speech_engine_id: string, name: string, speech_engine: record<ws_url: string, request_headers: record>, asr: record<quality: string, provider: string, user_input_audio_format: string, keywords: list<string>>, tts: record<model_id: string, voice_id: string, supported_voices: list<record>, expressive_mode: bool, suggested_audio_tags: list<record>, agent_output_audio_format: string, optimize_streaming_latency: int, stability: float, speed: float, similarity_boost: float, text_normalisation_type: string, pronunciation_dictionary_locators: list<record>>, turn: record<turn_timeout: float, initial_wait_time: any, silence_end_call_timeout: float, mode: string, turn_eagerness: string, spelling_patience: string, speculative_turn: bool, retranscribe_on_turn_timeout: bool, turn_model: string>, conversation: record<text_only: bool, max_duration_seconds: int, client_events: list<string>, file_input: record<enabled: bool, max_files_per_conversation: int>, monitoring_enabled: bool, monitoring_events: list<string>, source_attribution: bool>, privacy: record<record_voice: bool, retention_days: int, delete_transcript_and_pii: bool, delete_audio: bool, apply_to_existing_conversations: bool, zero_retention_mode: bool, conversation_history_redaction: record<enabled: bool, entities: list>>, call_limits: record<agent_concurrency_limit: int, daily_limit: int, bursting_enabled: bool>, language: string, tags: list<string>, overrides: record<first_message: bool>, metadata: record<created_at_unix_secs: int, updated_at_unix_secs: int, created_from: string, last_updated_from: string>, access_info: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/speech-engine")
  let body = {name: $name, speech_engine: $speech_engine, asr: $asr, tts: $tts, turn: $turn, conversation: $conversation, privacy: $privacy, call_limits: $call_limits, language: $language, tags: $tags, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Speech Engine
#
# GET /v1/speech-engine/{speech_engine_id}
# operationId: get_speech_engine
export def "speech-engine engine-by-speech_engine_id" [
  speech_engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<speech_engine_id: string, name: string, speech_engine: record<ws_url: string, request_headers: record>, asr: record<quality: string, provider: string, user_input_audio_format: string, keywords: list<string>>, tts: record<model_id: string, voice_id: string, supported_voices: list<record>, expressive_mode: bool, suggested_audio_tags: list<record>, agent_output_audio_format: string, optimize_streaming_latency: int, stability: float, speed: float, similarity_boost: float, text_normalisation_type: string, pronunciation_dictionary_locators: list<record>>, turn: record<turn_timeout: float, initial_wait_time: any, silence_end_call_timeout: float, mode: string, turn_eagerness: string, spelling_patience: string, speculative_turn: bool, retranscribe_on_turn_timeout: bool, turn_model: string>, conversation: record<text_only: bool, max_duration_seconds: int, client_events: list<string>, file_input: record<enabled: bool, max_files_per_conversation: int>, monitoring_enabled: bool, monitoring_events: list<string>, source_attribution: bool>, privacy: record<record_voice: bool, retention_days: int, delete_transcript_and_pii: bool, delete_audio: bool, apply_to_existing_conversations: bool, zero_retention_mode: bool, conversation_history_redaction: record<enabled: bool, entities: list>>, call_limits: record<agent_concurrency_limit: int, daily_limit: int, bursting_enabled: bool>, language: string, tags: list<string>, overrides: record<first_message: bool>, metadata: record<created_at_unix_secs: int, updated_at_unix_secs: int, created_from: string, last_updated_from: string>, access_info: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/speech-engine/($speech_engine_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Speech Engine
#
# PATCH /v1/speech-engine/{speech_engine_id}
# operationId: update_speech_engine
export def "speech-engine engine-by-speech_engine_id-1" [
  speech_engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: any
  --speech-engine: any
  --asr: any
  --tts: any
  --turn: any
  --conversation: any
  --privacy: any
  --call-limits: any
  --language: any
  --tags: any
  --overrides: any
]: any -> record<speech_engine_id: string, name: string, speech_engine: record<ws_url: string, request_headers: record>, asr: record<quality: string, provider: string, user_input_audio_format: string, keywords: list<string>>, tts: record<model_id: string, voice_id: string, supported_voices: list<record>, expressive_mode: bool, suggested_audio_tags: list<record>, agent_output_audio_format: string, optimize_streaming_latency: int, stability: float, speed: float, similarity_boost: float, text_normalisation_type: string, pronunciation_dictionary_locators: list<record>>, turn: record<turn_timeout: float, initial_wait_time: any, silence_end_call_timeout: float, mode: string, turn_eagerness: string, spelling_patience: string, speculative_turn: bool, retranscribe_on_turn_timeout: bool, turn_model: string>, conversation: record<text_only: bool, max_duration_seconds: int, client_events: list<string>, file_input: record<enabled: bool, max_files_per_conversation: int>, monitoring_enabled: bool, monitoring_events: list<string>, source_attribution: bool>, privacy: record<record_voice: bool, retention_days: int, delete_transcript_and_pii: bool, delete_audio: bool, apply_to_existing_conversations: bool, zero_retention_mode: bool, conversation_history_redaction: record<enabled: bool, entities: list>>, call_limits: record<agent_concurrency_limit: int, daily_limit: int, bursting_enabled: bool>, language: string, tags: list<string>, overrides: record<first_message: bool>, metadata: record<created_at_unix_secs: int, updated_at_unix_secs: int, created_from: string, last_updated_from: string>, access_info: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/speech-engine/($speech_engine_id)")
  let body = {name: $name, speech_engine: $speech_engine, asr: $asr, tts: $tts, turn: $turn, conversation: $conversation, privacy: $privacy, call_limits: $call_limits, language: $language, tags: $tags, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Speech Engine
#
# DELETE /v1/speech-engine/{speech_engine_id}
# operationId: delete_speech_engine
export def "speech-engine engine-by-speech_engine_id-2" [
  speech_engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/speech-engine/($speech_engine_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run Conversation Analysis
#
# POST /v1/convai/conversations/{conversation_id}/analysis/run
# operationId: run_conversation_analysis
export def "convai-conversations-analysis-run analysis" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<agent_id: string, agent_name: any, conversation_product: string, status: string, user_id: any, branch_id: any, version_id: any, metadata: record<start_time_unix_secs: int, accepted_time_unix_secs: any, call_duration_secs: int, cost: any, deletion_settings: record<deletion_time_unix_secs: any, deleted_logs_at_time_unix_secs: any, deleted_audio_at_time_unix_secs: any, deleted_transcript_at_time_unix_secs: any, delete_transcript_and_pii: bool, delete_audio: bool>, feedback: record<type: any, overall_score: any, likes: int, dislikes: int, rating: any, comment: any>, authorization_method: string, charging: record<dev_discount: bool, is_burst: bool, tier: any, llm_usage: record, llm_price: any, llm_charge: any, call_charge: any, free_minutes_consumed: float, free_llm_dollars_consumed: float, tts_usage: any, asr_usage: any>, phone_call: any, batch_call: any, termination_reason: string, error: any, warnings: list<string>, main_language: any, rag_usage: any, text_only: bool, features_usage: record<language_detection: record, transfer_to_agent: record, transfer_to_number: record, multivoice: record, dtmf_tones: record, external_mcp_servers: record, pii_zrm_workspace: bool, pii_zrm_agent: bool, tool_dynamic_variable_updates: record, is_livekit: bool, voicemail_detection: record, dtmf_input: record, workflow: record, agent_testing: record, versioning: record, file_input: record>, eleven_assistant: record<is_eleven_assistant: bool>, initiator_id: any, conversation_initiation_source: string, conversation_initiation_source_version: any, timezone: any, async_metadata: any, whatsapp: any, sms: any, agent_created_from: string, agent_last_updated_from: string, voice_rewards: list<record>>, analysis: any, visited_agents: table<agent_id: string, branch_id: any>, conversation_initiation_client_data: record<conversation_config_override: record<asr: any, turn: any, tts: any, conversation: any, agent: any>, custom_llm_extra_body: record, user_id: any, source_info: record<source: any, version: any>, branch_id: any, environment: any, starting_workflow_node_id: any, dynamic_variables: record>, environment: string, conversation_id: string, has_audio: bool, has_user_audio: bool, has_response_audio: bool, transcript: table<role: string, agent_metadata: any, message: any, multivoice_message: any, tool_calls: list, tool_results: list, feedback: any, llm_override: any, time_in_call_secs: int, conversation_turn_metrics: any, rag_retrieval_info: any, llm_usage: any, interrupted: bool, original_message: any, source_medium: any, source_event_id: any, used_static_kb_document_ids: list, file_input: any, contextual_update_info: any>, tag_ids: list<string>, otlp_traces: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/conversations/($conversation_id)/analysis/run")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Environment Variables
#
# GET /v1/convai/environment-variables
# operationId: list_environment_variables
export def "convai-environment-variables variables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # Pagination cursor from previous response
  --page-size: int # Number of items to return (1-100) (default: 100)
  --label: string # Filter by exact label match
  --environment: string # Filter to only return variables that have this environment. When specified, the values dict in the response will only contain this environment.
  --type: string # Filter by variable type
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<environment_variables: table<label: string, created_at_unix_secs: int, updated_at_unix_secs: int, created_by_user_id: any, type: string, id: string, workspace_id: string, values: any>, next_cursor: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "environment" $environment "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/convai/environment-variables" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Environment Variable
#
# POST /v1/convai/environment-variables
# Discriminator (request): type = string, secret, auth_connection
# operationId: create_environment_variable
export def "convai-environment-variables variable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  type: string@type-completer
  --label: string # Unique label for the environment variable.
  --values: record # Environment-specific values. Must include 'production' key.
]: any -> record<label: string, created_at_unix_secs: int, updated_at_unix_secs: int, created_by_user_id: any, type: string, id: string, workspace_id: string, values: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/convai/environment-variables")
  let body = {type: $type, label: $label, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Environment Variable
#
# GET /v1/convai/environment-variables/{env_var_id}
# operationId: get_environment_variable
export def "convai-environment-variables variable-by-env_var_id" [
  env_var_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<label: string, created_at_unix_secs: int, updated_at_unix_secs: int, created_by_user_id: any, type: string, id: string, workspace_id: string, values: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/environment-variables/($env_var_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Environment Variable
#
# PATCH /v1/convai/environment-variables/{env_var_id}
# operationId: update_environment_variable
export def "convai-environment-variables variable-by-env_var_id-1" [
  env_var_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  values: record # Values to replace. Set to null to remove an environment (except 'production').
]: any -> record<label: string, created_at_unix_secs: int, updated_at_unix_secs: int, created_by_user_id: any, type: string, id: string, workspace_id: string, values: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/convai/environment-variables/($env_var_id)")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate Composition Plan
#
# POST /v1/music/plan
# operationId: compose_plan
export def "music-plan plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  prompt: string # A simple text prompt to compose a plan from.
  --music-length-ms: any # The length of the composition plan to generate in milliseconds. Must be between 3000ms and 600000ms. Optional - if not provided, the model will choose a length based on the prompt.
  --source-composition-plan: any # An optional composition plan to use as a source for the new composition plan.
  --model-id: string@model-id-completer-1 # The model to use for the generation. (default: music_v1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/music/plan")
  let body = {prompt: $prompt, music_length_ms: $music_length_ms, source_composition_plan: $source_composition_plan, model_id: $model_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compose Music
#
# POST /v1/music
# operationId: generate
@deprecated --flag music-prompt
export def "music generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --prompt: any # A simple text prompt to generate a song from. Cannot be used in conjunction with `composition_plan`.
  --generation-mode: any # Optional generation mode hint for prompt-based music generation. Can only be used with `prompt`.
  --music-prompt: any # A music prompt. Deprecated. Use `composition_plan` instead. (DEPRECATED)
  --lyrics-text: any # The lyrics text to use for the generation.
  --composition-plan: any # A detailed composition plan to guide music generation. Cannot be used in conjunction with `prompt`.
  --music-length-ms: any # The length of the song to generate in milliseconds. Used only in conjunction with `prompt`. Must be between 3000ms and 600000ms. Optional - if not provided, the model will choose a length based on the prompt.
  --model-id: string@model-id-completer-1 # The model to use for the generation. (default: music_v1)
  --seed: any # Random seed to initialize the music generation process. Providing the same seed with the same parameters can help achieve more consistent results, but exact reproducibility is not guaranteed and outputs may change across system updates. Cannot be used in conjunction with prompt.
  --force-instrumental: oneof<nothing, bool> # If true, guarantees that the generated song will be instrumental. If false, the song may or may not be instrumental depending on the `prompt`. Can only be used with `prompt`. (default: false)
  --finetune-id: any # The ID of the finetune to use for the generation
  --finetune-strength: float # How strongly the finetune influences the generation. Defaults to 1.0 (full strength). Lower values soften the influence of the finetune, leaving more room for prompt-level steering. Only meaningful when `finetune_id` is also provided. (default: 1.0)
  --use-phonetic-names: oneof<nothing, bool> # If true, proper names in the prompt will be phonetically spelled in the lyrics for better pronunciation by the music model. The original names will be restored in word timestamps. (default: false)
  --respect-sections-durations: oneof<nothing, bool> # Controls how strictly section durations in the `composition_plan` are enforced. Only used with `composition_plan`. When set to true, the model will precisely respect each section's `duration_ms` from the plan. When set to false, the model may adjust individual section durations which will generally lead to better generation quality and improved latency, while always preserving the total song duration from the plan. (default: true)
  --store-for-inpainting: oneof<nothing, bool> # Whether to store the generated song for inpainting. Only available to enterprise clients with access to the inpainting feature. (default: false)
  --sign-with-c2pa: oneof<nothing, bool> # Whether to sign the generated song with C2PA. Applicable only for mp3 files. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/music" $qp)
  let body = {prompt: $prompt, generation_mode: $generation_mode, music_prompt: $music_prompt, lyrics_text: $lyrics_text, composition_plan: $composition_plan, music_length_ms: $music_length_ms, model_id: $model_id, seed: $seed, force_instrumental: $force_instrumental, finetune_id: $finetune_id, finetune_strength: $finetune_strength, use_phonetic_names: $use_phonetic_names, respect_sections_durations: $respect_sections_durations, store_for_inpainting: $store_for_inpainting, sign_with_c2pa: $sign_with_c2pa} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compose Music With A Detailed Response
#
# POST /v1/music/detailed
# operationId: compose_detailed
@deprecated --flag music-prompt
export def "music-detailed detailed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --prompt: any # A simple text prompt to generate a song from. Cannot be used in conjunction with `composition_plan`.
  --generation-mode: any # Optional generation mode hint for prompt-based music generation. Can only be used with `prompt`.
  --music-prompt: any # A music prompt. Deprecated. Use `composition_plan` instead. (DEPRECATED)
  --lyrics-text: any # The lyrics text to use for the generation.
  --composition-plan: any # A detailed composition plan to guide music generation. Cannot be used in conjunction with `prompt`.
  --music-length-ms: any # The length of the song to generate in milliseconds. Used only in conjunction with `prompt`. Must be between 3000ms and 600000ms. Optional - if not provided, the model will choose a length based on the prompt.
  --model-id: string@model-id-completer-1 # The model to use for the generation. (default: music_v1)
  --seed: any # Random seed to initialize the music generation process. Providing the same seed with the same parameters can help achieve more consistent results, but exact reproducibility is not guaranteed and outputs may change across system updates. Cannot be used in conjunction with prompt.
  --force-instrumental: oneof<nothing, bool> # If true, guarantees that the generated song will be instrumental. If false, the song may or may not be instrumental depending on the `prompt`. Can only be used with `prompt`. (default: false)
  --finetune-id: any # The ID of the finetune to use for the generation
  --finetune-strength: float # How strongly the finetune influences the generation. Defaults to 1.0 (full strength). Lower values soften the influence of the finetune, leaving more room for prompt-level steering. Only meaningful when `finetune_id` is also provided. (default: 1.0)
  --use-phonetic-names: oneof<nothing, bool> # If true, proper names in the prompt will be phonetically spelled in the lyrics for better pronunciation by the music model. The original names will be restored in word timestamps. (default: false)
  --respect-sections-durations: oneof<nothing, bool> # Controls how strictly section durations in the `composition_plan` are enforced. Only used with `composition_plan`. When set to true, the model will precisely respect each section's `duration_ms` from the plan. When set to false, the model may adjust individual section durations which will generally lead to better generation quality and improved latency, while always preserving the total song duration from the plan. (default: true)
  --store-for-inpainting: oneof<nothing, bool> # Whether to store the generated song for inpainting. Only available to enterprise clients with access to the inpainting feature. (default: false)
  --with-timestamps: oneof<nothing, bool> # Whether to return the timestamps of the words in the generated song. (default: false)
  --sign-with-c2pa: oneof<nothing, bool> # Whether to sign the generated song with C2PA. Applicable only for mp3 files. (default: false)
  --model-style-prefix: string@model-style-prefix-completer # default: music
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/music/detailed" $qp)
  let body = {prompt: $prompt, generation_mode: $generation_mode, music_prompt: $music_prompt, lyrics_text: $lyrics_text, composition_plan: $composition_plan, music_length_ms: $music_length_ms, model_id: $model_id, seed: $seed, force_instrumental: $force_instrumental, finetune_id: $finetune_id, finetune_strength: $finetune_strength, use_phonetic_names: $use_phonetic_names, respect_sections_durations: $respect_sections_durations, store_for_inpainting: $store_for_inpainting, with_timestamps: $with_timestamps, sign_with_c2pa: $sign_with_c2pa, model_style_prefix: $model_style_prefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "multipart/mixed"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stream Composed Music
#
# POST /v1/music/stream
# operationId: stream_compose
@deprecated --flag music-prompt
export def "music-stream compose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --prompt: any # A simple text prompt to generate a song from. Cannot be used in conjunction with `composition_plan`.
  --generation-mode: any # Optional generation mode hint for prompt-based music generation. Can only be used with `prompt`.
  --music-prompt: any # A music prompt. Deprecated. Use `composition_plan` instead. (DEPRECATED)
  --lyrics-text: any # The lyrics text to use for the generation.
  --composition-plan: any # A detailed composition plan to guide music generation. Cannot be used in conjunction with `prompt`.
  --music-length-ms: any # The length of the song to generate in milliseconds. Used only in conjunction with `prompt`. Must be between 3000ms and 600000ms. Optional - if not provided, the model will choose a length based on the prompt.
  --model-id: string@model-id-completer-1 # The model to use for the generation. (default: music_v1)
  --seed: any # Random seed to initialize the music generation process. Providing the same seed with the same parameters can help achieve more consistent results, but exact reproducibility is not guaranteed and outputs may change across system updates. Cannot be used in conjunction with prompt.
  --force-instrumental: oneof<nothing, bool> # If true, guarantees that the generated song will be instrumental. If false, the song may or may not be instrumental depending on the `prompt`. Can only be used with `prompt`. (default: false)
  --finetune-id: any # The ID of the finetune to use for the generation
  --finetune-strength: float # How strongly the finetune influences the generation. Defaults to 1.0 (full strength). Lower values soften the influence of the finetune, leaving more room for prompt-level steering. Only meaningful when `finetune_id` is also provided. (default: 1.0)
  --use-phonetic-names: oneof<nothing, bool> # If true, proper names in the prompt will be phonetically spelled in the lyrics for better pronunciation by the music model. The original names will be restored in word timestamps. (default: false)
  --store-for-inpainting: oneof<nothing, bool> # Whether to store the generated song for inpainting. Only available to enterprise clients with access to the inpainting feature. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/music/stream" $qp)
  let body = {prompt: $prompt, generation_mode: $generation_mode, music_prompt: $music_prompt, lyrics_text: $lyrics_text, composition_plan: $composition_plan, music_length_ms: $music_length_ms, model_id: $model_id, seed: $seed, force_instrumental: $force_instrumental, finetune_id: $finetune_id, finetune_strength: $finetune_strength, use_phonetic_names: $use_phonetic_names, store_for_inpainting: $store_for_inpainting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "audio/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload Music
#
# POST /v1/music/upload
# operationId: upload_song
export def "music-upload song" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  file: string # The audio file to upload. (format: binary)
  --extract-composition-plan: oneof<nothing, bool> # Whether to generate and return the composition plan for the uploaded song. If True, the response will include the composition_plan but will increase the latency. (default: false)
  --with-timestamps: oneof<nothing, bool> # Whether to transcribe the uploaded song and return word-level timestamps. If True, the response will include words_timestamps but will increase the latency. (default: false)
]: any -> record<song_id: string, composition_plan: any, words_timestamps: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/music/upload")
  let body = {file: $file, extract_composition_plan: $extract_composition_plan, with_timestamps: $with_timestamps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Stem Separation
#
# POST /v1/music/stem-separation
# operationId: separate_song_stems
export def "music-stem-separation stems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-format: string@output-format-completer # Output format of the generated audio. Formatted as codec_sample_rate_bitrate. So an mp3 with 22.05kHz sample rate at 32kbs is represented as mp3_22050_32. MP3 with 192kbps bitrate requires you to be subscribed to Creator tier or above. PCM with 44.1kHz sample rate requires you to be subscribed to Pro tier or above. Note that the μ-law format (sometimes written mu-law, often approximated as u-law) is commonly used for Twilio audio inputs.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  file: string # The audio file to separate into stems. (format: binary)
  --stem-variation-id: string@stem-variation-id-completer # The id of the stem variation to use. (default: six_stems_v1)
  --sign-with-c2pa: oneof<nothing, bool> # Whether to sign the generated song with C2PA. Applicable only for mp3 files. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_format" $output_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/music/stem-separation" $qp)
  let body = {file: $file, stem_variation_id: $stem_variation_id, sign_with_c2pa: $sign_with_c2pa} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create Order
#
# POST /v1/productions/orders
# operationId: public_create_order
export def "productions-orders order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --sandbox: oneof<nothing, bool> # When true, creates a sandbox order that auto-progresses without producer intervention. (default: false)
]: any -> record<order_id: string, sandbox: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/productions/orders")
  let body = {sandbox: $sandbox} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Orders
#
# GET /v1/productions/orders
# operationId: public_list_orders
export def "productions-orders orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Maximum number of orders to return per page. (default: 20)
  --offset: int # Number of orders to skip for pagination. (default: 0)
  --status: string # Filter orders by one or more statuses.
  --start-date: string # Filter orders created on or after this date.
  --end-date: string # Filter orders created on or before this date.
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<orders: table<order_id: string, name: string, state: string, total_amount_usd: any, sandbox: bool, submitted_at: any, updated_at: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/productions/orders" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Order
#
# GET /v1/productions/orders/{order_id}
# operationId: public_get_order
export def "productions-orders order-by-order_id" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<order_id: string, name: string, state: string, items: table<item_id: string, item: any, quote: any>, total_amount_usd: any, sandbox: bool, created_at: string, submitted_at: any, paid_at: any, accepted_at: any, completed_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Order
#
# PATCH /v1/productions/orders/{order_id}
# operationId: public_update_order
# --request shape: {name: string}
export def "productions-orders order-by-order_id-1" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  request: record # e.g. {name: Spanish Dubs} — shape: {name: string}
]: any -> record<name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)")
  let body = {request: $request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register Media
#
# POST /v1/productions/orders/{order_id}/media
# operationId: public_register_media
export def "productions-orders-media media" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  declared_language: string # The language code of the media content (e.g. 'en', 'es-ES'). Must be a supported source language for some order item kind.
  --media: any # The media file to upload. Mutually exclusive with media_url.
  --media-url: any # A URL to fetch the media file from. Mutually exclusive with media.
  --media-url-filename: any # The filename for URL-sourced media (e.g. 'example.mp4'). Required when using media_url.
  --media-url-content-type: any # The MIME type for URL-sourced media (e.g. 'video/mp4'). Required when using media_url.
]: any -> record<media_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)/media")
  let body = {declared_language: $declared_language, media: $media, media_url: $media_url, media_url_filename: $media_url_filename, media_url_content_type: $media_url_content_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Media Info
#
# GET /v1/productions/orders/{order_id}/media/{media_id}
# operationId: public_get_media_info
export def "productions-orders-media info" [
  order_id: string
  media_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<media_id: string, name: string, content_type: string, language: any, signed_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)/media/($media_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert Order Item
#
# POST /v1/productions/orders/{order_id}/items
# operationId: public_upsert_order_item
# --request shape: {item: any, item_id?: any}
export def "productions-orders-items item-by-order_id" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  request: record # shape: {item: any, item_id?: any}
]: any -> record<item_id: string, quote: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)/items")
  let body = {request: $request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Order Item
#
# DELETE /v1/productions/orders/{order_id}/items/{item_id}
# operationId: public_remove_order_item
export def "productions-orders-items item-by-order_id-item_id" [
  order_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)/items/($item_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Order
#
# POST /v1/productions/orders/{order_id}/submit
# operationId: public_submit_order
export def "productions-orders-submit order" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<order_id: string, state: string, submitted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)/submit")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Order Deliverables
#
# GET /v1/productions/orders/{order_id}/deliverables
# operationId: public_get_order_deliverables
export def "productions-orders-deliverables deliverables" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<deliverables: table<signed_url: string, content_type: string, name: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/($order_id)/deliverables")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Available Languages
#
# GET /v1/productions/orders/languages/{order_item_kind}
# Discriminator (response): kind = pair, single
# operationId: public_get_available_languages
export def "productions-orders-languages languages" [
  order_item_kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/productions/orders/languages/($order_item_kind)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Pvc Voice
#
# POST /v1/voices/pvc
# operationId: create_pvc_voice
export def "voices-pvc voice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  name: string # The name that identifies this voice. This will be displayed in the dropdown of the website.
  language: string # Language used in the samples.
  --description: any # Description to use for the created voice.
  --labels: any # Labels for the voice. Keys can be language, accent, gender, or age.
]: any -> record<voice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/voices/pvc")
  let body = {name: $name, language: $language, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit Pvc Voice
#
# POST /v1/voices/pvc/{voice_id}
# operationId: edit_pvc_voice
export def "voices-pvc voice-by-voice_id" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --name: string # The name that identifies this voice. This will be displayed in the dropdown of the website.
  --language: string # Language used in the samples.
  --description: any # Description to use for the created voice.
  --labels: any # Labels for the voice. Keys can be language, accent, gender, or age.
]: any -> record<voice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)")
  let body = {name: $name, language: $language, description: $description, labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Samples To Pvc Voice
#
# POST /v1/voices/pvc/{voice_id}/samples
# operationId: add_pvc_voice_samples
export def "voices-pvc-samples samples" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  files: list # Audio files used to create the voice.
  --remove-background-noise: oneof<nothing, bool> # If set will remove background noise for voice samples using our audio isolation model. If the samples do not include background noise, it can make the quality worse. (default: false)
]: any -> table<sample_id: string, file_name: string, mime_type: string, size_bytes: int, hash: string, duration_secs: any, remove_background_noise: any, has_isolated_audio: any, has_isolated_audio_preview: any, speaker_separation: any, trim_start: any, trim_end: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples")
  let body = {files: $files, remove_background_noise: $remove_background_noise} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update Pvc Voice Sample
#
# POST /v1/voices/pvc/{voice_id}/samples/{sample_id}
# operationId: edit_pvc_voice_sample
export def "voices-pvc-samples sample-by-voice_id-sample_id" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --remove-background-noise: oneof<nothing, bool> # If set will remove background noise for voice samples using our audio isolation model. If the samples do not include background noise, it can make the quality worse. (default: false)
  --selected-speaker-ids: any # Speaker IDs to be used for PVC training. Make sure you send all the speaker IDs you want to use for PVC training in one request because the last request will override the previous ones.
  --trim-start-time: any # The start time of the audio to be used for PVC training. Time should be in milliseconds
  --trim-end-time: any # The end time of the audio to be used for PVC training. Time should be in milliseconds
  --file-name: any # The name of the audio file to be used for PVC training.
]: any -> record<voice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples/($sample_id)")
  let body = {remove_background_noise: $remove_background_noise, selected_speaker_ids: $selected_speaker_ids, trim_start_time: $trim_start_time, trim_end_time: $trim_end_time, file_name: $file_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Pvc Voice Sample
#
# DELETE /v1/voices/pvc/{voice_id}/samples/{sample_id}
# operationId: delete_pvc_voice_sample
export def "voices-pvc-samples sample-by-voice_id-sample_id-1" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples/($sample_id)")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Voice Sample Audio
#
# GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/audio
# operationId: get_pvc_sample_audio
export def "voices-pvc-samples-audio audio" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --remove-background-noise: oneof<nothing, bool> # If set will remove background noise for voice samples using our audio isolation model. If the samples do not include background noise, it can make the quality worse. (default: false)
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<audio_base_64: string, voice_id: string, sample_id: string, media_type: string, duration_secs: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remove_background_noise" $remove_background_noise "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples/($sample_id)/audio" $qp)
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Voice Sample Visual Waveform
#
# GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/waveform
# operationId: get_pvc_sample_visual_waveform
export def "voices-pvc-samples-waveform waveform" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<sample_id: string, visual_waveform: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples/($sample_id)/waveform")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Speaker Separation Status
#
# GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/speakers
# operationId: get_pvc_sample_speakers
export def "voices-pvc-samples-speakers speakers" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<voice_id: string, sample_id: string, status: string, speakers: any, selected_speaker_ids: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples/($sample_id)/speakers")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start Speaker Separation
#
# POST /v1/voices/pvc/{voice_id}/samples/{sample_id}/separate-speakers
# operationId: start_speaker_separation
export def "voices-pvc-samples-separate-speakers separation" [
  voice_id: string
  sample_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples/($sample_id)/separate-speakers")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Separated Speaker Audio
#
# GET /v1/voices/pvc/{voice_id}/samples/{sample_id}/speakers/{speaker_id}/audio
# operationId: get_speaker_audio
export def "voices-pvc-samples-speakers-audio audio" [
  voice_id: string
  sample_id: string
  speaker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> record<audio_base_64: string, media_type: string, duration_secs: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/samples/($sample_id)/speakers/($speaker_id)/audio")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pvc Voice Captcha
#
# GET /v1/voices/pvc/{voice_id}/captcha
# operationId: get_pvc_voice_captcha
export def "voices-pvc-captcha captcha-by-voice_id" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/captcha")
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Pvc Voice Captcha
#
# POST /v1/voices/pvc/{voice_id}/captcha
# operationId: verify_pvc_voice_captcha
export def "voices-pvc-captcha captcha-by-voice_id-1" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  recording: string # Audio recording of the user (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/captcha")
  let body = {recording: $recording} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Run Pvc Training
#
# POST /v1/voices/pvc/{voice_id}/train
# operationId: run_pvc_voice_training
export def "voices-pvc-train training" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --model-id: any # The model ID to use for the conversion.
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/train")
  let body = {model_id: $model_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request Manual Verification
#
# POST /v1/voices/pvc/{voice_id}/verification
# operationId: request_pvc_manual_verification
export def "voices-pvc-verification verification" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  files: list # Verification documents
  --extra-text: any # Extra text to be used in the manual verification process.
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/voices/pvc/($voice_id)/verification")
  let body = {files: $files, extra_text: $extra_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Workspace Usage
#
# POST /v1/workspace/analytics/query/usage-by-product-over-time
# operationId: usage_by_product_over_time
export def "workspace-analytics-query-usage-by-product-over-time time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  start_time: int # Start of the time range as a Unix timestamp in milliseconds. Must be at least 2020-01-01.
  end_time: int # End of the time range as a Unix timestamp in milliseconds. Must be at least 2020-01-01.
  --interval-seconds: int # Bucket size in seconds. Each row in the response covers this many seconds of the selected time range. For example, pass 3600 for hourly buckets or 86400 for daily buckets. Whether `time_zone` shifts bucket boundaries depends on this value: whole-day multiples (e.g. 86400) align to local midnight; whole-hour multiples up to 24 hours (e.g. 3600, 14400) align to local hour boundaries from midnight; sub-hour values and other sizes remain UTC-anchored regardless of `time_zone`. (default: 60)
  --group-by: any
  --filters: any
  --time-zone: string # IANA time zone identifier (e.g. 'America/New_York', 'Europe/London', 'UTC') used to align bucket boundaries for eligible `interval_seconds` values. Whole-day multiples start at local midnight; whole-hour multiples up to 24 hours align to local hour boundaries from midnight. Sub-hour intervals and other bucket sizes remain UTC-anchored regardless of this setting. Defaults to UTC. (default: UTC)
]: any -> record<columns: list<string>, column_types: list<string>, rows: list<list<any>>, column_units: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/analytics/query/usage-by-product-over-time")
  let body = {start_time: $start_time, end_time: $end_time, interval_seconds: $interval_seconds, group_by: $group_by, filters: $filters, time_zone: $time_zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Api Requests
#
# POST /v1/workspace/analytics/requests
# operationId: requests_list
export def "workspace-analytics-requests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xi-api-key: string # Your API key. This is required by most endpoints to access our API programmatically. You can view your xi-api-key using the 'Profile' tab on the website.
  --start-time: any # Start of the time range as a Unix timestamp in milliseconds.
  --end-time: any # End of the time range as a Unix timestamp in milliseconds.
  --limit: int # default: 100
  --body-sort: any # Optional timestamp sort direction. If omitted, defaults to desc when end_time is provided, otherwise asc.
  --filters: any
  --search: any
]: any -> record<columns: list<string>, column_types: list<string>, rows: list<list<any>>, column_units: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workspace/analytics/requests")
  let body = {start_time: $start_time, end_time: $end_time, limit: $limit, sort: $body_sort, filters: $filters, search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xi-api-key": $xi_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Redirect To Mintlify
#
# GET /docs
# operationId: redirect_to_mintlify
export def "docs mintlify" [
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
  let full_url = (build-url $base "/docs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
