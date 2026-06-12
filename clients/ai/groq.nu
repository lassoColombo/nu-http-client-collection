# Auto-generated client for GroqCloud API v2.1
# Source: https://storage.googleapis.com/stainless-sdk-openapi-specs/groqcloud/groqcloud-0298a69b7d74303a353e8a586d85e5cc769b9560920487fadfe773c0100af249.yml
# Auth: --token flag or $env.GROQCLOUD_API_TOKEN

const BASE_URL = "https://api.groq.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GROQCLOUD_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.groq.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def response-format-completer [] { ["flac" "mp3" "mulaw" "ogg" "wav"] }
def sample-rate-completer [] { ["16000" "22050" "24000" "32000" "44100" "48000" "8000"] }
def response-format-completer-1 [] { ["json" "text" "verbose_json"] }
def accept-completer [] { ["application/json" "text/plain"] }
def endpoint-completer [] { ["/v1/chat/completions"] }
def service-tier-completer [] { ["" "auto" "flex" "on_demand" "performance"] }
def reasoning-effort-completer [] { ["default" "high" "low" "medium" "none"] }
def reasoning-format-completer [] { ["hidden" "parsed" "raw"] }
def citation-options-completer [] { ["disabled" "enabled"] }
def encoding-format-completer [] { ["base64" "float"] }
def purpose-completer [] { ["batch"] }
def service-tier-completer-1 [] { ["auto" "default" "flex"] }
def truncation-completer [] { ["auto" "disabled"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "openai-audio-speech createSpeech" } } | get name | first)
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

