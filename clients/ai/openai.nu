# Auto-generated client for OpenAI API v2.3.0
# Source: https://raw.githubusercontent.com/openai/openai-openapi/master/openapi.yaml
# Auth: --token flag or $env.OPENAI_API_TOKEN

const BASE_URL = "https://api.openai.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENAI_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.openai.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["asc" "desc"] }
def response-format-completer [] { ["aac" "flac" "mp3" "opus" "pcm" "wav"] }
def stream-format-completer [] { ["audio" "sse"] }
def accept-completer [] { ["application/octet-stream" "text/event-stream"] }
def response-format-completer-1 [] { ["diarized_json" "json" "srt" "text" "verbose_json" "vtt"] }
def accept-completer-1 [] { ["application/json" "text/event-stream"] }
def response-format-completer-2 [] { ["json" "srt" "text" "verbose_json" "vtt"] }
def endpoint-completer [] { ["/v1/chat/completions" "/v1/completions" "/v1/embeddings" "/v1/images/edits" "/v1/images/generations" "/v1/moderations" "/v1/responses" "/v1/videos"] }
def completion-window-completer [] { ["24h"] }
def memory-limit-completer [] { ["16g" "1g" "4g" "64g"] }
def encoding-format-completer [] { ["base64" "float"] }
def order-by-completer [] { ["created_at" "updated_at"] }
def status-completer [] { ["canceled" "completed" "failed" "in_progress" "queued"] }
def status-completer-1 [] { ["fail" "pass"] }
def purpose-completer [] { ["assistants" "batch" "evals" "fine-tune" "user_data" "vision"] }
def order-completer-1 [] { ["ascending" "descending"] }
def quality-completer [] { ["auto" "hd" "high" "low" "medium" "standard"] }
def response-format-completer-3 [] { ["b64_json" "url"] }
def output-format-completer [] { ["jpeg" "png" "webp"] }
def moderation-completer [] { ["auto" "low"] }
def background-completer [] { ["auto" "opaque" "transparent"] }
def style-completer [] { ["natural" "vivid"] }
def size-completer [] { ["1024x1024" "256x256" "512x512"] }
def bucket-width-completer [] { ["1d"] }
def role-completer [] { ["owner" "reader"] }
def bucket-width-completer-1 [] { ["1d" "1h" "1m"] }
def type-completer [] { ["realtime"] }
def input-audio-format-completer [] { ["g711_alaw" "g711_ulaw" "pcm16"] }
def role-completer-1 [] { ["assistant" "user"] }
def purpose-completer-1 [] { ["assistants" "batch" "fine-tune" "vision"] }
def filter-completer [] { ["cancelled" "completed" "failed" "in_progress"] }
def seconds-completer [] { ["12" "4" "8"] }
def size-completer-1 [] { ["1024x1792" "1280x720" "1792x1024" "720x1280"] }
def accept-completer-2 [] { ["application/json" "image/webp" "video/mp4"] }
def truncation-completer [] { ["auto" "disabled"] }
def accept-completer-3 [] { ["application/json" "application/zip"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "assistants listAssistants" } } | get name | first)
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

