# Auto-generated client for AssemblyAI API v1.3.4
# Source: https://www.assemblyai.com/docs/openapi.json
# Auth: --token flag or $env.ASSEMBLYAI_API_TOKEN

const BASE_URL = "https://api.assemblyai.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ASSEMBLYAI_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.assemblyai.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def redact-pii-audio-quality-completer [] { ["mp3" "wav"] }
def summary-model-completer [] { ["catchy" "conversational" "informative"] }
def summary-type-completer [] { ["bullets" "bullets_verbose" "gist" "headline" "paragraph"] }
def status-completer [] { ["completed" "error" "processing" "queued"] }
def accept-completer [] { ["text/html" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "upload uploadFile" } } | get name | first)
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

# Upload a media file
#
# POST /v2/upload
# operationId: uploadFile
export def "upload uploadFile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<upload_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/upload")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Transcribe audio
#
# POST /v2/transcript
# operationId: createTranscript
# --custom_spelling item shape: {from: list, to: string}
# --language_detection_options shape: {expected_languages?: list, fallback_language?: string, code_switching?: bool, code_switching_confidence_threshold?: float}
# --redact_pii_audio_options shape: {return_redacted_no_speech_audio?: bool, override_audio_redaction_method?: "silence"}
# --speaker_options shape: {min_speakers_expected?: int, max_speakers_expected?: int}
# --speech_understanding shape: {request: any}
@deprecated --flag auto-chapters
@deprecated --flag summarization
@deprecated --flag custom-topics
@deprecated --flag speech-model
@deprecated --flag topics
export def "transcript createTranscript" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  audio_url: string # The URL of the audio or video file to transcribe. (format: url)
  --audio-end-at: int # The point in time, in milliseconds, to stop transcribing in your media file. See [Set the start and end of the transcript](https://www.assemblyai.com/docs/pre-recorded-audio/set-the-start-and-end-of-the-transcript) for more details.
  --audio-start-from: int # The point in time, in milliseconds, to begin transcribing in your media file. See [Set the start and end of the transcript](https://www.assemblyai.com/docs/pre-recorded-audio/set-the-start-and-end-of-the-transcript) for more details.
  --auto-chapters: oneof<nothing, bool> # Enable [Auto Chapters](https://www.assemblyai.com/docs/speech-understanding/auto-chapters), can be true or false. Deprecated - use [LLM Gateway](https://www.assemblyai.com/docs/llm-gateway/overview) instead for more flexible chapter summaries. See the [updated Auto Chapters page](https://www.assemblyai.com/docs/speech-understanding/auto-chapters) for details.  Note: This parameter is only supported for the Universal-2 model.  (DEPRECATED, default: false)
  --auto-highlights: oneof<nothing, bool> # Enable [Key Phrases](https://www.assemblyai.com/docs/speech-understanding/key-phrases), either true or false (default: false)
  --content-safety: oneof<nothing, bool> # Enable [Content Moderation](https://www.assemblyai.com/docs/content-moderation), can be true or false (default: false)
  --content-safety-confidence: int # The confidence threshold for the [Content Moderation](https://www.assemblyai.com/docs/content-moderation) model. Values must be between 25 and 100. (default: 50)
  --custom-spelling: list # Customize how words are spelled and formatted using to and from values. See [Custom Spelling](https://www.assemblyai.com/docs/pre-recorded-audio/correct-spelling-of-terms) for more details. — item shape: {from: list, to: string}
  --disfluencies: oneof<nothing, bool> # Transcribe [Filler Words](https://www.assemblyai.com/docs/pre-recorded-audio/include-filler-words), like "umm", in your media file; can be true or false. Supported on Universal-3 Pro and Universal-2. (default: false)
  --domain: any # Enable domain-specific transcription models to improve accuracy for specialized terminology. Set to `"medical-v1"` to enable [Medical Mode](https://www.assemblyai.com/docs/pre-recorded-audio/medical-mode) for improved accuracy of medical terms such as medications, procedures, conditions, and dosages.  Supported languages: English (`en`), Spanish (`es`), German (`de`), French (`fr`). If used with an unsupported language, the parameter is ignored and a warning is returned.
  --entity-detection: oneof<nothing, bool> # Enable [Entity Detection](https://www.assemblyai.com/docs/speech-understanding/entity-detection), can be true or false (default: false)
  --filter-profanity: oneof<nothing, bool> # Filter profanity from the transcribed text, can be true or false. See [Profanity Filtering](https://www.assemblyai.com/docs/profanity-filtering) for more details. (default: false)
  --format-text: oneof<nothing, bool> # Enable [Text Formatting](https://www.assemblyai.com/docs/pre-recorded-audio), can be true or false (default: true)
  --iab-categories: oneof<nothing, bool> # Enable [Topic Detection](https://www.assemblyai.com/docs/speech-understanding/topic-detection), can be true or false (default: false)
  --keyterms-prompt: list # Improve accuracy with up to 200 (for Universal-2) or 1000 (for Universal-3 Pro) domain-specific words or phrases (maximum 6 words per phrase). See [Keyterms Prompting](https://www.assemblyai.com/docs/pre-recorded-audio/keyterms-prompting) for more details.
  --language-code: any # The language of your audio file. Possible values are found in [Supported Languages](https://www.assemblyai.com/docs/pre-recorded-audio/supported-languages). The default value is 'en_us'.  (default: en_us)
  --language-codes: list # The language codes of your audio file. Used for [Code switching](/speech-to-text/pre-recorded-audio/code-switching) One of the values specified must be `en`.  (nullable)
  --language-confidence-threshold: float # The confidence threshold for the automatically detected language. An error will be returned if the language confidence is below this threshold. Defaults to 0. See [Automatic Language Detection](https://www.assemblyai.com/docs/pre-recorded-audio/language-detection) for more details.  (format: float, default: 0)
  --language-detection: oneof<nothing, bool> # Enable [Automatic language detection](https://www.assemblyai.com/docs/pre-recorded-audio/language-detection), either true or false. (default: false)
  --language-detection-options: record # Specify options for [Automatic Language Detection](https://www.assemblyai.com/docs/pre-recorded-audio/language-detection). — shape: {expected_languages?: list, fallback_language?: string, code_switching?: bool, code_switching_confidence_threshold?: float}
  --multichannel: oneof<nothing, bool> # Enable [Multichannel](https://www.assemblyai.com/docs/pre-recorded-audio/transcribe-multiple-audio-channels) transcription, can be true or false. (default: false)
  --prompt: string # Provide natural language prompting of up to 1,500 words of contextual information to the model. See the [Prompting Guide](https://www.assemblyai.com/docs/pre-recorded-audio/prompting) for best practices.  Note: This parameter is only supported for the Universal-3 Pro model.
  --punctuate: oneof<nothing, bool> # Enable [Automatic Punctuation](https://www.assemblyai.com/docs/pre-recorded-audio), can be true or false (default: true)
  --redact-pii: oneof<nothing, bool> # Redact PII from the transcribed text using the Redact PII model, can be true or false. See [PII Redaction](https://www.assemblyai.com/docs/pii-redaction) for more details. (default: false)
  --redact-pii-audio: oneof<nothing, bool> # Generate a copy of the original media file with spoken PII "beeped" out, can be true or false. See [PII redaction](https://www.assemblyai.com/docs/pii-redaction#request-for-redacted-audio) for more details. (default: false)
  --redact-pii-audio-options: record # Specify options for [PII redacted audio](https://www.assemblyai.com/docs/pii-redaction#request-for-redacted-audio) files. — shape: {return_redacted_no_speech_audio?: bool, override_audio_redaction_method?: "silence"}
  --redact-pii-audio-quality: string@redact-pii-audio-quality-completer # Controls the filetype of the audio created by redact_pii_audio. Currently supports mp3 (default) and wav. See [PII redaction](https://www.assemblyai.com/docs/pii-redaction#request-for-redacted-audio) for more details. (e.g. mp3)
  --redact-pii-policies: list # The list of PII Redaction policies to enable. See [PII redaction](https://www.assemblyai.com/docs/pii-redaction) for more details.
  --redact-pii-sub: any # The replacement logic for detected PII, can be `entity_type` or `hash`. See [PII redaction](https://www.assemblyai.com/docs/pii-redaction) for more details. (default: hash)
  --redact-pii-return-unredacted: oneof<nothing, bool> # When set to `true`, returns the original unredacted transcript alongside the redacted one in the same response. Requires `redact_pii` to be `true`, otherwise a 400 error is returned.  When enabled, the response includes the additional fields `unredacted_text`, `unredacted_words`, and `unredacted_utterances`. The existing `text`, `words`, and `utterances` fields remain fully redacted. When disabled (default), the response is unchanged and contains only the redacted transcript. See [PII redaction](https://www.assemblyai.com/docs/pii-redaction) for more details.  (default: false)
  --redact-static-entities: record # A map of user-defined terms to redact, where each key is a redaction label and each value is a list of exact terms to match (e.g. `{ "INTERNAL_TOOL": ["Bearclaw", "Cubclaw"] }`). Each matching term in the transcript is redacted using the `redact_pii_sub` substitution, on top of standard PII Redaction. Useful for redacting specific, predefined terms (proprietary names, internal codenames) that aren't general PII categories.  This is a literal find-and-replace (tolerant of casing, surrounding punctuation, and minor spacing/hyphenation), not a model — it does not generalize beyond the terms you provide. Requires `redact_pii` to be `true`, otherwise a 400 error is returned. When `redact_pii_audio` is enabled, matched terms are also redacted in the audio output. See [Static Entity Redaction](https://www.assemblyai.com/docs/guardrails/redact-pii-from-transcripts#static-entity-redaction) for more details.
  --sentiment-analysis: oneof<nothing, bool> # Enable [Sentiment Analysis](https://www.assemblyai.com/docs/speech-understanding/sentiment-analysis), can be true or false (default: false)
  --speaker-labels: oneof<nothing, bool> # Enable [Speaker diarization](https://www.assemblyai.com/docs/pre-recorded-audio/label-speakers), can be true or false (default: false)
  --speaker-options: record # Specify options for [Speaker diarization](https://www.assemblyai.com/docs/pre-recorded-audio/label-speakers#set-a-range-of-possible-speakers). Use this to set a range of possible speakers. — shape: {min_speakers_expected?: int, max_speakers_expected?: int}
  --speakers-expected: int # Tells the speaker label model how many speakers it should attempt to identify. See [Set number of speakers expected](https://www.assemblyai.com/docs/pre-recorded-audio/label-speakers#set-number-of-speakers-expected) for more details. (nullable)
  --speech-models: list # Optional. List multiple speech models in priority order, allowing our system to automatically route your audio to the best available option. If omitted, defaults to `["universal-3-pro", "universal-2"]`. See [Model Selection](https://www.assemblyai.com/docs/pre-recorded-audio/select-the-speech-model) for available models and routing behavior.  (default: [universal-3-pro, universal-2])
  --speech-threshold: float # Reject audio files that contain less than this fraction of speech. Valid values are in the range [0, 1] inclusive. See [Speech Threshold](https://www.assemblyai.com/docs/speech-threshold) for more details.  (nullable, format: float, default: 0)
  --speech-understanding: record # Enable speech understanding tasks like [Translation](https://www.assemblyai.com/docs/speech-understanding/translation), [Speaker Identification](https://www.assemblyai.com/docs/speech-understanding/speaker-identification), and [Custom Formatting](https://www.assemblyai.com/docs/speech-understanding/custom-formatting). See the task-specific docs for available options and configuration. — shape: {request: any}
  --summarization: oneof<nothing, bool> # Enable [Summarization](https://www.assemblyai.com/docs/speech-understanding/summarization), can be true or false. Deprecated - use [LLM Gateway](https://www.assemblyai.com/docs/llm-gateway/overview) instead for more flexible summaries. See the [updated Summarization page](https://www.assemblyai.com/docs/speech-understanding/summarization) for details.  Note: This parameter is only supported for the Universal-2 model.  (DEPRECATED, default: false)
  --summary-model: string@summary-model-completer # The model to summarize the transcript
  --summary-type: string@summary-type-completer # The type of summary
  --remove-audio-tags: any # Universal-3 Pro generates rich transcripts that can include inline annotations such as audio event markers and speaker cues. Set to `"all"` to remove all inline annotations, or `"speaker"` to remove only speaker cues while keeping other annotations.  Note: This parameter is only supported for the Universal-3 Pro model.
  --temperature: float # Control the amount of randomness injected into the model's response. See the [Prompting Guide](https://www.assemblyai.com/docs/pre-recorded-audio/prompting) for more details.  Note: This parameter can only be used with the Universal-3 Pro model.  (default: 0)
  --webhook-auth-header-name: string # The header name to be sent with the transcript completed or failed [webhook](https://www.assemblyai.com/docs/deployment/webhooks-for-pre-recorded-audio) requests (nullable)
  --webhook-auth-header-value: string # The header value to send back with the transcript completed or failed [webhook](https://www.assemblyai.com/docs/deployment/webhooks-for-pre-recorded-audio) requests for added security (nullable)
  --webhook-url: string # The URL to which we send [webhook](https://www.assemblyai.com/docs/deployment/webhooks-for-pre-recorded-audio) requests.  (format: url)
  --custom-topics: oneof<nothing, bool> # This parameter does not currently have any functionality attached to it. (DEPRECATED, default: false)
  --speech-model: any # This parameter has been replaced with the `speech_models` parameter, learn more about the `speech_models` parameter [here](https://www.assemblyai.com/docs/pre-recorded-audio/select-the-speech-model).  (DEPRECATED)
  --topics: list # This parameter does not currently have any functionality attached to it. (DEPRECATED)
]: any -> record<audio_channels: int, audio_duration: int, audio_end_at: int, audio_start_from: int, audio_url: string, auto_chapters: bool, auto_highlights: bool, auto_highlights_result: any, chapters: table<gist: string, headline: string, summary: string, start: int, end: int>, confidence: float, content_safety: bool, content_safety_labels: any, custom_spelling: table<from: list, to: string>, disfluencies: bool, domain: string, entities: table<entity_type: string, text: string, start: int, end: int>, entity_detection: bool, error: string, filter_profanity: bool, format_text: bool, iab_categories: bool, iab_categories_result: any, id: string, keyterms_prompt: list<string>, language_code: any, language_codes: list<string>, language_confidence: float, language_confidence_threshold: float, language_detection: bool, language_detection_options: record<expected_languages: list<string>, fallback_language: string, code_switching: bool, code_switching_confidence_threshold: float>, multichannel: bool, prompt: string, punctuate: bool, redact_pii: bool, redact_pii_audio: bool, redact_pii_audio_options: record<return_redacted_no_speech_audio: bool, override_audio_redaction_method: string>, redact_pii_audio_quality: any, redact_pii_policies: list<string>, redact_pii_sub: string, redact_pii_return_unredacted: bool, sentiment_analysis: bool, sentiment_analysis_results: table<text: string, start: int, end: int, sentiment: any, confidence: float, channel: string, speaker: string>, speaker_labels: bool, speakers_expected: int, speech_model_used: string, speech_models: list<string>, speech_threshold: float, speech_understanding: record<request: any, response: any>, status: string, summarization: bool, summary: string, summary_model: string, summary_type: string, remove_audio_tags: any, temperature: float, text: string, unredacted_text: string, throttled: bool, utterances: table<confidence: float, start: int, end: int, text: string, words: list, channel: string, speaker: string, translated_texts: record>, unredacted_utterances: table<confidence: float, start: int, end: int, text: string, words: list, channel: string, speaker: string, translated_texts: record>, webhook_auth: bool, webhook_auth_header_name: string, webhook_status_code: int, webhook_url: string, words: table<confidence: float, start: int, end: int, text: string, channel: string, speaker: string>, unredacted_words: table<confidence: float, start: int, end: int, text: string, channel: string, speaker: string>, acoustic_model: string, custom_topics: bool, language_model: string, speech_model: any, speed_boost: bool, topics: list<string>, translated_texts: record<language_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/transcript")
  let body = {audio_url: $audio_url, audio_end_at: $audio_end_at, audio_start_from: $audio_start_from, auto_chapters: $auto_chapters, auto_highlights: $auto_highlights, content_safety: $content_safety, content_safety_confidence: $content_safety_confidence, custom_spelling: $custom_spelling, disfluencies: $disfluencies, domain: $domain, entity_detection: $entity_detection, filter_profanity: $filter_profanity, format_text: $format_text, iab_categories: $iab_categories, keyterms_prompt: $keyterms_prompt, language_code: $language_code, language_codes: $language_codes, language_confidence_threshold: $language_confidence_threshold, language_detection: $language_detection, language_detection_options: $language_detection_options, multichannel: $multichannel, prompt: $prompt, punctuate: $punctuate, redact_pii: $redact_pii, redact_pii_audio: $redact_pii_audio, redact_pii_audio_options: $redact_pii_audio_options, redact_pii_audio_quality: $redact_pii_audio_quality, redact_pii_policies: $redact_pii_policies, redact_pii_sub: $redact_pii_sub, redact_pii_return_unredacted: $redact_pii_return_unredacted, redact_static_entities: $redact_static_entities, sentiment_analysis: $sentiment_analysis, speaker_labels: $speaker_labels, speaker_options: $speaker_options, speakers_expected: $speakers_expected, speech_models: $speech_models, speech_threshold: $speech_threshold, speech_understanding: $speech_understanding, summarization: $summarization, summary_model: $summary_model, summary_type: $summary_type, remove_audio_tags: $remove_audio_tags, temperature: $temperature, webhook_auth_header_name: $webhook_auth_header_name, webhook_auth_header_value: $webhook_auth_header_value, webhook_url: $webhook_url, custom_topics: $custom_topics, speech_model: $speech_model, topics: $topics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List transcripts
#
# GET /v2/transcript
# operationId: listTranscripts
@deprecated --flag throttled-only
export def "transcript listTranscripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum amount of transcripts to retrieve (default: 10)
  --status: string@status-completer # Filter by transcript status
  --created-on: string # Only get transcripts created on this date (format: date)
  --before-id: string # Get transcripts that were created before this transcript ID (format: uuid)
  --after-id: string # Get transcripts that were created after this transcript ID (format: uuid)
  --throttled-only: oneof<nothing, bool> # Only get throttled transcripts, overrides the status filter (DEPRECATED, default: false)
]: nothing -> record<page_details: record<limit: int, result_count: int, current_url: string, prev_url: string, next_url: string>, transcripts: table<id: string, resource_url: string, status: string, created: string, completed: string, audio_url: string, error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "before_id" $before_id "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "throttled_only" $throttled_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/transcript" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get transcript
#
# GET /v2/transcript/{transcript_id}
# operationId: getTranscript
export def "transcript list" [
  transcript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<audio_channels: int, audio_duration: int, audio_end_at: int, audio_start_from: int, audio_url: string, auto_chapters: bool, auto_highlights: bool, auto_highlights_result: any, chapters: table<gist: string, headline: string, summary: string, start: int, end: int>, confidence: float, content_safety: bool, content_safety_labels: any, custom_spelling: table<from: list, to: string>, disfluencies: bool, domain: string, entities: table<entity_type: string, text: string, start: int, end: int>, entity_detection: bool, error: string, filter_profanity: bool, format_text: bool, iab_categories: bool, iab_categories_result: any, id: string, keyterms_prompt: list<string>, language_code: any, language_codes: list<string>, language_confidence: float, language_confidence_threshold: float, language_detection: bool, language_detection_options: record<expected_languages: list<string>, fallback_language: string, code_switching: bool, code_switching_confidence_threshold: float>, multichannel: bool, prompt: string, punctuate: bool, redact_pii: bool, redact_pii_audio: bool, redact_pii_audio_options: record<return_redacted_no_speech_audio: bool, override_audio_redaction_method: string>, redact_pii_audio_quality: any, redact_pii_policies: list<string>, redact_pii_sub: string, redact_pii_return_unredacted: bool, sentiment_analysis: bool, sentiment_analysis_results: table<text: string, start: int, end: int, sentiment: any, confidence: float, channel: string, speaker: string>, speaker_labels: bool, speakers_expected: int, speech_model_used: string, speech_models: list<string>, speech_threshold: float, speech_understanding: record<request: any, response: any>, status: string, summarization: bool, summary: string, summary_model: string, summary_type: string, remove_audio_tags: any, temperature: float, text: string, unredacted_text: string, throttled: bool, utterances: table<confidence: float, start: int, end: int, text: string, words: list, channel: string, speaker: string, translated_texts: record>, unredacted_utterances: table<confidence: float, start: int, end: int, text: string, words: list, channel: string, speaker: string, translated_texts: record>, webhook_auth: bool, webhook_auth_header_name: string, webhook_status_code: int, webhook_url: string, words: table<confidence: float, start: int, end: int, text: string, channel: string, speaker: string>, unredacted_words: table<confidence: float, start: int, end: int, text: string, channel: string, speaker: string>, acoustic_model: string, custom_topics: bool, language_model: string, speech_model: any, speed_boost: bool, topics: list<string>, translated_texts: record<language_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transcript/($transcript_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete transcript
#
# DELETE /v2/transcript/{transcript_id}
# operationId: deleteTranscript
export def "transcript delete" [
  transcript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<audio_channels: int, audio_duration: int, audio_end_at: int, audio_start_from: int, audio_url: string, auto_chapters: bool, auto_highlights: bool, auto_highlights_result: any, chapters: table<gist: string, headline: string, summary: string, start: int, end: int>, confidence: float, content_safety: bool, content_safety_labels: any, custom_spelling: table<from: list, to: string>, disfluencies: bool, domain: string, entities: table<entity_type: string, text: string, start: int, end: int>, entity_detection: bool, error: string, filter_profanity: bool, format_text: bool, iab_categories: bool, iab_categories_result: any, id: string, keyterms_prompt: list<string>, language_code: any, language_codes: list<string>, language_confidence: float, language_confidence_threshold: float, language_detection: bool, language_detection_options: record<expected_languages: list<string>, fallback_language: string, code_switching: bool, code_switching_confidence_threshold: float>, multichannel: bool, prompt: string, punctuate: bool, redact_pii: bool, redact_pii_audio: bool, redact_pii_audio_options: record<return_redacted_no_speech_audio: bool, override_audio_redaction_method: string>, redact_pii_audio_quality: any, redact_pii_policies: list<string>, redact_pii_sub: string, redact_pii_return_unredacted: bool, sentiment_analysis: bool, sentiment_analysis_results: table<text: string, start: int, end: int, sentiment: any, confidence: float, channel: string, speaker: string>, speaker_labels: bool, speakers_expected: int, speech_model_used: string, speech_models: list<string>, speech_threshold: float, speech_understanding: record<request: any, response: any>, status: string, summarization: bool, summary: string, summary_model: string, summary_type: string, remove_audio_tags: any, temperature: float, text: string, unredacted_text: string, throttled: bool, utterances: table<confidence: float, start: int, end: int, text: string, words: list, channel: string, speaker: string, translated_texts: record>, unredacted_utterances: table<confidence: float, start: int, end: int, text: string, words: list, channel: string, speaker: string, translated_texts: record>, webhook_auth: bool, webhook_auth_header_name: string, webhook_status_code: int, webhook_url: string, words: table<confidence: float, start: int, end: int, text: string, channel: string, speaker: string>, unredacted_words: table<confidence: float, start: int, end: int, text: string, channel: string, speaker: string>, acoustic_model: string, custom_topics: bool, language_model: string, speech_model: any, speed_boost: bool, topics: list<string>, translated_texts: record<language_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transcript/($transcript_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get subtitles for transcript
#
# GET /v2/transcript/{transcript_id}/{subtitle_format}
# operationId: getSubtitles
export def "transcript get" [
  transcript_id: string
  subtitle_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --chars-per-caption: int # The maximum number of characters per caption
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "chars_per_caption" $chars_per_caption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/transcript/($transcript_id)/($subtitle_format)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sentences in transcript
#
# GET /v2/transcript/{transcript_id}/sentences
# operationId: getTranscriptSentences
export def "transcript-sentences get" [
  transcript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, confidence: float, audio_duration: float, sentences: table<text: string, start: int, end: int, confidence: float, words: list, channel: string, speaker: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transcript/($transcript_id)/sentences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get paragraphs in transcript
#
# GET /v2/transcript/{transcript_id}/paragraphs
# operationId: getTranscriptParagraphs
export def "transcript-paragraphs get" [
  transcript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, confidence: float, audio_duration: float, paragraphs: table<text: string, start: int, end: int, confidence: float, words: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transcript/($transcript_id)/paragraphs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search words in transcript
#
# GET /v2/transcript/{transcript_id}/word-search
# operationId: wordSearch
export def "transcript-word-search wordSearch" [
  transcript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --words: list # Keywords to search for
]: nothing -> record<id: string, total_count: int, matches: table<text: string, count: int, timestamps: list, indexes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "words" $words "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/transcript/($transcript_id)/word-search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get redacted audio
#
# GET /v2/transcript/{transcript_id}/redacted-audio
# operationId: getRedactedAudio
export def "transcript-redacted-audio get" [
  transcript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, redacted_audio_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/transcript/($transcript_id)/redacted-audio")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