# Generates audio from the input text.
#
# POST /openai/v1/audio/speech
# operationId: createSpeech
export def "openai-audio-speech createSpeech" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: any # One of the [available TTS models](/docs/text-to-speech).  (e.g. playai-tts)
  input: string # The text to generate audio for. (e.g. The quick brown fox jumped over the lazy dog)
  voice: string # The voice to use when generating the audio. List of voices can be found [here](/docs/text-to-speech). (e.g. Fritz-PlayAI)
  --response-format: string@response-format-completer # The format of the generated audio. Supported formats are `flac, mp3, mulaw, ogg, wav`. (default: mp3)
  --sample-rate: int@sample-rate-completer # The sample rate for generated audio (default: 48000, e.g. 48000)
  --speed: float # The speed of the generated audio. (default: 1, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/audio/speech")
  let body = {model: $model, input: $input, voice: $voice, response_format: $response_format, sample_rate: $sample_rate, speed: $speed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "audio/wav"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transcribes audio into the input language.
#
# POST /openai/v1/audio/transcriptions
# operationId: createTranscription
export def "openai-audio-transcriptions createTranscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # The audio file object (not file name) to transcribe, in one of these formats: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, or webm. Either a file or a URL must be provided. Note that the file field is not supported in Batch API requests.  (format: binary)
  --body-url: string # The audio URL to translate/transcribe (supports Base64URL). Either a file or a URL must be provided. For Batch API requests, the URL field is required since the file field is not supported.
  model: any # ID of the model to use. `whisper-large-v3` and `whisper-large-v3-turbo` are currently available.  (e.g. whisper-large-v3-turbo)
  --language: any # The language of the input audio. Supplying the input language in [ISO-639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format will improve accuracy and latency.
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/speech-text) should match the audio language.
  --response-format: string@response-format-completer-1 # The format of the transcript output, in one of these options: `json`, `text`, or `verbose_json`.  (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit.  (default: 0)
  --timestamp-granularities: list # The timestamp granularities to populate for this transcription. `response_format` must be set `verbose_json` to use timestamp granularities. Either or both of these options are supported: `word`, or `segment`. Note: There is no additional latency for segment timestamps, but generating word timestamps incurs additional latency.  (default: [segment])
]: any -> record<text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/audio/transcriptions")
  let body = {file: $file, url: $body_url, model: $model, language: $language, prompt: $prompt, response_format: $response_format, temperature: $temperature, timestamp_granularities: $timestamp_granularities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Translates audio into English.
#
# POST /openai/v1/audio/translations
# operationId: createTranslation
export def "openai-audio-translations createTranslation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --file: string # The audio file object (not file name) translate, in one of these formats: flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, or webm.  (format: binary)
  --body-url: string # The audio URL to translate/transcribe (supports Base64URL). Either file or url must be provided. When using the Batch API only url is supported.
  model: any # ID of the model to use. `whisper-large-v3` and `whisper-large-v3-turbo` are currently available.  (e.g. whisper-large-v3-turbo)
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/guides/speech-to-text/prompting) should be in English.
  --response-format: string@response-format-completer-1 # The format of the transcript output, in one of these options: `json`, `text`, or `verbose_json`.  (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit.  (default: 0)
]: any -> record<text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/audio/translations")
  let body = {file: $file, url: $body_url, model: $model, prompt: $prompt, response_format: $response_format, temperature: $temperature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Creates and executes a batch from an uploaded file of requests. [Learn more](/docs/batch).
#
# POST /openai/v1/batches
# operationId: createBatch
export def "openai-batches createBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  input_file_id: string # The ID of an uploaded file that contains requests for the new batch.  See [upload file](/docs/api-reference#files-upload) for how to upload a file.  Your input file must be formatted as a [JSONL file](/docs/batch), and must be uploaded with the purpose `batch`. The file can be up to 100 MB in size.
  endpoint: string@endpoint-completer # The endpoint to be used for all requests in the batch. Currently `/v1/chat/completions` is supported.
  completion_window: string # The time frame within which the batch should be processed. Durations from `24h` to `7d` are supported.
  --metadata: record # Optional custom metadata for the batch. (nullable)
]: any -> record<id: string, object: string, endpoint: string, errors: record<object: string, data: list<record>>, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record<total: int, completed: int, failed: int>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/batches")
  let body = {input_file_id: $input_file_id, endpoint: $endpoint, completion_window: $completion_window, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List your organization's batches.
#
# GET /openai/v1/batches
# operationId: listBatches
export def "openai-batches listBatches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, object: string, endpoint: string, errors: record, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record, metadata: record>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/batches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a batch.
#
# GET /openai/v1/batches/{batch_id}
# operationId: retrieveBatch
export def "openai-batches retrieveBatch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, endpoint: string, errors: record<object: string, data: list<record>>, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record<total: int, completed: int, failed: int>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/openai/v1/batches/($batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels a batch.
#
# POST /openai/v1/batches/{batch_id}/cancel
# operationId: cancelBatch
export def "openai-batches-cancel cancelBatch" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, object: string, endpoint: string, errors: record<object: string, data: list<record>>, input_file_id: string, completion_window: string, status: string, output_file_id: string, error_file_id: string, created_at: int, in_progress_at: int, expires_at: int, finalizing_at: int, completed_at: int, failed_at: int, expired_at: int, cancelling_at: int, cancelled_at: int, request_counts: record<total: int, completed: int, failed: int>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/openai/v1/batches/($batch_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a model response for the given chat conversation.
#
# POST /openai/v1/chat/completions
# operationId: createChatCompletion
# --tools item shape: {type: any, function?: record}
# --functions item shape: {description?: string, name: string, parameters?: record}
# --search_settings shape: {include_domains?: list, exclude_domains?: list, include_images?: bool, country?: string}
# --compound_custom shape: {models?: record, tools?: record}
# --documents item shape: {id?: string, source: any}
@deprecated --flag max-tokens
@deprecated --flag function-call
@deprecated --flag functions
@deprecated --flag include-domains
@deprecated --flag exclude-domains
export def "openai-chat-completions createChatCompletion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # A list of messages comprising the conversation so far.
  model: any # ID of the model to use. For details on which models are compatible with the Chat API, see available [models](https://console.groq.com/docs/models) (e.g. meta-llama/llama-4-scout-17b-16e-instruct)
  --disable-tool-validation: oneof<nothing, bool> # If set to true, groq will return called tools without validating that the tool is present in request.tools. tool_choice=required/none will still be enforced, but the request cannot require a specific tool be used.  (default: false)
  --frequency-penalty: float # This is not yet supported by any of our models. Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. (nullable, default: 0)
  --include-reasoning: oneof<nothing, bool> # Whether to include reasoning in the response.  If true, the response will include a `reasoning` field. If false, the model's reasoning will not be included in the response. This field is mutually exclusive with `reasoning_format`.  (nullable)
  --logit-bias: record # This is not yet supported by any of our models. Modify the likelihood of specified tokens appearing in the completion.  (nullable)
  --logprobs: oneof<nothing, bool> # This is not yet supported by any of our models. Whether to return log probabilities of the output tokens or not. If true, returns the log probabilities of each output token returned in the `content` of `message`.  (nullable, default: false)
  --top-logprobs: int # This is not yet supported by any of our models. An integer between 0 and 20 specifying the number of most likely tokens to return at each token position, each with an associated log probability. `logprobs` must be set to `true` if this parameter is used.  (nullable)
  --max-tokens: int # Deprecated in favor of `max_completion_tokens`. The maximum number of tokens that can be generated in the chat completion. The total length of input tokens and generated tokens is limited by the model's context length.  (DEPRECATED, nullable)
  --max-completion-tokens: int # The maximum number of tokens that can be generated in the chat completion. The total length of input tokens and generated tokens is limited by the model's context length. (nullable)
  --n: int # How many chat completion choices to generate for each input message. Note that the current moment, only n=1 is supported. Other values will result in a 400 response. (nullable, default: 1, e.g. 1)
  --presence-penalty: float # This is not yet supported by any of our models. Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. (nullable, default: 0)
  --response-format: any # An object specifying the format that the model must output. Setting to `{ "type": "json_schema", "json_schema": {...} }` enables Structured Outputs which ensures the model will match your supplied JSON schema. `json_schema` response format is only available on [supported models](https://console.groq.com/docs/structured-outputs#supported-models). Setting to `{ "type": "json_object" }` enables the older JSON mode, which ensures the message the model generates is valid JSON. Using `json_schema` is preferred for models that support it.  (nullable)
  --seed: int # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same `seed` and parameters should return the same result. Determinism is not guaranteed, and you should refer to the `system_fingerprint` response parameter to monitor changes in the backend.  (nullable)
  --service-tier: string@service-tier-completer # The service tier to use for the request. Defaults to `on_demand`. - `auto` will automatically select the highest tier available within the rate limits of your organization. - `flex` uses the flex tier, which will succeed or fail quickly.  (nullable)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.  (nullable)
  --reasoning-effort: string@reasoning-effort-completer # qwen3 models support the following values Set to 'none' to disable reasoning. Set to 'default' or null to let Qwen reason.  openai/gpt-oss-20b and openai/gpt-oss-120b support 'low', 'medium', or 'high'. 'medium' is the default value.  (nullable)
  --reasoning-format: string@reasoning-format-completer # Specifies how to output reasoning tokens This field is mutually exclusive with `include_reasoning`.  (nullable)
  --stream: oneof<nothing, bool> # If set, partial message deltas will be sent. Tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. [Example code](/docs/text-chat#streaming-a-chat-completion).  (nullable, default: false)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or top_p but not both. (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or temperature but not both. (nullable, default: 1, e.g. 1)
  --tools: list # A list of tools the model may call. Currently, only functions are supported as a tool. Use this to provide a list of functions the model may generate JSON inputs for. A max of 128 functions are supported.  (nullable) — item shape: {type: any, function?: record}
  --tool-choice: any # Controls which (if any) tool is called by the model. `none` means the model will not call any tool and instead generates a message. `auto` means the model can pick between generating a message or calling one or more tools. `required` means the model must call one or more tools. Specifying a particular tool via `{"type": "function", "function": {"name": "my_function"}}` forces the model to call that tool.  `none` is the default when no tools are present. `auto` is the default if tools are present.  (nullable)
  --parallel-tool-calls: oneof<nothing, bool> # Whether to enable parallel function calling during tool use.  (nullable, default: true)
  --user: string # A unique identifier representing your end-user, which can help us monitor and detect abuse. (nullable)
  --function-call: any # Deprecated in favor of `tool_choice`.  Controls which (if any) function is called by the model. `none` means the model will not call a function and instead generates a message. `auto` means the model can pick between generating a message or calling a function. Specifying a particular function via `{"name": "my_function"}` forces the model to call that function.  `none` is the default when no functions are present. `auto` is the default if functions are present.  (DEPRECATED, nullable)
  --functions: list # Deprecated in favor of `tools`.  A list of functions the model may generate JSON inputs for.  (DEPRECATED, nullable) — item shape: {description?: string, name: string, parameters?: record}
  --metadata: record # This parameter is not currently supported.  (nullable)
  --store: oneof<nothing, bool> # This parameter is not currently supported.  (nullable)
  --include-domains: list # Deprecated: Use search_settings.include_domains instead. A list of domains to include in the search results when the model uses a web search tool.  (DEPRECATED, nullable)
  --exclude-domains: list # Deprecated: Use search_settings.exclude_domains instead. A list of domains to exclude from the search results when the model uses a web search tool.  (DEPRECATED, nullable)
  --search-settings: record # Settings for web search functionality when the model uses a web search tool.  (nullable) — shape: {include_domains?: list, exclude_domains?: list, include_images?: bool, country?: string}
  --compound-custom: record # Custom configuration of models and tools for Compound. (nullable) — shape: {models?: record, tools?: record}
  --documents: list # A list of documents to provide context for the conversation. Each document contains text that can be referenced by the model. (nullable) — item shape: {id?: string, source: any}
  --citation-options: string@citation-options-completer # Whether to enable citations in the response. When enabled, the model will include citations for information retrieved from provided documents or web searches. (nullable, default: enabled)
]: any -> record<id: string, choices: table<finish_reason: string, index: int, message: record, logprobs: record>, created: int, model: string, system_fingerprint: string, object: string, usage: record<queue_time: float, completion_time: float, completion_tokens: int, prompt_time: float, prompt_tokens: int, total_time: float, total_tokens: int, prompt_tokens_details: record<cached_tokens: int>, completion_tokens_details: record<reasoning_tokens: int>>, usage_breakdown: record<models: list<record>>, service_tier: string, mcp_list_tools: table<id: string, type: string, server_label: string, tools: list>, x_groq: record<id: string, seed: int, usage: record<sram_cached_tokens: int, dram_cached_tokens: int>, debug: record<input_token_ids: list, input_tokens: list, output_token_ids: list, output_tokens: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/chat/completions")
  let body = {messages: $messages, model: $model, disable_tool_validation: $disable_tool_validation, frequency_penalty: $frequency_penalty, include_reasoning: $include_reasoning, logit_bias: $logit_bias, logprobs: $logprobs, top_logprobs: $top_logprobs, max_tokens: $max_tokens, max_completion_tokens: $max_completion_tokens, n: $n, presence_penalty: $presence_penalty, response_format: $response_format, seed: $seed, service_tier: $service_tier, stop: $stop, reasoning_effort: $reasoning_effort, reasoning_format: $reasoning_format, stream: $stream, temperature: $temperature, top_p: $top_p, tools: $tools, tool_choice: $tool_choice, parallel_tool_calls: $parallel_tool_calls, user: $user, function_call: $function_call, functions: $functions, metadata: $metadata, store: $store, include_domains: $include_domains, exclude_domains: $exclude_domains, search_settings: $search_settings, compound_custom: $compound_custom, documents: $documents, citation_options: $citation_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an embedding vector representing the input text.
#
# POST /openai/v1/embeddings
# operationId: createEmbedding
export def "openai-embeddings createEmbedding" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  input: any # Input text to embed, encoded as a string or array of tokens. To embed multiple inputs in a single request, pass an array of strings or array of token arrays. The input must not exceed the max input tokens for the model, cannot be an empty string, and any array must be 2048 dimensions or less.  (e.g. The quick brown fox jumped over the lazy dog)
  model: any # ID of the model to use.  (e.g. nomic-embed-text-v1_5)
  --encoding-format: string@encoding-format-completer # The format to return the embeddings in. Can only be `float` or `base64`. (default: float, e.g. float)
  --user: string # A unique identifier representing your end-user, which can help us monitor and detect abuse. (nullable)
]: any -> record<data: table<index: int, embedding: any, object: string>, model: string, object: string, usage: record<prompt_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/embeddings")
  let body = {input: $input, model: $model, encoding_format: $encoding_format, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of files.
#
# GET /openai/v1/files
# operationId: listFiles
export def "openai-files listFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, data: table<id: string, bytes: int, created_at: int, filename: string, object: string, purpose: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file that can be used across various endpoints.  The Batch API only supports `.jsonl` files up to 100 MB in size. The input also has a specific required [format](/docs/batch).  Please contact us if you need to increase these storage limits.
#
# POST /openai/v1/files
# operationId: uploadFile
export def "openai-files uploadFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The File object (not file name) to be uploaded.  (format: binary)
  purpose: string@purpose-completer # The intended purpose of the uploaded file. Use "batch" for [Batch API](/docs/api-reference#batches).
]: any -> record<id: string, bytes: int, created_at: int, filename: string, object: string, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/files")
  let body = {file: $file, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a file.
#
# DELETE /openai/v1/files/{file_id}
# operationId: deleteFile
export def "openai-files delete" [
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
  let full_url = (build-url $base $"/openai/v1/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about a file.
#
# GET /openai/v1/files/{file_id}
# operationId: retrieveFile
export def "openai-files retrieveFile" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, bytes: int, created_at: int, filename: string, object: string, purpose: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/openai/v1/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the contents of the specified file.
#
# GET /openai/v1/files/{file_id}/content
# operationId: downloadFile
export def "openai-files-content downloadFile" [
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
  let full_url = (build-url $base $"/openai/v1/files/($file_id)/content")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all previously created fine tunings. This endpoint is in closed beta. [Contact us](https://groq.com/contact) for more information.
#
# GET /v1/fine_tunings
# operationId: listFineTunings
export def "fine-tunings listFineTunings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<base_model: string, created_at: float, fine_tuned_model: string, id: string, input_file_id: string, name: string, type: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fine_tunings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new fine tuning for the already uploaded files This endpoint is in closed beta. [Contact us](https://groq.com/contact) for more information.
#
# POST /v1/fine_tunings
# operationId: createFineTuning
export def "fine-tunings createFineTuning" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-model: string # BaseModel is the model that the fine tune was originally trained on.
  --input-file-id: string # InputFileID is the id of the file that was uploaded via the /files api.
  --name: string # Name is the given name to a fine tuned model.
  --type: string # Type is the type of fine tuning format such as "lora".
]: any -> record<data: record<base_model: string, created_at: float, fine_tuned_model: string, id: string, input_file_id: string, name: string, type: string>, id: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fine_tunings")
  let body = {base_model: $base_model, input_file_id: $input_file_id, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an existing fine tuning by id This endpoint is in closed beta. [Contact us](https://groq.com/contact) for more information.
#
# DELETE /v1/fine_tunings/{id}
# operationId: deleteFineTuning
export def "fine-tunings delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deleted: bool, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tunings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves an existing fine tuning by id This endpoint is in closed beta. [Contact us](https://groq.com/contact) for more information.
#
# GET /v1/fine_tunings/{id}
# operationId: getFineTuning
export def "fine-tunings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<base_model: string, created_at: float, fine_tuned_model: string, id: string, input_file_id: string, name: string, type: string>, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tunings/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all available [models](https://console.groq.com/docs/models).
#
# GET /openai/v1/models
# operationId: listModels
export def "openai-models listModels" [
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
  let full_url = (build-url $base "/openai/v1/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get detailed information about a [model](https://console.groq.com/docs/models).
#
# GET /openai/v1/models/{model}
# operationId: retrieveModel
export def "openai-models retrieveModel" [
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
  let full_url = (build-url $base $"/openai/v1/models/($model)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete model
#
# DELETE /openai/v1/models/{model}
# operationId: deleteModel
export def "openai-models delete" [
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
  let full_url = (build-url $base $"/openai/v1/models/($model)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reranks documents based on their relevance to a query.
#
# POST /openai/v1/reranking
# operationId: createReranking
export def "openai-reranking createReranking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: string # ID of the reranking model to use.  (e.g. qwen3-reranker-4b)
  --body-query: string # The search query to rank documents against.  (e.g. artificial intelligence research)
  docs: list # An array of documents to rank. Each document is a string containing the text content. Maximum of 100 documents per request.  (e.g. [Machine learning is a subset of artificial intelligence, The weather forecast predicts rain tomorrow, Deep learning uses neural networks with multiple layers])
  --instruction: string # Optional instruction to guide the reranking process. If not provided,  a default instruction will be used.  (nullable, e.g. Find the most relevant document about AI research)
]: any -> record<results: table<doc: string, score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/reranking")
  let body = {model: $model, query: $body_query, docs: $docs, instruction: $instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a model response for the given input.
#
# POST /openai/v1/responses
# operationId: createResponse
# --tools item shape: {type: "function", name: string, description?: string, parameters?: record, strict?: bool}
# --text shape: {format?: any}
# --reasoning shape: {effort?: "low"|"medium"|"high"}
export def "openai-responses createResponse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: any # ID of the model to use. For details on which models are compatible with the Responses API, see available [models](https://console.groq.com/docs/models) (e.g. llama-3.3-70b-versatile)
  input: any # Text input to the model, used to generate a response.
  --instructions: string # Inserts a system (or developer) message as the first item in the model's context.  (nullable)
  --max-output-tokens: int # An upper bound for the number of tokens that can be generated for a response, including visible output tokens and reasoning tokens.  (nullable)
  --temperature: float # Controls randomness in the response generation. Range: 0 to 2. Lower values produce more deterministic outputs, higher values increase variety and creativity.  (nullable, default: 1, e.g. 1)
  --top-p: float # Nucleus sampling parameter that controls the cumulative probability cutoff. Range: 0 to 1. A value of 0.1 restricts sampling to tokens within the top 10% probability mass.  (nullable, default: 1, e.g. 1)
  --tools: list # List of tools available to the model. Currently supports function definitions only. Maximum of 128 functions.  (nullable) — item shape: {type: "function", name: string, description?: string, parameters?: record, strict?: bool}
  --tool-choice: any # Controls which (if any) tool is called by the model. `none` means the model will not call any tool and instead generates a message. `auto` means the model can pick between generating a message or calling one or more tools. `required` means the model must call one or more tools. Specifying a particular tool via `{"type": "function", "function": {"name": "my_function"}}` forces the model to call that tool.  `none` is the default when no tools are present. `auto` is the default if tools are present.  (nullable)
  --text: record # Response format configuration. Supports plain text or structured JSON output. — shape: {format?: any}
  --reasoning: record # Configuration for reasoning capabilities when using [models that support reasoning](https://console.groq.com/docs/reasoning).  (nullable) — shape: {effort?: "low"|"medium"|"high"}
  --metadata: record # Custom key-value pairs for storing additional information. Maximum of 16 pairs.  (nullable)
  --parallel-tool-calls: oneof<nothing, bool> # Enable parallel execution of multiple tool calls.  (nullable, default: true)
  --store: oneof<nothing, bool> # Response storage flag. Note: Currently only supports false or null values.  (nullable, default: false)
  --stream: oneof<nothing, bool> # Enable streaming mode to receive response data as server-sent events.  (nullable, default: false)
  --user: string # Optional identifier for tracking end-user requests. Useful for usage monitoring and compliance.  (e.g. user-1234)
  --service-tier: string@service-tier-completer-1 # Specifies the latency tier to use for processing the request.  (nullable, default: auto)
  --truncation: string@truncation-completer # Context truncation strategy. Supported values: `auto` or `disabled`.  (nullable, default: disabled)
]: any -> record<id: string, object: string, status: string, created_at: int, output: list<any>, previous_response_id: string, model: string, reasoning: record<effort: string, summary: string>, max_output_tokens: int, instructions: string, text: record<format: any>, tools: table<type: string, name: string, description: string, parameters: record, strict: bool>, tool_choice: any, truncation: string, metadata: record, temperature: float, top_p: float, user: string, service_tier: string, error: record<code: string, message: string>, incomplete_details: record<reason: string>, usage: record<input_tokens: int, input_tokens_details: record<cached_tokens: int, reasoning_tokens: int>, output_tokens: int, output_tokens_details: record<cached_tokens: int, reasoning_tokens: int>, total_tokens: int>, parallel_tool_calls: bool, store: bool, background: bool, top_logprobs: int, max_tool_calls: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openai/v1/responses")
  let body = {model: $model, input: $input, instructions: $instructions, max_output_tokens: $max_output_tokens, temperature: $temperature, top_p: $top_p, tools: $tools, tool_choice: $tool_choice, text: $text, reasoning: $reasoning, metadata: $metadata, parallel_tool_calls: $parallel_tool_calls, store: $store, stream: $stream, user: $user, service_tier: $service_tier, truncation: $truncation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