# Returns a list of assistants.
#
# GET /assistants
# DEPRECATED
# operationId: listAssistants
@deprecated
export def "assistants listAssistants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
]: nothing -> record<object: string, data: table<id: string, object: string, created_at: int, name: any, description: any, model: string, instructions: any, tools: list, tool_resources: any, metadata: any, temperature: any, top_p: any, response_format: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/assistants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an assistant with a model and instructions.
#
# POST /assistants
# DEPRECATED
# operationId: createAssistant
@deprecated
export def "assistants createAssistant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: any # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models) for descriptions of them.  (e.g. gpt-4o)
  --name: any
  --description: any
  --instructions: any
  --reasoning-effort: any
  --tools: list # A list of tool enabled on the assistant. There can be a maximum of 128 tools per assistant. Tools can be of types `code_interpreter`, `file_search`, or `function`.  (default: [])
  --tool-resources: any
  --metadata: any
  --temperature: any
  --top-p: any
  --response-format: any
]: any -> record<id: string, object: string, created_at: int, name: any, description: any, model: string, instructions: any, tools: list<any>, tool_resources: any, metadata: any, temperature: any, top_p: any, response_format: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistants")
  let body = {model: $model, name: $name, description: $description, instructions: $instructions, reasoning_effort: $reasoning_effort, tools: $tools, tool_resources: $tool_resources, metadata: $metadata, temperature: $temperature, top_p: $top_p, response_format: $response_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves an assistant.
#
# GET /assistants/{assistant_id}
# DEPRECATED
# operationId: getAssistant
@deprecated
export def "assistants get" [
  assistant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, name: any, description: any, model: string, instructions: any, tools: list<any>, tool_resources: any, metadata: any, temperature: any, top_p: any, response_format: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/assistants/($assistant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies an assistant.
#
# POST /assistants/{assistant_id}
# DEPRECATED
# operationId: modifyAssistant
@deprecated
export def "assistants modifyAssistant" [
  assistant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: any # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models) for descriptions of them.
  --reasoning-effort: any
  --name: any
  --description: any
  --instructions: any
  --tools: list # A list of tool enabled on the assistant. There can be a maximum of 128 tools per assistant. Tools can be of types `code_interpreter`, `file_search`, or `function`.  (default: [])
  --tool-resources: any
  --metadata: any
  --temperature: any
  --top-p: any
  --response-format: any
]: any -> record<id: string, object: string, created_at: int, name: any, description: any, model: string, instructions: any, tools: list<any>, tool_resources: any, metadata: any, temperature: any, top_p: any, response_format: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/assistants/($assistant_id)")
  let body = {model: $model, reasoning_effort: $reasoning_effort, name: $name, description: $description, instructions: $instructions, tools: $tools, tool_resources: $tool_resources, metadata: $metadata, temperature: $temperature, top_p: $top_p, response_format: $response_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an assistant.
#
# DELETE /assistants/{assistant_id}
# DEPRECATED
# operationId: deleteAssistant
@deprecated
export def "assistants delete" [
  assistant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/assistants/($assistant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generates audio from the input text.  Returns the audio file content, or a stream of audio events.
#
# POST /audio/speech
# operationId: createSpeech
export def "audio-speech createSpeech" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  model: any # One of the available [TTS models](/docs/models#tts): `tts-1`, `tts-1-hd`, `gpt-4o-mini-tts`, or `gpt-4o-mini-tts-2025-12-15`.
  input: string # The text to generate audio for. The maximum length is 4096 characters.
  --instructions: string # Control the voice of your generated audio with additional instructions. Does not work with `tts-1` or `tts-1-hd`.
  voice: any # A built-in voice name or a custom voice reference.
  --response-format: string@response-format-completer # The format to audio in. Supported formats are `mp3`, `opus`, `aac`, `flac`, `wav`, and `pcm`. (default: mp3)
  --speed: float # The speed of the generated audio. Select a value from `0.25` to `4.0`. `1.0` is the default. (default: 1)
  --stream-format: string@stream-format-completer # The format to stream the audio in. Supported formats are `sse` and `audio`. `sse` is not supported for `tts-1` or `tts-1-hd`. (default: audio)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/speech")
  let body = {model: $model, input: $input, instructions: $instructions, voice: $voice, response_format: $response_format, speed: $speed, stream_format: $stream_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transcribes audio into the input language.  Returns a transcription object in `json`, `diarized_json`, or `verbose_json` format, or a stream of transcript events.
#
# POST /audio/transcriptions
# operationId: createTranscription
export def "audio-transcriptions createTranscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  file: string # The audio file object (not file name) to transcribe, in one of these formats: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, or webm.  (format: binary)
  model: any # ID of the model to use. The options are `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, `gpt-4o-mini-transcribe-2025-12-15`, `whisper-1` (which is powered by our open source Whisper V2 model), and `gpt-4o-transcribe-diarize`.  (e.g. gpt-4o-transcribe)
  --language: string # The language of the input audio. Supplying the input language in [ISO-639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) (e.g. `en`) format will improve accuracy and latency.
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/guides/speech-to-text#prompting) should match the audio language. This field is not supported when using `gpt-4o-transcribe-diarize`.
  --response-format: string@response-format-completer-1 # The format of the output, in one of these options: `json`, `text`, `srt`, `verbose_json`, `vtt`, or `diarized_json`. For `gpt-4o-transcribe` and `gpt-4o-mini-transcribe`, the only supported format is `json`. For `gpt-4o-transcribe-diarize`, the supported formats are `json`, `text`, and `diarized_json`, with `diarized_json` required to receive speaker annotations.  (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit.  (default: 0)
  --include: list # Additional information to include in the transcription response. `logprobs` will return the log probabilities of the tokens in the response to understand the model's confidence in the transcription. `logprobs` only works with response_format set to `json` and only with the models `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, and `gpt-4o-mini-transcribe-2025-12-15`. This field is not supported when using `gpt-4o-transcribe-diarize`.
  --timestamp-granularities: list # The timestamp granularities to populate for this transcription. `response_format` must be set `verbose_json` to use timestamp granularities. Either or both of these options are supported: `word`, or `segment`. Note: There is no additional latency for segment timestamps, but generating word timestamps incurs additional latency. This option is not available for `gpt-4o-transcribe-diarize`.  (default: [segment])
  --stream: any
  --chunking-strategy: any
  --known-speaker-names: list # Optional list of speaker names that correspond to the audio samples provided in `known_speaker_references[]`. Each entry should be a short identifier (for example `customer` or `agent`). Up to 4 speakers are supported.
  --known-speaker-references: list # Optional list of audio samples (as [data URLs](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs)) that contain known speaker references matching `known_speaker_names[]`. Each sample must be between 2 and 10 seconds, and can use any of the same input audio formats supported by `file`.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/transcriptions")
  let body = {file: $file, model: $model, language: $language, prompt: $prompt, response_format: $response_format, temperature: $temperature, include: $include, timestamp_granularities: $timestamp_granularities, stream: $stream, chunking_strategy: $chunking_strategy, known_speaker_names: $known_speaker_names, known_speaker_references: $known_speaker_references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Translates audio into English.
#
# POST /audio/translations
# operationId: createTranslation
export def "audio-translations createTranslation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The audio file object (not file name) translate, in one of these formats: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, or webm.  (format: binary)
  model: any # ID of the model to use. Only `whisper-1` (which is powered by our open source Whisper V2 model) is currently available.  (e.g. whisper-1)
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/guides/speech-to-text#prompting) should be in English.
  --response-format: string@response-format-completer-2 # The format of the output, in one of these options: `json`, `text`, `srt`, `verbose_json`, or `vtt`.  (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit.  (default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/translations")
  let body = {file: $file, model: $model, prompt: $prompt, response_format: $response_format, temperature: $temperature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Upload a voice consent recording.
#
# POST /audio/voice_consents
# operationId: createVoiceConsent
export def "audio-voice-consents createVoiceConsent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The label to use for this consent recording.
  recording: string # The consent audio recording file. Maximum size is 10 MiB.  Supported MIME types: `audio/mpeg`, `audio/wav`, `audio/x-wav`, `audio/ogg`, `audio/aac`, `audio/flac`, `audio/webm`, `audio/mp4`.  (format: binary)
  language: string # The BCP 47 language tag for the consent phrase (for example, `en-US`).
]: any -> record<object: string, id: string, name: string, language: string, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/voice_consents")
  let body = {name: $name, recording: $recording, language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Returns a list of voice consent recordings.
#
# GET /audio/voice_consents
# operationId: listVoiceConsents
export def "audio-voice-consents listVoiceConsents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
]: nothing -> record<object: string, data: table<object: string, id: string, name: string, language: string, created_at: int>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audio/voice_consents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a voice consent recording.
#
# GET /audio/voice_consents/{consent_id}
# operationId: getVoiceConsent
export def "audio-voice-consents get" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: string, language: string, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audio/voice_consents/($consent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a voice consent recording (metadata only).
#
# POST /audio/voice_consents/{consent_id}
# operationId: updateVoiceConsent
export def "audio-voice-consents updateVoiceConsent" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The updated label for this consent recording.
]: any -> record<object: string, id: string, name: string, language: string, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audio/voice_consents/($consent_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a voice consent recording.
#
# DELETE /audio/voice_consents/{consent_id}
# operationId: deleteVoiceConsent
export def "audio-voice-consents delete" [
  consent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audio/voice_consents/($consent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a custom voice.
#
# POST /audio/voices
# operationId: createVoice
export def "audio-voices createVoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the new voice.
  audio_sample: string # The sample audio recording file. Maximum size is 10 MiB.  Supported MIME types: `audio/mpeg`, `audio/wav`, `audio/x-wav`, `audio/ogg`, `audio/aac`, `audio/flac`, `audio/webm`, `audio/mp4`.  (format: binary)
  consent: string # The consent recording ID (for example, `cons_1234`).
]: any -> record<object: string, id: string, name: string, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/voices")
  let body = {name: $name, audio_sample: $audio_sample, consent: $consent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Creates and executes a batch from an uploaded file of requests
#
# POST /batches
# operationId: createBatch
# --output_expires_after shape: {anchor: "created_at", seconds: int}
export def "batches createBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  input_file_id: string # The ID of an uploaded file that contains requests for the new batch.  See [upload file](/docs/api-reference/files/create) for how to upload a file.  Your input file must be formatted as a [JSONL file](/docs/api-reference/batch/request-input), and must be uploaded with the purpose `batch`. The file can contain up to 50,000 requests, and can be up to 200 MB in size.
  endpoint: string@endpoint-completer # The endpoint to be used for all requests in the batch. Currently `/v1/responses`, `/v1/chat/completions`, `/v1/embeddings`, `/v1/completions`, `/v1/moderations`, `/v1/images/generations`, `/v1/images/edits`, and `/v1/videos` are supported. Note that `/v1/embeddings` batches are also restricted to a maximum of 50,000 embedding inputs across all requests in the batch.
  completion_window: string@completion-window-completer # The time frame within which the batch should be processed. Currently only `24h` is supported.
  --metadata: any
  --output-expires-after: record # The expiration policy for the output and/or error file that are generated for a batch. — shape: {anchor: "created_at", seconds: int}
]: any -> record<id: string, object: string, endpoint: string, model: string, errors: record<object: string, data: list<record>>, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record<total: int, completed: int, failed: int>, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int>, output_tokens: int, output_tokens_details: record<reasoning_tokens: int>, total_tokens: int>, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batches")
  let body = {input_file_id: $input_file_id, endpoint: $endpoint, completion_window: $completion_window, metadata: $metadata, output_expires_after: $output_expires_after} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List your organization's batches.
#
# GET /batches
# operationId: listBatches
export def "batches listBatches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
]: nothing -> record<data: table<id: string, object: string, endpoint: string, model: string, errors: record, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record, usage: record, metadata: any>, first_id: string, last_id: string, has_more: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a batch.
#
# GET /batches/{batch_id}
# operationId: retrieveBatch
export def "batches retrieveBatch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, endpoint: string, model: string, errors: record<object: string, data: list<record>>, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record<total: int, completed: int, failed: int>, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int>, output_tokens: int, output_tokens_details: record<reasoning_tokens: int>, total_tokens: int>, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels an in-progress batch. The batch will be in status `cancelling` for up to 10 minutes, before changing to `cancelled`, where it will have partial results (if any) available in the output file.
#
# POST /batches/{batch_id}/cancel
# operationId: cancelBatch
export def "batches-cancel cancelBatch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, endpoint: string, model: string, errors: record<object: string, data: list<record>>, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record<total: int, completed: int, failed: int>, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int>, output_tokens: int, output_tokens_details: record<reasoning_tokens: int>, total_tokens: int>, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/batches/($batch_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List stored Chat Completions. Only Chat Completions that have been stored with the `store` parameter set to `true` will be returned.
#
# GET /chat/completions
# operationId: listChatCompletions
export def "chat-completions listChatCompletions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string # The model used to generate the Chat Completions.
  --metadata: string # A list of metadata keys to filter the Chat Completions by. Example:  `metadata[key1]=value1&metadata[key2]=value2`
  --after: string # Identifier for the last chat completion from the previous pagination request.
  --limit: int # Number of Chat Completions to retrieve. (default: 20)
  --order: string@order-completer # Sort order for Chat Completions by timestamp. Use `asc` for ascending order or `desc` for descending order. Defaults to `asc`. (default: asc)
]: nothing -> record<object: string, data: table<id: string, choices: list, created: int, model: string, service_tier: any, system_fingerprint: string, object: string, usage: record>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chat/completions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Starting a new project?** We recommend trying [Responses](/docs/api-reference/responses) to take advantage of the latest OpenAI platform features. Compare [Chat Completions with Responses](/docs/guides/responses-vs-chat-completions?api-mode=responses).  ---  Creates a model response for the given chat conversation. Learn more in the [text generation](/docs/guides/text-generation), [vision](/docs/guides/vision), and [audio](/docs/guides/audio) guides.  Parameter support can differ depending on the model used to generate the response, particularly for newer reasoning models. Parameters that are only supported for reasoning models are noted below. For the current state of unsupported parameters in reasoning models, [refer to the reasoning guide](/docs/guides/reasoning).  Returns a chat completion object, or a streamed sequence of chat completion chunk objects if the request is streamed.
#
# POST /chat/completions
# operationId: createChatCompletion
# --web_search_options shape: {user_location?: record, search_context_size?: "low"|"medium"|"high"}
# --audio shape: {voice: any, format: "wav"|"aac"|"mp3"|"flac"|"opus"|"pcm16"}
# --functions item shape: {description?: string, name: string, parameters?: record}
@deprecated --flag max-tokens
@deprecated --flag seed
@deprecated --flag function-call
@deprecated --flag functions
export def "chat-completions createChatCompletion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  messages: list # A list of messages comprising the conversation so far. Depending on the [model](/docs/models) you use, different message types (modalities) are supported, like [text](/docs/guides/text-generation), [images](/docs/guides/vision), and [audio](/docs/guides/audio).
  model: any # e.g. gpt-5.4
  --modalities: any
  --verbosity: any
  --reasoning-effort: any
  --max-completion-tokens: int # An upper bound for the number of tokens that can be generated for a completion, including visible output tokens and [reasoning tokens](/docs/guides/reasoning).  (nullable)
  --frequency-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.  (nullable, default: 0)
  --presence-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.  (nullable, default: 0)
  --web-search-options: record # This tool searches the web for relevant results to use in a response. Learn more about the [web search tool](/docs/guides/tools-web-search?api-mode=chat). — shape: {user_location?: record, search_context_size?: "low"|"medium"|"high"}
  --top-logprobs: int # An integer between 0 and 20 specifying the maximum number of most likely tokens to return at each token position, each with an associated log probability. In some cases, the number of returned tokens may be fewer than requested. `logprobs` must be set to `true` if this parameter is used.  (nullable)
  --response-format: any # An object specifying the format that the model must output.  Setting to `{ "type": "json_schema", "json_schema": {...} }` enables Structured Outputs which ensures the model will match your supplied JSON schema. Learn more in the [Structured Outputs guide](/docs/guides/structured-outputs).  Setting to `{ "type": "json_object" }` enables the older JSON mode, which ensures the message the model generates is valid JSON. Using `json_schema` is preferred for models that support it.
  --audio: record # Parameters for audio output. Required when audio output is requested with `modalities: ["audio"]`. [Learn more](/docs/guides/audio).  (nullable) — shape: {voice: any, format: "wav"|"aac"|"mp3"|"flac"|"opus"|"pcm16"}
  --store: string@bool-completer # Whether or not to store the output of this chat completion request for use in our [model distillation](/docs/guides/distillation) or [evals](/docs/guides/evals) products.  Supports text and image inputs. Note: image inputs over 8MB will be dropped.  (nullable, default: false)
  --stream: string@bool-completer # If set to true, the model response data will be streamed to the client as it is generated using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format). See the [Streaming section below](/docs/api-reference/chat/streaming) for more information, along with the [streaming responses](/docs/guides/streaming-responses) guide for more information on how to handle the streaming events.  (nullable, default: false)
  --stop: any # Not supported with latest reasoning models `o3` and `o4-mini`.  Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.  (nullable)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion.  Accepts a JSON object that maps tokens (specified by their token ID in the tokenizer) to an associated bias value from -100 to 100. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token.  (nullable)
  --logprobs: string@bool-completer # Whether to return log probabilities of the output tokens or not. If true, returns the log probabilities of each output token returned in the `content` of `message`.  (nullable, default: false)
  --max-tokens: int # The maximum number of [tokens](/tokenizer) that can be generated in the chat completion. This value can be used to control [costs](https://openai.com/api/pricing/) for text generated via API.  This value is now deprecated in favor of `max_completion_tokens`, and is not compatible with [o-series models](/docs/guides/reasoning).  (DEPRECATED, nullable)
  --n: int # How many chat completion choices to generate for each input message. Note that you will be charged based on the number of generated tokens across all of the choices. Keep `n` as `1` to minimize costs. (nullable, default: 1, e.g. 1)
  --prediction: any # Configuration for a [Predicted Output](/docs/guides/predicted-outputs), which can greatly improve response times when large parts of the model response are known ahead of time. This is most common when you are regenerating a file with only minor changes to most of the content.  (nullable)
  --seed: int # This feature is in Beta. If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same `seed` and parameters should return the same result. Determinism is not guaranteed, and you should refer to the `system_fingerprint` response parameter to monitor changes in the backend.  (DEPRECATED, nullable)
  --stream-options: any
  --tools: list # A list of tools the model may call. You can provide either [custom tools](/docs/guides/function-calling#custom-tools) or [function tools](/docs/guides/function-calling).
  --tool-choice: any # Controls which (if any) tool is called by the model. `none` means the model will not call any tool and instead generates a message. `auto` means the model can pick between generating a message or calling one or more tools. `required` means the model must call one or more tools. Specifying a particular tool via `{"type": "function", "function": {"name": "my_function"}}` forces the model to call that tool.  `none` is the default when no tools are present. `auto` is the default if tools are present.
  --parallel-tool-calls: string@bool-completer # Whether to enable [parallel function calling](/docs/guides/function-calling#configuring-parallel-function-calling) during tool use. (default: true)
  --function-call: any # Deprecated in favor of `tool_choice`.  Controls which (if any) function is called by the model.  `none` means the model will not call a function and instead generates a message.  `auto` means the model can pick between generating a message or calling a function.  Specifying a particular function via `{"name": "my_function"}` forces the model to call that function.  `none` is the default when no functions are present. `auto` is the default if functions are present.  (DEPRECATED)
  --functions: list # Deprecated in favor of `tools`.  A list of functions the model may generate JSON inputs for.  (DEPRECATED) — item shape: {description?: string, name: string, parameters?: record}
]: any -> record<id: string, choices: table<finish_reason: string, index: int, message: record, logprobs: any>, created: int, model: string, service_tier: any, system_fingerprint: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int, completion_tokens_details: record<accepted_prediction_tokens: int, audio_tokens: int, reasoning_tokens: int, rejected_prediction_tokens: int>, prompt_tokens_details: record<audio_tokens: int, cached_tokens: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat/completions")
  let body = {messages: $messages, model: $model, modalities: $modalities, verbosity: $verbosity, reasoning_effort: $reasoning_effort, max_completion_tokens: $max_completion_tokens, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, web_search_options: $web_search_options, top_logprobs: $top_logprobs, response_format: $response_format, audio: $audio, store: $store, stream: $stream, stop: $stop, logit_bias: $logit_bias, logprobs: $logprobs, max_tokens: $max_tokens, n: $n, prediction: $prediction, seed: $seed, stream_options: $stream_options, tools: $tools, tool_choice: $tool_choice, parallel_tool_calls: $parallel_tool_calls, function_call: $function_call, functions: $functions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a stored chat completion. Only Chat Completions that have been created with the `store` parameter set to `true` will be returned.
#
# GET /chat/completions/{completion_id}
# operationId: getChatCompletion
export def "chat-completions get" [
  completion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, choices: table<finish_reason: string, index: int, message: record, logprobs: any>, created: int, model: string, service_tier: any, system_fingerprint: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int, completion_tokens_details: record<accepted_prediction_tokens: int, audio_tokens: int, reasoning_tokens: int, rejected_prediction_tokens: int>, prompt_tokens_details: record<audio_tokens: int, cached_tokens: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chat/completions/($completion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a stored chat completion. Only Chat Completions that have been created with the `store` parameter set to `true` can be modified. Currently, the only supported modification is to update the `metadata` field.
#
# POST /chat/completions/{completion_id}
# operationId: updateChatCompletion
export def "chat-completions updateChatCompletion" [
  completion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metadata: any
]: any -> record<id: string, choices: table<finish_reason: string, index: int, message: record, logprobs: any>, created: int, model: string, service_tier: any, system_fingerprint: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int, completion_tokens_details: record<accepted_prediction_tokens: int, audio_tokens: int, reasoning_tokens: int, rejected_prediction_tokens: int>, prompt_tokens_details: record<audio_tokens: int, cached_tokens: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chat/completions/($completion_id)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a stored chat completion. Only Chat Completions that have been created with the `store` parameter set to `true` can be deleted.
#
# DELETE /chat/completions/{completion_id}
# operationId: deleteChatCompletion
export def "chat-completions delete" [
  completion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chat/completions/($completion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the messages in a stored chat completion. Only Chat Completions that have been created with the `store` parameter set to `true` will be returned.
#
# GET /chat/completions/{completion_id}/messages
# operationId: getChatCompletionMessages
export def "chat-completions-messages get" [
  completion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Identifier for the last message from the previous pagination request.
  --limit: int # Number of messages to retrieve. (default: 20)
  --order: string@order-completer # Sort order for messages by timestamp. Use `asc` for ascending order or `desc` for descending order. Defaults to `asc`. (default: asc)
]: nothing -> record<object: string, data: table<content: any, refusal: any, tool_calls: list, annotations: list, role: string, function_call: record, audio: any, id: string, content_parts: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/chat/completions/($completion_id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a completion for the provided prompt and parameters.  Returns a completion object, or a sequence of completion objects if the request is streamed.
#
# POST /completions
# operationId: createCompletion
export def "completions createCompletion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: any # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models) for descriptions of them.
  --prompt: any # The prompt(s) to generate completions for, encoded as a string, array of strings, array of tokens, or array of token arrays.  Note that <|endoftext|> is the document separator that the model sees during training, so if a prompt is not specified the model will generate as if from the beginning of a new document.  (nullable, default: <|endoftext|>)
  --best-of: int # Generates `best_of` completions server-side and returns the "best" (the one with the highest log probability per token). Results cannot be streamed.  When used with `n`, `best_of` controls the number of candidate completions and `n` specifies how many to return – `best_of` must be greater than `n`.  **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`.  (nullable, default: 1)
  --echo: string@bool-completer # Echo back the prompt in addition to the completion  (nullable, default: false)
  --frequency-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.  [See more information about frequency and presence penalties.](/docs/guides/text-generation)  (nullable, default: 0)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion.  Accepts a JSON object that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this [tokenizer tool](/tokenizer?view=bpe) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token.  As an example, you can pass `{"50256": -100}` to prevent the <|endoftext|> token from being generated.  (nullable)
  --logprobs: int # Include the log probabilities on the `logprobs` most likely output tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response.  The maximum value for `logprobs` is 5.  (nullable)
  --max-tokens: int # The maximum number of [tokens](/tokenizer) that can be generated in the completion.  The token count of your prompt plus `max_tokens` cannot exceed the model's context length. [Example Python code](https://cookbook.openai.com/examples/how_to_count_tokens_with_tiktoken) for counting tokens.  (nullable, default: 16, e.g. 16)
  --n: int # How many completions to generate for each prompt.  **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`.  (nullable, default: 1, e.g. 1)
  --presence-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.  [See more information about frequency and presence penalties.](/docs/guides/text-generation)  (nullable, default: 0)
  --seed: int # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same `seed` and parameters should return the same result.  Determinism is not guaranteed, and you should refer to the `system_fingerprint` response parameter to monitor changes in the backend.  (nullable, format: int64)
  --stop: any # Not supported with latest reasoning models `o3` and `o4-mini`.  Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.  (nullable)
  --stream: string@bool-completer # Whether to stream back partial progress. If set, tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. [Example Python code](https://cookbook.openai.com/examples/how_to_stream_completions).  (nullable, default: false)
  --stream-options: any
  --suffix: string # The suffix that comes after a completion of inserted text.  This parameter is only supported for `gpt-3.5-turbo-instruct`.  (nullable, e.g. test.)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.  We generally recommend altering this or `top_p` but not both.  (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.  We generally recommend altering this or `temperature` but not both.  (nullable, default: 1, e.g. 1)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices#end-user-ids).  (e.g. user-1234)
]: any -> record<id: string, choices: table<finish_reason: string, index: int, logprobs: any, text: string>, created: int, model: string, system_fingerprint: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int, completion_tokens_details: record<accepted_prediction_tokens: int, audio_tokens: int, reasoning_tokens: int, rejected_prediction_tokens: int>, prompt_tokens_details: record<audio_tokens: int, cached_tokens: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/completions")
  let body = {model: $model, prompt: $prompt, best_of: $best_of, echo: $echo, frequency_penalty: $frequency_penalty, logit_bias: $logit_bias, logprobs: $logprobs, max_tokens: $max_tokens, n: $n, presence_penalty: $presence_penalty, seed: $seed, stop: $stop, stream: $stream, stream_options: $stream_options, suffix: $suffix, temperature: $temperature, top_p: $top_p, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Containers
#
# GET /containers
# operationId: ListContainers
export def "containers ListContainers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --name: string # Filter results by container name.
]: nothing -> record<object: string, data: table<id: string, object: string, name: string, created_at: int, status: string, last_active_at: int, expires_after: record, memory_limit: string, network_policy: record>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Container
#
# POST /containers
# operationId: CreateContainer
# --expires_after shape: {anchor: "last_active_at", minutes: int}
export def "containers CreateContainer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the container to create.
  --file-ids: list # IDs of files to copy to the container.
  --expires-after: record # Container expiration time in seconds relative to the 'anchor' time. — shape: {anchor: "last_active_at", minutes: int}
  --skills: list # An optional list of skills referenced by id or inline data.
  --memory-limit: string@memory-limit-completer # Optional memory limit for the container. Defaults to "1g".
  --network-policy: any # Network access policy for the container.
]: any -> record<id: string, object: string, name: string, created_at: int, status: string, last_active_at: int, expires_after: record<anchor: string, minutes: int>, memory_limit: string, network_policy: record<type: string, allowed_domains: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers")
  let body = {name: $name, file_ids: $file_ids, expires_after: $expires_after, skills: $skills, memory_limit: $memory_limit, network_policy: $network_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Container
#
# GET /containers/{container_id}
# operationId: RetrieveContainer
export def "containers RetrieveContainer" [
  container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, created_at: int, status: string, last_active_at: int, expires_after: record<anchor: string, minutes: int>, memory_limit: string, network_policy: record<type: string, allowed_domains: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($container_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Container
#
# DELETE /containers/{container_id}
# operationId: DeleteContainer
export def "containers DeleteContainer" [
  container_id: string
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
  let full_url = (build-url $base $"/containers/($container_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Container File  You can send either a multipart/form-data request with the raw file content, or a JSON request with a file ID.
#
# POST /containers/{container_id}/files
# operationId: CreateContainerFile
export def "containers-files CreateContainerFile" [
  container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file-id: string # Name of the file to create.
  --file: string # The File object (not file name) to be uploaded.  (format: binary)
]: any -> record<id: string, object: string, container_id: string, created_at: int, bytes: int, path: string, source: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($container_id)/files")
  let body = {file_id: $file_id, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Container files
#
# GET /containers/{container_id}/files
# operationId: ListContainerFiles
export def "containers-files ListContainerFiles" [
  container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
]: nothing -> record<object: string, data: table<id: string, object: string, container_id: string, created_at: int, bytes: int, path: string, source: string>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($container_id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Container File
#
# GET /containers/{container_id}/files/{file_id}
# operationId: RetrieveContainerFile
export def "containers-files RetrieveContainerFile" [
  container_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, container_id: string, created_at: int, bytes: int, path: string, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($container_id)/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Container File
#
# DELETE /containers/{container_id}/files/{file_id}
# operationId: DeleteContainerFile
export def "containers-files DeleteContainerFile" [
  container_id: string
  file_id: string
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
  let full_url = (build-url $base $"/containers/($container_id)/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Container File Content
#
# GET /containers/{container_id}/files/{file_id}/content
# operationId: RetrieveContainerFileContent
export def "containers-files-content RetrieveContainerFileContent" [
  container_id: string
  file_id: string
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
  let full_url = (build-url $base $"/containers/($container_id)/files/($file_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create items in a conversation with the given ID.
#
# POST /conversations/{conversation_id}/items
# operationId: createConversationItems
export def "conversations-items createConversationItems" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Additional fields to include in the response. See the `include` parameter for [listing Conversation items above](/docs/api-reference/conversations/list-items#conversations_list_items-include) for more information.
  items: list # The items to add to the conversation. You may add up to 20 items at a time.
]: any -> record<object: string, data: list<any>, has_more: bool, first_id: string, last_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)/items" $qp)
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all items for a conversation with the given ID.
#
# GET /conversations/{conversation_id}/items
# operationId: listConversationItems
export def "conversations-items listConversationItems" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # The order to return the input items in. Default is `desc`. - `asc`: Return the input items in ascending order. - `desc`: Return the input items in descending order.
  --after: string # An item ID to list items after, used in pagination.
  --include: list # Specify additional output data to include in the model response. Currently supported values are: - `web_search_call.action.sources`: Include the sources of the web search tool call. - `code_interpreter_call.outputs`: Includes the outputs of python code execution in code interpreter tool call items. - `computer_call_output.output.image_url`: Include image urls from the computer call output. - `file_search_call.results`: Include the search results of the file search tool call. - `message.input_image.image_url`: Include image urls from the input message. - `message.output_text.logprobs`: Include logprobs with assistant messages. - `reasoning.encrypted_content`: Includes an encrypted version of reasoning tokens in reasoning item outputs. This enables reasoning items to be used in multi-turn conversations when using the Responses API statelessly (like when the `store` parameter is set to `false`, or when an organization is enrolled in the zero data retention program).
]: nothing -> record<object: string, data: list<any>, has_more: bool, first_id: string, last_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single item from a conversation with the given IDs.
#
# GET /conversations/{conversation_id}/items/{item_id}
# Discriminator (response): type
# operationId: getConversationItem
export def "conversations-items get" [
  conversation_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Additional fields to include in the response. See the `include` parameter for [listing Conversation items above](/docs/api-reference/conversations/list-items#conversations_list_items-include) for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversations/($conversation_id)/items/($item_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an item from a conversation with the given IDs.
#
# DELETE /conversations/{conversation_id}/items/{item_id}
# operationId: deleteConversationItem
export def "conversations-items delete" [
  conversation_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, metadata: any, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)/items/($item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an embedding vector representing the input text.
#
# POST /embeddings
# operationId: createEmbedding
export def "embeddings createEmbedding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  input: any # Input text to embed, encoded as a string or array of tokens. To embed multiple inputs in a single request, pass an array of strings or array of token arrays. The input must not exceed the max input tokens for the model (8192 tokens for all embedding models), cannot be an empty string, and any array must be 2048 dimensions or less. [Example Python code](https://cookbook.openai.com/examples/how_to_count_tokens_with_tiktoken) for counting tokens. In addition to the per-input token limit, all embedding  models enforce a maximum of 300,000 tokens summed across all inputs in a  single request.  (e.g. The quick brown fox jumped over the lazy dog)
  model: any # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models) for descriptions of them.  (e.g. text-embedding-3-small)
  --encoding-format: string@encoding-format-completer # The format to return the embeddings in. Can be either `float` or [`base64`](https://pypi.org/project/pybase64/). (default: float, e.g. float)
  --dimensions: int # The number of dimensions the resulting output embeddings should have. Only supported in `text-embedding-3` and later models.
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices#end-user-ids).  (e.g. user-1234)
]: any -> record<data: table<index: int, embedding: list, object: string>, model: string, object: string, usage: record<prompt_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/embeddings")
  let body = {input: $input, model: $model, encoding_format: $encoding_format, dimensions: $dimensions, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List evaluations for a project.
#
# GET /evals
# operationId: listEvals
export def "evals listEvals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Identifier for the last eval from the previous pagination request.
  --limit: int # Number of evals to retrieve. (default: 20)
  --order: string@order-completer # Sort order for evals by timestamp. Use `asc` for ascending order or `desc` for descending order. (default: asc)
  --order-by: string@order-by-completer # Evals can be ordered by creation time or last updated time. Use `created_at` for creation time or `updated_at` for last updated time.  (default: created_at)
]: nothing -> record<object: string, data: table<object: string, id: string, name: string, data_source_config: record, testing_criteria: list, created_at: int, metadata: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/evals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create the structure of an evaluation that can be used to test a model's performance. An evaluation is a set of testing criteria and the config for a data source, which dictates the schema of the data used in the evaluation. After creating an evaluation, you can run it on different models and model parameters. We support several types of graders and datasources. For more information, see the [Evals guide](/docs/guides/evals).
#
# POST /evals
# operationId: createEval
# --data_source_config shape: {type?: "custom", item_schema?: record, include_sample_schema?: bool, metadata?: record}
export def "evals createEval" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the evaluation.
  --metadata: any
  data_source_config: record # The configuration for the data source used for the evaluation runs. Dictates the schema of the data used in the evaluation. — shape: {type?: "custom", item_schema?: record, include_sample_schema?: bool, metadata?: record}
  testing_criteria: list # A list of graders for all eval runs in this group. Graders can reference variables in the data source using double curly braces notation, like `{{item.variable_name}}`. To reference the model's output, use the `sample` namespace (ie, `{{sample.output_text}}`).
]: any -> record<object: string, id: string, name: string, data_source_config: record, testing_criteria: list<any>, created_at: int, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/evals")
  let body = {name: $name, metadata: $metadata, data_source_config: $data_source_config, testing_criteria: $testing_criteria} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an evaluation by ID.
#
# GET /evals/{eval_id}
# operationId: getEval
export def "evals get" [
  eval_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: string, data_source_config: record, testing_criteria: list<any>, created_at: int, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update certain properties of an evaluation.
#
# POST /evals/{eval_id}
# operationId: updateEval
export def "evals updateEval" [
  eval_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Rename the evaluation.
  --metadata: any
]: any -> record<object: string, id: string, name: string, data_source_config: record, testing_criteria: list<any>, created_at: int, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)")
  let body = {name: $name, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an evaluation.
#
# DELETE /evals/{eval_id}
# operationId: deleteEval
export def "evals delete" [
  eval_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool, eval_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of runs for an evaluation.
#
# GET /evals/{eval_id}/runs
# operationId: getEvalRuns
export def "evals-runs list" [
  eval_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Identifier for the last run from the previous pagination request.
  --limit: int # Number of runs to retrieve. (default: 20)
  --order: string@order-completer # Sort order for runs by timestamp. Use `asc` for ascending order or `desc` for descending order. Defaults to `asc`. (default: asc)
  --status: string@status-completer # Filter runs by status. One of `queued` | `in_progress` | `failed` | `completed` | `canceled`.
]: nothing -> record<object: string, data: table<object: string, id: string, eval_id: string, status: string, model: string, name: string, created_at: int, report_url: string, result_counts: record, per_model_usage: list, per_testing_criteria_results: list, data_source: record, metadata: any, error: record>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/evals/($eval_id)/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kicks off a new run for a given evaluation, specifying the data source, and what model configuration to use to test. The datasource will be validated against the schema specified in the config of the evaluation.
#
# POST /evals/{eval_id}/runs
# operationId: createEvalRun
# --data_source shape: {type?: "jsonl", source?: any, input_messages?: any, sampling_params?: record, model?: string}
export def "evals-runs createEvalRun" [
  eval_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the run.
  --metadata: any
  data_source: record # Details about the run's data source. — shape: {type?: "jsonl", source?: any, input_messages?: any, sampling_params?: record, model?: string}
]: any -> record<object: string, id: string, eval_id: string, status: string, model: string, name: string, created_at: int, report_url: string, result_counts: record<total: int, errored: int, failed: int, passed: int>, per_model_usage: table<model_name: string, invocation_count: int, prompt_tokens: int, completion_tokens: int, total_tokens: int, cached_tokens: int>, per_testing_criteria_results: table<testing_criteria: string, passed: int, failed: int>, data_source: record, metadata: any, error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)/runs")
  let body = {name: $name, metadata: $metadata, data_source: $data_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an evaluation run by ID.
#
# GET /evals/{eval_id}/runs/{run_id}
# operationId: getEvalRun
export def "evals-runs get" [
  eval_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, eval_id: string, status: string, model: string, name: string, created_at: int, report_url: string, result_counts: record<total: int, errored: int, failed: int, passed: int>, per_model_usage: table<model_name: string, invocation_count: int, prompt_tokens: int, completion_tokens: int, total_tokens: int, cached_tokens: int>, per_testing_criteria_results: table<testing_criteria: string, passed: int, failed: int>, data_source: record, metadata: any, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)/runs/($run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an ongoing evaluation run.
#
# POST /evals/{eval_id}/runs/{run_id}
# operationId: cancelEvalRun
export def "evals-runs cancelEvalRun" [
  eval_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, eval_id: string, status: string, model: string, name: string, created_at: int, report_url: string, result_counts: record<total: int, errored: int, failed: int, passed: int>, per_model_usage: table<model_name: string, invocation_count: int, prompt_tokens: int, completion_tokens: int, total_tokens: int, cached_tokens: int>, per_testing_criteria_results: table<testing_criteria: string, passed: int, failed: int>, data_source: record, metadata: any, error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)/runs/($run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an eval run.
#
# DELETE /evals/{eval_id}/runs/{run_id}
# operationId: deleteEvalRun
export def "evals-runs delete" [
  eval_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool, run_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)/runs/($run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of output items for an evaluation run.
#
# GET /evals/{eval_id}/runs/{run_id}/output_items
# operationId: getEvalRunOutputItems
export def "evals-runs-output-items list" [
  eval_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Identifier for the last output item from the previous pagination request.
  --limit: int # Number of output items to retrieve. (default: 20)
  --status: string@status-completer-1 # Filter output items by status. Use `failed` to filter by failed output items or `pass` to filter by passed output items.
  --order: string@order-completer # Sort order for output items by timestamp. Use `asc` for ascending order or `desc` for descending order. Defaults to `asc`. (default: asc)
]: nothing -> record<object: string, data: table<object: string, id: string, run_id: string, eval_id: string, created_at: int, status: string, datasource_item_id: int, datasource_item: record, results: list, sample: record>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/evals/($eval_id)/runs/($run_id)/output_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an evaluation run output item by ID.
#
# GET /evals/{eval_id}/runs/{run_id}/output_items/{output_item_id}
# operationId: getEvalRunOutputItem
export def "evals-runs-output-items get" [
  eval_id: string
  run_id: string
  output_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, run_id: string, eval_id: string, created_at: int, status: string, datasource_item_id: int, datasource_item: record, results: table<name: string, type: string, score: float, passed: bool, sample: any>, sample: record<input: list<record>, output: list<record>, finish_reason: string, model: string, usage: record<total_tokens: int, completion_tokens: int, prompt_tokens: int, cached_tokens: int>, error: record<code: string, message: string>, temperature: float, max_completion_tokens: int, top_p: float, seed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/evals/($eval_id)/runs/($run_id)/output_items/($output_item_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of files.
#
# GET /files
# operationId: listFiles
export def "files listFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --purpose: string # Only return files with the given purpose.
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 10,000, and the default is 10,000.  (default: 10000)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
]: nothing -> record<object: string, data: table<id: string, bytes: int, created_at: int, expires_at: int, filename: string, object: string, purpose: string, status: string, status_details: string>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "purpose" $purpose "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file that can be used across various endpoints. Individual files can be up to 512 MB, and each project can store up to 2.5 TB of files in total. There is no organization-wide storage limit. Uploads to this endpoint are rate-limited to 1,000 requests per minute per authenticated user.  - The Assistants API supports files up to 2 million tokens and of specific   file types. See the [Assistants Tools guide](/docs/assistants/tools) for   details. - The Fine-tuning API only supports `.jsonl` files. The input also has   certain required formats for fine-tuning   [chat](/docs/api-reference/fine-tuning/chat-input) or   [completions](/docs/api-reference/fine-tuning/completions-input) models. - The Batch API only supports `.jsonl` files up to 200 MB in size. The input   also has a specific required   [format](/docs/api-reference/batch/request-input). - For Retrieval or `file_search` ingestion, upload files here first. If   you need to attach multiple uploaded files to the same vector store, use   [`/vector_stores/{vector_store_id}/file_batches`](/docs/api-reference/vector-stores-file-batches/createBatch)   instead of attaching them one by one. Vector store attachment has separate   limits from file upload, including 2,000 attached files per minute per   organization.  Please [contact us](https://help.openai.com/) if you need to increase these storage limits.
#
# POST /files
# operationId: createFile
# --expires_after shape: {anchor: "created_at", seconds: int}
export def "files createFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The File object (not file name) to be uploaded.  (format: binary)
  purpose: string@purpose-completer # The intended purpose of the uploaded file. One of: - `assistants`: Used in the Assistants API - `batch`: Used in the Batch API - `fine-tune`: Used for fine-tuning - `vision`: Images used for vision fine-tuning - `user_data`: Flexible file type for any purpose - `evals`: Used for eval data sets
  --expires-after: record # The expiration policy for a file. By default, files with `purpose=batch` expire after 30 days and all other files are persisted until they are manually deleted. — shape: {anchor: "created_at", seconds: int}
]: any -> record<id: string, bytes: int, created_at: int, expires_at: int, filename: string, object: string, purpose: string, status: string, status_details: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let body = {file: $file, purpose: $purpose, expires_after: $expires_after} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a file and remove it from all vector stores.
#
# DELETE /files/{file_id}
# operationId: deleteFile
export def "files delete" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about a specific file.
#
# GET /files/{file_id}
# operationId: retrieveFile
export def "files retrieveFile" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, bytes: int, created_at: int, expires_at: int, filename: string, object: string, purpose: string, status: string, status_details: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the contents of the specified file.
#
# GET /files/{file_id}/content
# operationId: downloadFile
export def "files-content downloadFile" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run a grader.
#
# POST /fine_tuning/alpha/graders/run
# operationId: runGrader
# --grader shape: {type?: "string_check", name?: string, input?: string, reference?: string, operation?: "eq"|"ne"|"like"|"ilike", evaluation_metric?: "cosine"|"fuzzy_match"|"bleu"|"gleu"|"meteor"|"rouge_1"|"rouge_2"|"rouge_3"|"rouge_4"|"rouge_5"|"rouge_l", source?: string, image_tag?: string, model?: string, sampling_params?: record, range?: list, graders?: any, calculate_output?: string}
export def "fine-tuning-alpha-graders-run runGrader" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grader: record # The grader used for the fine-tuning job. — shape: {type?: "string_check", name?: string, input?: string, reference?: string, operation?: "eq"|"ne"|"like"|"ilike", evaluation_metric?: "cosine"|"fuzzy_match"|"bleu"|"gleu"|"meteor"|"rouge_1"|"rouge_2"|"rouge_3"|"rouge_4"|"rouge_5"|"rouge_l", source?: string, image_tag?: string, model?: string, sampling_params?: record, range?: list, graders?: any, calculate_output?: string}
  --item: record # The dataset item provided to the grader. This will be used to populate  the `item` namespace. See [the guide](/docs/guides/graders) for more details. 
  model_sample: string # The model sample to be evaluated. This value will be used to populate  the `sample` namespace. See [the guide](/docs/guides/graders) for more details. The `output_json` variable will be populated if the model sample is a  valid JSON string.  
]: any -> record<reward: float, metadata: record<name: string, type: string, errors: record<formula_parse_error: bool, sample_parse_error: bool, truncated_observation_error: bool, unresponsive_reward_error: bool, invalid_variable_error: bool, other_error: bool, python_grader_server_error: bool, python_grader_server_error_type: any, python_grader_runtime_error: bool, python_grader_runtime_error_details: any, model_grader_server_error: bool, model_grader_refusal_error: bool, model_grader_parse_error: bool, model_grader_server_error_details: any>, execution_time: float, scores: record, token_usage: any, sampled_model_name: any>, sub_rewards: record, model_grader_token_usage_per_model: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine_tuning/alpha/graders/run")
  let body = {grader: $grader, item: $item, model_sample: $model_sample} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate a grader.
#
# POST /fine_tuning/alpha/graders/validate
# operationId: validateGrader
# --grader shape: {type?: "string_check", name?: string, input?: string, reference?: string, operation?: "eq"|"ne"|"like"|"ilike", evaluation_metric?: "cosine"|"fuzzy_match"|"bleu"|"gleu"|"meteor"|"rouge_1"|"rouge_2"|"rouge_3"|"rouge_4"|"rouge_5"|"rouge_l", source?: string, image_tag?: string, model?: string, sampling_params?: record, range?: list, graders?: any, calculate_output?: string}
export def "fine-tuning-alpha-graders-validate validateGrader" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grader: record # The grader used for the fine-tuning job. — shape: {type?: "string_check", name?: string, input?: string, reference?: string, operation?: "eq"|"ne"|"like"|"ilike", evaluation_metric?: "cosine"|"fuzzy_match"|"bleu"|"gleu"|"meteor"|"rouge_1"|"rouge_2"|"rouge_3"|"rouge_4"|"rouge_5"|"rouge_l", source?: string, image_tag?: string, model?: string, sampling_params?: record, range?: list, graders?: any, calculate_output?: string}
]: any -> record<grader: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine_tuning/alpha/graders/validate")
  let body = {grader: $grader} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# **NOTE:** This endpoint requires an [admin API key](../admin-api-keys).  Organization owners can use this endpoint to view all permissions for a fine-tuned model checkpoint.
#
# GET /fine_tuning/checkpoints/{fine_tuned_model_checkpoint}/permissions
# operationId: listFineTuningCheckpointPermissions
export def "fine-tuning-checkpoints-permissions listFineTuningCheckpointPermissions" [
  fine_tuned_model_checkpoint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: string # The ID of the project to get permissions for.
  --after: string # Identifier for the last permission ID from the previous pagination request.
  --limit: int # Number of permissions to retrieve. (default: 10)
  --order: string@order-completer-1 # The order in which to retrieve permissions. (default: descending)
]: nothing -> record<data: table<id: string, created_at: int, project_id: string, object: string>, object: string, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_id" $project_id "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fine_tuning/checkpoints/($fine_tuned_model_checkpoint)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **NOTE:** Calling this endpoint requires an [admin API key](../admin-api-keys).  This enables organization owners to share fine-tuned models with other projects in their organization.
#
# POST /fine_tuning/checkpoints/{fine_tuned_model_checkpoint}/permissions
# operationId: createFineTuningCheckpointPermission
export def "fine-tuning-checkpoints-permissions createFineTuningCheckpointPermission" [
  fine_tuned_model_checkpoint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  project_ids: list # The project identifiers to grant access to.
]: any -> record<data: table<id: string, created_at: int, project_id: string, object: string>, object: string, first_id: any, last_id: any, has_more: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine_tuning/checkpoints/($fine_tuned_model_checkpoint)/permissions")
  let body = {project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# **NOTE:** This endpoint requires an [admin API key](../admin-api-keys).  Organization owners can use this endpoint to delete a permission for a fine-tuned model checkpoint.
#
# DELETE /fine_tuning/checkpoints/{fine_tuned_model_checkpoint}/permissions/{permission_id}
# operationId: deleteFineTuningCheckpointPermission
export def "fine-tuning-checkpoints-permissions delete" [
  fine_tuned_model_checkpoint: string
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine_tuning/checkpoints/($fine_tuned_model_checkpoint)/permissions/($permission_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a fine-tuning job which begins the process of creating a new model from a given dataset.  Response includes details of the enqueued job including job status and the name of the fine-tuned models once complete.  [Learn more about fine-tuning](/docs/guides/model-optimization)
#
# POST /fine_tuning/jobs
# operationId: createFineTuningJob
# --hyperparameters shape: {batch_size?: any, learning_rate_multiplier?: any, n_epochs?: any}
# --integrations item shape: {type: any, wandb: record}
# --method shape: {type: "supervised"|"dpo"|"reinforcement", supervised?: record, dpo?: record, reinforcement?: record}
@deprecated --flag hyperparameters
export def "fine-tuning-jobs createFineTuningJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: any # The name of the model to fine-tune. You can select one of the [supported models](/docs/guides/fine-tuning#which-models-can-be-fine-tuned).  (e.g. gpt-4o-mini)
  training_file: string # The ID of an uploaded file that contains training data.  See [upload file](/docs/api-reference/files/create) for how to upload a file.  Your dataset must be formatted as a JSONL file. Additionally, you must upload your file with the purpose `fine-tune`.  The contents of the file should differ depending on if the model uses the [chat](/docs/api-reference/fine-tuning/chat-input), [completions](/docs/api-reference/fine-tuning/completions-input) format, or if the fine-tuning method uses the [preference](/docs/api-reference/fine-tuning/preference-input) format.  See the [fine-tuning guide](/docs/guides/model-optimization) for more details.  (e.g. file-abc123)
  --hyperparameters: record # The hyperparameters used for the fine-tuning job. This value is now deprecated in favor of `method`, and should be passed in under the `method` parameter.  (DEPRECATED) — shape: {batch_size?: any, learning_rate_multiplier?: any, n_epochs?: any}
  --suffix: string # A string of up to 64 characters that will be added to your fine-tuned model name.  For example, a `suffix` of "custom-model-name" would produce a model name like `ft:gpt-4o-mini:openai:custom-model-name:7p4lURel`.  (nullable)
  --validation-file: string # The ID of an uploaded file that contains validation data.  If you provide this file, the data is used to generate validation metrics periodically during fine-tuning. These metrics can be viewed in the fine-tuning results file. The same data should not be present in both train and validation files.  Your dataset must be formatted as a JSONL file. You must upload your file with the purpose `fine-tune`.  See the [fine-tuning guide](/docs/guides/model-optimization) for more details.  (nullable, e.g. file-abc123)
  --integrations: list # A list of integrations to enable for your fine-tuning job. (nullable) — item shape: {type: any, wandb: record}
  --seed: int # The seed controls the reproducibility of the job. Passing in the same seed and job parameters should produce the same results, but may differ in rare cases. If a seed is not specified, one will be generated for you.  (nullable, e.g. 42)
  --method: record # The method used for fine-tuning. — shape: {type: "supervised"|"dpo"|"reinforcement", supervised?: record, dpo?: record, reinforcement?: record}
  --metadata: any
]: any -> record<id: string, created_at: int, error: any, fine_tuned_model: any, finished_at: any, hyperparameters: record<batch_size: any, learning_rate_multiplier: any, n_epochs: any>, model: string, object: string, organization_id: string, result_files: list<string>, status: string, trained_tokens: any, training_file: string, validation_file: any, integrations: any, seed: int, estimated_finish: any, method: record<type: string, supervised: record<hyperparameters: record>, dpo: record<hyperparameters: record>, reinforcement: record<grader: record, hyperparameters: record>>, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine_tuning/jobs")
  let body = {model: $model, training_file: $training_file, hyperparameters: $hyperparameters, suffix: $suffix, validation_file: $validation_file, integrations: $integrations, seed: $seed, method: $method, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List your organization's fine-tuning jobs
#
# GET /fine_tuning/jobs
# operationId: listPaginatedFineTuningJobs
export def "fine-tuning-jobs listPaginatedFineTuningJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Identifier for the last job from the previous pagination request.
  --limit: int # Number of fine-tuning jobs to retrieve. (default: 20)
  --metadata: record # Optional metadata filter. To filter, use the syntax `metadata[k]=v`. Alternatively, set `metadata=null` to indicate no metadata.  (nullable)
]: nothing -> record<data: table<id: string, created_at: int, error: any, fine_tuned_model: any, finished_at: any, hyperparameters: record, model: string, object: string, organization_id: string, result_files: list, status: string, trained_tokens: any, training_file: string, validation_file: any, integrations: any, seed: int, estimated_finish: any, method: record, metadata: any>, has_more: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "metadata" $metadata "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/fine_tuning/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get info about a fine-tuning job.  [Learn more about fine-tuning](/docs/guides/model-optimization)
#
# GET /fine_tuning/jobs/{fine_tuning_job_id}
# operationId: retrieveFineTuningJob
export def "fine-tuning-jobs retrieveFineTuningJob" [
  fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: int, error: any, fine_tuned_model: any, finished_at: any, hyperparameters: record<batch_size: any, learning_rate_multiplier: any, n_epochs: any>, model: string, object: string, organization_id: string, result_files: list<string>, status: string, trained_tokens: any, training_file: string, validation_file: any, integrations: any, seed: int, estimated_finish: any, method: record<type: string, supervised: record<hyperparameters: record>, dpo: record<hyperparameters: record>, reinforcement: record<grader: record, hyperparameters: record>>, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine_tuning/jobs/($fine_tuning_job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Immediately cancel a fine-tune job.
#
# POST /fine_tuning/jobs/{fine_tuning_job_id}/cancel
# operationId: cancelFineTuningJob
export def "fine-tuning-jobs-cancel cancelFineTuningJob" [
  fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: int, error: any, fine_tuned_model: any, finished_at: any, hyperparameters: record<batch_size: any, learning_rate_multiplier: any, n_epochs: any>, model: string, object: string, organization_id: string, result_files: list<string>, status: string, trained_tokens: any, training_file: string, validation_file: any, integrations: any, seed: int, estimated_finish: any, method: record<type: string, supervised: record<hyperparameters: record>, dpo: record<hyperparameters: record>, reinforcement: record<grader: record, hyperparameters: record>>, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine_tuning/jobs/($fine_tuning_job_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List checkpoints for a fine-tuning job.
#
# GET /fine_tuning/jobs/{fine_tuning_job_id}/checkpoints
# operationId: listFineTuningJobCheckpoints
export def "fine-tuning-jobs-checkpoints listFineTuningJobCheckpoints" [
  fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Identifier for the last checkpoint ID from the previous pagination request.
  --limit: int # Number of checkpoints to retrieve. (default: 10)
]: nothing -> record<data: table<id: string, created_at: int, fine_tuned_model_checkpoint: string, step_number: int, metrics: record, fine_tuning_job_id: string, object: string>, object: string, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fine_tuning/jobs/($fine_tuning_job_id)/checkpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get status updates for a fine-tuning job.
#
# GET /fine_tuning/jobs/{fine_tuning_job_id}/events
# operationId: listFineTuningEvents
export def "fine-tuning-jobs-events listFineTuningEvents" [
  fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Identifier for the last event from the previous pagination request.
  --limit: int # Number of events to retrieve. (default: 20)
]: nothing -> record<data: table<object: string, id: string, created_at: int, level: string, message: string, type: string, data: record>, object: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/fine_tuning/jobs/($fine_tuning_job_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause a fine-tune job.
#
# POST /fine_tuning/jobs/{fine_tuning_job_id}/pause
# operationId: pauseFineTuningJob
export def "fine-tuning-jobs-pause pauseFineTuningJob" [
  fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: int, error: any, fine_tuned_model: any, finished_at: any, hyperparameters: record<batch_size: any, learning_rate_multiplier: any, n_epochs: any>, model: string, object: string, organization_id: string, result_files: list<string>, status: string, trained_tokens: any, training_file: string, validation_file: any, integrations: any, seed: int, estimated_finish: any, method: record<type: string, supervised: record<hyperparameters: record>, dpo: record<hyperparameters: record>, reinforcement: record<grader: record, hyperparameters: record>>, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine_tuning/jobs/($fine_tuning_job_id)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume a fine-tune job.
#
# POST /fine_tuning/jobs/{fine_tuning_job_id}/resume
# operationId: resumeFineTuningJob
export def "fine-tuning-jobs-resume resumeFineTuningJob" [
  fine_tuning_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: int, error: any, fine_tuned_model: any, finished_at: any, hyperparameters: record<batch_size: any, learning_rate_multiplier: any, n_epochs: any>, model: string, object: string, organization_id: string, result_files: list<string>, status: string, trained_tokens: any, training_file: string, validation_file: any, integrations: any, seed: int, estimated_finish: any, method: record<type: string, supervised: record<hyperparameters: record>, dpo: record<hyperparameters: record>, reinforcement: record<grader: record, hyperparameters: record>>, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fine_tuning/jobs/($fine_tuning_job_id)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an edited or extended image given one or more source images and a prompt. This endpoint supports GPT Image models (`gpt-image-1.5`, `gpt-image-1`, `gpt-image-1-mini`, and `chatgpt-image-latest`) and `dall-e-2`.
#
# POST /images/edits
# operationId: createImageEdit
# --images item shape: {image_url?: string, file_id?: string}
# --mask shape: {image_url?: string, file_id?: string}
export def "images-edits createImageEdit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --model: any # The model to use for image editing. (default: gpt-image-1.5, e.g. gpt-image-1.5)
  images: list # Input image references to edit. For GPT image models, you can provide up to 16 images. — item shape: {image_url?: string, file_id?: string}
  --mask: record # Reference an input image by either URL or uploaded file ID. Provide exactly one of `image_url` or `file_id`. — shape: {image_url?: string, file_id?: string}
  prompt: string # A text description of the desired image edit. (e.g. Add a watercolor effect and keep the subject centered)
  --n: any # The number of edited images to generate. (default: 1, e.g. 1)
  --quality: any # Output quality for GPT image models.  (default: auto, e.g. high)
  --input-fidelity: any # Controls fidelity to the original input image(s).
  --size: any # Requested output image size. (default: auto, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI monitor and detect abuse.  (e.g. user-1234)
  --output-format: any # Output image format. Supported for GPT image models. (default: png, e.g. png)
  --output-compression: any # Compression level for `jpeg` or `webp` output. (e.g. 100)
  --moderation: any # Moderation level for GPT image models. (default: auto, e.g. auto)
  --background: any # Background behavior for generated image output. (default: auto, e.g. transparent)
  --stream: any # Stream partial image results as events. (default: false, e.g. false)
  --partial-images: any
]: any -> record<created: int, data: table<b64_json: string, url: string, revised_prompt: string>, background: string, output_format: string, size: string, quality: string, usage: record<input_tokens: int, total_tokens: int, output_tokens: int, output_tokens_details: record<image_tokens: int, text_tokens: int>, input_tokens_details: record<text_tokens: int, image_tokens: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/edits")
  let body = {model: $model, images: $images, mask: $mask, prompt: $prompt, n: $n, quality: $quality, input_fidelity: $input_fidelity, size: $size, user: $user, output_format: $output_format, output_compression: $output_compression, moderation: $moderation, background: $background, stream: $stream, partial_images: $partial_images} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an image given a prompt. [Learn more](/docs/guides/images).
#
# POST /images/generations
# operationId: createImage
export def "images-generations createImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  prompt: string # A text description of the desired image(s). The maximum length is 32000 characters for the GPT image models, 1000 characters for `dall-e-2` and 4000 characters for `dall-e-3`. (e.g. A cute baby sea otter)
  --model: any # The model to use for image generation. One of `dall-e-2`, `dall-e-3`, or a GPT image model (`gpt-image-1`, `gpt-image-1-mini`, `gpt-image-1.5`). Defaults to `dall-e-2` unless a parameter specific to the GPT image models is used. (nullable, default: dall-e-2, e.g. gpt-image-1.5)
  --n: int # The number of images to generate. Must be between 1 and 10. For `dall-e-3`, only `n=1` is supported. (nullable, default: 1, e.g. 1)
  --quality: string@quality-completer # The quality of the image that will be generated.  - `auto` (default value) will automatically select the best quality for the given model. - `high`, `medium` and `low` are supported for the GPT image models. - `hd` and `standard` are supported for `dall-e-3`. - `standard` is the only option for `dall-e-2`.  (nullable, default: auto, e.g. medium)
  --response-format: string@response-format-completer-3 # The format in which generated images with `dall-e-2` and `dall-e-3` are returned. Must be one of `url` or `b64_json`. URLs are only valid for 60 minutes after the image has been generated. This parameter isn't supported for the GPT image models, which always return base64-encoded images. (nullable, default: url, e.g. url)
  --output-format: string@output-format-completer # The format in which the generated images are returned. This parameter is only supported for the GPT image models. Must be one of `png`, `jpeg`, or `webp`. (nullable, default: png, e.g. png)
  --output-compression: int # The compression level (0-100%) for the generated images. This parameter is only supported for the GPT image models with the `webp` or `jpeg` output formats, and defaults to 100. (nullable, default: 100, e.g. 100)
  --stream: string@bool-completer # Generate the image in streaming mode. Defaults to `false`. See the [Image generation guide](/docs/guides/image-generation) for more information. This parameter is only supported for the GPT image models.  (nullable, default: false, e.g. false)
  --partial-images: any
  --size: any # The size of the generated images. For `gpt-image-2` and `gpt-image-2-2026-04-21`, arbitrary resolutions are supported as `WIDTHxHEIGHT` strings, for example `1536x864`. Width and height must both be divisible by 16 and the requested aspect ratio must be between 1:3 and 3:1. Resolutions above `2560x1440` are experimental, and the maximum supported resolution is `3840x2160`. The requested size must also satisfy the model's current pixel and edge limits. The standard sizes `1024x1024`, `1536x1024`, and `1024x1536` are supported by the GPT image models; `auto` is supported for models that allow automatic sizing. For `dall-e-2`, use one of `256x256`, `512x512`, or `1024x1024`. For `dall-e-3`, use one of `1024x1024`, `1792x1024`, or `1024x1792`. (nullable, default: auto, e.g. 1024x1024)
  --moderation: string@moderation-completer # Control the content-moderation level for images generated by the GPT image models. Must be either `low` for less restrictive filtering or `auto` (default value). (nullable, default: auto, e.g. low)
  --background: string@background-completer # Allows to set transparency for the background of the generated image(s). This parameter is only supported for the GPT image models. Must be one of `transparent`, `opaque` or `auto` (default value). When `auto` is used, the model will automatically determine the best background for the image.  If `transparent`, the output format needs to support transparency, so it should be set to either `png` (default value) or `webp`.  (nullable, default: auto, e.g. transparent)
  --style: string@style-completer # The style of the generated images. This parameter is only supported for `dall-e-3`. Must be one of `vivid` or `natural`. Vivid causes the model to lean towards generating hyper-real and dramatic images. Natural causes the model to produce more natural, less hyper-real looking images. (nullable, default: vivid, e.g. vivid)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices#end-user-ids).  (e.g. user-1234)
]: any -> record<created: int, data: table<b64_json: string, url: string, revised_prompt: string>, background: string, output_format: string, size: string, quality: string, usage: record<input_tokens: int, total_tokens: int, output_tokens: int, output_tokens_details: record<image_tokens: int, text_tokens: int>, input_tokens_details: record<text_tokens: int, image_tokens: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/generations")
  let body = {prompt: $prompt, model: $model, n: $n, quality: $quality, response_format: $response_format, output_format: $output_format, output_compression: $output_compression, stream: $stream, partial_images: $partial_images, size: $size, moderation: $moderation, background: $background, style: $style, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a variation of a given image. This endpoint only supports `dall-e-2`.
#
# POST /images/variations
# operationId: createImageVariation
export def "images-variations createImageVariation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  image: string # The image to use as the basis for the variation(s). Must be a valid PNG file, less than 4MB, and square. (format: binary)
  --model: any # The model to use for image generation. Only `dall-e-2` is supported at this time. (nullable, default: dall-e-2, e.g. dall-e-2)
  --n: int # The number of images to generate. Must be between 1 and 10. (nullable, default: 1, e.g. 1)
  --response-format: string@response-format-completer-3 # The format in which the generated images are returned. Must be one of `url` or `b64_json`. URLs are only valid for 60 minutes after the image has been generated. (nullable, default: url, e.g. url)
  --size: string@size-completer # The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024`. (nullable, default: 1024x1024, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices#end-user-ids).  (e.g. user-1234)
]: any -> record<created: int, data: table<b64_json: string, url: string, revised_prompt: string>, background: string, output_format: string, size: string, quality: string, usage: record<input_tokens: int, total_tokens: int, output_tokens: int, output_tokens_details: record<image_tokens: int, text_tokens: int>, input_tokens_details: record<text_tokens: int, image_tokens: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/variations")
  let body = {image: $image, model: $model, n: $n, response_format: $response_format, size: $size, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Lists the currently available models, and provides basic information about each one such as the owner and availability.
#
# GET /models
# operationId: listModels
export def "models listModels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, data: table<id: string, created: int, object: string, owned_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a model instance, providing basic information about the model such as the owner and permissioning.
#
# GET /models/{model}
# operationId: retrieveModel
export def "models retrieveModel" [
  model: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created: int, object: string, owned_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a fine-tuned model. You must have the Owner role in your organization to delete a model.
#
# DELETE /models/{model}
# operationId: deleteModel
export def "models delete" [
  model: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Classifies if text and/or image inputs are potentially harmful. Learn more in the [moderation guide](/docs/guides/moderation).
#
# POST /moderations
# operationId: createModeration
export def "moderations createModeration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  input: any # Input (or inputs) to classify. Can be a single string, an array of strings, or an array of multi-modal input objects similar to other models.
  --model: any # The content moderation model you would like to use. Learn more in [the moderation guide](/docs/guides/moderation), and learn about available models [here](/docs/models#moderation).  (default: omni-moderation-latest, e.g. omni-moderation-2024-09-26)
]: any -> record<id: string, model: string, results: table<flagged: bool, categories: record, category_scores: record, category_applied_input_types: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderations")
  let body = {input: $input, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List organization API keys
#
# GET /organization/admin_api_keys
# operationId: admin-api-keys-list
export def "organization-admin-api-keys admin-api-keys-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # nullable
  --order: string@order-completer # default: asc
  --limit: int # default: 20
]: nothing -> record<object: string, data: table<object: string, id: string, name: any, redacted_value: string, created_at: int, last_used_at: any, owner: record>, has_more: bool, first_id: any, last_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/admin_api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization admin API key
#
# POST /organization/admin_api_keys
# operationId: admin-api-keys-create
export def "organization-admin-api-keys admin-api-keys-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # e.g. New Admin Key
]: any -> record<object: string, id: string, name: any, redacted_value: string, created_at: int, last_used_at: any, owner: record<type: string, object: string, id: string, name: string, created_at: int, role: string>, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/admin_api_keys")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single organization API key
#
# GET /organization/admin_api_keys/{key_id}
# operationId: admin-api-keys-get
export def "organization-admin-api-keys admin-api-keys-get" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: any, redacted_value: string, created_at: int, last_used_at: any, owner: record<type: string, object: string, id: string, name: string, created_at: int, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/admin_api_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization admin API key
#
# DELETE /organization/admin_api_keys/{key_id}
# operationId: admin-api-keys-delete
export def "organization-admin-api-keys admin-api-keys-delete" [
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/admin_api_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user actions and configuration changes within this organization.
#
# GET /organization/audit_logs
# operationId: list-audit-logs
export def "organization-audit-logs list-audit-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --effective-at: record # Return only events whose `effective_at` (Unix seconds) is in this range.
  --project-ids: list # Return only events for these projects.
  --event-types: list # Return only events with a `type` in one of these values. For example, `project.created`. For all options, see the documentation for the [audit log object](/docs/api-reference/audit-logs/object).
  --actor-ids: list # Return only events performed by these actors. Can be a user ID, a service account ID, or an api key tracking ID.
  --actor-emails: list # Return only events performed by users with these emails.
  --resource-ids: list # Return only events performed on these targets. For example, a project ID updated.
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
]: nothing -> record<object: string, data: table<id: string, type: string, effective_at: int, project: record, actor: any, api_key_created: record, api_key_updated: record, api_key_deleted: record, checkpoint_permission_created: record, checkpoint_permission_deleted: record, external_key_registered: record, external_key_removed: record, group_created: record, group_updated: record, group_deleted: record, scim_enabled: record, scim_disabled: record, invite_sent: record, invite_accepted: record, invite_deleted: record, ip_allowlist_created: record, ip_allowlist_updated: record, ip_allowlist_deleted: record, ip_allowlist_config_activated: record, ip_allowlist_config_deactivated: record, login_succeeded: record, login_failed: record, logout_succeeded: record, logout_failed: record, organization_updated: record, project_created: record, project_updated: record, project_archived: record, project_deleted: record, rate_limit_updated: record, rate_limit_deleted: record, role_created: record, role_updated: record, role_deleted: record, role_assignment_created: record, role_assignment_deleted: record, service_account_created: record, service_account_updated: record, service_account_deleted: record, user_added: record, user_updated: record, user_deleted: record, certificate_created: record, certificate_updated: record, certificate_deleted: record, certificates_activated: record, certificates_deactivated: record>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "effective_at" $effective_at "multi") (serialize-qp "project_ids[]" $project_ids "multi") (serialize-qp "event_types[]" $event_types "multi") (serialize-qp "actor_ids[]" $actor_ids "multi") (serialize-qp "actor_emails[]" $actor_emails "multi") (serialize-qp "resource_ids[]" $resource_ids "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/audit_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List uploaded certificates for this organization.
#
# GET /organization/certificates
# operationId: listOrganizationCertificates
export def "organization-certificates listOrganizationCertificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
]: nothing -> record<data: table<object: string, id: string, name: any, created_at: int, certificate_details: record, active: bool>, first_id: any, last_id: any, has_more: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a certificate to the organization. This does **not** automatically activate the certificate.  Organizations can upload up to 50 certificates.
#
# POST /organization/certificates
# operationId: uploadCertificate
export def "organization-certificates uploadCertificate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # An optional name for the certificate
  certificate: string # The certificate content in PEM format
]: any -> record<object: string, id: string, name: any, created_at: int, certificate_details: record<valid_at: int, expires_at: int, content: string>, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/certificates")
  let body = {name: $name, certificate: $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activate certificates at the organization level.  You can atomically and idempotently activate up to 10 certificates at a time.
#
# POST /organization/certificates/activate
# operationId: activateOrganizationCertificates
export def "organization-certificates-activate activateOrganizationCertificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  certificate_ids: list
]: any -> record<object: string, data: table<object: string, id: string, name: any, created_at: int, certificate_details: record, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/certificates/activate")
  let body = {certificate_ids: $certificate_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate certificates at the organization level.  You can atomically and idempotently deactivate up to 10 certificates at a time.
#
# POST /organization/certificates/deactivate
# operationId: deactivateOrganizationCertificates
export def "organization-certificates-deactivate deactivateOrganizationCertificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  certificate_ids: list
]: any -> record<object: string, data: table<object: string, id: string, name: any, created_at: int, certificate_details: record, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/certificates/deactivate")
  let body = {certificate_ids: $certificate_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a certificate that has been uploaded to the organization.  You can get a certificate regardless of whether it is active or not.
#
# GET /organization/certificates/{certificate_id}
# operationId: getCertificate
export def "organization-certificates get" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # A list of additional fields to include in the response. Currently the only supported value is `content` to fetch the PEM content of the certificate.
]: nothing -> record<object: string, id: string, name: any, created_at: int, certificate_details: record<valid_at: int, expires_at: int, content: string>, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/certificates/($certificate_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify a certificate. Note that only the name can be modified.
#
# POST /organization/certificates/{certificate_id}
# operationId: modifyCertificate
export def "organization-certificates modifyCertificate" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The updated name for the certificate
]: any -> record<object: string, id: string, name: any, created_at: int, certificate_details: record<valid_at: int, expires_at: int, content: string>, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/certificates/($certificate_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a certificate from the organization.  The certificate must be inactive for the organization and all projects.
#
# DELETE /organization/certificates/{certificate_id}
# operationId: deleteCertificate
export def "organization-certificates delete" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/certificates/($certificate_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get costs details for the organization.
#
# GET /organization/costs
# operationId: usage-costs
export def "organization-costs usage-costs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer # Width of each time bucket in response. Currently only `1d` is supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only costs for these projects.
  --api-key-ids: list # Return only costs for these API keys.
  --group-by: list # Group the costs by the specified fields. Support fields include `project_id`, `line_item`, `api_key_id` and any combination of them.
  --limit: int # A limit on the number of buckets to be returned. Limit can range between 1 and 180, and the default is 7.  (default: 7)
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "api_key_ids" $api_key_ids "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/costs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all groups in the organization.
#
# GET /organization/groups
# operationId: list-groups
export def "organization-groups list-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of groups to be returned. Limit can range between 0 and 1000, and the default is 100.  (default: 100)
  --after: string # A cursor for use in pagination. `after` is a group ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with group_abc, your subsequent call can include `after=group_abc` in order to fetch the next page of the list.
  --order: string@order-completer # Specifies the sort order of the returned groups. (default: asc)
]: nothing -> record<object: string, data: table<id: string, name: string, created_at: int, is_scim_managed: bool, group_type: string>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new group in the organization.
#
# POST /organization/groups
# operationId: create-group
export def "organization-groups create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Human readable name for the group.
]: any -> record<id: string, name: string, created_at: int, is_scim_managed: bool, group_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/groups")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a group's information.
#
# POST /organization/groups/{group_id}
# operationId: update-group
export def "organization-groups update-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # New display name for the group.
]: any -> record<id: string, name: string, created_at: int, is_scim_managed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/groups/($group_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a group from the organization.
#
# DELETE /organization/groups/{group_id}
# operationId: delete-group
export def "organization-groups delete-group" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the organization roles assigned to a group within the organization.
#
# GET /organization/groups/{group_id}/roles
# operationId: list-group-role-assignments
export def "organization-groups-roles list-group-role-assignments" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of organization role assignments to return.
  --after: string # Cursor for pagination. Provide the value from the previous response's `next` field to continue listing organization roles.
  --order: string@order-completer # Sort order for the returned organization roles.
]: nothing -> record<object: string, data: table<id: string, name: string, permissions: list, resource_type: string, predefined_role: bool, description: any, created_at: any, updated_at: any, created_by: any, created_by_user_obj: any, metadata: any>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/groups/($group_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assigns an organization role to a group within the organization.
#
# POST /organization/groups/{group_id}/roles
# operationId: assign-group-role
export def "organization-groups-roles assign-group-role" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_id: string # Identifier of the role to assign.
]: any -> record<object: string, group: record<object: string, id: string, name: string, created_at: int, scim_managed: bool>, role: record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/groups/($group_id)/roles")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassigns an organization role from a group within the organization.
#
# DELETE /organization/groups/{group_id}/roles/{role_id}
# operationId: unassign-group-role
export def "organization-groups-roles unassign-group-role" [
  group_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/groups/($group_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the users assigned to a group.
#
# GET /organization/groups/{group_id}/users
# operationId: list-group-users
export def "organization-groups-users list-group-users" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of users to be returned. Limit can range between 0 and 1000, and the default is 100.  (default: 100)
  --after: string # A cursor for use in pagination. Provide the ID of the last user from the previous list response to retrieve the next page.
  --order: string@order-completer # Specifies the sort order of users in the list. (default: desc)
]: nothing -> record<object: string, data: table<id: string, name: string, email: any>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/groups/($group_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a user to a group.
#
# POST /organization/groups/{group_id}/users
# operationId: add-group-user
export def "organization-groups-users add-group-user" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # Identifier of the user to add to the group.
]: any -> record<object: string, user_id: string, group_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/groups/($group_id)/users")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes a user from a group.
#
# DELETE /organization/groups/{group_id}/users/{user_id}
# operationId: remove-group-user
export def "organization-groups-users remove-group-user" [
  group_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/groups/($group_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of invites in the organization.
#
# GET /organization/invites
# operationId: list-invites
export def "organization-invites list-invites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
]: nothing -> record<object: string, data: table<object: string, id: string, email: string, role: string, status: string, created_at: int, expires_at: any, accepted_at: any, projects: list>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an invite for a user to the organization. The invite must be accepted by the user before they have access to the organization.
#
# POST /organization/invites
# operationId: inviteUser
# --projects item shape: {id: string, role: "member"|"owner"}
export def "organization-invites inviteUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Send an email to this address
  role: string@role-completer # `owner` or `reader`
  --projects: list # An array of projects to which membership is granted at the same time the org invite is accepted. If omitted, the user will be invited to the default project for compatibility with legacy behavior. — item shape: {id: string, role: "member"|"owner"}
]: any -> record<object: string, id: string, email: string, role: string, status: string, created_at: int, expires_at: any, accepted_at: any, projects: table<id: string, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/invites")
  let body = {email: $email, role: $role, projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves an invite.
#
# GET /organization/invites/{invite_id}
# operationId: retrieve-invite
export def "organization-invites retrieve-invite" [
  invite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, email: string, role: string, status: string, created_at: int, expires_at: any, accepted_at: any, projects: table<id: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/invites/($invite_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an invite. If the invite has already been accepted, it cannot be deleted.
#
# DELETE /organization/invites/{invite_id}
# operationId: delete-invite
export def "organization-invites delete-invite" [
  invite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/invites/($invite_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of projects.
#
# GET /organization/projects
# operationId: list-projects
export def "organization-projects list-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --include-archived: string@bool-completer # If `true` returns all projects including those that have been `archived`. Archived projects are not included by default. (default: false)
]: nothing -> record<object: string, data: table<id: string, object: string, name: any, created_at: int, archived_at: any, status: any, external_key_id: any>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new project in the organization. Projects can be created and archived, but cannot be deleted.
#
# POST /organization/projects
# operationId: create-project
export def "organization-projects create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The friendly name of the project, this name appears in reports.
  --geography: any # Create the project with the specified data residency region. Your organization must have access to Data residency functionality in order to use. See [data residency controls](/docs/guides/your-data#data-residency-controls) to review the functionality and limitations of setting this field.
  --external-key-id: any # External key ID to associate with the project.
]: any -> record<id: string, object: string, name: any, created_at: int, archived_at: any, status: any, external_key_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/projects")
  let body = {name: $name, geography: $geography, external_key_id: $external_key_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a project.
#
# GET /organization/projects/{project_id}
# operationId: retrieve-project
export def "organization-projects retrieve-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: any, created_at: int, archived_at: any, status: any, external_key_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies a project in the organization.
#
# POST /organization/projects/{project_id}
# operationId: modify-project
export def "organization-projects modify-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: any # The updated name of the project, this name appears in reports.
  --external-key-id: any # External key ID to associate with the project.
  --geography: any # Geography for the project.
]: any -> record<id: string, object: string, name: any, created_at: int, archived_at: any, status: any, external_key_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)")
  let body = {name: $name, external_key_id: $external_key_id, geography: $geography} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of API keys in the project.
#
# GET /organization/projects/{project_id}/api_keys
# operationId: list-project-api-keys
export def "organization-projects-api-keys list-project-api-keys" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
]: nothing -> record<object: string, data: table<object: string, redacted_value: string, name: string, created_at: int, last_used_at: any, id: string, owner: record>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/projects/($project_id)/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves an API key in the project.
#
# GET /organization/projects/{project_id}/api_keys/{api_key_id}
# operationId: retrieve-project-api-key
export def "organization-projects-api-keys retrieve-project-api-key" [
  project_id: string
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, redacted_value: string, name: string, created_at: int, last_used_at: any, id: string, owner: record<type: string, user: record<id: string, email: string, name: string, created_at: int, role: string>, service_account: record<id: string, name: string, created_at: int, role: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/api_keys/($api_key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an API key from the project.  Returns confirmation of the key deletion, or an error if the key belonged to a service account.
#
# DELETE /organization/projects/{project_id}/api_keys/{api_key_id}
# operationId: delete-project-api-key
export def "organization-projects-api-keys delete-project-api-key" [
  project_id: string
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/api_keys/($api_key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archives a project in the organization. Archived projects cannot be used or updated.
#
# POST /organization/projects/{project_id}/archive
# operationId: archive-project
export def "organization-projects-archive archive-project" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: any, created_at: int, archived_at: any, status: any, external_key_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List certificates for this project.
#
# GET /organization/projects/{project_id}/certificates
# operationId: listProjectCertificates
export def "organization-projects-certificates listProjectCertificates" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
]: nothing -> record<data: table<object: string, id: string, name: any, created_at: int, certificate_details: record, active: bool>, first_id: any, last_id: any, has_more: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/projects/($project_id)/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate certificates at the project level.  You can atomically and idempotently activate up to 10 certificates at a time.
#
# POST /organization/projects/{project_id}/certificates/activate
# operationId: activateProjectCertificates
export def "organization-projects-certificates-activate activateProjectCertificates" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  certificate_ids: list
]: any -> record<object: string, data: table<object: string, id: string, name: any, created_at: int, certificate_details: record, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/certificates/activate")
  let body = {certificate_ids: $certificate_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate certificates at the project level. You can atomically and  idempotently deactivate up to 10 certificates at a time.
#
# POST /organization/projects/{project_id}/certificates/deactivate
# operationId: deactivateProjectCertificates
export def "organization-projects-certificates-deactivate deactivateProjectCertificates" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  certificate_ids: list
]: any -> record<object: string, data: table<object: string, id: string, name: any, created_at: int, certificate_details: record, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/certificates/deactivate")
  let body = {certificate_ids: $certificate_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the groups that have access to a project.
#
# GET /organization/projects/{project_id}/groups
# operationId: list-project-groups
export def "organization-projects-groups list-project-groups" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of project groups to return. Defaults to 20. (default: 20)
  --after: string # Cursor for pagination. Provide the ID of the last group from the previous response to fetch the next page.
  --order: string@order-completer # Sort order for the returned groups. (default: asc)
]: nothing -> record<object: string, data: table<object: string, project_id: string, group_id: string, group_name: string, group_type: string, created_at: int>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/projects/($project_id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Grants a group access to a project.
#
# POST /organization/projects/{project_id}/groups
# operationId: add-project-group
export def "organization-projects-groups add-project-group" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  group_id: string # Identifier of the group to add to the project.
  role: string # Identifier of the project role to grant to the group.
]: any -> record<object: string, project_id: string, group_id: string, group_name: string, group_type: string, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/groups")
  let body = {group_id: $group_id, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revokes a group's access to a project.
#
# DELETE /organization/projects/{project_id}/groups/{group_id}
# operationId: remove-project-group
export def "organization-projects-groups remove-project-group" [
  project_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the rate limits per model for a project.
#
# GET /organization/projects/{project_id}/rate_limits
# operationId: list-project-rate-limits
export def "organization-projects-rate-limits list-project-rate-limits" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. The default is 100.  (default: 100)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, beginning with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
]: nothing -> record<object: string, data: table<object: string, id: string, model: string, max_requests_per_1_minute: int, max_tokens_per_1_minute: int, max_images_per_1_minute: int, max_audio_megabytes_per_1_minute: int, max_requests_per_1_day: int, batch_1_day_max_input_tokens: int>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/projects/($project_id)/rate_limits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a project rate limit.
#
# POST /organization/projects/{project_id}/rate_limits/{rate_limit_id}
# operationId: update-project-rate-limits
export def "organization-projects-rate-limits update-project-rate-limits" [
  project_id: string
  rate_limit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-requests-per-1-minute: int # The maximum requests per minute.
  --max-tokens-per-1-minute: int # The maximum tokens per minute.
  --max-images-per-1-minute: int # The maximum images per minute. Only relevant for certain models.
  --max-audio-megabytes-per-1-minute: int # The maximum audio megabytes per minute. Only relevant for certain models.
  --max-requests-per-1-day: int # The maximum requests per day. Only relevant for certain models.
  --batch-1-day-max-input-tokens: int # The maximum batch input tokens per day. Only relevant for certain models.
]: any -> record<object: string, id: string, model: string, max_requests_per_1_minute: int, max_tokens_per_1_minute: int, max_images_per_1_minute: int, max_audio_megabytes_per_1_minute: int, max_requests_per_1_day: int, batch_1_day_max_input_tokens: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/rate_limits/($rate_limit_id)")
  let body = {max_requests_per_1_minute: $max_requests_per_1_minute, max_tokens_per_1_minute: $max_tokens_per_1_minute, max_images_per_1_minute: $max_images_per_1_minute, max_audio_megabytes_per_1_minute: $max_audio_megabytes_per_1_minute, max_requests_per_1_day: $max_requests_per_1_day, batch_1_day_max_input_tokens: $batch_1_day_max_input_tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of service accounts in the project.
#
# GET /organization/projects/{project_id}/service_accounts
# operationId: list-project-service-accounts
export def "organization-projects-service-accounts list-project-service-accounts" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
]: nothing -> record<object: string, data: table<object: string, id: string, name: string, role: string, created_at: int>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/projects/($project_id)/service_accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new service account in the project. This also returns an unredacted API key for the service account.
#
# POST /organization/projects/{project_id}/service_accounts
# operationId: create-project-service-account
export def "organization-projects-service-accounts create-project-service-account" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the service account being created.
]: any -> record<object: string, id: string, name: string, role: string, created_at: int, api_key: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/service_accounts")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a service account in the project.
#
# GET /organization/projects/{project_id}/service_accounts/{service_account_id}
# operationId: retrieve-project-service-account
export def "organization-projects-service-accounts retrieve-project-service-account" [
  project_id: string
  service_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: string, role: string, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/service_accounts/($service_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a service account from the project.  Returns confirmation of service account deletion, or an error if the project is archived (archived projects have no service accounts).
#
# DELETE /organization/projects/{project_id}/service_accounts/{service_account_id}
# operationId: delete-project-service-account
export def "organization-projects-service-accounts delete-project-service-account" [
  project_id: string
  service_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/service_accounts/($service_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of users in the project.
#
# GET /organization/projects/{project_id}/users
# operationId: list-project-users
export def "organization-projects-users list-project-users" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
]: nothing -> record<object: string, data: table<object: string, id: string, name: any, email: any, role: string, added_at: int>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/projects/($project_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a user to the project. Users must already be members of the organization to be added to a project.
#
# POST /organization/projects/{project_id}/users
# operationId: create-project-user
export def "organization-projects-users create-project-user" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: any # The ID of the user.
  --email: any # Email of the user to add.
  role: string # `owner` or `member`
]: any -> record<object: string, id: string, name: any, email: any, role: string, added_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/users")
  let body = {user_id: $user_id, email: $email, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a user in the project.
#
# GET /organization/projects/{project_id}/users/{user_id}
# operationId: retrieve-project-user
export def "organization-projects-users retrieve-project-user" [
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: any, email: any, role: string, added_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies a user's role in the project.
#
# POST /organization/projects/{project_id}/users/{user_id}
# operationId: modify-project-user
export def "organization-projects-users modify-project-user" [
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: any # `owner` or `member`
]: any -> record<object: string, id: string, name: any, email: any, role: string, added_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/users/($user_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a user from the project.  Returns confirmation of project user deletion, or an error if the project is archived (archived projects have no users).
#
# DELETE /organization/projects/{project_id}/users/{user_id}
# operationId: delete-project-user
export def "organization-projects-users delete-project-user" [
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/projects/($project_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the roles configured for the organization.
#
# GET /organization/roles
# operationId: list-roles
export def "organization-roles list-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of roles to return. Defaults to 1000. (default: 1000)
  --after: string # Cursor for pagination. Provide the value from the previous response's `next` field to continue listing roles.
  --order: string@order-completer # Sort order for the returned roles. (default: asc)
]: nothing -> record<object: string, data: table<object: string, id: string, name: string, description: any, permissions: list, resource_type: string, predefined_role: bool>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a custom role for the organization.
#
# POST /organization/roles
# operationId: create-role
export def "organization-roles create-role" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_name: string # Unique name for the role.
  permissions: list # Permissions to grant to the role.
  --description: any # Optional description of the role.
]: any -> record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/roles")
  let body = {role_name: $role_name, permissions: $permissions, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates an existing organization role.
#
# POST /organization/roles/{role_id}
# operationId: update-role
export def "organization-roles update-role" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissions: any # Updated set of permissions for the role.
  --description: any # New description for the role.
  --role-name: any # New name for the role.
]: any -> record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/roles/($role_id)")
  let body = {permissions: $permissions, description: $description, role_name: $role_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a custom role from the organization.
#
# DELETE /organization/roles/{role_id}
# operationId: delete-role
export def "organization-roles delete-role" [
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audio speeches usage details for the organization.
#
# GET /organization/usage/audio_speeches
# operationId: usage-audio-speeches
export def "organization-usage-audio-speeches usage-audio-speeches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only usage for these projects.
  --user-ids: list # Return only usage for these users.
  --api-key-ids: list # Return only usage for these API keys.
  --models: list # Return only usage for these models.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`, `user_id`, `api_key_id`, `model` or any combination of them.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "user_ids" $user_ids "multi") (serialize-qp "api_key_ids" $api_key_ids "multi") (serialize-qp "models" $models "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/audio_speeches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get audio transcriptions usage details for the organization.
#
# GET /organization/usage/audio_transcriptions
# operationId: usage-audio-transcriptions
export def "organization-usage-audio-transcriptions usage-audio-transcriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only usage for these projects.
  --user-ids: list # Return only usage for these users.
  --api-key-ids: list # Return only usage for these API keys.
  --models: list # Return only usage for these models.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`, `user_id`, `api_key_id`, `model` or any combination of them.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "user_ids" $user_ids "multi") (serialize-qp "api_key_ids" $api_key_ids "multi") (serialize-qp "models" $models "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/audio_transcriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get code interpreter sessions usage details for the organization.
#
# GET /organization/usage/code_interpreter_sessions
# operationId: usage-code-interpreter-sessions
export def "organization-usage-code-interpreter-sessions usage-code-interpreter-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only usage for these projects.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/code_interpreter_sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get completions usage details for the organization.
#
# GET /organization/usage/completions
# operationId: usage-completions
export def "organization-usage-completions usage-completions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only usage for these projects.
  --user-ids: list # Return only usage for these users.
  --api-key-ids: list # Return only usage for these API keys.
  --models: list # Return only usage for these models.
  --batch: string@bool-completer # If `true`, return batch jobs only. If `false`, return non-batch jobs only. By default, return both.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`, `user_id`, `api_key_id`, `model`, `batch`, `service_tier` or any combination of them.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "user_ids" $user_ids "multi") (serialize-qp "api_key_ids" $api_key_ids "multi") (serialize-qp "models" $models "multi") (serialize-qp "batch" $batch "scalar") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/completions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get embeddings usage details for the organization.
#
# GET /organization/usage/embeddings
# operationId: usage-embeddings
export def "organization-usage-embeddings usage-embeddings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only usage for these projects.
  --user-ids: list # Return only usage for these users.
  --api-key-ids: list # Return only usage for these API keys.
  --models: list # Return only usage for these models.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`, `user_id`, `api_key_id`, `model` or any combination of them.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "user_ids" $user_ids "multi") (serialize-qp "api_key_ids" $api_key_ids "multi") (serialize-qp "models" $models "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/embeddings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get images usage details for the organization.
#
# GET /organization/usage/images
# operationId: usage-images
export def "organization-usage-images usage-images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --sources: list # Return only usages for these sources. Possible values are `image.generation`, `image.edit`, `image.variation` or any combination of them.
  --sizes: list # Return only usages for these image sizes. Possible values are `256x256`, `512x512`, `1024x1024`, `1792x1792`, `1024x1792` or any combination of them.
  --project-ids: list # Return only usage for these projects.
  --user-ids: list # Return only usage for these users.
  --api-key-ids: list # Return only usage for these API keys.
  --models: list # Return only usage for these models.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`, `user_id`, `api_key_id`, `model`, `size`, `source` or any combination of them.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "sources" $sources "multi") (serialize-qp "sizes" $sizes "multi") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "user_ids" $user_ids "multi") (serialize-qp "api_key_ids" $api_key_ids "multi") (serialize-qp "models" $models "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get moderations usage details for the organization.
#
# GET /organization/usage/moderations
# operationId: usage-moderations
export def "organization-usage-moderations usage-moderations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only usage for these projects.
  --user-ids: list # Return only usage for these users.
  --api-key-ids: list # Return only usage for these API keys.
  --models: list # Return only usage for these models.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`, `user_id`, `api_key_id`, `model` or any combination of them.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "user_ids" $user_ids "multi") (serialize-qp "api_key_ids" $api_key_ids "multi") (serialize-qp "models" $models "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/moderations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get vector stores usage details for the organization.
#
# GET /organization/usage/vector_stores
# operationId: usage-vector-stores
export def "organization-usage-vector-stores usage-vector-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-time: int # Start time (Unix seconds) of the query time range, inclusive.
  --end-time: int # End time (Unix seconds) of the query time range, exclusive.
  --bucket-width: string@bucket-width-completer-1 # Width of each time bucket in response. Currently `1m`, `1h` and `1d` are supported, default to `1d`. (default: 1d)
  --project-ids: list # Return only usage for these projects.
  --group-by: list # Group the usage data by the specified fields. Support fields include `project_id`.
  --limit: int # Specifies the number of buckets to return. - `bucket_width=1d`: default: 7, max: 31 - `bucket_width=1h`: default: 24, max: 168 - `bucket_width=1m`: default: 60, max: 1440
  --page: string # A cursor for use in pagination. Corresponding to the `next_page` field from the previous response.
]: nothing -> record<object: string, data: table<object: string, start_time: int, end_time: int, results: list>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "bucket_width" $bucket_width "scalar") (serialize-qp "project_ids" $project_ids "multi") (serialize-qp "group_by" $group_by "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/usage/vector_stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all of the users in the organization.
#
# GET /organization/users
# operationId: list-users
export def "organization-users list-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --emails: list # Filter by the email address of users.
]: nothing -> record<object: string, data: table<object: string, id: string, name: any, email: any, role: any, added_at: int, is_default: bool, created: int, user: record, is_service_account: bool, is_scale_tier_authorized_purchaser: any, is_scim_managed: bool, api_key_last_used_at: any, technical_level: any, developer_persona: any, projects: any>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "emails" $emails "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a user by their identifier.
#
# GET /organization/users/{user_id}
# operationId: retrieve-user
export def "organization-users retrieve-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: any, email: any, role: any, added_at: int, is_default: bool, created: int, user: record<object: string, id: string, email: any, name: any, picture: any, enabled: any, banned: any, banned_at: any>, is_service_account: bool, is_scale_tier_authorized_purchaser: any, is_scim_managed: bool, api_key_last_used_at: any, technical_level: any, developer_persona: any, projects: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies a user's role in the organization.
#
# POST /organization/users/{user_id}
# operationId: modify-user
export def "organization-users modify-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: any # `owner` or `reader`
  --role-id: any # Role ID to assign to the user.
  --technical-level: any # Technical level metadata.
  --developer-persona: any # Developer persona metadata.
]: any -> record<object: string, id: string, name: any, email: any, role: any, added_at: int, is_default: bool, created: int, user: record<object: string, id: string, email: any, name: any, picture: any, enabled: any, banned: any, banned_at: any>, is_service_account: bool, is_scale_tier_authorized_purchaser: any, is_scim_managed: bool, api_key_last_used_at: any, technical_level: any, developer_persona: any, projects: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/users/($user_id)")
  let body = {role: $role, role_id: $role_id, technical_level: $technical_level, developer_persona: $developer_persona} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a user from the organization.
#
# DELETE /organization/users/{user_id}
# operationId: delete-user
export def "organization-users delete-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the organization roles assigned to a user within the organization.
#
# GET /organization/users/{user_id}/roles
# operationId: list-user-role-assignments
export def "organization-users-roles list-user-role-assignments" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of organization role assignments to return.
  --after: string # Cursor for pagination. Provide the value from the previous response's `next` field to continue listing organization roles.
  --order: string@order-completer # Sort order for the returned organization roles.
]: nothing -> record<object: string, data: table<id: string, name: string, permissions: list, resource_type: string, predefined_role: bool, description: any, created_at: any, updated_at: any, created_by: any, created_by_user_obj: any, metadata: any>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/users/($user_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assigns an organization role to a user within the organization.
#
# POST /organization/users/{user_id}/roles
# operationId: assign-user-role
export def "organization-users-roles assign-user-role" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_id: string # Identifier of the role to assign.
]: any -> record<object: string, user: record<object: string, id: string, name: any, email: any, role: any, added_at: int, is_default: bool, created: int, user: record<object: string, id: string, email: any, name: any, picture: any, enabled: any, banned: any, banned_at: any>, is_service_account: bool, is_scale_tier_authorized_purchaser: any, is_scim_managed: bool, api_key_last_used_at: any, technical_level: any, developer_persona: any, projects: any>, role: record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/users/($user_id)/roles")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassigns an organization role from a user within the organization.
#
# DELETE /organization/users/{user_id}/roles/{role_id}
# operationId: unassign-user-role
export def "organization-users-roles unassign-user-role" [
  user_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/users/($user_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the project roles assigned to a group within a project.
#
# GET /projects/{project_id}/groups/{group_id}/roles
# operationId: list-project-group-role-assignments
export def "projects-groups-roles list-project-group-role-assignments" [
  project_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of project role assignments to return.
  --after: string # Cursor for pagination. Provide the value from the previous response's `next` field to continue listing project roles.
  --order: string@order-completer # Sort order for the returned project roles.
]: nothing -> record<object: string, data: table<id: string, name: string, permissions: list, resource_type: string, predefined_role: bool, description: any, created_at: any, updated_at: any, created_by: any, created_by_user_obj: any, metadata: any>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/groups/($group_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assigns a project role to a group within a project.
#
# POST /projects/{project_id}/groups/{group_id}/roles
# operationId: assign-project-group-role
export def "projects-groups-roles assign-project-group-role" [
  project_id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_id: string # Identifier of the role to assign.
]: any -> record<object: string, group: record<object: string, id: string, name: string, created_at: int, scim_managed: bool>, role: record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/groups/($group_id)/roles")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassigns a project role from a group within a project.
#
# DELETE /projects/{project_id}/groups/{group_id}/roles/{role_id}
# operationId: unassign-project-group-role
export def "projects-groups-roles unassign-project-group-role" [
  project_id: string
  group_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/groups/($group_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the roles configured for a project.
#
# GET /projects/{project_id}/roles
# operationId: list-project-roles
export def "projects-roles list-project-roles" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of roles to return. Defaults to 1000. (default: 1000)
  --after: string # Cursor for pagination. Provide the value from the previous response's `next` field to continue listing roles.
  --order: string@order-completer # Sort order for the returned roles. (default: asc)
]: nothing -> record<object: string, data: table<object: string, id: string, name: string, description: any, permissions: list, resource_type: string, predefined_role: bool>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a custom role for a project.
#
# POST /projects/{project_id}/roles
# operationId: create-project-role
export def "projects-roles create-project-role" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_name: string # Unique name for the role.
  permissions: list # Permissions to grant to the role.
  --description: any # Optional description of the role.
]: any -> record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/roles")
  let body = {role_name: $role_name, permissions: $permissions, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates an existing project role.
#
# POST /projects/{project_id}/roles/{role_id}
# operationId: update-project-role
export def "projects-roles update-project-role" [
  project_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissions: any # Updated set of permissions for the role.
  --description: any # New description for the role.
  --role-name: any # New name for the role.
]: any -> record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/roles/($role_id)")
  let body = {permissions: $permissions, description: $description, role_name: $role_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a custom role from a project.
#
# DELETE /projects/{project_id}/roles/{role_id}
# operationId: delete-project-role
export def "projects-roles delete-project-role" [
  project_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the project roles assigned to a user within a project.
#
# GET /projects/{project_id}/users/{user_id}/roles
# operationId: list-project-user-role-assignments
export def "projects-users-roles list-project-user-role-assignments" [
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of project role assignments to return.
  --after: string # Cursor for pagination. Provide the value from the previous response's `next` field to continue listing project roles.
  --order: string@order-completer # Sort order for the returned project roles.
]: nothing -> record<object: string, data: table<id: string, name: string, permissions: list, resource_type: string, predefined_role: bool, description: any, created_at: any, updated_at: any, created_by: any, created_by_user_obj: any, metadata: any>, has_more: bool, next: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($project_id)/users/($user_id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assigns a project role to a user within a project.
#
# POST /projects/{project_id}/users/{user_id}/roles
# operationId: assign-project-user-role
export def "projects-users-roles assign-project-user-role" [
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_id: string # Identifier of the role to assign.
]: any -> record<object: string, user: record<object: string, id: string, name: any, email: any, role: any, added_at: int, is_default: bool, created: int, user: record<object: string, id: string, email: any, name: any, picture: any, enabled: any, banned: any, banned_at: any>, is_service_account: bool, is_scale_tier_authorized_purchaser: any, is_scim_managed: bool, api_key_last_used_at: any, technical_level: any, developer_persona: any, projects: any>, role: record<object: string, id: string, name: string, description: any, permissions: list<string>, resource_type: string, predefined_role: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/users/($user_id)/roles")
  let body = {role_id: $role_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassigns a project role from a user within a project.
#
# DELETE /projects/{project_id}/users/{user_id}/roles/{role_id}
# operationId: unassign-project-user-role
export def "projects-users-roles unassign-project-user-role" [
  project_id: string
  user_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($project_id)/users/($user_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Realtime API call over WebRTC and receive the SDP answer needed to complete the peer connection.
#
# POST /realtime/calls
# operationId: create-realtime-call
export def "realtime-calls create-realtime-call" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sdp: string # WebRTC Session Description Protocol (SDP) offer generated by the caller.
  --session: any # Optional session configuration to apply before the realtime session is created. Use the same parameters you would send in a [`create client secret`](/docs/api-reference/realtime-sessions/create-realtime-client-secret) request.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realtime/calls")
  let body = {sdp: $sdp, session: $session} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/sdp"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Accept an incoming SIP call and configure the realtime session that will handle it.
#
# POST /realtime/calls/{call_id}/accept
# operationId: accept-realtime-call
# --audio shape: {input?: record, output?: record}
# --reasoning shape: {effort?: "minimal"|"low"|"medium"|"high"|"xhigh"}
export def "realtime-calls-accept accept-realtime-call" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # The type of session to create. Always `realtime` for the Realtime API.
  --output-modalities: list # The set of modalities the model can respond with. It defaults to `["audio"]`, indicating that the model will respond with audio plus a transcript. `["text"]` can be used to make the model respond with text only. It is not possible to request both `text` and `audio` at the same time.  (default: [audio])
  --model: any # The Realtime model used for this session.
  --instructions: string # The default system instructions (i.e. system message) prepended to model calls. This field allows the client to guide the model on desired responses. The model can be instructed on response content and format, (e.g. "be extremely succinct", "act friendly", "here are examples of good responses") and on audio behavior (e.g. "talk quickly", "inject emotion into your voice", "laugh frequently"). The instructions are not guaranteed to be followed by the model, but they provide guidance to the model on the desired behavior.  Note that the server sets default instructions which will be used if this field is not set and are visible in the `session.created` event at the start of the session.
  --audio: record # Configuration for input and output audio. — shape: {input?: record, output?: record}
  --include: list # Additional fields to include in server outputs.  `item.input_audio_transcription.logprobs`: Include logprobs for input audio transcription.
  --tracing: any # Realtime API can write session traces to the [Traces Dashboard](https://platform.openai.com/logs?api=traces). Set to null to disable tracing. Once tracing is enabled for a session, the configuration cannot be modified.  `auto` will create a trace for the session with default values for the workflow name, group id, and metadata.  (nullable)
  --tools: list # Tools available to the model.
  --tool-choice: any # How the model chooses tools. Provide one of the string modes or force a specific function/MCP tool.  (default: auto)
  --parallel-tool-calls: string@bool-completer # Whether the model may call multiple tools in parallel. Only supported by reasoning Realtime models such as `gpt-realtime-2`.
  --reasoning: record # Configuration for reasoning-capable Realtime models such as `gpt-realtime-2`. — shape: {effort?: "minimal"|"low"|"medium"|"high"|"xhigh"}
  --max-output-tokens: any # Maximum number of output tokens for a single assistant response, inclusive of tool calls. Provide an integer between 1 and 4096 to limit output tokens, or `inf` for the maximum available tokens for a given model. Defaults to `inf`.
  --truncation: any # When the number of tokens in a conversation exceeds the model's input token limit, the conversation be truncated, meaning messages (starting from the oldest) will not be included in the model's context. A 32k context model with 4,096 max output tokens can only include 28,224 tokens in the context before truncation occurs.  Clients can configure truncation behavior to truncate with a lower max token limit, which is an effective way to control token usage and cost.  Truncation will reduce the number of cached tokens on the next turn (busting the cache), since messages are dropped from the beginning of the context. However, clients can also configure truncation to retain messages up to a fraction of the maximum context size, which will reduce the need for future truncations and thus improve the cache rate.  Truncation can be disabled entirely, which means the server will never truncate but would instead return an error if the conversation exceeds the model's input token limit.
  --prompt: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realtime/calls/($call_id)/accept")
  let body = {type: $type, output_modalities: $output_modalities, model: $model, instructions: $instructions, audio: $audio, include: $include, tracing: $tracing, tools: $tools, tool_choice: $tool_choice, parallel_tool_calls: $parallel_tool_calls, reasoning: $reasoning, max_output_tokens: $max_output_tokens, truncation: $truncation, prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# End an active Realtime API call, whether it was initiated over SIP or WebRTC.
#
# POST /realtime/calls/{call_id}/hangup
# operationId: hangup-realtime-call
export def "realtime-calls-hangup hangup-realtime-call" [
  call_id: string
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
  let full_url = (build-url $base $"/realtime/calls/($call_id)/hangup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer an active SIP call to a new destination using the SIP REFER verb.
#
# POST /realtime/calls/{call_id}/refer
# operationId: refer-realtime-call
export def "realtime-calls-refer refer-realtime-call" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  target_uri: string # URI that should appear in the SIP Refer-To header. Supports values like `tel:+14155550123` or `sip:agent@example.com`. (e.g. tel:+14155550123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realtime/calls/($call_id)/refer")
  let body = {target_uri: $target_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Decline an incoming SIP call by returning a SIP status code to the caller.
#
# POST /realtime/calls/{call_id}/reject
# operationId: reject-realtime-call
export def "realtime-calls-reject reject-realtime-call" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status-code: int # SIP response code to send back to the caller. Defaults to `603` (Decline) when omitted. (e.g. 486)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/realtime/calls/($call_id)/reject")
  let body = {status_code: $status_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Realtime client secret with an associated session configuration.  Client secrets are short-lived tokens that can be passed to a client app, such as a web frontend or mobile client, which grants access to the Realtime API without leaking your main API key. You can configure a custom TTL for each client secret.  You can also attach session configuration options to the client secret, which will be applied to any sessions created using that client secret, but these can also be overridden by the client connection.  [Learn more about authentication with client secrets over WebRTC](/docs/guides/realtime-webrtc).  Returns the created client secret and the effective session object. The client secret is a string that looks like `ek_1234`.
#
# POST /realtime/client_secrets
# operationId: create-realtime-client-secret
# --expires_after shape: {anchor?: "created_at", seconds?: int}
export def "realtime-client-secrets create-realtime-client-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-after: record # Configuration for the client secret expiration. Expiration refers to the time after which a client secret will no longer be valid for creating sessions. The session itself may continue after that time once started. A secret can be used to create multiple sessions until it expires. — shape: {anchor?: "created_at", seconds?: int}
  --session: any # Session configuration to use for the client secret. Choose either a realtime session or a transcription session.
]: any -> record<value: string, expires_at: int, session: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realtime/client_secrets")
  let body = {expires_after: $expires_after, session: $session} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an ephemeral API token for use in client-side applications with the Realtime API. Can be configured with the same session parameters as the `session.update` client event.  It responds with a session object, plus a `client_secret` key which contains a usable ephemeral API token that can be used to authenticate browser clients for the Realtime API.  Returns the created Realtime session object, plus an ephemeral key.
#
# POST /realtime/sessions
# operationId: create-realtime-session
# --client_secret shape: {value: string, expires_at: int}
# --input_audio_transcription shape: {model?: string}
# --turn_detection shape: {type?: string, threshold?: float, prefix_padding_ms?: int, silence_duration_ms?: int}
# --tools item shape: {type?: "function", name?: string, description?: string, parameters?: record}
export def "realtime-sessions create-realtime-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_secret: record # Ephemeral key returned by the API. — shape: {value: string, expires_at: int}
  --modalities: any # The set of modalities the model can respond with. To disable audio, set this to ["text"].
  --instructions: string # The default system instructions (i.e. system message) prepended to model calls. This field allows the client to guide the model on desired responses. The model can be instructed on response content and format, (e.g. "be extremely succinct", "act friendly", "here are examples of good responses") and on audio behavior (e.g. "talk quickly", "inject emotion into your voice", "laugh frequently"). The instructions are not guaranteed to be followed by the model, but they provide guidance to the model on the desired behavior. Note that the server sets default instructions which will be used if this field is not set and are visible in the `session.created` event at the start of the session.
  --voice: any # A built-in voice name or a custom voice reference.
  --input-audio-format: string # The format of input audio. Options are `pcm16`, `g711_ulaw`, or `g711_alaw`.
  --output-audio-format: string # The format of output audio. Options are `pcm16`, `g711_ulaw`, or `g711_alaw`.
  --input-audio-transcription: record # Configuration for input audio transcription, defaults to off and can be set to `null` to turn off once on. Input audio transcription is not native to the model, since the model consumes audio directly. Transcription runs asynchronously and should be treated as rough guidance rather than the representation understood by the model. — shape: {model?: string}
  --speed: float # The speed of the model's spoken response. 1.0 is the default speed. 0.25 is the minimum speed. 1.5 is the maximum speed. This value can only be changed in between model turns, not while a response is in progress.  (default: 1)
  --tracing: any # Configuration options for tracing. Set to null to disable tracing. Once tracing is enabled for a session, the configuration cannot be modified.  `auto` will create a trace for the session with default values for the workflow name, group id, and metadata.
  --turn-detection: record # Configuration for turn detection. Can be set to `null` to turn off. Server VAD means that the model will detect the start and end of speech based on audio volume and respond at the end of user speech. — shape: {type?: string, threshold?: float, prefix_padding_ms?: int, silence_duration_ms?: int}
  --tools: list # Tools (functions) available to the model. — item shape: {type?: "function", name?: string, description?: string, parameters?: record}
  --tool-choice: string # How the model chooses tools. Options are `auto`, `none`, `required`, or specify a function.
  --temperature: float # Sampling temperature for the model, limited to [0.6, 1.2]. Defaults to 0.8.
  --max-response-output-tokens: any # Maximum number of output tokens for a single assistant response, inclusive of tool calls. Provide an integer between 1 and 4096 to limit output tokens, or `inf` for the maximum available tokens for a given model. Defaults to `inf`.
  --truncation: any # When the number of tokens in a conversation exceeds the model's input token limit, the conversation be truncated, meaning messages (starting from the oldest) will not be included in the model's context. A 32k context model with 4,096 max output tokens can only include 28,224 tokens in the context before truncation occurs.  Clients can configure truncation behavior to truncate with a lower max token limit, which is an effective way to control token usage and cost.  Truncation will reduce the number of cached tokens on the next turn (busting the cache), since messages are dropped from the beginning of the context. However, clients can also configure truncation to retain messages up to a fraction of the maximum context size, which will reduce the need for future truncations and thus improve the cache rate.  Truncation can be disabled entirely, which means the server will never truncate but would instead return an error if the conversation exceeds the model's input token limit.
  --prompt: any
]: any -> record<id: string, object: string, expires_at: int, include: list<string>, model: string, output_modalities: list<string>, instructions: string, audio: record<input: record<format: any, transcription: record, noise_reduction: record, turn_detection: record>, output: record<format: any, voice: any, speed: float>>, tracing: any, turn_detection: record<type: string, threshold: float, prefix_padding_ms: int, silence_duration_ms: int>, tools: table<type: string, name: string, description: string, parameters: record>, tool_choice: string, max_output_tokens: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realtime/sessions")
  let body = {client_secret: $client_secret, modalities: $modalities, instructions: $instructions, voice: $voice, input_audio_format: $input_audio_format, output_audio_format: $output_audio_format, input_audio_transcription: $input_audio_transcription, speed: $speed, tracing: $tracing, turn_detection: $turn_detection, tools: $tools, tool_choice: $tool_choice, temperature: $temperature, max_response_output_tokens: $max_response_output_tokens, truncation: $truncation, prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an ephemeral API token for use in client-side applications with the Realtime API specifically for realtime transcriptions.  Can be configured with the same session parameters as the `transcription_session.update` client event.  It responds with a session object, plus a `client_secret` key which contains a usable ephemeral API token that can be used to authenticate browser clients for the Realtime API.  Returns the created Realtime transcription session object, plus an ephemeral key.
#
# POST /realtime/transcription_sessions
# operationId: create-realtime-transcription-session
# --turn_detection shape: {type?: "server_vad", threshold?: float, prefix_padding_ms?: int, silence_duration_ms?: int}
# --input_audio_noise_reduction shape: {type?: "near_field"|"far_field"}
# --input_audio_transcription shape: {model?: any, language?: string, prompt?: string, delay?: "minimal"|"low"|"medium"|"high"|"xhigh"}
export def "realtime-transcription-sessions create-realtime-transcription-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --turn-detection: record # Configuration for turn detection. Can be set to `null` to turn off. Server VAD means that the model will detect the start and end of speech based on audio volume and respond at the end of user speech. — shape: {type?: "server_vad", threshold?: float, prefix_padding_ms?: int, silence_duration_ms?: int}
  --input-audio-noise-reduction: record # Configuration for input audio noise reduction. This can be set to `null` to turn off. Noise reduction filters audio added to the input audio buffer before it is sent to VAD and the model. Filtering the audio can improve VAD and turn detection accuracy (reducing false positives) and model performance by improving perception of the input audio. — shape: {type?: "near_field"|"far_field"}
  --input-audio-format: string@input-audio-format-completer # The format of input audio. Options are `pcm16`, `g711_ulaw`, or `g711_alaw`. For `pcm16`, input audio must be 16-bit PCM at a 24kHz sample rate, single channel (mono), and little-endian byte order.  (default: pcm16)
  --input-audio-transcription: record # shape: {model?: any, language?: string, prompt?: string, delay?: "minimal"|"low"|"medium"|"high"|"xhigh"}
  --include: list # The set of items to include in the transcription. Current available items are: `item.input_audio_transcription.logprobs`
]: any -> record<client_secret: record<value: string, expires_at: int>, modalities: list<string>, input_audio_format: string, input_audio_transcription: record<model: any, language: string, prompt: string>, turn_detection: record<type: string, threshold: float, prefix_padding_ms: int, silence_duration_ms: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realtime/transcription_sessions")
  let body = {turn_detection: $turn_detection, input_audio_noise_reduction: $input_audio_noise_reduction, input_audio_format: $input_audio_format, input_audio_transcription: $input_audio_transcription, include: $include} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Realtime translation client secret with an associated translation session configuration.  Client secrets are short-lived tokens that can be passed to a client app, such as a web frontend or mobile client, which grants access to the Realtime Translation API without leaking your main API key. You can configure a custom TTL for each client secret.  Returns the created client secret and the effective translation session object. The client secret is a string that looks like `ek_1234`.
#
# POST /realtime/translations/client_secrets
# operationId: create-realtime-translation-client-secret
# --expires_after shape: {anchor?: "created_at", seconds?: int}
# --session shape: {model: string, audio?: record}
export def "realtime-translations-client-secrets create-realtime-translation-client-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-after: record # Configuration for the client secret expiration. Expiration refers to the time after which a client secret will no longer be valid for creating sessions. The session itself may continue after that time once started. A secret can be used to create multiple sessions until it expires. — shape: {anchor?: "created_at", seconds?: int}
  session: record # Realtime translation session configuration. Translation sessions stream source audio in and translated audio plus transcript deltas out continuously. — shape: {model: string, audio?: record}
]: any -> record<value: string, expires_at: int, session: record<id: string, type: string, expires_at: int, model: string, audio: record<input: record, output: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/realtime/translations/client_secrets")
  let body = {expires_after: $expires_after, session: $session} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a model response. Provide [text](/docs/guides/text) or [image](/docs/guides/images) inputs to generate [text](/docs/guides/text) or [JSON](/docs/guides/structured-outputs) outputs. Have the model call your own [custom code](/docs/guides/function-calling) or use built-in [tools](/docs/guides/tools) like [web search](/docs/guides/tools-web-search) or [file search](/docs/guides/tools-file-search) to use your own data as input for the model's response.
#
# POST /responses
# operationId: createResponse
# --text shape: {format?: any, verbosity?: any}
export def "responses createResponse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --previous-response-id: any
  --model: any # e.g. gpt-5.1
  --reasoning: any
  --background: any
  --max-tool-calls: any
  --text: record # Configuration options for a text response from the model. Can be plain text or structured JSON data. Learn more: - [Text inputs and outputs](/docs/guides/text) - [Structured Outputs](/docs/guides/structured-outputs) — shape: {format?: any, verbosity?: any}
  --tools: list # An array of tools the model may call while generating a response. You can specify which tool to use by setting the `tool_choice` parameter.  We support the following categories of tools: - **Built-in tools**: Tools that are provided by OpenAI that extend the   model's capabilities, like [web search](/docs/guides/tools-web-search)   or [file search](/docs/guides/tools-file-search). Learn more about   [built-in tools](/docs/guides/tools). - **MCP Tools**: Integrations with third-party systems via custom MCP servers   or predefined connectors such as Google Drive and SharePoint. Learn more about   [MCP Tools](/docs/guides/tools-connectors-mcp). - **Function calls (custom tools)**: Functions that are defined by you,   enabling the model to call your own code with strongly typed arguments   and outputs. Learn more about   [function calling](/docs/guides/function-calling). You can also use   custom tools to call your own code.
  --tool-choice: any # How the model should select which tool (or tools) to use when generating a response. See the `tools` parameter to see how to specify which tools the model can call.
  --prompt: any
  --truncation: any
  --input: any # Text, image, or file inputs to the model, used to generate a response.  Learn more: - [Text inputs and outputs](/docs/guides/text) - [Image inputs](/docs/guides/images) - [File inputs](/docs/guides/pdf-files) - [Conversation state](/docs/guides/conversation-state) - [Function calling](/docs/guides/function-calling)
  --include: any
  --parallel-tool-calls: any
  --store: any
  --instructions: any
  --stream: any
  --stream-options: any
  --conversation: any
  --context-management: any
  --max-output-tokens: any
]: any -> record<metadata: any, top_logprobs: any, temperature: any, top_p: any, user: string, safety_identifier: string, prompt_cache_key: string, service_tier: any, prompt_cache_retention: any, previous_response_id: any, model: any, reasoning: any, background: any, max_tool_calls: any, text: record<format: any, verbosity: any>, tools: list<any>, tool_choice: any, prompt: any, truncation: any, id: string, object: string, status: string, created_at: float, completed_at: any, error: any, incomplete_details: any, output: list<any>, instructions: any, output_text: any, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int>, output_tokens: int, output_tokens_details: record<reasoning_tokens: int>, total_tokens: int>, parallel_tool_calls: bool, conversation: any, max_output_tokens: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/responses")
  let body = {previous_response_id: $previous_response_id, model: $model, reasoning: $reasoning, background: $background, max_tool_calls: $max_tool_calls, text: $text, tools: $tools, tool_choice: $tool_choice, prompt: $prompt, truncation: $truncation, input: $input, include: $include, parallel_tool_calls: $parallel_tool_calls, store: $store, instructions: $instructions, stream: $stream, stream_options: $stream_options, conversation: $conversation, context_management: $context_management, max_output_tokens: $max_output_tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a model response with the given ID.
#
# GET /responses/{response_id}
# operationId: getResponse
export def "responses get" [
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Additional fields to include in the response. See the `include` parameter for Response creation above for more information.
  --stream: string@bool-completer # If set to true, the model response data will be streamed to the client as it is generated using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format). See the [Streaming section below](/docs/api-reference/responses-streaming) for more information.
  --starting-after: int # The sequence number of the event after which to start streaming.
  --include-obfuscation: string@bool-completer # When true, stream obfuscation will be enabled. Stream obfuscation adds random characters to an `obfuscation` field on streaming delta events to normalize payload sizes as a mitigation to certain side-channel attacks. These obfuscation fields are included by default, but add a small amount of overhead to the data stream. You can set `include_obfuscation` to false to optimize for bandwidth if you trust the network links between your application and the OpenAI API.
]: nothing -> record<metadata: any, top_logprobs: any, temperature: any, top_p: any, user: string, safety_identifier: string, prompt_cache_key: string, service_tier: any, prompt_cache_retention: any, previous_response_id: any, model: any, reasoning: any, background: any, max_tool_calls: any, text: record<format: any, verbosity: any>, tools: list<any>, tool_choice: any, prompt: any, truncation: any, id: string, object: string, status: string, created_at: float, completed_at: any, error: any, incomplete_details: any, output: list<any>, instructions: any, output_text: any, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int>, output_tokens: int, output_tokens_details: record<reasoning_tokens: int>, total_tokens: int>, parallel_tool_calls: bool, conversation: any, max_output_tokens: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi") (serialize-qp "stream" $stream "scalar") (serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "include_obfuscation" $include_obfuscation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/responses/($response_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a model response with the given ID.
#
# DELETE /responses/{response_id}
# operationId: deleteResponse
export def "responses delete" [
  response_id: string
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
  let full_url = (build-url $base $"/responses/($response_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels a model response with the given ID. Only responses created with the `background` parameter set to `true` can be cancelled.  [Learn more](/docs/guides/background).
#
# POST /responses/{response_id}/cancel
# operationId: cancelResponse
export def "responses-cancel cancelResponse" [
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: any, top_logprobs: any, temperature: any, top_p: any, user: string, safety_identifier: string, prompt_cache_key: string, service_tier: any, prompt_cache_retention: any, previous_response_id: any, model: any, reasoning: any, background: any, max_tool_calls: any, text: record<format: any, verbosity: any>, tools: list<any>, tool_choice: any, prompt: any, truncation: any, id: string, object: string, status: string, created_at: float, completed_at: any, error: any, incomplete_details: any, output: list<any>, instructions: any, output_text: any, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int>, output_tokens: int, output_tokens_details: record<reasoning_tokens: int>, total_tokens: int>, parallel_tool_calls: bool, conversation: any, max_output_tokens: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/responses/($response_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of input items for a given response.
#
# GET /responses/{response_id}/input_items
# operationId: listInputItems
export def "responses-input-items listInputItems" [
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # The order to return the input items in. Default is `desc`. - `asc`: Return the input items in ascending order. - `desc`: Return the input items in descending order.
  --after: string # An item ID to list items after, used in pagination.
  --include: list # Additional fields to include in the response. See the `include` parameter for Response creation above for more information.
]: nothing -> record<object: string, data: list<any>, has_more: bool, first_id: string, last_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/responses/($response_id)/input_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a thread.
#
# POST /threads
# operationId: createThread
# --messages item shape: {role: "user"|"assistant", content: any, attachments?: any, metadata?: any}
export def "threads createThread" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messages: list # A list of [messages](/docs/api-reference/messages) to start the thread with. — item shape: {role: "user"|"assistant", content: any, attachments?: any, metadata?: any}
  --tool-resources: any
  --metadata: any
]: any -> record<id: string, object: string, created_at: int, tool_resources: any, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/threads")
  let body = {messages: $messages, tool_resources: $tool_resources, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a thread and run it in one request.
#
# POST /threads/runs
# operationId: createThreadAndRun
# --thread shape: {messages?: list, tool_resources?: any, metadata?: any}
# --tool_resources shape: {code_interpreter?: record, file_search?: record}
export def "threads-runs createThreadAndRun" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  assistant_id: string # The ID of the [assistant](/docs/api-reference/assistants) to use to execute this run.
  --thread: record # Options to create a new thread. If no thread is provided when running a request, an empty thread will be created. — shape: {messages?: list, tool_resources?: any, metadata?: any}
  --model: any # The ID of the [Model](/docs/api-reference/models) to be used to execute this run. If a value is provided here, it will override the model associated with the assistant. If not, the model associated with the assistant will be used. (nullable, e.g. gpt-4o)
  --instructions: string # Override the default system message of the assistant. This is useful for modifying the behavior on a per-run basis. (nullable)
  --tools: list # Override the tools the assistant can use for this run. This is useful for modifying the behavior on a per-run basis. (nullable)
  --tool-resources: record # A set of resources that are used by the assistant's tools. The resources are specific to the type of tool. For example, the `code_interpreter` tool requires a list of file IDs, while the `file_search` tool requires a list of vector store IDs.  (nullable) — shape: {code_interpreter?: record, file_search?: record}
  --metadata: any
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.  (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.  We generally recommend altering this or temperature but not both.  (nullable, default: 1, e.g. 1)
  --stream: string@bool-completer # If `true`, returns a stream of events that happen during the Run as server-sent events, terminating when the Run enters a terminal state with a `data: [DONE]` message.  (nullable)
  --max-prompt-tokens: int # The maximum number of prompt tokens that may be used over the course of the run. The run will make a best effort to use only the number of prompt tokens specified, across multiple turns of the run. If the run exceeds the number of prompt tokens specified, the run will end with status `incomplete`. See `incomplete_details` for more info.  (nullable)
  --max-completion-tokens: int # The maximum number of completion tokens that may be used over the course of the run. The run will make a best effort to use only the number of completion tokens specified, across multiple turns of the run. If the run exceeds the number of completion tokens specified, the run will end with status `incomplete`. See `incomplete_details` for more info.  (nullable)
  --truncation-strategy: any
  --tool-choice: any
  --parallel-tool-calls: string@bool-completer # Whether to enable [parallel function calling](/docs/guides/function-calling#configuring-parallel-function-calling) during tool use. (default: true)
  --response-format: any # Specifies the format that the model must output. Compatible with [GPT-4o](/docs/models#gpt-4o), [GPT-4 Turbo](/docs/models#gpt-4-turbo-and-gpt-4), and all GPT-3.5 Turbo models since `gpt-3.5-turbo-1106`.  Setting to `{ "type": "json_schema", "json_schema": {...} }` enables Structured Outputs which ensures the model will match your supplied JSON schema. Learn more in the [Structured Outputs guide](/docs/guides/structured-outputs).  Setting to `{ "type": "json_object" }` enables JSON mode, which ensures the message the model generates is valid JSON.  **Important:** when using JSON mode, you **must** also instruct the model to produce JSON yourself via a system or user message. Without this, the model may generate an unending stream of whitespace until the generation reaches the token limit, resulting in a long-running and seemingly "stuck" request. Also note that the message content may be partially cut off if `finish_reason="length"`, which indicates the generation exceeded `max_tokens` or the conversation exceeded the max context length.
]: any -> record<id: string, object: string, created_at: int, thread_id: string, assistant_id: string, status: string, required_action: record<type: string, submit_tool_outputs: record<tool_calls: list>>, last_error: record<code: string, message: string>, expires_at: int, started_at: int, cancelled_at: int, failed_at: int, completed_at: int, incomplete_details: record<reason: string>, model: string, instructions: string, tools: list<any>, metadata: any, usage: any, temperature: float, top_p: float, max_prompt_tokens: int, max_completion_tokens: int, truncation_strategy: record<type: string, last_messages: any>, tool_choice: record, parallel_tool_calls: bool, response_format: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/threads/runs")
  let body = {assistant_id: $assistant_id, thread: $thread, model: $model, instructions: $instructions, tools: $tools, tool_resources: $tool_resources, metadata: $metadata, temperature: $temperature, top_p: $top_p, stream: $stream, max_prompt_tokens: $max_prompt_tokens, max_completion_tokens: $max_completion_tokens, truncation_strategy: $truncation_strategy, tool_choice: $tool_choice, parallel_tool_calls: $parallel_tool_calls, response_format: $response_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a thread.
#
# GET /threads/{thread_id}
# operationId: getThread
export def "threads get" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, tool_resources: any, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies a thread.
#
# POST /threads/{thread_id}
# operationId: modifyThread
export def "threads modifyThread" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tool-resources: any
  --metadata: any
]: any -> record<id: string, object: string, created_at: int, tool_resources: any, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)")
  let body = {tool_resources: $tool_resources, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a thread.
#
# DELETE /threads/{thread_id}
# operationId: deleteThread
export def "threads delete" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of messages for a given thread.
#
# GET /threads/{thread_id}/messages
# operationId: listMessages
export def "threads-messages listMessages" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
  --run-id: string # Filter messages by the run ID that generated them.
]: nothing -> record<object: string, data: table<id: string, object: string, created_at: int, thread_id: string, status: string, incomplete_details: any, completed_at: any, incomplete_at: any, role: string, content: list, assistant_id: any, run_id: any, attachments: any, metadata: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "run_id" $run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/threads/($thread_id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a message.
#
# POST /threads/{thread_id}/messages
# operationId: createMessage
export def "threads-messages createMessage" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: string@role-completer-1 # The role of the entity that is creating the message. Allowed values include: - `user`: Indicates the message is sent by an actual user and should be used in most cases to represent user-generated messages. - `assistant`: Indicates the message is generated by the assistant. Use this value to insert messages from the assistant into the conversation.
  content: any
  --attachments: any
  --metadata: any
]: any -> record<id: string, object: string, created_at: int, thread_id: string, status: string, incomplete_details: any, completed_at: any, incomplete_at: any, role: string, content: list<any>, assistant_id: any, run_id: any, attachments: any, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/messages")
  let body = {role: $role, content: $content, attachments: $attachments, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a message.
#
# GET /threads/{thread_id}/messages/{message_id}
# operationId: getMessage
export def "threads-messages get" [
  thread_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, thread_id: string, status: string, incomplete_details: any, completed_at: any, incomplete_at: any, role: string, content: list<any>, assistant_id: any, run_id: any, attachments: any, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies a message.
#
# POST /threads/{thread_id}/messages/{message_id}
# operationId: modifyMessage
export def "threads-messages modifyMessage" [
  thread_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: any
]: any -> record<id: string, object: string, created_at: int, thread_id: string, status: string, incomplete_details: any, completed_at: any, incomplete_at: any, role: string, content: list<any>, assistant_id: any, run_id: any, attachments: any, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/messages/($message_id)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a message.
#
# DELETE /threads/{thread_id}/messages/{message_id}
# operationId: deleteMessage
export def "threads-messages delete" [
  thread_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of runs belonging to a thread.
#
# GET /threads/{thread_id}/runs
# operationId: listRuns
export def "threads-runs listRuns" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
]: nothing -> record<object: string, data: table<id: string, object: string, created_at: int, thread_id: string, assistant_id: string, status: string, required_action: record, last_error: record, expires_at: int, started_at: int, cancelled_at: int, failed_at: int, completed_at: int, incomplete_details: record, model: string, instructions: string, tools: list, metadata: any, usage: any, temperature: float, top_p: float, max_prompt_tokens: int, max_completion_tokens: int, truncation_strategy: record, tool_choice: record, parallel_tool_calls: bool, response_format: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/threads/($thread_id)/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a run.
#
# POST /threads/{thread_id}/runs
# operationId: createRun
# --additional_messages item shape: {role: "user"|"assistant", content: any, attachments?: any, metadata?: any}
export def "threads-runs createRun" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # A list of additional fields to include in the response. Currently the only supported value is `step_details.tool_calls[*].file_search.results[*].content` to fetch the file search result content.  See the [file search tool documentation](/docs/assistants/tools/file-search#customizing-file-search-settings) for more information.
  assistant_id: string # The ID of the [assistant](/docs/api-reference/assistants) to use to execute this run.
  --model: any # The ID of the [Model](/docs/api-reference/models) to be used to execute this run. If a value is provided here, it will override the model associated with the assistant. If not, the model associated with the assistant will be used. (nullable, e.g. gpt-4o)
  --reasoning-effort: any
  --instructions: string # Overrides the [instructions](/docs/api-reference/assistants/createAssistant) of the assistant. This is useful for modifying the behavior on a per-run basis. (nullable)
  --additional-instructions: string # Appends additional instructions at the end of the instructions for the run. This is useful for modifying the behavior on a per-run basis without overriding other instructions. (nullable)
  --additional-messages: list # Adds additional messages to the thread before creating the run. (nullable) — item shape: {role: "user"|"assistant", content: any, attachments?: any, metadata?: any}
  --tools: list # Override the tools the assistant can use for this run. This is useful for modifying the behavior on a per-run basis. (nullable)
  --metadata: any
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.  (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.  We generally recommend altering this or temperature but not both.  (nullable, default: 1, e.g. 1)
  --stream: string@bool-completer # If `true`, returns a stream of events that happen during the Run as server-sent events, terminating when the Run enters a terminal state with a `data: [DONE]` message.  (nullable)
  --max-prompt-tokens: int # The maximum number of prompt tokens that may be used over the course of the run. The run will make a best effort to use only the number of prompt tokens specified, across multiple turns of the run. If the run exceeds the number of prompt tokens specified, the run will end with status `incomplete`. See `incomplete_details` for more info.  (nullable)
  --max-completion-tokens: int # The maximum number of completion tokens that may be used over the course of the run. The run will make a best effort to use only the number of completion tokens specified, across multiple turns of the run. If the run exceeds the number of completion tokens specified, the run will end with status `incomplete`. See `incomplete_details` for more info.  (nullable)
  --truncation-strategy: any
  --tool-choice: any
  --parallel-tool-calls: string@bool-completer # Whether to enable [parallel function calling](/docs/guides/function-calling#configuring-parallel-function-calling) during tool use. (default: true)
  --response-format: any # Specifies the format that the model must output. Compatible with [GPT-4o](/docs/models#gpt-4o), [GPT-4 Turbo](/docs/models#gpt-4-turbo-and-gpt-4), and all GPT-3.5 Turbo models since `gpt-3.5-turbo-1106`.  Setting to `{ "type": "json_schema", "json_schema": {...} }` enables Structured Outputs which ensures the model will match your supplied JSON schema. Learn more in the [Structured Outputs guide](/docs/guides/structured-outputs).  Setting to `{ "type": "json_object" }` enables JSON mode, which ensures the message the model generates is valid JSON.  **Important:** when using JSON mode, you **must** also instruct the model to produce JSON yourself via a system or user message. Without this, the model may generate an unending stream of whitespace until the generation reaches the token limit, resulting in a long-running and seemingly "stuck" request. Also note that the message content may be partially cut off if `finish_reason="length"`, which indicates the generation exceeded `max_tokens` or the conversation exceeded the max context length.
]: any -> record<id: string, object: string, created_at: int, thread_id: string, assistant_id: string, status: string, required_action: record<type: string, submit_tool_outputs: record<tool_calls: list>>, last_error: record<code: string, message: string>, expires_at: int, started_at: int, cancelled_at: int, failed_at: int, completed_at: int, incomplete_details: record<reason: string>, model: string, instructions: string, tools: list<any>, metadata: any, usage: any, temperature: float, top_p: float, max_prompt_tokens: int, max_completion_tokens: int, truncation_strategy: record<type: string, last_messages: any>, tool_choice: record, parallel_tool_calls: bool, response_format: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/threads/($thread_id)/runs" $qp)
  let body = {assistant_id: $assistant_id, model: $model, reasoning_effort: $reasoning_effort, instructions: $instructions, additional_instructions: $additional_instructions, additional_messages: $additional_messages, tools: $tools, metadata: $metadata, temperature: $temperature, top_p: $top_p, stream: $stream, max_prompt_tokens: $max_prompt_tokens, max_completion_tokens: $max_completion_tokens, truncation_strategy: $truncation_strategy, tool_choice: $tool_choice, parallel_tool_calls: $parallel_tool_calls, response_format: $response_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a run.
#
# GET /threads/{thread_id}/runs/{run_id}
# operationId: getRun
export def "threads-runs get" [
  thread_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, thread_id: string, assistant_id: string, status: string, required_action: record<type: string, submit_tool_outputs: record<tool_calls: list>>, last_error: record<code: string, message: string>, expires_at: int, started_at: int, cancelled_at: int, failed_at: int, completed_at: int, incomplete_details: record<reason: string>, model: string, instructions: string, tools: list<any>, metadata: any, usage: any, temperature: float, top_p: float, max_prompt_tokens: int, max_completion_tokens: int, truncation_strategy: record<type: string, last_messages: any>, tool_choice: record, parallel_tool_calls: bool, response_format: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/runs/($run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies a run.
#
# POST /threads/{thread_id}/runs/{run_id}
# operationId: modifyRun
export def "threads-runs modifyRun" [
  thread_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: any
]: any -> record<id: string, object: string, created_at: int, thread_id: string, assistant_id: string, status: string, required_action: record<type: string, submit_tool_outputs: record<tool_calls: list>>, last_error: record<code: string, message: string>, expires_at: int, started_at: int, cancelled_at: int, failed_at: int, completed_at: int, incomplete_details: record<reason: string>, model: string, instructions: string, tools: list<any>, metadata: any, usage: any, temperature: float, top_p: float, max_prompt_tokens: int, max_completion_tokens: int, truncation_strategy: record<type: string, last_messages: any>, tool_choice: record, parallel_tool_calls: bool, response_format: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/runs/($run_id)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancels a run that is `in_progress`.
#
# POST /threads/{thread_id}/runs/{run_id}/cancel
# operationId: cancelRun
export def "threads-runs-cancel cancelRun" [
  thread_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, thread_id: string, assistant_id: string, status: string, required_action: record<type: string, submit_tool_outputs: record<tool_calls: list>>, last_error: record<code: string, message: string>, expires_at: int, started_at: int, cancelled_at: int, failed_at: int, completed_at: int, incomplete_details: record<reason: string>, model: string, instructions: string, tools: list<any>, metadata: any, usage: any, temperature: float, top_p: float, max_prompt_tokens: int, max_completion_tokens: int, truncation_strategy: record<type: string, last_messages: any>, tool_choice: record, parallel_tool_calls: bool, response_format: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/runs/($run_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of run steps belonging to a run.
#
# GET /threads/{thread_id}/runs/{run_id}/steps
# operationId: listRunSteps
export def "threads-runs-steps listRunSteps" [
  thread_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
  --include: list # A list of additional fields to include in the response. Currently the only supported value is `step_details.tool_calls[*].file_search.results[*].content` to fetch the file search result content.  See the [file search tool documentation](/docs/assistants/tools/file-search#customizing-file-search-settings) for more information.
]: nothing -> record<object: string, data: table<id: string, object: string, created_at: int, assistant_id: string, thread_id: string, run_id: string, type: string, status: string, step_details: record, last_error: any, expired_at: any, cancelled_at: any, failed_at: any, completed_at: any, metadata: any, usage: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "include[]" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/threads/($thread_id)/runs/($run_id)/steps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a run step.
#
# GET /threads/{thread_id}/runs/{run_id}/steps/{step_id}
# operationId: getRunStep
export def "threads-runs-steps get" [
  thread_id: string
  run_id: string
  step_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # A list of additional fields to include in the response. Currently the only supported value is `step_details.tool_calls[*].file_search.results[*].content` to fetch the file search result content.  See the [file search tool documentation](/docs/assistants/tools/file-search#customizing-file-search-settings) for more information.
]: nothing -> record<id: string, object: string, created_at: int, assistant_id: string, thread_id: string, run_id: string, type: string, status: string, step_details: record, last_error: any, expired_at: any, cancelled_at: any, failed_at: any, completed_at: any, metadata: any, usage: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/threads/($thread_id)/runs/($run_id)/steps/($step_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# When a run has the `status: "requires_action"` and `required_action.type` is `submit_tool_outputs`, this endpoint can be used to submit the outputs from the tool calls once they're all completed. All outputs must be submitted in a single request.
#
# POST /threads/{thread_id}/runs/{run_id}/submit_tool_outputs
# operationId: submitToolOuputsToRun
# --tool_outputs item shape: {tool_call_id?: string, output?: string}
export def "threads-runs-submit-tool-outputs submitToolOuputsToRun" [
  thread_id: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tool_outputs: list # A list of tools for which the outputs are being submitted. — item shape: {tool_call_id?: string, output?: string}
  --stream: any
]: any -> record<id: string, object: string, created_at: int, thread_id: string, assistant_id: string, status: string, required_action: record<type: string, submit_tool_outputs: record<tool_calls: list>>, last_error: record<code: string, message: string>, expires_at: int, started_at: int, cancelled_at: int, failed_at: int, completed_at: int, incomplete_details: record<reason: string>, model: string, instructions: string, tools: list<any>, metadata: any, usage: any, temperature: float, top_p: float, max_prompt_tokens: int, max_completion_tokens: int, truncation_strategy: record<type: string, last_messages: any>, tool_choice: record, parallel_tool_calls: bool, response_format: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/threads/($thread_id)/runs/($run_id)/submit_tool_outputs")
  let body = {tool_outputs: $tool_outputs, stream: $stream} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an intermediate [Upload](/docs/api-reference/uploads/object) object that you can add [Parts](/docs/api-reference/uploads/part-object) to. Currently, an Upload can accept at most 8 GB in total and expires after an hour after you create it.  Once you complete the Upload, we will create a [File](/docs/api-reference/files/object) object that contains all the parts you uploaded. This File is usable in the rest of our platform as a regular File object.  For certain `purpose` values, the correct `mime_type` must be specified.  Please refer to documentation for the  [supported MIME types for your use case](/docs/assistants/tools/file-search#supported-files).  For guidance on the proper filename extensions for each purpose, please follow the documentation on [creating a File](/docs/api-reference/files/create).  Returns the Upload object with status `pending`.
#
# POST /uploads
# operationId: createUpload
# --expires_after shape: {anchor: "created_at", seconds: int}
export def "uploads createUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  filename: string # The name of the file to upload.
  purpose: string@purpose-completer-1 # The intended purpose of the uploaded file.  See the [documentation on File purposes](/docs/api-reference/files/create#files-create-purpose).
  bytes: int # The number of bytes in the file you are uploading.
  mime_type: string # The MIME type of the file.   This must fall within the supported MIME types for your file purpose. See the supported MIME types for assistants and vision.
  --expires-after: record # The expiration policy for a file. By default, files with `purpose=batch` expire after 30 days and all other files are persisted until they are manually deleted. — shape: {anchor: "created_at", seconds: int}
]: any -> record<id: string, created_at: int, filename: string, bytes: int, purpose: string, status: string, expires_at: int, object: string, file: record<id: string, bytes: int, created_at: int, expires_at: int, filename: string, object: string, purpose: string, status: string, status_details: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploads")
  let body = {filename: $filename, purpose: $purpose, bytes: $bytes, mime_type: $mime_type, expires_after: $expires_after} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancels the Upload. No Parts may be added after an Upload is cancelled.  Returns the Upload object with status `cancelled`.
#
# POST /uploads/{upload_id}/cancel
# operationId: cancelUpload
export def "uploads-cancel cancelUpload" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: int, filename: string, bytes: int, purpose: string, status: string, expires_at: int, object: string, file: record<id: string, bytes: int, created_at: int, expires_at: int, filename: string, object: string, purpose: string, status: string, status_details: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/uploads/($upload_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Completes the [Upload](/docs/api-reference/uploads/object).   Within the returned Upload object, there is a nested [File](/docs/api-reference/files/object) object that is ready to use in the rest of the platform.  You can specify the order of the Parts by passing in an ordered list of the Part IDs.  The number of bytes uploaded upon completion must match the number of bytes initially specified when creating the Upload object. No Parts may be added after an Upload is completed. Returns the Upload object with status `completed`, including an additional `file` property containing the created usable File object.
#
# POST /uploads/{upload_id}/complete
# operationId: completeUpload
export def "uploads-complete completeUpload" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  part_ids: list # The ordered list of Part IDs.
  --md5: string # The optional md5 checksum for the file contents to verify if the bytes uploaded matches what you expect.
]: any -> record<id: string, created_at: int, filename: string, bytes: int, purpose: string, status: string, expires_at: int, object: string, file: record<id: string, bytes: int, created_at: int, expires_at: int, filename: string, object: string, purpose: string, status: string, status_details: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/uploads/($upload_id)/complete")
  let body = {part_ids: $part_ids, md5: $md5} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a [Part](/docs/api-reference/uploads/part-object) to an [Upload](/docs/api-reference/uploads/object) object. A Part represents a chunk of bytes from the file you are trying to upload.   Each Part can be at most 64 MB, and you can add Parts until you hit the Upload maximum of 8 GB.  It is possible to add multiple Parts in parallel. You can decide the intended order of the Parts when you [complete the Upload](/docs/api-reference/uploads/complete).
#
# POST /uploads/{upload_id}/parts
# operationId: addUploadPart
export def "uploads-parts addUploadPart" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: string # The chunk of bytes for this Part.  (format: binary)
]: any -> record<id: string, created_at: int, upload_id: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/uploads/($upload_id)/parts")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Returns a list of vector stores.
#
# GET /vector_stores
# operationId: listVectorStores
export def "vector-stores listVectorStores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
]: nothing -> record<object: string, data: table<id: string, object: string, created_at: int, name: string, usage_bytes: int, file_counts: record, status: string, expires_after: record, expires_at: any, last_active_at: any, metadata: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vector_stores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a vector store.
#
# POST /vector_stores
# operationId: createVectorStore
# --expires_after shape: {anchor: "last_active_at", days: int}
# --chunking_strategy shape: {type?: "auto", static?: record}
export def "vector-stores createVectorStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file-ids: list # A list of [File](/docs/api-reference/files) IDs that the vector store should use. Useful for tools like `file_search` that can access files.
  --name: string # The name of the vector store.
  --description: string # A description for the vector store. Can be used to describe the vector store's purpose.
  --expires-after: record # The expiration policy for a vector store. — shape: {anchor: "last_active_at", days: int}
  --chunking-strategy: record # The chunking strategy used to chunk the file(s). If not set, will use the `auto` strategy. Only applicable if `file_ids` is non-empty. — shape: {type?: "auto", static?: record}
  --metadata: any
]: any -> record<id: string, object: string, created_at: int, name: string, usage_bytes: int, file_counts: record<in_progress: int, completed: int, failed: int, cancelled: int, total: int>, status: string, expires_after: record<anchor: string, days: int>, expires_at: any, last_active_at: any, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vector_stores")
  let body = {file_ids: $file_ids, name: $name, description: $description, expires_after: $expires_after, chunking_strategy: $chunking_strategy, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a vector store.
#
# GET /vector_stores/{vector_store_id}
# operationId: getVectorStore
export def "vector-stores get" [
  vector_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, name: string, usage_bytes: int, file_counts: record<in_progress: int, completed: int, failed: int, cancelled: int, total: int>, status: string, expires_after: record<anchor: string, days: int>, expires_at: any, last_active_at: any, metadata: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modifies a vector store.
#
# POST /vector_stores/{vector_store_id}
# operationId: modifyVectorStore
export def "vector-stores modifyVectorStore" [
  vector_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the vector store. (nullable)
  --expires-after: any
  --metadata: any
]: any -> record<id: string, object: string, created_at: int, name: string, usage_bytes: int, file_counts: record<in_progress: int, completed: int, failed: int, cancelled: int, total: int>, status: string, expires_after: record<anchor: string, days: int>, expires_at: any, last_active_at: any, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)")
  let body = {name: $name, expires_after: $expires_after, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a vector store.
#
# DELETE /vector_stores/{vector_store_id}
# operationId: deleteVectorStore
export def "vector-stores delete" [
  vector_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a vector store file batch.
#
# POST /vector_stores/{vector_store_id}/file_batches
# operationId: createVectorStoreFileBatch
# --files item shape: {file_id: string, chunking_strategy?: record, attributes?: any}
# --chunking_strategy shape: {type: "auto", static?: record}
export def "vector-stores-file-batches createVectorStoreFileBatch" [
  vector_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file-ids: list # A list of [File](/docs/api-reference/files) IDs that the vector store should use. Useful for tools like `file_search` that can access files.  If `attributes` or `chunking_strategy` are provided, they will be  applied to all files in the batch. The maximum batch size is 2000 files. This endpoint is recommended for multi-file ingestion and helps reduce per-vector-store write request pressure. Mutually exclusive with `files`.
  --files: list # A list of objects that each include a `file_id` plus optional `attributes` or `chunking_strategy`. Use this when you need to override metadata for specific files. The global `attributes` or `chunking_strategy` will be ignored and must be specified for each file. The maximum batch size is 2000 files. This endpoint is recommended for multi-file ingestion and helps reduce per-vector-store write request pressure. Mutually exclusive with `file_ids`. — item shape: {file_id: string, chunking_strategy?: record, attributes?: any}
  --chunking-strategy: record # The chunking strategy used to chunk the file(s). If not set, will use the `auto` strategy. — shape: {type: "auto", static?: record}
  --attributes: any
]: any -> record<id: string, object: string, created_at: int, vector_store_id: string, status: string, file_counts: record<in_progress: int, completed: int, failed: int, cancelled: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/file_batches")
  let body = {file_ids: $file_ids, files: $files, chunking_strategy: $chunking_strategy, attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a vector store file batch.
#
# GET /vector_stores/{vector_store_id}/file_batches/{batch_id}
# operationId: getVectorStoreFileBatch
export def "vector-stores-file-batches get" [
  vector_store_id: string
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, vector_store_id: string, status: string, file_counts: record<in_progress: int, completed: int, failed: int, cancelled: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/file_batches/($batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a vector store file batch. This attempts to cancel the processing of files in this batch as soon as possible.
#
# POST /vector_stores/{vector_store_id}/file_batches/{batch_id}/cancel
# operationId: cancelVectorStoreFileBatch
export def "vector-stores-file-batches-cancel cancelVectorStoreFileBatch" [
  vector_store_id: string
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, vector_store_id: string, status: string, file_counts: record<in_progress: int, completed: int, failed: int, cancelled: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/file_batches/($batch_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of vector store files in a batch.
#
# GET /vector_stores/{vector_store_id}/file_batches/{batch_id}/files
# operationId: listFilesInVectorStoreBatch
export def "vector-stores-file-batches-files listFilesInVectorStoreBatch" [
  vector_store_id: string
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
  --filter: string@filter-completer # Filter by file status. One of `in_progress`, `completed`, `failed`, `cancelled`.
]: nothing -> record<object: string, data: table<id: string, object: string, usage_bytes: int, created_at: int, vector_store_id: string, status: string, last_error: any, chunking_strategy: record, attributes: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/file_batches/($batch_id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of vector store files.
#
# GET /vector_stores/{vector_store_id}/files
# operationId: listVectorStoreFiles
export def "vector-stores-files listVectorStoreFiles" [
  vector_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.  (default: 20)
  --order: string@order-completer # Sort order by the `created_at` timestamp of the objects. `asc` for ascending order and `desc` for descending order.  (default: desc)
  --after: string # A cursor for use in pagination. `after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with obj_foo, your subsequent call can include after=obj_foo in order to fetch the next page of the list.
  --before: string # A cursor for use in pagination. `before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with obj_foo, your subsequent call can include before=obj_foo in order to fetch the previous page of the list.
  --filter: string@filter-completer # Filter by file status. One of `in_progress`, `completed`, `failed`, `cancelled`.
]: nothing -> record<object: string, data: table<id: string, object: string, usage_bytes: int, created_at: int, vector_store_id: string, status: string, last_error: any, chunking_strategy: record, attributes: any>, first_id: string, last_id: string, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a vector store file by attaching a [File](/docs/api-reference/files) to a [vector store](/docs/api-reference/vector-stores/object).
#
# POST /vector_stores/{vector_store_id}/files
# operationId: createVectorStoreFile
# --chunking_strategy shape: {type: "auto", static?: record}
export def "vector-stores-files createVectorStoreFile" [
  vector_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file_id: string # A [File](/docs/api-reference/files) ID that the vector store should use. Useful for tools like `file_search` that can access files. For multi-file ingestion, we recommend [`file_batches`](/docs/api-reference/vector-stores-file-batches/createBatch) to minimize per-vector-store write requests.
  --chunking-strategy: record # The chunking strategy used to chunk the file(s). If not set, will use the `auto` strategy. — shape: {type: "auto", static?: record}
  --attributes: any
]: any -> record<id: string, object: string, usage_bytes: int, created_at: int, vector_store_id: string, status: string, last_error: any, chunking_strategy: record, attributes: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/files")
  let body = {file_id: $file_id, chunking_strategy: $chunking_strategy, attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a vector store file.
#
# GET /vector_stores/{vector_store_id}/files/{file_id}
# operationId: getVectorStoreFile
export def "vector-stores-files get" [
  vector_store_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, usage_bytes: int, created_at: int, vector_store_id: string, status: string, last_error: any, chunking_strategy: record, attributes: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a vector store file. This will remove the file from the vector store but the file itself will not be deleted. To delete the file, use the [delete file](/docs/api-reference/files/delete) endpoint.
#
# DELETE /vector_stores/{vector_store_id}/files/{file_id}
# operationId: deleteVectorStoreFile
export def "vector-stores-files delete" [
  vector_store_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, deleted: bool, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update attributes on a vector store file.
#
# POST /vector_stores/{vector_store_id}/files/{file_id}
# operationId: updateVectorStoreFileAttributes
export def "vector-stores-files updateVectorStoreFileAttributes" [
  vector_store_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  attributes: any
]: any -> record<id: string, object: string, usage_bytes: int, created_at: int, vector_store_id: string, status: string, last_error: any, chunking_strategy: record, attributes: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/files/($file_id)")
  let body = {attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the parsed contents of a vector store file.
#
# GET /vector_stores/{vector_store_id}/files/{file_id}/content
# operationId: retrieveVectorStoreFileContent
export def "vector-stores-files-content retrieveVectorStoreFileContent" [
  vector_store_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, data: table<type: string, text: string>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/files/($file_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search a vector store for relevant chunks based on a query and file attributes filter.
#
# POST /vector_stores/{vector_store_id}/search
# operationId: searchVectorStore
# --ranking_options shape: {ranker?: "none"|"auto"|"default-2024-11-15", score_threshold?: float}
export def "vector-stores-search searchVectorStore" [
  vector_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: any # A query string for a search
  --rewrite-query: string@bool-completer # Whether to rewrite the natural language query for vector search. (default: false)
  --max-num-results: int # The maximum number of results to return. This number should be between 1 and 50 inclusive. (default: 10)
  --filters: any # A filter to apply based on file attributes.
  --ranking-options: record # Ranking options for search. — shape: {ranker?: "none"|"auto"|"default-2024-11-15", score_threshold?: float}
]: any -> record<object: string, search_query: list<string>, data: table<file_id: string, filename: string, score: float, attributes: any, content: list>, has_more: bool, next_page: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vector_stores/($vector_store_id)/search")
  let body = {query: $body_query, rewrite_query: $rewrite_query, max_num_results: $max_num_results, filters: $filters, ranking_options: $ranking_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a conversation.
#
# POST /conversations
# operationId: createConversation
export def "conversations createConversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: any
  --items: any
]: any -> record<id: string, object: string, metadata: any, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations")
  let body = {metadata: $metadata, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a conversation
#
# GET /conversations/{conversation_id}
# operationId: getConversation
export def "conversations get" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, metadata: any, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a conversation. Items in the conversation will not be deleted.
#
# DELETE /conversations/{conversation_id}
# operationId: deleteConversation
export def "conversations delete" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a conversation
#
# POST /conversations/{conversation_id}
# operationId: updateConversation
export def "conversations updateConversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metadata: any
]: any -> record<id: string, object: string, metadata: any, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/($conversation_id)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new video generation job from a prompt and optional reference assets.
#
# POST /videos
# operationId: createVideo
# --input_reference shape: {image_url?: string, file_id?: string}
export def "videos createVideo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: any
  prompt: string # Text prompt that describes the video to generate.
  --input-reference: record # shape: {image_url?: string, file_id?: string}
  --seconds: string@seconds-completer
  --size: string@size-completer-1
]: any -> record<id: string, object: string, model: any, status: string, progress: int, created_at: int, completed_at: any, expires_at: any, prompt: any, size: string, seconds: string, remixed_from_video_id: any, error: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/videos")
  let body = {model: $model, prompt: $prompt, input_reference: $input_reference, seconds: $seconds, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List recently generated videos for the current project.
#
# GET /videos
# operationId: ListVideos
export def "videos ListVideos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of items to retrieve
  --order: string # Sort order of results by timestamp. Use `asc` for ascending order or `desc` for descending order.
  --after: string # Identifier for the last item from the previous pagination request
]: nothing -> record<object: string, data: table<id: string, object: string, model: any, status: string, progress: int, created_at: int, completed_at: any, expires_at: any, prompt: any, size: string, seconds: string, remixed_from_video_id: any, error: any>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a character from an uploaded video.
#
# POST /videos/characters
# operationId: CreateVideoCharacter
export def "videos-characters CreateVideoCharacter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  video: string # Video file used to create a character. (format: binary)
  name: string # Display name for this API character.
]: any -> record<id: any, name: any, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/videos/characters")
  let body = {video: $video, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Fetch a character.
#
# GET /videos/characters/{character_id}
# operationId: GetVideoCharacter
export def "videos-characters GetVideoCharacter" [
  character_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: any, name: any, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videos/characters/($character_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new video generation job by editing a source video or existing generated video.
#
# POST /videos/edits
# operationId: CreateVideoEdit
# --video shape: {id: string}
export def "videos-edits CreateVideoEdit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  video: record # Reference to the completed video. — shape: {id: string}
  prompt: string # Text prompt that describes how to edit the source video.
]: any -> record<id: string, object: string, model: any, status: string, progress: int, created_at: int, completed_at: any, expires_at: any, prompt: any, size: string, seconds: string, remixed_from_video_id: any, error: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/videos/edits")
  let body = {video: $video, prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an extension of a completed video.
#
# POST /videos/extensions
# operationId: CreateVideoExtend
# --video shape: {id: string}
export def "videos-extensions CreateVideoExtend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  video: record # Reference to the completed video. — shape: {id: string}
  prompt: string # Updated text prompt that directs the extension generation.
  seconds: string@seconds-completer
]: any -> record<id: string, object: string, model: any, status: string, progress: int, created_at: int, completed_at: any, expires_at: any, prompt: any, size: string, seconds: string, remixed_from_video_id: any, error: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/videos/extensions")
  let body = {video: $video, prompt: $prompt, seconds: $seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch the latest metadata for a generated video.
#
# GET /videos/{video_id}
# operationId: GetVideo
export def "videos GetVideo" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, model: any, status: string, progress: int, created_at: int, completed_at: any, expires_at: any, prompt: any, size: string, seconds: string, remixed_from_video_id: any, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Permanently delete a completed or failed video and its stored assets.
#
# DELETE /videos/{video_id}
# operationId: DeleteVideo
export def "videos DeleteVideo" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download the generated video bytes or a derived preview asset.  Streams the rendered video content for the specified video job.
#
# GET /videos/{video_id}/content
# operationId: RetrieveVideoContent
export def "videos-content RetrieveVideoContent" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --variant: string # Which downloadable asset to return. Defaults to the MP4 video.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variant" $variant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/content" $qp)
  let accept_val = ($accept | default "video/mp4")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a remix of a completed video using a refreshed prompt.
#
# POST /videos/{video_id}/remix
# operationId: CreateVideoRemix
export def "videos-remix CreateVideoRemix" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  prompt: string # Updated text prompt that directs the remix generation.
]: any -> record<id: string, object: string, model: any, status: string, progress: int, created_at: int, completed_at: any, expires_at: any, prompt: any, size: string, seconds: string, remixed_from_video_id: any, error: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/videos/($video_id)/remix")
  let body = {prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns input token counts of the request.  Returns an object with `object` set to `response.input_tokens` and an `input_tokens` count.
#
# POST /responses/input_tokens
# operationId: Getinputtokencounts
export def "responses-input-tokens Getinputtokencounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: any
  --input: any
  --previous-response-id: any
  --tools: any
  --text: any
  --reasoning: any
  --truncation: string@truncation-completer
  --instructions: any
  --conversation: any
  --tool-choice: any
  --parallel-tool-calls: any
]: any -> record<object: string, input_tokens: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/responses/input_tokens")
  let body = {model: $model, input: $input, previous_response_id: $previous_response_id, tools: $tools, text: $text, reasoning: $reasoning, truncation: $truncation, instructions: $instructions, conversation: $conversation, tool_choice: $tool_choice, parallel_tool_calls: $parallel_tool_calls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compact a conversation. Returns a compacted response object.  Learn when and how to compact long-running conversations in the [conversation state guide](/docs/guides/conversation-state#managing-the-context-window). For ZDR-compatible compaction details, see [Compaction (advanced)](/docs/guides/conversation-state#compaction-advanced).
#
# POST /responses/compact
# operationId: Compactconversation
export def "responses-compact Compactconversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: any # Model ID used to generate the response, like `gpt-5` or `o3`. OpenAI offers a wide range of models with different capabilities, performance characteristics, and price points. Refer to the [model guide](/docs/models) to browse and compare available models.
  --input: any
  --previous-response-id: any
  --instructions: any
  --prompt-cache-key: any
  --prompt-cache-retention: any
  --service-tier: any
]: any -> record<id: string, object: string, output: list<any>, created_at: int, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int>, output_tokens: int, output_tokens_details: record<reasoning_tokens: int>, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/responses/compact")
  let body = {model: $model, input: $input, previous_response_id: $previous_response_id, instructions: $instructions, prompt_cache_key: $prompt_cache_key, prompt_cache_retention: $prompt_cache_retention, service_tier: $service_tier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new skill.
#
# POST /skills
# operationId: CreateSkill
export def "skills CreateSkill" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  files: any
]: any -> record<id: string, object: string, name: string, description: string, created_at: int, default_version: string, latest_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/skills")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all skills for the current project.
#
# GET /skills
# operationId: ListSkills
export def "skills ListSkills" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of items to retrieve
  --order: string # Sort order of results by timestamp. Use `asc` for ascending order or `desc` for descending order.
  --after: string # Identifier for the last item from the previous pagination request
]: nothing -> record<object: string, data: table<id: string, object: string, name: string, description: string, created_at: int, default_version: string, latest_version: string>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/skills" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a skill by its ID.
#
# DELETE /skills/{skill_id}
# operationId: DeleteSkill
export def "skills DeleteSkill" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a skill by its ID.
#
# GET /skills/{skill_id}
# operationId: GetSkill
export def "skills GetSkill" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, name: string, description: string, created_at: int, default_version: string, latest_version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the default version pointer for a skill.
#
# POST /skills/{skill_id}
# operationId: UpdateSkillDefaultVersion
export def "skills UpdateSkillDefaultVersion" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  default_version: string # The skill version number to set as default.
]: any -> record<id: string, object: string, name: string, description: string, created_at: int, default_version: string, latest_version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)")
  let body = {default_version: $default_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download a skill zip bundle by its ID.
#
# GET /skills/{skill_id}/content
# operationId: GetSkillContent
export def "skills-content GetSkillContent" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-3 # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)/content")
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new immutable skill version.
#
# POST /skills/{skill_id}/versions
# operationId: CreateSkillVersion
export def "skills-versions CreateSkillVersion" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  files: any
  --default: string@bool-completer # Whether to set this version as the default.
]: any -> record<object: string, id: string, skill_id: string, version: string, created_at: int, name: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)/versions")
  let body = {files: $files, default: $default} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List skill versions for a skill.
#
# GET /skills/{skill_id}/versions
# operationId: ListSkillVersions
export def "skills-versions ListSkillVersions" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of versions to retrieve.
  --order: string # Sort order of results by version number.
  --after: string # The skill version ID to start after. (e.g. skillver_123)
]: nothing -> record<object: string, data: table<object: string, id: string, skill_id: string, version: string, created_at: int, name: string, description: string>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/skills/($skill_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific skill version.
#
# GET /skills/{skill_id}/versions/{version}
# operationId: GetSkillVersion
export def "skills-versions GetSkillVersion" [
  skill_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, skill_id: string, version: string, created_at: int, name: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)/versions/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a skill version.
#
# DELETE /skills/{skill_id}/versions/{version}
# operationId: DeleteSkillVersion
export def "skills-versions DeleteSkillVersion" [
  skill_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, deleted: bool, id: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)/versions/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a skill version zip bundle.
#
# GET /skills/{skill_id}/versions/{version}/content
# operationId: GetSkillVersionContent
export def "skills-versions-content GetSkillVersionContent" [
  skill_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-3 # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/skills/($skill_id)/versions/($version)/content")
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an active ChatKit session and return its most recent metadata.  Cancelling prevents new requests from using the issued client secret.
#
# POST /chatkit/sessions/{session_id}/cancel
# operationId: CancelChatSessionMethod
export def "chatkit-sessions-cancel CancelChatSessionMethod" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, expires_at: int, client_secret: string, workflow: record<id: string, version: any, state_variables: any, tracing: record<enabled: bool>>, user: string, rate_limits: record<max_requests_per_1_minute: int>, max_requests_per_1_minute: int, status: string, chatkit_configuration: record<automatic_thread_titling: record<enabled: bool>, file_upload: record<enabled: bool, max_file_size: any, max_files: any>, history: record<enabled: bool, recent_threads: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chatkit/sessions/($session_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a ChatKit session.
#
# POST /chatkit/sessions
# operationId: CreateChatSessionMethod
# --workflow shape: {id: string, version?: string, state_variables?: record, tracing?: record}
# --expires_after shape: {anchor: "created_at", seconds: int}
# --rate_limits shape: {max_requests_per_1_minute?: int}
# --chatkit_configuration shape: {automatic_thread_titling?: record, file_upload?: record, history?: record}
export def "chatkit-sessions CreateChatSessionMethod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workflow: record # Workflow reference and overrides applied to the chat session. — shape: {id: string, version?: string, state_variables?: record, tracing?: record}
  user: string # A free-form string that identifies your end user; ensures this Session can access other objects that have the same `user` scope.
  --expires-after: record # Controls when the session expires relative to an anchor timestamp. — shape: {anchor: "created_at", seconds: int}
  --rate-limits: record # Controls request rate limits for the session. — shape: {max_requests_per_1_minute?: int}
  --chatkit-configuration: record # Optional per-session configuration settings for ChatKit behavior. — shape: {automatic_thread_titling?: record, file_upload?: record, history?: record}
]: any -> record<id: string, object: string, expires_at: int, client_secret: string, workflow: record<id: string, version: any, state_variables: any, tracing: record<enabled: bool>>, user: string, rate_limits: record<max_requests_per_1_minute: int>, max_requests_per_1_minute: int, status: string, chatkit_configuration: record<automatic_thread_titling: record<enabled: bool>, file_upload: record<enabled: bool, max_file_size: any, max_files: any>, history: record<enabled: bool, recent_threads: any>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chatkit/sessions")
  let body = {workflow: $workflow, user: $user, expires_after: $expires_after, rate_limits: $rate_limits, chatkit_configuration: $chatkit_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List items that belong to a ChatKit thread.
#
# GET /chatkit/threads/{thread_id}/items
# operationId: ListThreadItemsMethod
export def "chatkit-threads-items ListThreadItemsMethod" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of thread items to return. Defaults to 20.
  --order: string # Sort order for results by creation time. Defaults to `desc`.
  --after: string # List items created after this thread item ID. Defaults to null for the first page.
  --before: string # List items created before this thread item ID. Defaults to null for the newest results.
]: nothing -> record<object: string, data: list<any>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/chatkit/threads/($thread_id)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a ChatKit thread by its identifier.
#
# GET /chatkit/threads/{thread_id}
# operationId: GetThreadMethod
export def "chatkit-threads GetThreadMethod" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, created_at: int, title: any, status: any, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chatkit/threads/($thread_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a ChatKit thread along with its items and stored attachments.
#
# DELETE /chatkit/threads/{thread_id}
# operationId: DeleteThreadMethod
export def "chatkit-threads DeleteThreadMethod" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chatkit/threads/($thread_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List ChatKit threads with optional pagination and user filters.
#
# GET /chatkit/threads
# operationId: ListThreadsMethod
export def "chatkit-threads ListThreadsMethod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of thread items to return. Defaults to 20.
  --order: string # Sort order for results by creation time. Defaults to `desc`.
  --after: string # List items created after this thread item ID. Defaults to null for the first page.
  --before: string # List items created before this thread item ID. Defaults to null for the newest results.
  --user: string # Filter threads that belong to this user identifier. Defaults to null to return all users.
]: nothing -> record<object: string, data: table<id: string, object: string, created_at: int, title: any, status: any, user: string>, first_id: any, last_id: any, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chatkit/threads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
