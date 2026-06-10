# Auto-generated client for DeepL API Documentation v3.10.0
# Source: https://raw.githubusercontent.com/DeepLcom/openapi/main/openapi.json
# Auth: --token flag or $env.DEEPL_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.deepl.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DEEPL_API_DOCUMENTATION_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.deepl.com" "https://api-free.deepl.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def group-by-completer [] { ["key" "key_and_day"] }
def aggregate-by-completer [] { ["day" "period"] }
def split-sentences-completer [] { ["0" "1" "nonewlines"] }
def formality-completer [] { ["default" "less" "more" "prefer_less" "prefer_more"] }
def model-type-completer [] { ["latency_optimized" "prefer_quality_optimized" "quality_optimized"] }
def tag-handling-completer [] { ["html" "xml"] }
def tag-handling-version-completer [] { ["v1" "v2"] }
def source-lang-completer [] { ["ar" "bg" "cs" "da" "de" "el" "en" "es" "et" "fi" "fr" "he" "hu" "id" "it" "ja" "ko" "lt" "lv" "nb" "nl" "pl" "pt" "ro" "ru" "sk" "sl" "sv" "th" "tr" "uk" "vi" "zh"] }
def target-lang-completer [] { ["ar" "bg" "cs" "da" "de" "el" "en" "es" "et" "fi" "fr" "he" "hu" "id" "it" "ja" "ko" "lt" "lv" "nb" "nl" "pl" "pt" "ro" "ru" "sk" "sl" "sv" "th" "tr" "uk" "vi" "zh"] }
def entries-format-completer [] { ["csv" "tsv"] }
def target-lang-completer-1 [] { ["de" "en" "en-GB" "en-US" "es" "fr" "it" "ja" "ko" "pt" "pt-BR" "pt-PT" "zh" "zh-Hans"] }
def writing-style-completer [] { ["academic" "business" "casual" "default" "prefer_academic" "prefer_business" "prefer_casual" "prefer_simple" "simple"] }
def tone-completer [] { ["confident" "default" "diplomatic" "enthusiastic" "friendly" "prefer_confident" "prefer_diplomatic" "prefer_enthusiastic" "prefer_friendly"] }
def type-completer [] { ["source" "target"] }
def resource-completer [] { ["glossary" "style_rules" "translate_document" "translate_text" "voice" "write"] }
def language-completer [] { ["de" "en" "es" "fr" "it" "ja" "ko" "zh"] }
def message-format-completer [] { ["json" "msgpack"] }
def source-media-content-type-completer [] { ["audio/auto" "audio/flac" "audio/mpeg" "audio/ogg" "audio/ogg;codecs=flac" "audio/ogg;codecs=opus" "audio/pcm;encoding=alaw;rate=8000" "audio/pcm;encoding=s16le;rate=16000" "audio/pcm;encoding=s16le;rate=44100" "audio/pcm;encoding=s16le;rate=48000" "audio/pcm;encoding=s16le;rate=8000" "audio/pcm;encoding=ulaw;rate=8000" "audio/webm" "audio/webm;codecs=opus" "audio/x-matroska" "audio/x-matroska;codecs=aac" "audio/x-matroska;codecs=flac" "audio/x-matroska;codecs=mp3" "audio/x-matroska;codecs=opus"] }
def source-language-completer [] { ["ar" "bg" "bn" "cs" "da" "de" "el" "en" "es" "et" "fi" "fr" "ga" "he" "hr" "hu" "id" "it" "ja" "ko" "lt" "lv" "mt" "nb" "nl" "pl" "pt" "ro" "ru" "sk" "sl" "sv" "th" "tl" "tr" "uk" "vi" "zh"] }
def source-language-mode-completer [] { ["auto" "fixed"] }
def target-media-content-type-completer [] { ["audio/flac" "audio/ogg" "audio/ogg;codecs=flac" "audio/ogg;codecs=opus" "audio/opus" "audio/pcm;encoding=alaw;rate=8000" "audio/pcm;encoding=s16le;rate=16000" "audio/pcm;encoding=s16le;rate=24000" "audio/pcm;encoding=ulaw;rate=8000" "audio/webm" "audio/webm;codecs=opus" "audio/x-matroska;codecs=aac" "audio/x-matroska;codecs=flac" "audio/x-matroska;codecs=opus" "video/mp2t;codecs=aac" "video/mp2t;codecs=opus"] }
def target-media-voice-completer [] { ["female" "male"] }
def formality-completer-1 [] { ["default" "formal" "informal" "less" "more"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-analytics adminGetAnalytics" } } | get name | first)
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

# Get usage statistics as an admin
#
# GET /v2/admin/analytics
# operationId: adminGetAnalytics
export def "admin-analytics adminGetAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for the usage report (ISO 8601 date format). (format: date, e.g. 2025-09-29)
  --end-date: string # End date for the usage report (ISO 8601 date format). (format: date, e.g. 2025-10-01)
  --group-by: string@group-by-completer # Optional parameter to group usage statistics. Possible values:  * `key` - Group by API key  * `key_and_day` - Group by API key and usage date (e.g. key_and_day)
]: nothing -> record<usage_report: record<total_usage: record<total_characters: int, text_translation_characters: int, document_translation_characters: int, text_improvement_characters: int, speech_to_text_minutes: float>, start_date: string, end_date: string, group_by: string, key_usages: list<record>, key_and_day_usages: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "group_by" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/admin/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get custom tag usage statistics as an admin
#
# GET /v2/admin/analytics/custom-tags
# operationId: adminGetCustomTagAnalytics
export def "admin-analytics-custom-tags adminGetCustomTagAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for the usage report (ISO 8601 date format). (format: date, e.g. 2026-05-17)
  --end-date: string # End date for the usage report (ISO 8601 date format). (format: date, e.g. 2026-05-18)
  --aggregate-by: string@aggregate-by-completer # Optional parameter to control aggregation of usage statistics. Possible values:  * `period` - Aggregate usage over the entire date range (default)  * `day` - Group usage by individual day (default: period, e.g. day)
  --page: int # Page number for pagination. Use the integer value returned in `next_page` from a previous response to retrieve the next page of results. (e.g. 2)
]: nothing -> record<custom_tag_usage_report: record<aggregate_by: string, start_date: string, end_date: string, next_page: int, usage: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "aggregate_by" $aggregate_by "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/admin/analytics/custom-tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a developer key as an admin
#
# POST /v2/admin/developer-keys
# operationId: adminCreateDeveloperKey
export def "admin-developer-keys adminCreateDeveloperKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --label: string # API key label. The default value is `DeepL API Key`. (e.g. developer key prod)
]: any -> record<key_id: string, label: string, creation_time: string, deactivated_time: string, is_deactivated: bool, usage_limits: record<characters: float, speech_to_text_milliseconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/admin/developer-keys")
  let body = {label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all developer keys as an admin
#
# GET /v2/admin/developer-keys
# operationId: adminGetDeveloperKeys
export def "admin-developer-keys adminGetDeveloperKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key_id: string, label: string, creation_time: string, deactivated_time: string, is_deactivated: bool, usage_limits: record<characters: float, speech_to_text_milliseconds: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/admin/developer-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate a developer key as an admin
#
# PUT /v2/admin/developer-keys/deactivate
# operationId: adminDeactivateDeveloperKey
export def "admin-developer-keys-deactivate adminDeactivateDeveloperKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key_id: string # API key ID. Consists of two valid GUIDs separated by a colon. (e.g. ca7d5694-96eb-4263-a9a4-7f7e4211529e:20c2abcf-4c3c-4cd6-8ae8-8bd2a7d4da38)
]: any -> record<key_id: string, label: string, creation_time: string, deactivated_time: string, is_deactivated: bool, usage_limits: record<characters: float, speech_to_text_milliseconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/admin/developer-keys/deactivate")
  let body = {key_id: $key_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename a developer key as an admin
#
# PUT /v2/admin/developer-keys/label
# operationId: adminRenameDeveloperKey
export def "admin-developer-keys-label adminRenameDeveloperKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key_id: string # API key ID. Consists of two valid GUIDs separated by a colon. (e.g. ca7d5694-96eb-4263-a9a4-7f7e4211529e:20c2abcf-4c3c-4cd6-8ae8-8bd2a7d4da38)
  label: string # API key label. (e.g. developer key prod)
]: any -> record<key_id: string, label: string, creation_time: string, deactivated_time: string, is_deactivated: bool, usage_limits: record<characters: float, speech_to_text_milliseconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/admin/developer-keys/label")
  let body = {key_id: $key_id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set developer key usage limits as an admin
#
# PUT /v2/admin/developer-keys/limits
# operationId: adminSetDeveloperKeyUsageLimits
export def "admin-developer-keys-limits adminSetDeveloperKeyUsageLimits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key_id: string # API key ID. Consists of two valid GUIDs separated by a colon. (e.g. ca7d5694-96eb-4263-a9a4-7f7e4211529e:20c2abcf-4c3c-4cd6-8ae8-8bd2a7d4da38)
  --characters: float # Restricts the number of total characters (across text translation, document translation, and text improvement) that can be consumed by an API key in a one-month usage period.  Setting the limit to `0` means the API key will not be able to consume characters. Setting the limit to `null` disables the limit, effectively allowing unlimited usage.  (e.g. 5000)
  --speech-to-text-milliseconds: float # Restricts the number of milliseconds of speech-to-text that can be consumed by an API key in a one-month usage period. Setting the limit to `0` means the API key will not be able to consume speech-to-text milliseconds. Setting the limit to `null` disables the limit, effectively allowing unlimited usage.  (e.g. 3600000)
]: any -> record<key_id: string, label: string, creation_time: string, deactivated_time: string, is_deactivated: bool, usage_limits: record<characters: float, speech_to_text_milliseconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/admin/developer-keys/limits")
  let body = {key_id: $key_id, characters: $characters, speech_to_text_milliseconds: $speech_to_text_milliseconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request Translation
#
# POST /v2/translate
# operationId: translateText
@deprecated --flag enable-beta-languages
export def "translate translateText" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: list # Text to be translated. Only UTF-8-encoded plain text is supported. The parameter may be specified many times in a single request, within the request size limit (128KiB). Translations are returned in the same order as they are requested. Each text in the array is translated independently — texts do not share context with each other.
  --source-lang: string # Language of the text to be translated. If this parameter is omitted, the API will attempt to detect the language of the text and translate it.  For the full list of supported source languages, see [supported languages](https://developers.deepl.com/docs/getting-started/supported-languages) or query the [`GET /v3/languages` endpoint](https://developers.deepl.com/api-reference/languages/retrieve-supported-languages-by-resource). (e.g. EN)
  target_lang: string # The language into which the text should be translated.  For the full list of supported target languages, see [supported languages](https://developers.deepl.com/docs/getting-started/supported-languages) or query the [`GET /v3/languages` endpoint](https://developers.deepl.com/api-reference/languages/retrieve-supported-languages-by-resource). (e.g. DE)
  --context: string # Additional context that can influence a translation but is not translated itself.  Characters included in the `context` parameter will not be counted toward billing. (e.g. This is context.)
  --show-billed-characters: string@bool-completer # When true, the response will include the billed_characters parameter, giving the number of characters from the request that will be counted by DeepL for billing purposes.
  --split-sentences: string@split-sentences-completer # Sets whether the translation engine should first split the input into sentences.  Possible values are:   * 0 - no splitting at all, whole input is treated as one sentence   * 1 (default when tag_handling is not set to html) - splits on punctuation and on newlines   * nonewlines (default when tag_handling=html) - splits on punctuation only, ignoring newlines (default: 1, e.g. 1)
  --preserve-formatting: string@bool-completer # Sets whether the translation engine should respect the original formatting, even if it would usually correct some aspects. (default: false)
  --formality: string@formality-completer # Sets whether the translated text should lean towards formal or informal language. This feature is only available for certain target languages. Setting this parameter with a target language that does not support formality will fail, unless one of the `prefer_...` options are used. Possible options are:   * `default` (default)   * `more` - for a more formal language   * `less` - for a more informal language   * `prefer_more` - for a more formal language if available, otherwise fallback to default formality   * `prefer_less` - for a more informal language if available, otherwise fallback to default formality (default: default, e.g. prefer_more)
  --model-type: string@model-type-completer # Specifies which DeepL model should be used for translation.
  --glossary-id: string # Specify the glossary to use for the translation. **Important:** This requires the `source_lang` parameter to be set. The language pair of the glossary has to match the language pair of the request. (e.g. def3a26b-3e84-45b3-84ae-0c0aaf3525f7)
  --style-id: string # Specify the [style rule list](/api-reference/style-rules) to use for the translation.  **Important:**  The target language has to match the language of the style rule list.  **Note:** Any request with the `style_id` parameter enabled will use `quality_optimized` models. Requests combining `style_id` and `model_type: latency_optimized` will be rejected. (e.g. 7ff9bfd6-cd85-4190-8503-d6215a321519)
  --translation-memory-id: string # A unique ID assigned to a translation memory.  **Note:** Requests with the `translation_memory_id` parameter must use the `quality_optimized` model type. Requests combining `translation_memory_id` and `model_type: latency_optimized` will be rejected. (format: uuid, e.g. a74d88fb-ed2a-4943-a664-a4512398b994)
  --translation-memory-threshold: int # The minimum matching percentage required for a translation memory segment to be applied (recommended to be 75% or higher). (default: 75, e.g. 75)
  --custom-instructions: list # Specify a list of instructions to customize the translation behavior. Up to 10 custom instructions can be specified, each with a maximum of 300 characters.  **Important:**  The target language must be `de`, `en`, `es`, `fr`, `it`, `ja`, `ko`, `zh` or any variants of these languages.  **Note:** Any request with the `custom_instructions` parameter enabled will default to use the `quality_optimized` model type. Requests combining `custom_instructions` and `model_type: latency_optimized` will be rejected.
  --tag-handling: string@tag-handling-completer # Sets which kind of tags should be handled. Options currently available:  * `xml`  * `html` (e.g. html)
  --tag-handling-version: string@tag-handling-version-completer # Sets which version of the tag handling algorithm should be used. Options currently available: * `v1`: Traditional algorithm (currently the default, will become deprecated in the future). * `v2`: Improved algorithm released in October 2025 (will become the default in the future).
  --outline-detection: string@bool-completer # Disable the automatic detection of XML structure by setting the `outline_detection` parameter to `false` and selecting the tags that should be considered structure tags. This will split sentences using the `splitting_tags` parameter. (default: true)
  --enable-beta-languages: string@bool-completer # This parameter is maintained for backward compatibility and has no effect. (DEPRECATED, default: false)
  --non-splitting-tags: list # Comma-separated list of XML tags which never split sentences.
  --splitting-tags: list # Comma-separated list of XML tags which always cause splits.
  --ignore-tags: list # Comma-separated list of XML tags that indicate text not to be translated.
]: any -> record<translations: table<detected_source_language: string, text: string, billed_characters: int, model_type_used: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/translate")
  let body = {text: $text, source_lang: $source_lang, target_lang: $target_lang, context: $context, show_billed_characters: $show_billed_characters, split_sentences: $split_sentences, preserve_formatting: $preserve_formatting, formality: $formality, model_type: $model_type, glossary_id: $glossary_id, style_id: $style_id, translation_memory_id: $translation_memory_id, translation_memory_threshold: $translation_memory_threshold, custom_instructions: $custom_instructions, tag_handling: $tag_handling, tag_handling_version: $tag_handling_version, outline_detection: $outline_detection, enable_beta_languages: $enable_beta_languages, non_splitting_tags: $non_splitting_tags, splitting_tags: $splitting_tags, ignore_tags: $ignore_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload and Translate a Document
#
# POST /v2/document
# operationId: translateDocument
@deprecated --flag enable-beta-languages
export def "document translateDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-lang: string # Language of the text to be translated. If this parameter is omitted, the API will attempt to detect the language of the text and translate it.  For the full list of supported source languages, see [supported languages](https://developers.deepl.com/docs/getting-started/supported-languages) or query the [`GET /v3/languages` endpoint](https://developers.deepl.com/api-reference/languages/retrieve-supported-languages-by-resource). (e.g. EN)
  target_lang: string # The language into which the text should be translated.  For the full list of supported target languages, see [supported languages](https://developers.deepl.com/docs/getting-started/supported-languages) or query the [`GET /v3/languages` endpoint](https://developers.deepl.com/api-reference/languages/retrieve-supported-languages-by-resource). (e.g. DE)
  file: string # The document file to be translated. The file name should be included in this part's content disposition. As an alternative, the filename parameter can be used. The following file types and extensions are supported:   * `docx` - Microsoft Word Document   * `pptx` - Microsoft PowerPoint Document   * `xlsx` - Microsoft Excel Document   * `pdf` - Portable Document Format   * `htm / html` - HTML Document   * `txt` - Plain Text Document   * `xlf / xliff` - XLIFF Document, version 2.1   * `srt` - SRT Document   * `jpeg` / `jpg` / `png` - Image (currently in beta) (format: binary)
  --filename: string # The name of the uploaded file. Can be used as an alternative to including the file name in the file part's content disposition.
  --output-format: string # File extension of desired format of translated file, for example: `docx`. If unspecified, by default the translated file will be in the same format as the input file.
  --formality: string@formality-completer # Sets whether the translated text should lean towards formal or informal language. This feature is only available for certain target languages. Setting this parameter with a target language that does not support formality will fail, unless one of the `prefer_...` options are used. Possible options are:   * `default` (default)   * `more` - for a more formal language   * `less` - for a more informal language   * `prefer_more` - for a more formal language if available, otherwise fallback to default formality   * `prefer_less` - for a more informal language if available, otherwise fallback to default formality (default: default, e.g. prefer_more)
  --glossary-id: string # A unique ID assigned to a glossary. (e.g. def3a26b-3e84-45b3-84ae-0c0aaf3525f7)
  --style-id: string # Specify the [style rule list](/api-reference/style-rules) to use for the translation.  **Important:** The target language has to match the language of the style rule list. (e.g. 7ff9bfd6-cd85-4190-8503-d6215a321519)
  --translation-memory-id: string # A unique ID assigned to a translation memory.  **Note:** Requests with the `translation_memory_id` parameter must use the `quality_optimized` model type. Requests combining `translation_memory_id` and `model_type: latency_optimized` will be rejected. (format: uuid, e.g. a74d88fb-ed2a-4943-a664-a4512398b994)
  --translation-memory-threshold: int # The minimum matching percentage required for a translation memory segment to be applied (recommended to be 75% or higher). (default: 75, e.g. 75)
  --enable-beta-languages: string@bool-completer # This parameter is maintained for backward compatibility and has no effect. (DEPRECATED, default: false)
]: any -> record<document_id: string, document_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/document")
  let body = {source_lang: $source_lang, target_lang: $target_lang, file: $file, filename: $filename, output_format: $output_format, formality: $formality, glossary_id: $glossary_id, style_id: $style_id, translation_memory_id: $translation_memory_id, translation_memory_threshold: $translation_memory_threshold, enable_beta_languages: $enable_beta_languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Check Document Status
#
# POST /v2/document/{document_id}
# operationId: getDocumentStatus
export def "document post" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  document_key: string # The document encryption key that was sent to the client when the document was uploaded to the API. (e.g. 0CB0054F1C132C1625B392EADDA41CB754A742822F6877173029A6C487E7F60A)
]: any -> record<document_id: string, status: string, seconds_remaining: int, billed_characters: int, error_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/document/($document_id)")
  let body = {document_key: $document_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download Translated Document
#
# POST /v2/document/{document_id}/result
# operationId: downloadDocument
export def "document-result downloadDocument" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  document_key: string # The document encryption key that was sent to the client when the document was uploaded to the API. (e.g. 0CB0054F1C132C1625B392EADDA41CB754A742822F6877173029A6C487E7F60A)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/document/($document_id)/result")
  let body = {document_key: $document_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Language Pairs Supported by Glossaries
#
# GET /v2/glossary-language-pairs
# DEPRECATED
# operationId: listGlossaryLanguages
@deprecated
export def "glossary-language-pairs listGlossaryLanguages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<supported_languages: table<source_lang: string, target_lang: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/glossary-language-pairs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Glossary
#
# POST /v3/glossaries
# operationId: createMultilingualGlossary
# --dictionaries item shape: {source_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", target_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", entries?: string, entries_format?: "tsv"|"csv"}
export def "glossaries createMultilingualGlossary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name to be associated with the glossary. (e.g. My Glossary)
  dictionaries: list # Dictionaries to populate the glossary with. — item shape: {source_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", target_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", entries?: string, entries_format?: "tsv"|"csv"}
]: any -> record<glossary_id: string, name: string, dictionaries: table<source_lang: string, target_lang: string, entries: string, entries_format: string>, creation_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/glossaries")
  let body = {name: $name, dictionaries: $dictionaries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all Glossaries
#
# GET /v3/glossaries
# operationId: listMultilingualGlossaries
export def "glossaries listMultilingualGlossaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<glossaries: table<glossary_id: string, name: string, dictionaries: list, creation_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/glossaries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Glossary Details
#
# GET /v3/glossaries/{glossary_id}
# operationId: getMultilingualGlossary
export def "glossaries get-by-glossary_id" [
  glossary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<glossary_id: string, name: string, dictionaries: table<source_lang: string, target_lang: string, entries: string, entries_format: string>, creation_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/glossaries/($glossary_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit glossary details
#
# PATCH /v3/glossaries/{glossary_id}
# operationId: patchMultilingualGlossary
# --dictionaries item shape: {source_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", target_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", entries?: string, entries_format?: "tsv"|"csv"}
export def "glossaries patch" [
  glossary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A unique ID assigned to a glossary. (e.g. def3a26b-3e84-45b3-84ae-0c0aaf3525f7)
  --dictionaries: list # Dictionaries to edit the glossary with. Currently only supports 0 or 1 dictionaries in the array. — item shape: {source_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", target_lang?: "ar"|"bg"|"cs"|"da"|"de"|"el"|"en"|"es"|"et"|"fi"|"fr"|"he"|"hu"|"id"|"it"|"ja"|"ko"|"lt"|"lv"|"nb"|"nl"|"pl"|"pt"|"ro"|"ru"|"sk"|"sl"|"sv"|"th"|"tr"|"uk"|"vi"|"zh", entries?: string, entries_format?: "tsv"|"csv"}
]: any -> record<glossary_id: string, name: string, dictionaries: table<source_lang: string, target_lang: string, entries: string, entries_format: string>, creation_time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/glossaries/($glossary_id)")
  let body = {name: $name, dictionaries: $dictionaries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Glossary
#
# DELETE /v3/glossaries/{glossary_id}
# operationId: deleteMultilingualGlossary
export def "glossaries delete-by-glossary_id" [
  glossary_id: string
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
  let full_url = (build-url $base $"/v3/glossaries/($glossary_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Glossary Entries
#
# GET /v3/glossaries/{glossary_id}/entries
# operationId: getMultilingualGlossaryEntries
export def "glossaries-entries get-by-glossary_id" [
  glossary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-lang: string
  --target-lang: string
]: nothing -> record<source_lang: string, target_lang: string, entries: string, entries_format: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_lang" $source_lang "scalar") (serialize-qp "target_lang" $target_lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/glossaries/($glossary_id)/entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the dictionary associated with the given language pair with the given glossary ID.
#
# DELETE /v3/glossaries/{glossary_id}/dictionaries
# operationId: deleteDictionary
export def "glossaries-dictionaries delete" [
  glossary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-lang: string
  --target-lang: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_lang" $source_lang "scalar") (serialize-qp "target_lang" $target_lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/glossaries/($glossary_id)/dictionaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replaces or creates a dictionary in the glossary with the specified entries.
#
# PUT /v3/glossaries/{glossary_id}/dictionaries
# operationId: replaceDictionary
export def "glossaries-dictionaries replaceDictionary" [
  glossary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-lang: string@source-lang-completer # The language in which the source texts in the glossary are specified. (e.g. en)
  --target-lang: string@target-lang-completer # The language in which the target texts in the glossary are specified. (e.g. de)
  --entries: string # The entries of the glossary. The entries have to be specified in the format provided by the `entries_format` parameter. (e.g. Hello	Guten Tag)
  --entries-format: string@entries-format-completer # The format in which the glossary entries are provided. Formats currently available: - `tsv` (default) - tab-separated values - `csv` - comma-separated values  See [Supported Glossary Formats](/api-reference/multilingual-glossaries#formats) for details about each format. (default: tsv, e.g. tsv)
]: any -> record<source_lang: string, target_lang: string, entry_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/glossaries/($glossary_id)/dictionaries")
  let body = {source_lang: $source_lang, target_lang: $target_lang, entries: $entries, entries_format: $entries_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Glossary
#
# POST /v2/glossaries
# operationId: createGlossary
export def "glossaries createGlossary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name to be associated with the glossary. (e.g. My Glossary)
  source_lang: string@source-lang-completer # The language in which the source texts in the glossary are specified. (e.g. en)
  target_lang: string@target-lang-completer # The language in which the target texts in the glossary are specified. (e.g. de)
  entries: string # The entries of the glossary. The entries have to be specified in the format provided by the `entries_format` parameter. (e.g. Hello	Guten Tag)
  entries_format: string@entries-format-completer # The format in which the glossary entries are provided. Formats currently available: - `tsv` (default) - tab-separated values - `csv` - comma-separated values  See [Supported Glossary Formats](/api-reference/multilingual-glossaries#formats) for details about each format. (default: tsv, e.g. tsv)
]: any -> record<glossary_id: string, name: string, ready: bool, source_lang: string, target_lang: string, creation_time: string, entry_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/glossaries")
  let body = {name: $name, source_lang: $source_lang, target_lang: $target_lang, entries: $entries, entries_format: $entries_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all Glossaries
#
# GET /v2/glossaries
# operationId: listGlossaries
export def "glossaries listGlossaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<glossaries: table<glossary_id: string, name: string, ready: bool, source_lang: string, target_lang: string, creation_time: string, entry_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/glossaries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Glossary Details
#
# GET /v2/glossaries/{glossary_id}
# operationId: getGlossary
export def "glossaries get-by-glossary_id-1" [
  glossary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<glossary_id: string, name: string, ready: bool, source_lang: string, target_lang: string, creation_time: string, entry_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/glossaries/($glossary_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Glossary
#
# DELETE /v2/glossaries/{glossary_id}
# operationId: deleteGlossary
export def "glossaries delete-by-glossary_id-1" [
  glossary_id: string
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
  let full_url = (build-url $base $"/v2/glossaries/($glossary_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Glossary Entries
#
# GET /v2/glossaries/{glossary_id}/entries
# operationId: getGlossaryEntries
export def "glossaries-entries get-by-glossary_id-1" [
  glossary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string # The requested format of the returned glossary entries. Currently, supports only `text/tab-separated-values`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/glossaries/($glossary_id)/entries")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/tab-separated-values"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Improve text
#
# POST /v2/write/rephrase
# operationId: rephraseText
export def "write-rephrase rephraseText" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: list # Text to be improved. Only UTF-8-encoded plain text is supported. Improvements are returned in the same order as they are requested.
  --target-lang: string@target-lang-completer-1 # The language for the text improvement. (e.g. de)
  --writing-style: string@writing-style-completer # Specify a style to rephrase your text in a way that fits your audience and goals. The `prefer_` prefix allows falling back to the default style if the language does not yet support styles.
  --tone: string@tone-completer # Specify the desired tone for your text. The `prefer_` prefix allows falling back to the default tone if the language does not yet support tones.
]: any -> record<improvements: table<detected_source_language: string, target_language: string, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/write/rephrase")
  let body = {text: $text, target_lang: $target_lang, writing_style: $writing_style, tone: $tone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Correct text
#
# POST /v2/write/correct
# operationId: correctText
export def "write-correct correctText" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  text: list # Text to be corrected. Only UTF-8-encoded plain text is supported. Corrections are returned in the same order as they are requested.
  --target-lang: string@target-lang-completer-1 # The language for the text improvement. (e.g. de)
]: any -> record<improvements: table<detected_source_language: string, target_language: string, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/write/correct")
  let body = {text: $text, target_lang: $target_lang} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check Usage and Limits
#
# GET /v2/usage
# operationId: getUsage
export def "usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<character_count: int, character_limit: int, products: table<product_type: string, billing_unit: string, api_key_unit_count: int, account_unit_count: int, api_key_character_count: int, character_count: int>, api_key_character_count: int, api_key_character_limit: int, speech_to_text_milliseconds_count: int, speech_to_text_milliseconds_limit: int, start_time: string, end_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Supported Languages
#
# GET /v2/languages
# DEPRECATED
# operationId: getLanguagesV2
@deprecated
export def "languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Supported values are "source" or "target". If type parameter is not included, defaults to "source". (default: source)
]: nothing -> table<language: string, name: string, supports_formality: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/languages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Language Resources
#
# GET /v3/languages/resources
# operationId: getLanguageResources
export def "languages-resources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, features: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/languages/resources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Languages
#
# GET /v3/languages
# operationId: getLanguages
export def "languages get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resource: string@resource-completer # The resource to retrieve languages for. Supported values: `translate_text`, `translate_document`, `glossary`, `voice`, `write`, `style_rules`. (e.g. translate_text)
  --include: list # Controls which languages and features are included in the response. By default, only stable languages and features are returned. Values can be combined with repeated parameters (e.g. `?include=beta&include=external`).  - `beta`: Include languages and features in beta, in addition to stable - `external`: Include features that rely on third-party service providers
]: nothing -> table<lang: string, name: string, usable_as_source: bool, usable_as_target: bool, status: string, features: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/languages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List translation memories
#
# GET /v3/translation_memories
# operationId: listTranslationMemories
export def "translation-memories listTranslationMemories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The index of the first page to return. Use with `page_size` to get the next page of translation memories. (default: 0)
  --page-size: int # The maximum number of translation memories to return. (default: 10)
]: nothing -> record<translation_memories: table<translation_memory_id: string, name: string, source_language: string, target_languages: list, segment_count: int>, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/translation_memories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve style rule lists
#
# GET /v3/style_rules
# operationId: getStyleRuleLists
export def "style-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The index of the first page to return. Use with `page_size` to get the next page of rule lists (default: 0)
  --page-size: int # The maximum number of style rule lists to return. (default: 10)
  --detailed: string@bool-completer # Determines if the rule list's `configured_rules` and `custom_instructions` should be included in the response body. (default: false)
]: nothing -> record<style_rules: table<style_id: string, name: string, creation_time: string, updated_time: string, language: string, version: int, configured_rules: record, custom_instructions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/style_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a style rule list
#
# POST /v3/style_rules
# operationId: createStyleRuleList
# --configured_rules shape: {dates_and_times?: record, formatting?: record, numbers?: record, punctuation?: record, spelling_and_grammar?: record, style_and_tone?: record, vocabulary?: record}
# --custom_instructions item shape: {label: string, prompt: string, source_language?: string}
export def "style-rules createStyleRuleList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name associated with the style rule list.
  language: string@language-completer # The language that the style rule list is applied to.
  --configured-rules: record # The enabled rules for the style rule list including what option was selected for each rule. This schema combines rules from all supported languages. (e.g. {style_and_tone: {abbreviations: use_abbreviations_and_symbols, short_vs_long_words: use_short_words}, punctuation: {apostrophe: use_curly_apostrophes}}) — shape: {dates_and_times?: record, formatting?: record, numbers?: record, punctuation?: record, spelling_and_grammar?: record, style_and_tone?: record, vocabulary?: record}
  --custom-instructions: list # Array of custom instruction objects — item shape: {label: string, prompt: string, source_language?: string}
]: any -> record<style_id: string, name: string, creation_time: string, updated_time: string, language: string, version: int, configured_rules: record<dates_and_times: record<calendar_era: string, centuries: string, date_format: string, dates_in_numerical_form: string, decades: string, hours_minutes_seconds_separator: string, hours_minutes_separator: string, midnight_in_numerals: string, single_digit_days_and_months: string, single_digit_hours: string, time_format: string, writing_dates: string, years: string>, formatting: record<email_address_format: string, phone_number_country_code_format: string, phone_number_format: string, space_between_arabic_numerals_and_unit: string, space_between_chinese_and_english: string, space_between_chinese_characters_and_arabic_numerals: string>, numbers: record<approximate_numbers: string, currency_format: string, decimal_numbers_less_than_one: string, decimal_separator: string, dimensions_separator: string, equation_formula_reference: string, kanji_numbers: string, large_number_format: string, large_sums_of_money: string, large_sums_of_money_format: string, list_of_measurements_with_units: string, mathematical_expression_spacing: string, number_format: string, number_separator: string, numbers_of_5_digits_or_more: string, numbers_up_to_4_digits: string, percentage_format: string, reference_to_symbol: string, spelling_out_units: string, temperature_format: string, thousands_separator: string, units_of_measure_spacing: string, use_of_hiragana_and_kanji: string, writing_numbers: string, zero_format: string>, punctuation: record<abbreviations: string, acronyms: string, ampersand_abbreviation_spacing: string, ampersand_usage: string, apostrophe: string, bracket: string, chinese_mixed_with_english: string, colon: string, colon_between_hours_and_minutes_or_chapters_and_verses: string, colon_in_heading: string, colon_to_replace_versus_or_to: string, comma_after_conjunctive_adverbs: string, comma_after_i_e_and_e_g: string, comma_after_short_introductory_phrase: string, comma_and_semicolon: string, corner_bracket_and_periods: string, corner_brackets_and_periods: string, dash: string, ellipsis: string, em_dash: string, emphasis: string, exclamation_marks: string, explanatory_note_indicator: string, full_sentence_in_round_brackets: string, highlighting_specific_expressions: string, japanese_reference_materials: string, parentheses_for_supplementary_information: string, passage_of_time_and_movement_between_locations: string, periods_and_commas: string, periods_in_academic_degrees: string, periods_in_direct_quotes: string, periods_in_uppercase_initialisms_and_acronyms: string, plus_sign_usage: string, possessives_of_proper_names_ending_in_s_style: string, quotation_mark: string, quotation_mark_and_apostrophe: string, quotation_style: string, range_indicator: string, related_phrases_indicator: string, round_brackets: string, salutation: string, sentence_break_indicator: string, serial_comma: string, setting_off_non_quoted_phrases: string, slash: string, slash_usage: string, spacing_and_punctuation: string, text_in_round_brackets_referring_to_previous_sentence: string, text_in_round_brackets_supplementing_preceding_text: string, titles_of_books_and_newspapers: string, titles_of_creative_works_trade_names_laws_and_regulations: string, uppercase_acronyms: string>, spelling_and_grammar: record<abbreviating_french_word_numero: string, abbreviation_usage: string, accents_and_cedillas: string, accents_in_verbs_conjugated_like_french_word_c_der: string, accents_with_subject_verb_inversion: string, active_passive_voice: string, all_caps: string, complete_sentences: string, compound_nouns: string, conjunctions: string, contractions: string, established_loanwords: string, eszett: string, foreign_word_translation: string, french_verbs_ending_in_eler_and_eter: string, i_and_u_with_circumflex_accents: string, informal_address_pronouns: string, latin_abbreviations: string, passive_voice: string, past_participle_of_french_word_laisser_followed_by_infinitive: string, personal_titles: string, pluralizing_foreign_words: string, quotation_modification: string, spanish_word_solo: string, special_characters: string, spelled_out_numbers: string, umlauts: string, unestablished_loanwords: string>, style_and_tone: record<abbreviations: string, addressing_non_binary_people: string, addressing_the_reader: string, anglicisms: string, binary_representation_of_gender: string, complex_sentences: string, country_names: string, declarative_endings: string, default_first_person_pronoun: string, default_second_person_pronoun: string, directional_language: string, double_negatives: string, formality: string, gender_neutral_language_readability: string, gender_unspecified: string, gender_unspecified_or_mixed: string, idioms_colloquialisms_and_culture_specific_references: string, inflected_words_masculine_noun_agreement: string, instructions_style: string, mixing_styles: string, modal_verbs: string, personal_vs_impersonal_style: string, positive_vs_negative_language: string, proximity_agreement: string, reader_action_required: string, redundant_introductory_phrases: string, redundant_phrases: string, referring_to_non_binary_people: string, short_vs_long_words: string, simple_words_and_sentences: string, text_position_references: string, tone: string, verbal_vs_nominal_style: string>, vocabulary: record<abbreviations: string, loanwords: string>>, custom_instructions: table<id: string, label: string, prompt: string, source_language: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/style_rules")
  let body = {name: $name, language: $language, configured_rules: $configured_rules, custom_instructions: $custom_instructions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a style rule list
#
# GET /v3/style_rules/{style_id}
# operationId: getStyleRuleList
export def "style-rules get" [
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<style_id: string, name: string, creation_time: string, updated_time: string, language: string, version: int, configured_rules: record<dates_and_times: record<calendar_era: string, centuries: string, date_format: string, dates_in_numerical_form: string, decades: string, hours_minutes_seconds_separator: string, hours_minutes_separator: string, midnight_in_numerals: string, single_digit_days_and_months: string, single_digit_hours: string, time_format: string, writing_dates: string, years: string>, formatting: record<email_address_format: string, phone_number_country_code_format: string, phone_number_format: string, space_between_arabic_numerals_and_unit: string, space_between_chinese_and_english: string, space_between_chinese_characters_and_arabic_numerals: string>, numbers: record<approximate_numbers: string, currency_format: string, decimal_numbers_less_than_one: string, decimal_separator: string, dimensions_separator: string, equation_formula_reference: string, kanji_numbers: string, large_number_format: string, large_sums_of_money: string, large_sums_of_money_format: string, list_of_measurements_with_units: string, mathematical_expression_spacing: string, number_format: string, number_separator: string, numbers_of_5_digits_or_more: string, numbers_up_to_4_digits: string, percentage_format: string, reference_to_symbol: string, spelling_out_units: string, temperature_format: string, thousands_separator: string, units_of_measure_spacing: string, use_of_hiragana_and_kanji: string, writing_numbers: string, zero_format: string>, punctuation: record<abbreviations: string, acronyms: string, ampersand_abbreviation_spacing: string, ampersand_usage: string, apostrophe: string, bracket: string, chinese_mixed_with_english: string, colon: string, colon_between_hours_and_minutes_or_chapters_and_verses: string, colon_in_heading: string, colon_to_replace_versus_or_to: string, comma_after_conjunctive_adverbs: string, comma_after_i_e_and_e_g: string, comma_after_short_introductory_phrase: string, comma_and_semicolon: string, corner_bracket_and_periods: string, corner_brackets_and_periods: string, dash: string, ellipsis: string, em_dash: string, emphasis: string, exclamation_marks: string, explanatory_note_indicator: string, full_sentence_in_round_brackets: string, highlighting_specific_expressions: string, japanese_reference_materials: string, parentheses_for_supplementary_information: string, passage_of_time_and_movement_between_locations: string, periods_and_commas: string, periods_in_academic_degrees: string, periods_in_direct_quotes: string, periods_in_uppercase_initialisms_and_acronyms: string, plus_sign_usage: string, possessives_of_proper_names_ending_in_s_style: string, quotation_mark: string, quotation_mark_and_apostrophe: string, quotation_style: string, range_indicator: string, related_phrases_indicator: string, round_brackets: string, salutation: string, sentence_break_indicator: string, serial_comma: string, setting_off_non_quoted_phrases: string, slash: string, slash_usage: string, spacing_and_punctuation: string, text_in_round_brackets_referring_to_previous_sentence: string, text_in_round_brackets_supplementing_preceding_text: string, titles_of_books_and_newspapers: string, titles_of_creative_works_trade_names_laws_and_regulations: string, uppercase_acronyms: string>, spelling_and_grammar: record<abbreviating_french_word_numero: string, abbreviation_usage: string, accents_and_cedillas: string, accents_in_verbs_conjugated_like_french_word_c_der: string, accents_with_subject_verb_inversion: string, active_passive_voice: string, all_caps: string, complete_sentences: string, compound_nouns: string, conjunctions: string, contractions: string, established_loanwords: string, eszett: string, foreign_word_translation: string, french_verbs_ending_in_eler_and_eter: string, i_and_u_with_circumflex_accents: string, informal_address_pronouns: string, latin_abbreviations: string, passive_voice: string, past_participle_of_french_word_laisser_followed_by_infinitive: string, personal_titles: string, pluralizing_foreign_words: string, quotation_modification: string, spanish_word_solo: string, special_characters: string, spelled_out_numbers: string, umlauts: string, unestablished_loanwords: string>, style_and_tone: record<abbreviations: string, addressing_non_binary_people: string, addressing_the_reader: string, anglicisms: string, binary_representation_of_gender: string, complex_sentences: string, country_names: string, declarative_endings: string, default_first_person_pronoun: string, default_second_person_pronoun: string, directional_language: string, double_negatives: string, formality: string, gender_neutral_language_readability: string, gender_unspecified: string, gender_unspecified_or_mixed: string, idioms_colloquialisms_and_culture_specific_references: string, inflected_words_masculine_noun_agreement: string, instructions_style: string, mixing_styles: string, modal_verbs: string, personal_vs_impersonal_style: string, positive_vs_negative_language: string, proximity_agreement: string, reader_action_required: string, redundant_introductory_phrases: string, redundant_phrases: string, referring_to_non_binary_people: string, short_vs_long_words: string, simple_words_and_sentences: string, text_position_references: string, tone: string, verbal_vs_nominal_style: string>, vocabulary: record<abbreviations: string, loanwords: string>>, custom_instructions: table<id: string, label: string, prompt: string, source_language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/style_rules/($style_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a style rule list's name
#
# PATCH /v3/style_rules/{style_id}
# operationId: updateStyleRuleList
export def "style-rules updateStyleRuleList" [
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name associated with the style rule list.
]: any -> record<style_id: string, name: string, creation_time: string, updated_time: string, language: string, version: int, configured_rules: record<dates_and_times: record<calendar_era: string, centuries: string, date_format: string, dates_in_numerical_form: string, decades: string, hours_minutes_seconds_separator: string, hours_minutes_separator: string, midnight_in_numerals: string, single_digit_days_and_months: string, single_digit_hours: string, time_format: string, writing_dates: string, years: string>, formatting: record<email_address_format: string, phone_number_country_code_format: string, phone_number_format: string, space_between_arabic_numerals_and_unit: string, space_between_chinese_and_english: string, space_between_chinese_characters_and_arabic_numerals: string>, numbers: record<approximate_numbers: string, currency_format: string, decimal_numbers_less_than_one: string, decimal_separator: string, dimensions_separator: string, equation_formula_reference: string, kanji_numbers: string, large_number_format: string, large_sums_of_money: string, large_sums_of_money_format: string, list_of_measurements_with_units: string, mathematical_expression_spacing: string, number_format: string, number_separator: string, numbers_of_5_digits_or_more: string, numbers_up_to_4_digits: string, percentage_format: string, reference_to_symbol: string, spelling_out_units: string, temperature_format: string, thousands_separator: string, units_of_measure_spacing: string, use_of_hiragana_and_kanji: string, writing_numbers: string, zero_format: string>, punctuation: record<abbreviations: string, acronyms: string, ampersand_abbreviation_spacing: string, ampersand_usage: string, apostrophe: string, bracket: string, chinese_mixed_with_english: string, colon: string, colon_between_hours_and_minutes_or_chapters_and_verses: string, colon_in_heading: string, colon_to_replace_versus_or_to: string, comma_after_conjunctive_adverbs: string, comma_after_i_e_and_e_g: string, comma_after_short_introductory_phrase: string, comma_and_semicolon: string, corner_bracket_and_periods: string, corner_brackets_and_periods: string, dash: string, ellipsis: string, em_dash: string, emphasis: string, exclamation_marks: string, explanatory_note_indicator: string, full_sentence_in_round_brackets: string, highlighting_specific_expressions: string, japanese_reference_materials: string, parentheses_for_supplementary_information: string, passage_of_time_and_movement_between_locations: string, periods_and_commas: string, periods_in_academic_degrees: string, periods_in_direct_quotes: string, periods_in_uppercase_initialisms_and_acronyms: string, plus_sign_usage: string, possessives_of_proper_names_ending_in_s_style: string, quotation_mark: string, quotation_mark_and_apostrophe: string, quotation_style: string, range_indicator: string, related_phrases_indicator: string, round_brackets: string, salutation: string, sentence_break_indicator: string, serial_comma: string, setting_off_non_quoted_phrases: string, slash: string, slash_usage: string, spacing_and_punctuation: string, text_in_round_brackets_referring_to_previous_sentence: string, text_in_round_brackets_supplementing_preceding_text: string, titles_of_books_and_newspapers: string, titles_of_creative_works_trade_names_laws_and_regulations: string, uppercase_acronyms: string>, spelling_and_grammar: record<abbreviating_french_word_numero: string, abbreviation_usage: string, accents_and_cedillas: string, accents_in_verbs_conjugated_like_french_word_c_der: string, accents_with_subject_verb_inversion: string, active_passive_voice: string, all_caps: string, complete_sentences: string, compound_nouns: string, conjunctions: string, contractions: string, established_loanwords: string, eszett: string, foreign_word_translation: string, french_verbs_ending_in_eler_and_eter: string, i_and_u_with_circumflex_accents: string, informal_address_pronouns: string, latin_abbreviations: string, passive_voice: string, past_participle_of_french_word_laisser_followed_by_infinitive: string, personal_titles: string, pluralizing_foreign_words: string, quotation_modification: string, spanish_word_solo: string, special_characters: string, spelled_out_numbers: string, umlauts: string, unestablished_loanwords: string>, style_and_tone: record<abbreviations: string, addressing_non_binary_people: string, addressing_the_reader: string, anglicisms: string, binary_representation_of_gender: string, complex_sentences: string, country_names: string, declarative_endings: string, default_first_person_pronoun: string, default_second_person_pronoun: string, directional_language: string, double_negatives: string, formality: string, gender_neutral_language_readability: string, gender_unspecified: string, gender_unspecified_or_mixed: string, idioms_colloquialisms_and_culture_specific_references: string, inflected_words_masculine_noun_agreement: string, instructions_style: string, mixing_styles: string, modal_verbs: string, personal_vs_impersonal_style: string, positive_vs_negative_language: string, proximity_agreement: string, reader_action_required: string, redundant_introductory_phrases: string, redundant_phrases: string, referring_to_non_binary_people: string, short_vs_long_words: string, simple_words_and_sentences: string, text_position_references: string, tone: string, verbal_vs_nominal_style: string>, vocabulary: record<abbreviations: string, loanwords: string>>, custom_instructions: table<id: string, label: string, prompt: string, source_language: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/style_rules/($style_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a style rule list
#
# DELETE /v3/style_rules/{style_id}
# operationId: deleteStyleRuleList
export def "style-rules delete" [
  style_id: string
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
  let full_url = (build-url $base $"/v3/style_rules/($style_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace configured rules for a style rule list
#
# PUT /v3/style_rules/{style_id}/configured_rules
# operationId: updateStyleRuleConfiguredRules
# --dates_and_times shape: {calendar_era?: "use_bc_and_ad"|"use_bce_and_ce", centuries?: "spell_out"|"use_arabic_numerals"|"use_numerals"|"use_roman_numerals", date_format?: "use_dd_period_mm_period_yy_with_leading_zeros_for_single_digit_days_and_months"|"use_dd_period_mm_period_yyyy"|"use_dd_period_mm_period_yyyy_with_leading_zeros_for_single_digit_days_and_months"|"use_dd_period_space_abbreviated_month_yyyy_with_abbreviations_jan_period_feb_period_mrz_period_apr_period_mai_jun_period_jul_period_aug_period_sep_period_okt_period_nov_period_dez_period_without_leading_zeros_for_single_digit_days"|"use_dd_period_space_abbreviated_month_yyyy_with_abbreviations_jan_period_febr_period_maerz_apr_period_mai_juni_juli_aug_period_sept_period_okt_period_nov_period_dez_period_without_leading_zeros_for_single_digit_days"|"use_dd_period_space_month_yyyy_without_leading_zeros_for_single_digit_days"|"use_dd_slash_mm_slash_yyyy"|"use_dd_slash_mm_slash_yyyy_with_leading_zeros_for_single_digit_days_and_months"|"use_dd_space_spelled_out_month_space_yyyy"|"use_dd_space_spelled_out_month_space_yyyy_and_use_spanish_word_septiembre_for_ninth_month"|"use_dd_space_spelled_out_month_space_yyyy_and_use_spanish_word_setiembre_for_ninth_month"|"use_dd_space_spelled_out_month_space_yyyy_without_leading_zeros_for_single_digit_days"|"use_historical_eras_and_write_numbers_in_chinese_followed_by_chinese_word_公元前_or_公元后_with_arabic_numerals_in_parentheses"|"use_mm_slash_dd_slash_yyyy_with_leading_zeros_for_single_digit_days_and_months"|"use_numerals_only_with_leading_zero_for_single_digits"|"use_numerals_only_without_leading_zero_for_single_digits"|"use_spelled_out_month_space_dd_comma_space_yyyy_and_use_spanish_word_septiembre_for_ninth_month"|"use_spelled_out_month_space_dd_comma_space_yyyy_without_leading_zeros_for_single_digit_days"|"use_traditional_calendar_system_with_chinese_numbers"|"use_yyyy_chinese_word_年_mm_chinese_word_月_dd_chinese_word_日_with_chinese_numbers"|"use_yyyy_chinese_word_年_mm_chinese_word_月_dd_chinese_word_日_without_leading_zero_for_single_digit_months_and_days"|"use_yyyy_hyphen_mm_hyphen_dd_with_leading_zero_for_single_digit_days_and_months"|"use_yyyy_hyphen_mm_hyphen_dd_with_leading_zeros_for_single_digit_days_and_months"|"use_yyyy_korean word_년_space_mm_korean word_월_space_dd_korean word_일_without_leading_zero_for_single_digit_days_and_months"|"use_yyyy_period_mm_period_dd"|"use_yyyy_period_space_mm_period_space_dd_period_space_without_leading_zero_for_single_digit_days_and_months"|"use_yyyy_slash_mm_slash_dd"|"use_yyyy_slash_mm_slash_dd_with_leading_zero_for_single_digit_days_and_months", dates_in_numerical_form?: "use_dd_hyphen_mm_hyphen_yyyy"|"use_dd_period_mm_period_yyyy"|"use_dd_slash_mm_slash_yyyy", decades?: "spell_out"|"use_apostrophe_yy"|"use_yy_for_20th_century_but_yyyy_for_other_centuries"|"use_yy_without_apostrophe"|"use_yyyy", hours_minutes_seconds_separator?: "use_colon"|"use_period", hours_minutes_separator?: "use_colon_without_spaces"|"use_letter_h_with_regular_space_on_either_side"|"use_letter_h_without_spaces", midnight_in_numerals?: "use_00_00"|"use_24_00", single_digit_days_and_months?: "do_not_use_leading_zero"|"use_leading_zero", single_digit_hours?: "do_not_use_leading_zero"|"use_leading_zero", time_format?: "spell_out_time_in_words"|"use_12_hour_clock_and_do_not_specify_morning_or_evening"|"use_12_hour_clock_and_lowercase_am_or_pm_with_periods"|"use_12_hour_clock_and_lowercase_am_or_pm_with_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_lowercase_am_or_pm_without_periods"|"use_12_hour_clock_and_lowercase_am_or_pm_without_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_specify_morning_or_evening"|"use_12_hour_clock_and_uppercase_am_or_pm_with_periods"|"use_12_hour_clock_and_uppercase_am_or_pm_with_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_uppercase_am_or_pm_without_periods"|"use_12_hour_clock_and_uppercase_am_or_pm_without_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_arabic_numerals"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_arabic_numerals_with_chinese_word_点_for_hours"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_arabic_numerals_with_chinese_words_时_and_分_for_hours_and_minutes"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_chinese_numbers_with_chinese_words_时_and_分_for_hours_and_minutes"|"use_12_hour_clock_with_arabic_numerals_and_colon"|"use_12_hour_clock_with_korean_words_시_and_분"|"use_12_hour_clock_without_leading_zero_or_minutes_for_full_hours_use_colon_as_separator_and_lowercase_am_or_pm_without_periods"|"use_12_hour_clock_without_leading_zero_or_minutes_for_full_hours_use_colon_as_separator_and_uppercase_am_or_pm_without_periods"|"use_12_hour_clock_without_leading_zero_use_period_as_separator_and_lowercase_am_or_pm_with_periods_and_spaces"|"use_24_hour_clock"|"use_24_hour_clock_with_arabic_numerals_and_colon"|"use_24_hour_clock_with_colon_as_separator"|"use_24_hour_clock_with_korean_words_시_and_분"|"use_24_hour_clock_with_period_as_separator"|"use_hh_colon_mm_german_word_uhr_with_leading_zeros_for_single_digit_hours"|"use_hh_colon_mm_german_word_uhr_without_leading_zeros_for_single_digit_hours"|"use_hh_period_mm_german_word_uhr_with_leading_zeros_for_single_digit_hours"|"use_hh_period_mm_german_word_uhr_without_leading_zeros_for_single_digit_hours"|"use_hh_period_mm_german_word_uhr_without_leading_zeros_for_single_digit_hours_and_for_full_hours_state_hour_only", writing_dates?: "use_dd_space_spelled_out_month_space_yyyy"|"use_numerals", years?: "use_apostrophe_yy"|"use_common_era"|"use_japanese_imperial_era"|"use_yyyy"}
# --formatting shape: {email_address_format?: "place_domain_in_parentheses"|"replace_at_symbol_with_english_word_at_in_brackets_and_replace_periods_with_english_word_dot_in_brackets"|"replace_at_symbol_with_english_word_at_in_brackets_with_space_on_either_side"|"replace_at_symbol_with_english_word_at_in_parentheses_with_space_on_either_side"|"replace_at_symbol_with_english_word_at_with_space_on_either_side"|"use_standard_format", phone_number_country_code_format?: "use_00_before_country_code"|"use_plus_sign_before_country_code", phone_number_format?: "do_not_use_spaces"|"do_not_use_spaces_or_special_characters_between_digits_of_phone_number"|"keep_original_format"|"place_area_code_in_parentheses_followed_by_space"|"separate_area_code_and_phone_number_with_slash"|"separate_area_code_and_phone_number_with_space"|"separate_country_code_area_code_local_prefix_and_last_four_digits_with_hyphens"|"separate_country_code_area_code_local_prefix_and_last_four_digits_with_periods"|"separate_country_code_area_code_local_prefix_and_last_four_digits_with_spaces"|"use_north_american_numbering_plan_format"|"use_space_after_country_code", space_between_arabic_numerals_and_unit?: "do_not_use", space_between_chinese_and_english?: "do_not_use", space_between_chinese_characters_and_arabic_numerals?: "do_not_use"}
# --numbers shape: {approximate_numbers?: "use_kanji_numbers", currency_format?: "spell_out"|"spell_out_currency_name_followed_by_amount_in_arabic_numerals_without_space"|"spell_out_currency_name_followed_by_amount_in_chinese"|"use_amount_followed_by_currency_symbol_without_space"|"use_amount_followed_by_space_then_currency_symbol"|"use_amount_followed_by_space_then_iso_code"|"use_amount_followed_by_space_then_spell_out_currency_name"|"use_amount_followed_by_space_then_spell_out_currency_name_in_lowercase"|"use_amount_followed_by_spelled_out_currency_name_in_japanese_without_space"|"use_amount_followed_by_spelled_out_currency_name_without_space"|"use_currency_symbol_but_spell_out_if_no_symbol_exists"|"use_currency_symbol_but_use_iso_code_if_no_symbol_exists"|"use_currency_symbol_followed_by_amount_in_arabic_numerals_without_space"|"use_currency_symbol_followed_by_amount_without_space"|"use_currency_symbol_followed_by_space_then_amount"|"use_currency_symbol_followed_by_space_then_amount_in_arabic_numerals"|"use_full_width_currency_symbol_followed_by_amount_without_space"|"use_half_width_currency_symbol_followed_by_amount_without_space"|"use_half_width_currency_symbol_followed_by_space_then_amount"|"use_iso_code"|"use_iso_code_followed_by_space_then_amount"|"use_iso_code_followed_by_space_then_amount_in_arabic_numerals", decimal_numbers_less_than_one?: "always_use_0_before_decimal_separator", decimal_separator?: "use_comma_and_do_not_use_thousands_separator"|"use_comma_as_decimal_separator"|"use_comma_do_not_use_thousands_separator_and_use_period_only_for_radio_stations"|"use_period_and_do_not_use_thousands_separator"|"use_period_as_decimal_separator", dimensions_separator?: "use_multiplication_sign_between_dimensions_with_space_on_either_side"|"use_multiplication_sign_between_dimensions_without_space_on_either_side"|"use_x_between_dimensions_with_space_on_either_side"|"use_x_between_dimensions_without_space_on_either_side", equation_formula_reference?: "always_use_arabic_numerals_to_number_equations_or_formulas_referenced_in_text", kanji_numbers?: "use_kanji_numbers_for_numbers_in_phrases_and_counting_method_based_on_native_japanese_readings", large_number_format?: "always_use_arabic_numerals"|"spell_out_large_numbers"|"use_abbreviations_for_large_numbers"|"use_chinese_characters_for_ten_thousands_and_hundred_millions"|"use_comma_to_separate_large_numbers_into_units_of_three_except_for_calendar_years"|"use_kanji_for_trillions_hundred_millions_and_ten_thousands"|"use_korean_words_만_억_조_with_space"|"use_korean_words_만_억_조_without_space", large_sums_of_money?: "spell_out_italian_words_milione_and_miliardo"|"use_italian_words_mio_and_mrd_instead_of_italian_words_milione_and_miliardo", large_sums_of_money_format?: "use_amount_followed_by_abbreviation_for_million_or_billion_without_space"|"use_amount_followed_by_space_then_abbreviation_for_million_or_billion"|"use_amount_followed_by_space_then_english_word_million_or_billion", list_of_measurements_with_units?: "repeat_unit_for_each_measurement_in_list", mathematical_expression_spacing?: "use_space_between_elements_of_mathematical_expression_or_equation", number_format?: "use_half_width_comma_to_separate_large_numbers_into_units_of_three_except_for_calendar_years_and_use_half_width_period_as_decimal_separator", number_separator?: "do_not_use_chinese_comma_to_separate_numbers_indicating_approximate_value"|"use_chinese_comma_to_separate_numbers_in_abbreviations", numbers_of_5_digits_or_more?: "use_comma_as_decimal_separator_and_period_as_thousands_separator"|"use_comma_as_decimal_separator_and_space_as_thousands_separator"|"use_comma_as_decimal_separator_period_as_thousands_separator_and_period_for_radio_stations"|"use_comma_as_decimal_separator_space_as_thousands_separator_and_period_for_radio_stations"|"use_period_as_decimal_separator_and_comma_as_thousands_separator"|"use_period_as_decimal_separator_and_space_as_thousands_separator", numbers_up_to_4_digits?: "use_comma_as_decimal_separator_and_period_as_thousands_separator"|"use_comma_as_decimal_separator_and_space_as_thousands_separator"|"use_comma_as_decimal_separator_period_as_thousands_separator_and_period_for_radio_stations"|"use_comma_as_decimal_separator_space_as_thousands_separator_and_period_for_radio_stations"|"use_period_as_decimal_separator_and_comma_as_thousands_separator"|"use_period_as_decimal_separator_and_space_as_thousands_separator", percentage_format?: "use_arabic_numerals_followed_by_percent_symbol_without_space"|"use_chinese_numbers_followed_by_chinese_word_百分之"|"use_numerals_followed_by_full_width_percent_symbol_without_space"|"use_numerals_followed_by_japanese_word_パーセント_without_space"|"use_numerals_followed_by_korean_word_퍼센트"|"use_numerals_followed_by_percent_symbol"|"use_numerals_followed_by_space_then_german_word_prozent"|"use_numerals_followed_by_space_then_half_width_percent_symbol"|"use_numerals_followed_by_space_then_italian_word_per_cento"|"use_numerals_followed_by_space_then_italian_word_percento"|"use_numerals_followed_by_space_then_korean_word_퍼센트"|"use_numerals_followed_by_space_then_percent_symbol"|"use_numerals_followed_by_space_then_spell_out_per_cent"|"use_numerals_followed_by_space_then_spell_out_percent"|"use_spanish_word_por_cien"|"use_spanish_word_por_ciento", reference_to_symbol?: "spell_out_symbol_name_followed_by_symbol_in_parentheses", spelling_out_units?: "abbreviate_units_of_measure_when_used_with_numeral_but_spell_out_when_used_without_numeral"|"always_abbreviate_units_of_measure"|"always_spell_out_units_of_measure"|"spell_out_units_in_korean"|"spell_out_units_of_measure_when_used_with_spelled_out_numbers_but_abbreviate_when_used_with_numeral"|"spell_out_units_of_measure_with_katakana_or_katakana_and_kanji"|"use_si_symbols"|"use_unit_symbols", temperature_format?: "spell_out_unit"|"spell_out_unit_followed_by_numerals_then_korean_word_도"|"use_arabic_numerals_followed_by_space_then_spell_out_unit"|"use_arabic_numerals_followed_by_unit_symbol_without_space"|"use_arabic_numerals_then_spell_out_unit"|"use_chinese_numbers_then_spell_out_unit"|"use_italian_word_grado_and_do_not_specify_temperature_scale"|"use_numerals_followed_by_japanese_word_度_without_space"|"use_numerals_followed_by_korean_word_도"|"use_numerals_followed_by_space_then_spell_out_unit"|"use_numerals_followed_by_space_then_unit_symbol"|"use_numerals_followed_by_unit_symbol_without_space"|"use_spanish_word_grado_and_do_not_specify_temperature_scale", thousands_separator?: "do_not_use"|"do_not_use_thousands_separator"|"use_comma"|"use_comma_to_separate_large_numbers_into_units_of_three"|"use_period"|"use_period_as_thousands_separator"|"use_space"|"use_space_as_thousands_separator"|"use_space_to_separate_large_numbers_into_units_of_three"|"use_straight_apostrophe_as_thousands_separator", units_of_measure_spacing?: "do_not_use_space_between_numeral_and_unit_of_measure"|"use_space_between_numeral_and_unit_of_measure", use_of_hiragana_and_kanji?: "use_hiragana_japanese_word_か所_or_か月_when_using_arabic_numerals_in_horizontal_writing_but_use_kanji_japanese_word_箇所_or_箇月_when_using_kanji_numbers", writing_numbers?: "always_use_kanji_numbers"|"use_arabic_numerals"|"use_full_width_arabic_numerals_and_only_use_kanji_numbers_where_it_would_otherwise_sound_unnatural"|"use_half_width_arabic_numerals_and_only_use_kanji_numbers_where_it_would_otherwise_sound_unnatural", zero_format?: "use_chinese_word_〇_for_numbering"|"use_chinese_word_零_for_measurement"}
# --punctuation shape: {abbreviations?: "do_not_separate_abbreviated_words"|"separate_each_abbreviated_word_with_period_and_space"|"separate_each_abbreviated_word_with_period_without_space"|"separate_each_abbreviated_word_with_space_without_period", acronyms?: "do_not_use_periods", ampersand_abbreviation_spacing?: "do_not_use_spaces_before_and_after_ampersand_as_part_of_abbreviation"|"use_spaces_before_and_after_ampersand_as_part_of_abbreviation", ampersand_usage?: "use_english_word_and_except_in_company_names_common_abbreviations_titles_software_code_and_mathematical_equations"|"use_full_width_ampersand"|"use_german_word_und_except_in_company_names_common_abbreviations_titles_software_code_and_mathematical_equations"|"use_half_width_ampersand", apostrophe?: "use_curly_apostrophes"|"use_straight_apostrophes", bracket?: "use_hexagonal_brackets"|"use_lenticular_brackets"|"use_parentheses"|"use_square_brackets_for_nationality_and_hexagonal_brackets_for_historical_period", chinese_mixed_with_english?: "do_not_place_english_in_quotation_marks"|"place_english_in_quotation_marks", colon?: "use_full_width_colon"|"use_half_width_colon", colon_between_hours_and_minutes_or_chapters_and_verses?: "do_not_use_space_before_or_after_colon", colon_in_heading?: "use_space_after_colon_not_before", colon_to_replace_versus_or_to?: "do_not_use_space_before_or_after_colon", comma_after_conjunctive_adverbs?: "do_not_use"|"use", comma_after_i_e_and_e_g?: "do_not_use"|"use", comma_after_short_introductory_phrase?: "do_not_use"|"use", comma_and_semicolon?: "use_comma_between_clauses"|"use_semicolon_between_clauses", corner_bracket_and_periods?: "add_period_after_closing_corner_bracket_at_end_of_sentence", corner_brackets_and_periods?: "do_not_add_period_before_closing_corner_bracket_when_sentence_continues", dash?: "use_em_dash"|"use_hyphen"|"use_tilde", ellipsis?: "use_ellipsis_character"|"use_one_ellipsis_character"|"use_six_dots_at_the_bottom"|"use_six_dots_in_the_center"|"use_three_dots_at_the_bottom"|"use_three_dots_in_the_center"|"use_three_ellipsis_characters"|"use_three_periods"|"use_three_periods_without_spaces"|"use_three_spaced_periods"|"use_two_ellipsis_characters", em_dash?: "use_double_em_dash", emphasis?: "use_double_corner_brackets", exclamation_marks?: "do_not_use", explanatory_note_indicator?: "use_double_em_dash"|"use_parentheses", full_sentence_in_round_brackets?: "add_period_before_closing_round_bracket", highlighting_specific_expressions?: "use_single_curly_quotation_marks"|"use_single_straight_quotation_marks", japanese_reference_materials?: "use_double_corner_brackets", parentheses_for_supplementary_information?: "use_parentheses_without_space_on_either_side", passage_of_time_and_movement_between_locations?: "use_double_em_dash", periods_and_commas?: "use_full_width_japanese_periods_and_full_width_japanese_commas"|"use_full_width_japanese_periods_and_full_width_non_japanese_commas"|"use_full_width_non_japanese_periods_and_full_width_japanese_commas"|"use_full_width_non_japanese_periods_and_full_width_non_japanese_commas", periods_in_academic_degrees?: "do_not_use"|"use", periods_in_direct_quotes?: "do_not_use"|"use", periods_in_uppercase_initialisms_and_acronyms?: "do_not_use", plus_sign_usage?: "do_not_use_plus_sign_to_symbolize_english_word_and_unless_it_is_part_of_a_proper_noun", possessives_of_proper_names_ending_in_s_style?: "add_apostrophe_only"|"add_apostrophe_s", quotation_mark?: "use_curly_quotation_marks"|"use_double_curly_quotation_marks"|"use_double_straight_quotation_marks"|"use_guillemets"|"use_straight_quotation_marks", quotation_mark_and_apostrophe?: "use_curly_quotation_marks_and_apostrophes"|"use_double_and_single_curly_quotation_marks_and_curly_apostrophes"|"use_double_and_single_straight_quotation_marks_and_straight_apostrophes"|"use_guillemets_and_curly_apostrophes"|"use_guillemets_and_straight_apostrophes"|"use_straight_quotation_marks_and_apostrophes", quotation_style?: "use_corner_brackets_for_primary_quotations_and_double_corner_brackets_for_secondary_quotations"|"use_double_curly_quotation_marks_for_primary_quotations_and_single_curly_quotation_marks_for_secondary_quotations"|"use_double_curly_quotation_marks_for_primary_quotations_then_alternate_with_single_curly_quotation_marks_for_nested_quotations"|"use_double_german_quotation_marks_for_primary_quotations_and_single_german_quotation_marks_for_secondary_quotations"|"use_double_quotation_marks_for_primary_quotations_and_single_quotation_marks_for_secondary_quotations"|"use_double_straight_quotation_marks_for_primary_quotations_and_single_straight_quotation_marks_for_secondary_quotations"|"use_double_straight_quotation_marks_for_primary_quotations_then_alternate_with_single_straight_quotation_marks_for_nested_quotations"|"use_guillemets_for_primary_quotations_and_double_curly_quotation_marks_for_secondary_quotations"|"use_guillemets_for_primary_quotations_and_double_straight_quotation_marks_for_secondary_quotations"|"use_guillemets_for_primary_quotations_and_single_guillemets_for_secondary_quotations"|"use_guillemets_for_primary_quotations_double_curly_quotation_marks_for_secondary_quotations_and_single_curly_quotation_marks_for_further_nested_quotations"|"use_reversed_guillemets_for_primary_quotations_and_single_reversed_guillemets_for_secondary_quotations"|"use_single_quotation_marks_for_primary_quotations_and_double_quotation_marks_for_secondary_quotations", range_indicator?: "use_en_dash_with_spaces"|"use_en_dash_without_space_on_either_side"|"use_en_dash_without_spaces"|"use_english_word_to"|"use_full_width_dash"|"use_full_width_wave_dash"|"use_german_word_bis"|"use_half_width_dash"|"use_hyphen"|"use_hyphen_with_space_on_either_side"|"use_hyphen_with_spaces"|"use_hyphen_without_space_on_either_side"|"use_hyphen_without_spaces"|"use_italian_words_da_a"|"use_japanese_word_から"|"use_korean_words_부터_까지"|"use_spanish_words_de_a"|"use_tilde", related_phrases_indicator?: "use_comma"|"use_hyphen"|"use_middle_dot", round_brackets?: "use_full_width_round_brackets"|"use_half_width_round_brackets", salutation?: "do_not_use_comma_after_salutation_capitalize_following_word"|"use_colon_after_salutation"|"use_comma_after_salutation"|"use_exclamation_mark_after_salutation", sentence_break_indicator?: "use_em_dash_with_space_on_either_side"|"use_em_dash_without_space_on_either_side"|"use_en_dash_with_space_on_either_side", serial_comma?: "do_not_use"|"do_not_use_serial_comma_when_using_chinese_comma"|"use"|"use_serial_comma_when_using_comma", setting_off_non_quoted_phrases?: "use_full_width_quotation_marks"|"use_half_width_quotation_marks", slash?: "do_not_use_spaces_before_and_after_slashes"|"use_spaces_before_and_after_slashes"|"use_spaces_before_and_after_slashes_if_there_are_multiple_words_before_and_after_slash"|"use_spaces_before_and_after_slashes_if_there_are_multiple_words_before_or_after_slash", slash_usage?: "do_not_use_slash_to_symbolize_english_word_or", spacing_and_punctuation?: "do_not_use_space"|"use_regular_space", text_in_round_brackets_referring_to_previous_sentence?: "add_period_after_closing_round_bracket"|"add_period_before_closing_round_bracket", text_in_round_brackets_supplementing_preceding_text?: "add_period_after_closing_round_bracket", titles_of_books_and_newspapers?: "use_double_angle_brackets"|"use_double_corner_brackets"|"use_double_straight_quotation_marks", titles_of_creative_works_trade_names_laws_and_regulations?: "use_single_angle_brackets"|"use_single_corner_brackets"|"use_single_straight_quotation_marks", uppercase_acronyms?: "do_not_use_spaces"|"use_spaces"}
# --spelling_and_grammar shape: {abbreviating_french_word_numero?: "abbreviate_as_n_then_degree_symbol"|"abbreviate_as_n_then_o_in_superscript"|"abbreviate_as_no", abbreviation_usage?: "do_not_use_abbreviations"|"do_not_use_abbreviations_unless_necessary"|"use_abbreviations"|"use_abbreviations_as_needed", accents_and_cedillas?: "do_not_use_on_capital_letters"|"never_use"|"use_even_on_capital_letters", accents_in_verbs_conjugated_like_french_word_céder?: "use_acute_accent"|"use_grave_accent", accents_with_subject_verb_inversion?: "use_acute_accent"|"use_grave_accent", active_passive_voice?: "use_active_voice_if_subject_is_prominent_and_agent_is_clear"|"use_active_voice_to_describe_operations_with_user_as_subject"|"use_active_voice_unless_agent_is_unknown_or_irrelevant"|"use_passive_voice_as_needed"|"use_passive_voice_for_automatic_operations_from_user_perspective"|"use_passive_voice_if_agent_is_unknown_or_irrelevant", all_caps?: "do_not_use_all_caps_except_for_acronyms_initialisms_or_proper_nouns"|"do_not_use_all_caps_except_for_acronyms_or_brand_names", complete_sentences?: "always_write_complete_sentences", compound_nouns?: "write_as_one_word"|"write_with_hyphen", conjunctions?: "never_start_sentence_with_coordinating_conjunction", contractions?: "do_not_use_contractions"|"use_contractions"|"use_contractions_but_avoid_negative_contractions", established_loanwords?: "use_as_is"|"use_native_or_sino_korean_equivalents", eszett?: "replace_eszett_with_ss", foreign_word_translation?: "use_equivalent_expressions_in_chinese"|"use_foreign_forms_or_abbreviations_for_technical_terms_or_brand_names"|"use_literal_translation"|"use_localized_names_for_brands_with_official_chinese_translations"|"use_mixture_of_transliteration_and_translation"|"use_transliteration", french_verbs_ending_in_eler_and_eter?: "transcribe_open_e_sound_by_doubling_next_consonant"|"transcribe_open_e_sound_with_grave_accent", i_and_u_with_circumflex_accents?: "do_not_use_circumflex_accents_except_in_verbs_and_to_distinguish_homophones"|"use_circumflex_accents", informal_address_pronouns?: "capitalize_informal_address_pronouns"|"do_not_capitalize_informal_address_pronouns", latin_abbreviations?: "do_not_use_latin_abbreviations", passive_voice?: "avoid_passive_voice_when_agent_is_known", past_participle_of_french_word_laisser_followed_by_infinitive?: "make_french_word_laisser_agree_with_direct_object_complement_if_it_appears_before_verb"|"use_invariable_form_french_word_laissé", personal_titles?: "abbreviate"|"do_not_abbreviate", pluralizing_foreign_words?: "use_french_spelling_rules"|"use_original_language_spelling", quotation_modification?: "do_not_modify_text_in_quotation_marks"|"modify_text_in_quotation_marks_according_to_custom_rules", spanish_word_solo?: "never_use_acute_accent"|"use_acute_accent_when_used_as_adverb", special_characters?: "never_use_symbols", spelled_out_numbers?: "use_hyphens"|"use_hyphens_between_elements_under_100_and_not_separated_by_french_word_et", umlauts?: "replace_umlauts_with_ae_oe_ue", unestablished_loanwords?: "paraphrase_in_korean"|"use_as_is"|"use_as_is_with_explanation_in_parentheses"}
# --style_and_tone shape: {abbreviations?: "avoid_abbreviations_and_symbols_that_can_be_spelled_out_easily"|"use_abbreviations_and_symbols", addressing_non_binary_people?: "use_spanish_word_elle"|"use_spanish_word_ellx", addressing_the_reader?: "use_formal_french_word_vous"|"use_formal_italian_word_lei"|"use_informal_french_word_tu"|"use_informal_italian_word_tu", anglicisms?: "avoid_anglicisms_when_there_is_a_french_equivalent", binary_representation_of_gender?: "avoid_binary_representation_of_gender_when_gender_neutral_language_can_be_used"|"replace_binary_representations_of_gender_with_gender_neutral_language"|"use_neutral_pronouns", complex_sentences?: "avoid_unnecessarily_complex_sentences", country_names?: "use_long_form"|"use_short_form", declarative_endings?: "mix_hapsho_and_haeyo_styles"|"use_hae_style"|"use_haeyo_style"|"use_hapsho_style"|"use_hara_style", default_first_person_pronoun?: "do_not_use_first_person_pronouns"|"omit_first_person_subject_when_clear_from_context"|"use_first_person_pronouns", default_second_person_pronoun?: "do_not_use_second_person_pronouns"|"use_second_person_pronouns", directional_language?: "do_not_use_directional_language", double_negatives?: "do_not_use_double_negatives"|"use_double_negatives", formality?: "use_casual_tone"|"use_formal_tone", gender_neutral_language_readability?: "use_generic_masculine_for_common_compound_nouns_if_it_increases_readability", gender_unspecified?: "use_both_masculine_and_feminine_forms"|"use_gender_neutral_terms"|"use_masculine_form_only"|"use_middle_dots"|"use_parentheses"|"use_periods", gender_unspecified_or_mixed?: "use_both_feminine_and_masculine_forms"|"use_feminine_form_only"|"use_inclusive_nouns_and_adjectives"|"use_masculine_form_only"|"use_neutral_nouns_and_adjectives", idioms_colloquialisms_and_culture_specific_references?: "do_not_use", inflected_words_masculine_noun_agreement?: "place_masculine_nouns_closest_to_inflected_words", instructions_style?: "use_imperative"|"use_indicative"|"use_infinitive"|"use_modal_verbs"|"use_passive_voice", mixing_styles?: "do_not_mix_desu_masu_style_and_dearu_style", modal_verbs?: "avoid_modal_verbs", personal_vs_impersonal_style?: "use_impersonal_style"|"use_personal_style", positive_vs_negative_language?: "use_positive_language", proximity_agreement?: "use", reader_action_required?: "use_you_must_when_action_is_required_from_reader", redundant_introductory_phrases?: "avoid_redundant_introductory_phrases"|"do_not_use_redundant_phrases_that_refer_to_current_text", redundant_phrases?: "avoid_relativizing_and_redundant_phrases"|"do_not_use_redundant_phrases", referring_to_non_binary_people?: "use_the_singular_and_plural_schwa", short_vs_long_words?: "use_short_words", simple_words_and_sentences?: "use_simple_words_and_sentences_avoid_hard_to_translate_words_and_figures_of_speech", text_position_references?: "avoid_directional_terms_as_only_reference_to_position_in_text_specify_exact_position_instead", tone?: "use_dearu_style_to_give_impression_content_is_accurate_and_rigorous_or_to_convey_sense_of_confidence_and_reliability"|"use_desu_masu_style_to_give_impression_content_is_plain_and_straightforward_or_to_give_reader_reassuring_or_soft_impression", verbal_vs_nominal_style?: "use_nominal_style"|"use_verbal_style"}
# --vocabulary shape: {abbreviations?: "write_original_term_then_abbreviation_and_explanation", loanwords?: "add_explanation_to_loanword_if_difficult_to_rephrase"|"rephrase_loanword_in_daily_use_chinese_or_japanese_words_if_possible"|"rephrase_loanword_with_another_expression_if_not_established"|"use_loanword_as_is_if_well_established"}
export def "style-rules-configured-rules updateStyleRuleConfiguredRules" [
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dates-and-times: record # shape: {calendar_era?: "use_bc_and_ad"|"use_bce_and_ce", centuries?: "spell_out"|"use_arabic_numerals"|"use_numerals"|"use_roman_numerals", date_format?: "use_dd_period_mm_period_yy_with_leading_zeros_for_single_digit_days_and_months"|"use_dd_period_mm_period_yyyy"|"use_dd_period_mm_period_yyyy_with_leading_zeros_for_single_digit_days_and_months"|"use_dd_period_space_abbreviated_month_yyyy_with_abbreviations_jan_period_feb_period_mrz_period_apr_period_mai_jun_period_jul_period_aug_period_sep_period_okt_period_nov_period_dez_period_without_leading_zeros_for_single_digit_days"|"use_dd_period_space_abbreviated_month_yyyy_with_abbreviations_jan_period_febr_period_maerz_apr_period_mai_juni_juli_aug_period_sept_period_okt_period_nov_period_dez_period_without_leading_zeros_for_single_digit_days"|"use_dd_period_space_month_yyyy_without_leading_zeros_for_single_digit_days"|"use_dd_slash_mm_slash_yyyy"|"use_dd_slash_mm_slash_yyyy_with_leading_zeros_for_single_digit_days_and_months"|"use_dd_space_spelled_out_month_space_yyyy"|"use_dd_space_spelled_out_month_space_yyyy_and_use_spanish_word_septiembre_for_ninth_month"|"use_dd_space_spelled_out_month_space_yyyy_and_use_spanish_word_setiembre_for_ninth_month"|"use_dd_space_spelled_out_month_space_yyyy_without_leading_zeros_for_single_digit_days"|"use_historical_eras_and_write_numbers_in_chinese_followed_by_chinese_word_公元前_or_公元后_with_arabic_numerals_in_parentheses"|"use_mm_slash_dd_slash_yyyy_with_leading_zeros_for_single_digit_days_and_months"|"use_numerals_only_with_leading_zero_for_single_digits"|"use_numerals_only_without_leading_zero_for_single_digits"|"use_spelled_out_month_space_dd_comma_space_yyyy_and_use_spanish_word_septiembre_for_ninth_month"|"use_spelled_out_month_space_dd_comma_space_yyyy_without_leading_zeros_for_single_digit_days"|"use_traditional_calendar_system_with_chinese_numbers"|"use_yyyy_chinese_word_年_mm_chinese_word_月_dd_chinese_word_日_with_chinese_numbers"|"use_yyyy_chinese_word_年_mm_chinese_word_月_dd_chinese_word_日_without_leading_zero_for_single_digit_months_and_days"|"use_yyyy_hyphen_mm_hyphen_dd_with_leading_zero_for_single_digit_days_and_months"|"use_yyyy_hyphen_mm_hyphen_dd_with_leading_zeros_for_single_digit_days_and_months"|"use_yyyy_korean word_년_space_mm_korean word_월_space_dd_korean word_일_without_leading_zero_for_single_digit_days_and_months"|"use_yyyy_period_mm_period_dd"|"use_yyyy_period_space_mm_period_space_dd_period_space_without_leading_zero_for_single_digit_days_and_months"|"use_yyyy_slash_mm_slash_dd"|"use_yyyy_slash_mm_slash_dd_with_leading_zero_for_single_digit_days_and_months", dates_in_numerical_form?: "use_dd_hyphen_mm_hyphen_yyyy"|"use_dd_period_mm_period_yyyy"|"use_dd_slash_mm_slash_yyyy", decades?: "spell_out"|"use_apostrophe_yy"|"use_yy_for_20th_century_but_yyyy_for_other_centuries"|"use_yy_without_apostrophe"|"use_yyyy", hours_minutes_seconds_separator?: "use_colon"|"use_period", hours_minutes_separator?: "use_colon_without_spaces"|"use_letter_h_with_regular_space_on_either_side"|"use_letter_h_without_spaces", midnight_in_numerals?: "use_00_00"|"use_24_00", single_digit_days_and_months?: "do_not_use_leading_zero"|"use_leading_zero", single_digit_hours?: "do_not_use_leading_zero"|"use_leading_zero", time_format?: "spell_out_time_in_words"|"use_12_hour_clock_and_do_not_specify_morning_or_evening"|"use_12_hour_clock_and_lowercase_am_or_pm_with_periods"|"use_12_hour_clock_and_lowercase_am_or_pm_with_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_lowercase_am_or_pm_without_periods"|"use_12_hour_clock_and_lowercase_am_or_pm_without_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_specify_morning_or_evening"|"use_12_hour_clock_and_uppercase_am_or_pm_with_periods"|"use_12_hour_clock_and_uppercase_am_or_pm_with_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_uppercase_am_or_pm_without_periods"|"use_12_hour_clock_and_uppercase_am_or_pm_without_periods_except_use_noon_and_midnight_instead_of_12_am_and_12_pm"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_arabic_numerals"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_arabic_numerals_with_chinese_word_点_for_hours"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_arabic_numerals_with_chinese_words_时_and_分_for_hours_and_minutes"|"use_12_hour_clock_and_write_chinese_word_上午_or_下午_or_chinese_word_早上_or_晚上_followed_by_chinese_numbers_with_chinese_words_时_and_分_for_hours_and_minutes"|"use_12_hour_clock_with_arabic_numerals_and_colon"|"use_12_hour_clock_with_korean_words_시_and_분"|"use_12_hour_clock_without_leading_zero_or_minutes_for_full_hours_use_colon_as_separator_and_lowercase_am_or_pm_without_periods"|"use_12_hour_clock_without_leading_zero_or_minutes_for_full_hours_use_colon_as_separator_and_uppercase_am_or_pm_without_periods"|"use_12_hour_clock_without_leading_zero_use_period_as_separator_and_lowercase_am_or_pm_with_periods_and_spaces"|"use_24_hour_clock"|"use_24_hour_clock_with_arabic_numerals_and_colon"|"use_24_hour_clock_with_colon_as_separator"|"use_24_hour_clock_with_korean_words_시_and_분"|"use_24_hour_clock_with_period_as_separator"|"use_hh_colon_mm_german_word_uhr_with_leading_zeros_for_single_digit_hours"|"use_hh_colon_mm_german_word_uhr_without_leading_zeros_for_single_digit_hours"|"use_hh_period_mm_german_word_uhr_with_leading_zeros_for_single_digit_hours"|"use_hh_period_mm_german_word_uhr_without_leading_zeros_for_single_digit_hours"|"use_hh_period_mm_german_word_uhr_without_leading_zeros_for_single_digit_hours_and_for_full_hours_state_hour_only", writing_dates?: "use_dd_space_spelled_out_month_space_yyyy"|"use_numerals", years?: "use_apostrophe_yy"|"use_common_era"|"use_japanese_imperial_era"|"use_yyyy"}
  --formatting: record # shape: {email_address_format?: "place_domain_in_parentheses"|"replace_at_symbol_with_english_word_at_in_brackets_and_replace_periods_with_english_word_dot_in_brackets"|"replace_at_symbol_with_english_word_at_in_brackets_with_space_on_either_side"|"replace_at_symbol_with_english_word_at_in_parentheses_with_space_on_either_side"|"replace_at_symbol_with_english_word_at_with_space_on_either_side"|"use_standard_format", phone_number_country_code_format?: "use_00_before_country_code"|"use_plus_sign_before_country_code", phone_number_format?: "do_not_use_spaces"|"do_not_use_spaces_or_special_characters_between_digits_of_phone_number"|"keep_original_format"|"place_area_code_in_parentheses_followed_by_space"|"separate_area_code_and_phone_number_with_slash"|"separate_area_code_and_phone_number_with_space"|"separate_country_code_area_code_local_prefix_and_last_four_digits_with_hyphens"|"separate_country_code_area_code_local_prefix_and_last_four_digits_with_periods"|"separate_country_code_area_code_local_prefix_and_last_four_digits_with_spaces"|"use_north_american_numbering_plan_format"|"use_space_after_country_code", space_between_arabic_numerals_and_unit?: "do_not_use", space_between_chinese_and_english?: "do_not_use", space_between_chinese_characters_and_arabic_numerals?: "do_not_use"}
  --numbers: record # shape: {approximate_numbers?: "use_kanji_numbers", currency_format?: "spell_out"|"spell_out_currency_name_followed_by_amount_in_arabic_numerals_without_space"|"spell_out_currency_name_followed_by_amount_in_chinese"|"use_amount_followed_by_currency_symbol_without_space"|"use_amount_followed_by_space_then_currency_symbol"|"use_amount_followed_by_space_then_iso_code"|"use_amount_followed_by_space_then_spell_out_currency_name"|"use_amount_followed_by_space_then_spell_out_currency_name_in_lowercase"|"use_amount_followed_by_spelled_out_currency_name_in_japanese_without_space"|"use_amount_followed_by_spelled_out_currency_name_without_space"|"use_currency_symbol_but_spell_out_if_no_symbol_exists"|"use_currency_symbol_but_use_iso_code_if_no_symbol_exists"|"use_currency_symbol_followed_by_amount_in_arabic_numerals_without_space"|"use_currency_symbol_followed_by_amount_without_space"|"use_currency_symbol_followed_by_space_then_amount"|"use_currency_symbol_followed_by_space_then_amount_in_arabic_numerals"|"use_full_width_currency_symbol_followed_by_amount_without_space"|"use_half_width_currency_symbol_followed_by_amount_without_space"|"use_half_width_currency_symbol_followed_by_space_then_amount"|"use_iso_code"|"use_iso_code_followed_by_space_then_amount"|"use_iso_code_followed_by_space_then_amount_in_arabic_numerals", decimal_numbers_less_than_one?: "always_use_0_before_decimal_separator", decimal_separator?: "use_comma_and_do_not_use_thousands_separator"|"use_comma_as_decimal_separator"|"use_comma_do_not_use_thousands_separator_and_use_period_only_for_radio_stations"|"use_period_and_do_not_use_thousands_separator"|"use_period_as_decimal_separator", dimensions_separator?: "use_multiplication_sign_between_dimensions_with_space_on_either_side"|"use_multiplication_sign_between_dimensions_without_space_on_either_side"|"use_x_between_dimensions_with_space_on_either_side"|"use_x_between_dimensions_without_space_on_either_side", equation_formula_reference?: "always_use_arabic_numerals_to_number_equations_or_formulas_referenced_in_text", kanji_numbers?: "use_kanji_numbers_for_numbers_in_phrases_and_counting_method_based_on_native_japanese_readings", large_number_format?: "always_use_arabic_numerals"|"spell_out_large_numbers"|"use_abbreviations_for_large_numbers"|"use_chinese_characters_for_ten_thousands_and_hundred_millions"|"use_comma_to_separate_large_numbers_into_units_of_three_except_for_calendar_years"|"use_kanji_for_trillions_hundred_millions_and_ten_thousands"|"use_korean_words_만_억_조_with_space"|"use_korean_words_만_억_조_without_space", large_sums_of_money?: "spell_out_italian_words_milione_and_miliardo"|"use_italian_words_mio_and_mrd_instead_of_italian_words_milione_and_miliardo", large_sums_of_money_format?: "use_amount_followed_by_abbreviation_for_million_or_billion_without_space"|"use_amount_followed_by_space_then_abbreviation_for_million_or_billion"|"use_amount_followed_by_space_then_english_word_million_or_billion", list_of_measurements_with_units?: "repeat_unit_for_each_measurement_in_list", mathematical_expression_spacing?: "use_space_between_elements_of_mathematical_expression_or_equation", number_format?: "use_half_width_comma_to_separate_large_numbers_into_units_of_three_except_for_calendar_years_and_use_half_width_period_as_decimal_separator", number_separator?: "do_not_use_chinese_comma_to_separate_numbers_indicating_approximate_value"|"use_chinese_comma_to_separate_numbers_in_abbreviations", numbers_of_5_digits_or_more?: "use_comma_as_decimal_separator_and_period_as_thousands_separator"|"use_comma_as_decimal_separator_and_space_as_thousands_separator"|"use_comma_as_decimal_separator_period_as_thousands_separator_and_period_for_radio_stations"|"use_comma_as_decimal_separator_space_as_thousands_separator_and_period_for_radio_stations"|"use_period_as_decimal_separator_and_comma_as_thousands_separator"|"use_period_as_decimal_separator_and_space_as_thousands_separator", numbers_up_to_4_digits?: "use_comma_as_decimal_separator_and_period_as_thousands_separator"|"use_comma_as_decimal_separator_and_space_as_thousands_separator"|"use_comma_as_decimal_separator_period_as_thousands_separator_and_period_for_radio_stations"|"use_comma_as_decimal_separator_space_as_thousands_separator_and_period_for_radio_stations"|"use_period_as_decimal_separator_and_comma_as_thousands_separator"|"use_period_as_decimal_separator_and_space_as_thousands_separator", percentage_format?: "use_arabic_numerals_followed_by_percent_symbol_without_space"|"use_chinese_numbers_followed_by_chinese_word_百分之"|"use_numerals_followed_by_full_width_percent_symbol_without_space"|"use_numerals_followed_by_japanese_word_パーセント_without_space"|"use_numerals_followed_by_korean_word_퍼센트"|"use_numerals_followed_by_percent_symbol"|"use_numerals_followed_by_space_then_german_word_prozent"|"use_numerals_followed_by_space_then_half_width_percent_symbol"|"use_numerals_followed_by_space_then_italian_word_per_cento"|"use_numerals_followed_by_space_then_italian_word_percento"|"use_numerals_followed_by_space_then_korean_word_퍼센트"|"use_numerals_followed_by_space_then_percent_symbol"|"use_numerals_followed_by_space_then_spell_out_per_cent"|"use_numerals_followed_by_space_then_spell_out_percent"|"use_spanish_word_por_cien"|"use_spanish_word_por_ciento", reference_to_symbol?: "spell_out_symbol_name_followed_by_symbol_in_parentheses", spelling_out_units?: "abbreviate_units_of_measure_when_used_with_numeral_but_spell_out_when_used_without_numeral"|"always_abbreviate_units_of_measure"|"always_spell_out_units_of_measure"|"spell_out_units_in_korean"|"spell_out_units_of_measure_when_used_with_spelled_out_numbers_but_abbreviate_when_used_with_numeral"|"spell_out_units_of_measure_with_katakana_or_katakana_and_kanji"|"use_si_symbols"|"use_unit_symbols", temperature_format?: "spell_out_unit"|"spell_out_unit_followed_by_numerals_then_korean_word_도"|"use_arabic_numerals_followed_by_space_then_spell_out_unit"|"use_arabic_numerals_followed_by_unit_symbol_without_space"|"use_arabic_numerals_then_spell_out_unit"|"use_chinese_numbers_then_spell_out_unit"|"use_italian_word_grado_and_do_not_specify_temperature_scale"|"use_numerals_followed_by_japanese_word_度_without_space"|"use_numerals_followed_by_korean_word_도"|"use_numerals_followed_by_space_then_spell_out_unit"|"use_numerals_followed_by_space_then_unit_symbol"|"use_numerals_followed_by_unit_symbol_without_space"|"use_spanish_word_grado_and_do_not_specify_temperature_scale", thousands_separator?: "do_not_use"|"do_not_use_thousands_separator"|"use_comma"|"use_comma_to_separate_large_numbers_into_units_of_three"|"use_period"|"use_period_as_thousands_separator"|"use_space"|"use_space_as_thousands_separator"|"use_space_to_separate_large_numbers_into_units_of_three"|"use_straight_apostrophe_as_thousands_separator", units_of_measure_spacing?: "do_not_use_space_between_numeral_and_unit_of_measure"|"use_space_between_numeral_and_unit_of_measure", use_of_hiragana_and_kanji?: "use_hiragana_japanese_word_か所_or_か月_when_using_arabic_numerals_in_horizontal_writing_but_use_kanji_japanese_word_箇所_or_箇月_when_using_kanji_numbers", writing_numbers?: "always_use_kanji_numbers"|"use_arabic_numerals"|"use_full_width_arabic_numerals_and_only_use_kanji_numbers_where_it_would_otherwise_sound_unnatural"|"use_half_width_arabic_numerals_and_only_use_kanji_numbers_where_it_would_otherwise_sound_unnatural", zero_format?: "use_chinese_word_〇_for_numbering"|"use_chinese_word_零_for_measurement"}
  --punctuation: record # shape: {abbreviations?: "do_not_separate_abbreviated_words"|"separate_each_abbreviated_word_with_period_and_space"|"separate_each_abbreviated_word_with_period_without_space"|"separate_each_abbreviated_word_with_space_without_period", acronyms?: "do_not_use_periods", ampersand_abbreviation_spacing?: "do_not_use_spaces_before_and_after_ampersand_as_part_of_abbreviation"|"use_spaces_before_and_after_ampersand_as_part_of_abbreviation", ampersand_usage?: "use_english_word_and_except_in_company_names_common_abbreviations_titles_software_code_and_mathematical_equations"|"use_full_width_ampersand"|"use_german_word_und_except_in_company_names_common_abbreviations_titles_software_code_and_mathematical_equations"|"use_half_width_ampersand", apostrophe?: "use_curly_apostrophes"|"use_straight_apostrophes", bracket?: "use_hexagonal_brackets"|"use_lenticular_brackets"|"use_parentheses"|"use_square_brackets_for_nationality_and_hexagonal_brackets_for_historical_period", chinese_mixed_with_english?: "do_not_place_english_in_quotation_marks"|"place_english_in_quotation_marks", colon?: "use_full_width_colon"|"use_half_width_colon", colon_between_hours_and_minutes_or_chapters_and_verses?: "do_not_use_space_before_or_after_colon", colon_in_heading?: "use_space_after_colon_not_before", colon_to_replace_versus_or_to?: "do_not_use_space_before_or_after_colon", comma_after_conjunctive_adverbs?: "do_not_use"|"use", comma_after_i_e_and_e_g?: "do_not_use"|"use", comma_after_short_introductory_phrase?: "do_not_use"|"use", comma_and_semicolon?: "use_comma_between_clauses"|"use_semicolon_between_clauses", corner_bracket_and_periods?: "add_period_after_closing_corner_bracket_at_end_of_sentence", corner_brackets_and_periods?: "do_not_add_period_before_closing_corner_bracket_when_sentence_continues", dash?: "use_em_dash"|"use_hyphen"|"use_tilde", ellipsis?: "use_ellipsis_character"|"use_one_ellipsis_character"|"use_six_dots_at_the_bottom"|"use_six_dots_in_the_center"|"use_three_dots_at_the_bottom"|"use_three_dots_in_the_center"|"use_three_ellipsis_characters"|"use_three_periods"|"use_three_periods_without_spaces"|"use_three_spaced_periods"|"use_two_ellipsis_characters", em_dash?: "use_double_em_dash", emphasis?: "use_double_corner_brackets", exclamation_marks?: "do_not_use", explanatory_note_indicator?: "use_double_em_dash"|"use_parentheses", full_sentence_in_round_brackets?: "add_period_before_closing_round_bracket", highlighting_specific_expressions?: "use_single_curly_quotation_marks"|"use_single_straight_quotation_marks", japanese_reference_materials?: "use_double_corner_brackets", parentheses_for_supplementary_information?: "use_parentheses_without_space_on_either_side", passage_of_time_and_movement_between_locations?: "use_double_em_dash", periods_and_commas?: "use_full_width_japanese_periods_and_full_width_japanese_commas"|"use_full_width_japanese_periods_and_full_width_non_japanese_commas"|"use_full_width_non_japanese_periods_and_full_width_japanese_commas"|"use_full_width_non_japanese_periods_and_full_width_non_japanese_commas", periods_in_academic_degrees?: "do_not_use"|"use", periods_in_direct_quotes?: "do_not_use"|"use", periods_in_uppercase_initialisms_and_acronyms?: "do_not_use", plus_sign_usage?: "do_not_use_plus_sign_to_symbolize_english_word_and_unless_it_is_part_of_a_proper_noun", possessives_of_proper_names_ending_in_s_style?: "add_apostrophe_only"|"add_apostrophe_s", quotation_mark?: "use_curly_quotation_marks"|"use_double_curly_quotation_marks"|"use_double_straight_quotation_marks"|"use_guillemets"|"use_straight_quotation_marks", quotation_mark_and_apostrophe?: "use_curly_quotation_marks_and_apostrophes"|"use_double_and_single_curly_quotation_marks_and_curly_apostrophes"|"use_double_and_single_straight_quotation_marks_and_straight_apostrophes"|"use_guillemets_and_curly_apostrophes"|"use_guillemets_and_straight_apostrophes"|"use_straight_quotation_marks_and_apostrophes", quotation_style?: "use_corner_brackets_for_primary_quotations_and_double_corner_brackets_for_secondary_quotations"|"use_double_curly_quotation_marks_for_primary_quotations_and_single_curly_quotation_marks_for_secondary_quotations"|"use_double_curly_quotation_marks_for_primary_quotations_then_alternate_with_single_curly_quotation_marks_for_nested_quotations"|"use_double_german_quotation_marks_for_primary_quotations_and_single_german_quotation_marks_for_secondary_quotations"|"use_double_quotation_marks_for_primary_quotations_and_single_quotation_marks_for_secondary_quotations"|"use_double_straight_quotation_marks_for_primary_quotations_and_single_straight_quotation_marks_for_secondary_quotations"|"use_double_straight_quotation_marks_for_primary_quotations_then_alternate_with_single_straight_quotation_marks_for_nested_quotations"|"use_guillemets_for_primary_quotations_and_double_curly_quotation_marks_for_secondary_quotations"|"use_guillemets_for_primary_quotations_and_double_straight_quotation_marks_for_secondary_quotations"|"use_guillemets_for_primary_quotations_and_single_guillemets_for_secondary_quotations"|"use_guillemets_for_primary_quotations_double_curly_quotation_marks_for_secondary_quotations_and_single_curly_quotation_marks_for_further_nested_quotations"|"use_reversed_guillemets_for_primary_quotations_and_single_reversed_guillemets_for_secondary_quotations"|"use_single_quotation_marks_for_primary_quotations_and_double_quotation_marks_for_secondary_quotations", range_indicator?: "use_en_dash_with_spaces"|"use_en_dash_without_space_on_either_side"|"use_en_dash_without_spaces"|"use_english_word_to"|"use_full_width_dash"|"use_full_width_wave_dash"|"use_german_word_bis"|"use_half_width_dash"|"use_hyphen"|"use_hyphen_with_space_on_either_side"|"use_hyphen_with_spaces"|"use_hyphen_without_space_on_either_side"|"use_hyphen_without_spaces"|"use_italian_words_da_a"|"use_japanese_word_から"|"use_korean_words_부터_까지"|"use_spanish_words_de_a"|"use_tilde", related_phrases_indicator?: "use_comma"|"use_hyphen"|"use_middle_dot", round_brackets?: "use_full_width_round_brackets"|"use_half_width_round_brackets", salutation?: "do_not_use_comma_after_salutation_capitalize_following_word"|"use_colon_after_salutation"|"use_comma_after_salutation"|"use_exclamation_mark_after_salutation", sentence_break_indicator?: "use_em_dash_with_space_on_either_side"|"use_em_dash_without_space_on_either_side"|"use_en_dash_with_space_on_either_side", serial_comma?: "do_not_use"|"do_not_use_serial_comma_when_using_chinese_comma"|"use"|"use_serial_comma_when_using_comma", setting_off_non_quoted_phrases?: "use_full_width_quotation_marks"|"use_half_width_quotation_marks", slash?: "do_not_use_spaces_before_and_after_slashes"|"use_spaces_before_and_after_slashes"|"use_spaces_before_and_after_slashes_if_there_are_multiple_words_before_and_after_slash"|"use_spaces_before_and_after_slashes_if_there_are_multiple_words_before_or_after_slash", slash_usage?: "do_not_use_slash_to_symbolize_english_word_or", spacing_and_punctuation?: "do_not_use_space"|"use_regular_space", text_in_round_brackets_referring_to_previous_sentence?: "add_period_after_closing_round_bracket"|"add_period_before_closing_round_bracket", text_in_round_brackets_supplementing_preceding_text?: "add_period_after_closing_round_bracket", titles_of_books_and_newspapers?: "use_double_angle_brackets"|"use_double_corner_brackets"|"use_double_straight_quotation_marks", titles_of_creative_works_trade_names_laws_and_regulations?: "use_single_angle_brackets"|"use_single_corner_brackets"|"use_single_straight_quotation_marks", uppercase_acronyms?: "do_not_use_spaces"|"use_spaces"}
  --spelling-and-grammar: record # shape: {abbreviating_french_word_numero?: "abbreviate_as_n_then_degree_symbol"|"abbreviate_as_n_then_o_in_superscript"|"abbreviate_as_no", abbreviation_usage?: "do_not_use_abbreviations"|"do_not_use_abbreviations_unless_necessary"|"use_abbreviations"|"use_abbreviations_as_needed", accents_and_cedillas?: "do_not_use_on_capital_letters"|"never_use"|"use_even_on_capital_letters", accents_in_verbs_conjugated_like_french_word_céder?: "use_acute_accent"|"use_grave_accent", accents_with_subject_verb_inversion?: "use_acute_accent"|"use_grave_accent", active_passive_voice?: "use_active_voice_if_subject_is_prominent_and_agent_is_clear"|"use_active_voice_to_describe_operations_with_user_as_subject"|"use_active_voice_unless_agent_is_unknown_or_irrelevant"|"use_passive_voice_as_needed"|"use_passive_voice_for_automatic_operations_from_user_perspective"|"use_passive_voice_if_agent_is_unknown_or_irrelevant", all_caps?: "do_not_use_all_caps_except_for_acronyms_initialisms_or_proper_nouns"|"do_not_use_all_caps_except_for_acronyms_or_brand_names", complete_sentences?: "always_write_complete_sentences", compound_nouns?: "write_as_one_word"|"write_with_hyphen", conjunctions?: "never_start_sentence_with_coordinating_conjunction", contractions?: "do_not_use_contractions"|"use_contractions"|"use_contractions_but_avoid_negative_contractions", established_loanwords?: "use_as_is"|"use_native_or_sino_korean_equivalents", eszett?: "replace_eszett_with_ss", foreign_word_translation?: "use_equivalent_expressions_in_chinese"|"use_foreign_forms_or_abbreviations_for_technical_terms_or_brand_names"|"use_literal_translation"|"use_localized_names_for_brands_with_official_chinese_translations"|"use_mixture_of_transliteration_and_translation"|"use_transliteration", french_verbs_ending_in_eler_and_eter?: "transcribe_open_e_sound_by_doubling_next_consonant"|"transcribe_open_e_sound_with_grave_accent", i_and_u_with_circumflex_accents?: "do_not_use_circumflex_accents_except_in_verbs_and_to_distinguish_homophones"|"use_circumflex_accents", informal_address_pronouns?: "capitalize_informal_address_pronouns"|"do_not_capitalize_informal_address_pronouns", latin_abbreviations?: "do_not_use_latin_abbreviations", passive_voice?: "avoid_passive_voice_when_agent_is_known", past_participle_of_french_word_laisser_followed_by_infinitive?: "make_french_word_laisser_agree_with_direct_object_complement_if_it_appears_before_verb"|"use_invariable_form_french_word_laissé", personal_titles?: "abbreviate"|"do_not_abbreviate", pluralizing_foreign_words?: "use_french_spelling_rules"|"use_original_language_spelling", quotation_modification?: "do_not_modify_text_in_quotation_marks"|"modify_text_in_quotation_marks_according_to_custom_rules", spanish_word_solo?: "never_use_acute_accent"|"use_acute_accent_when_used_as_adverb", special_characters?: "never_use_symbols", spelled_out_numbers?: "use_hyphens"|"use_hyphens_between_elements_under_100_and_not_separated_by_french_word_et", umlauts?: "replace_umlauts_with_ae_oe_ue", unestablished_loanwords?: "paraphrase_in_korean"|"use_as_is"|"use_as_is_with_explanation_in_parentheses"}
  --style-and-tone: record # shape: {abbreviations?: "avoid_abbreviations_and_symbols_that_can_be_spelled_out_easily"|"use_abbreviations_and_symbols", addressing_non_binary_people?: "use_spanish_word_elle"|"use_spanish_word_ellx", addressing_the_reader?: "use_formal_french_word_vous"|"use_formal_italian_word_lei"|"use_informal_french_word_tu"|"use_informal_italian_word_tu", anglicisms?: "avoid_anglicisms_when_there_is_a_french_equivalent", binary_representation_of_gender?: "avoid_binary_representation_of_gender_when_gender_neutral_language_can_be_used"|"replace_binary_representations_of_gender_with_gender_neutral_language"|"use_neutral_pronouns", complex_sentences?: "avoid_unnecessarily_complex_sentences", country_names?: "use_long_form"|"use_short_form", declarative_endings?: "mix_hapsho_and_haeyo_styles"|"use_hae_style"|"use_haeyo_style"|"use_hapsho_style"|"use_hara_style", default_first_person_pronoun?: "do_not_use_first_person_pronouns"|"omit_first_person_subject_when_clear_from_context"|"use_first_person_pronouns", default_second_person_pronoun?: "do_not_use_second_person_pronouns"|"use_second_person_pronouns", directional_language?: "do_not_use_directional_language", double_negatives?: "do_not_use_double_negatives"|"use_double_negatives", formality?: "use_casual_tone"|"use_formal_tone", gender_neutral_language_readability?: "use_generic_masculine_for_common_compound_nouns_if_it_increases_readability", gender_unspecified?: "use_both_masculine_and_feminine_forms"|"use_gender_neutral_terms"|"use_masculine_form_only"|"use_middle_dots"|"use_parentheses"|"use_periods", gender_unspecified_or_mixed?: "use_both_feminine_and_masculine_forms"|"use_feminine_form_only"|"use_inclusive_nouns_and_adjectives"|"use_masculine_form_only"|"use_neutral_nouns_and_adjectives", idioms_colloquialisms_and_culture_specific_references?: "do_not_use", inflected_words_masculine_noun_agreement?: "place_masculine_nouns_closest_to_inflected_words", instructions_style?: "use_imperative"|"use_indicative"|"use_infinitive"|"use_modal_verbs"|"use_passive_voice", mixing_styles?: "do_not_mix_desu_masu_style_and_dearu_style", modal_verbs?: "avoid_modal_verbs", personal_vs_impersonal_style?: "use_impersonal_style"|"use_personal_style", positive_vs_negative_language?: "use_positive_language", proximity_agreement?: "use", reader_action_required?: "use_you_must_when_action_is_required_from_reader", redundant_introductory_phrases?: "avoid_redundant_introductory_phrases"|"do_not_use_redundant_phrases_that_refer_to_current_text", redundant_phrases?: "avoid_relativizing_and_redundant_phrases"|"do_not_use_redundant_phrases", referring_to_non_binary_people?: "use_the_singular_and_plural_schwa", short_vs_long_words?: "use_short_words", simple_words_and_sentences?: "use_simple_words_and_sentences_avoid_hard_to_translate_words_and_figures_of_speech", text_position_references?: "avoid_directional_terms_as_only_reference_to_position_in_text_specify_exact_position_instead", tone?: "use_dearu_style_to_give_impression_content_is_accurate_and_rigorous_or_to_convey_sense_of_confidence_and_reliability"|"use_desu_masu_style_to_give_impression_content_is_plain_and_straightforward_or_to_give_reader_reassuring_or_soft_impression", verbal_vs_nominal_style?: "use_nominal_style"|"use_verbal_style"}
  --vocabulary: record # shape: {abbreviations?: "write_original_term_then_abbreviation_and_explanation", loanwords?: "add_explanation_to_loanword_if_difficult_to_rephrase"|"rephrase_loanword_in_daily_use_chinese_or_japanese_words_if_possible"|"rephrase_loanword_with_another_expression_if_not_established"|"use_loanword_as_is_if_well_established"}
]: any -> record<style_id: string, name: string, creation_time: string, updated_time: string, language: string, version: int, configured_rules: record<dates_and_times: record<calendar_era: string, centuries: string, date_format: string, dates_in_numerical_form: string, decades: string, hours_minutes_seconds_separator: string, hours_minutes_separator: string, midnight_in_numerals: string, single_digit_days_and_months: string, single_digit_hours: string, time_format: string, writing_dates: string, years: string>, formatting: record<email_address_format: string, phone_number_country_code_format: string, phone_number_format: string, space_between_arabic_numerals_and_unit: string, space_between_chinese_and_english: string, space_between_chinese_characters_and_arabic_numerals: string>, numbers: record<approximate_numbers: string, currency_format: string, decimal_numbers_less_than_one: string, decimal_separator: string, dimensions_separator: string, equation_formula_reference: string, kanji_numbers: string, large_number_format: string, large_sums_of_money: string, large_sums_of_money_format: string, list_of_measurements_with_units: string, mathematical_expression_spacing: string, number_format: string, number_separator: string, numbers_of_5_digits_or_more: string, numbers_up_to_4_digits: string, percentage_format: string, reference_to_symbol: string, spelling_out_units: string, temperature_format: string, thousands_separator: string, units_of_measure_spacing: string, use_of_hiragana_and_kanji: string, writing_numbers: string, zero_format: string>, punctuation: record<abbreviations: string, acronyms: string, ampersand_abbreviation_spacing: string, ampersand_usage: string, apostrophe: string, bracket: string, chinese_mixed_with_english: string, colon: string, colon_between_hours_and_minutes_or_chapters_and_verses: string, colon_in_heading: string, colon_to_replace_versus_or_to: string, comma_after_conjunctive_adverbs: string, comma_after_i_e_and_e_g: string, comma_after_short_introductory_phrase: string, comma_and_semicolon: string, corner_bracket_and_periods: string, corner_brackets_and_periods: string, dash: string, ellipsis: string, em_dash: string, emphasis: string, exclamation_marks: string, explanatory_note_indicator: string, full_sentence_in_round_brackets: string, highlighting_specific_expressions: string, japanese_reference_materials: string, parentheses_for_supplementary_information: string, passage_of_time_and_movement_between_locations: string, periods_and_commas: string, periods_in_academic_degrees: string, periods_in_direct_quotes: string, periods_in_uppercase_initialisms_and_acronyms: string, plus_sign_usage: string, possessives_of_proper_names_ending_in_s_style: string, quotation_mark: string, quotation_mark_and_apostrophe: string, quotation_style: string, range_indicator: string, related_phrases_indicator: string, round_brackets: string, salutation: string, sentence_break_indicator: string, serial_comma: string, setting_off_non_quoted_phrases: string, slash: string, slash_usage: string, spacing_and_punctuation: string, text_in_round_brackets_referring_to_previous_sentence: string, text_in_round_brackets_supplementing_preceding_text: string, titles_of_books_and_newspapers: string, titles_of_creative_works_trade_names_laws_and_regulations: string, uppercase_acronyms: string>, spelling_and_grammar: record<abbreviating_french_word_numero: string, abbreviation_usage: string, accents_and_cedillas: string, accents_in_verbs_conjugated_like_french_word_c_der: string, accents_with_subject_verb_inversion: string, active_passive_voice: string, all_caps: string, complete_sentences: string, compound_nouns: string, conjunctions: string, contractions: string, established_loanwords: string, eszett: string, foreign_word_translation: string, french_verbs_ending_in_eler_and_eter: string, i_and_u_with_circumflex_accents: string, informal_address_pronouns: string, latin_abbreviations: string, passive_voice: string, past_participle_of_french_word_laisser_followed_by_infinitive: string, personal_titles: string, pluralizing_foreign_words: string, quotation_modification: string, spanish_word_solo: string, special_characters: string, spelled_out_numbers: string, umlauts: string, unestablished_loanwords: string>, style_and_tone: record<abbreviations: string, addressing_non_binary_people: string, addressing_the_reader: string, anglicisms: string, binary_representation_of_gender: string, complex_sentences: string, country_names: string, declarative_endings: string, default_first_person_pronoun: string, default_second_person_pronoun: string, directional_language: string, double_negatives: string, formality: string, gender_neutral_language_readability: string, gender_unspecified: string, gender_unspecified_or_mixed: string, idioms_colloquialisms_and_culture_specific_references: string, inflected_words_masculine_noun_agreement: string, instructions_style: string, mixing_styles: string, modal_verbs: string, personal_vs_impersonal_style: string, positive_vs_negative_language: string, proximity_agreement: string, reader_action_required: string, redundant_introductory_phrases: string, redundant_phrases: string, referring_to_non_binary_people: string, short_vs_long_words: string, simple_words_and_sentences: string, text_position_references: string, tone: string, verbal_vs_nominal_style: string>, vocabulary: record<abbreviations: string, loanwords: string>>, custom_instructions: table<id: string, label: string, prompt: string, source_language: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/style_rules/($style_id)/configured_rules")
  let body = {dates_and_times: $dates_and_times, formatting: $formatting, numbers: $numbers, punctuation: $punctuation, spelling_and_grammar: $spelling_and_grammar, style_and_tone: $style_and_tone, vocabulary: $vocabulary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a custom instruction
#
# POST /v3/style_rules/{style_id}/custom_instructions
# operationId: createCustomInstruction
export def "style-rules-custom-instructions createCustomInstruction" [
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  label: string # Label for the custom instruction
  prompt: string # Instruction text
  --source-language: string # Optional source language code
]: any -> record<id: string, label: string, prompt: string, source_language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/style_rules/($style_id)/custom_instructions")
  let body = {label: $label, prompt: $prompt, source_language: $source_language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a custom instruction
#
# GET /v3/style_rules/{style_id}/custom_instructions/{instruction_id}
# operationId: getCustomInstruction
export def "style-rules-custom-instructions get" [
  style_id: string
  instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, label: string, prompt: string, source_language: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/style_rules/($style_id)/custom_instructions/($instruction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace a custom instruction
#
# PUT /v3/style_rules/{style_id}/custom_instructions/{instruction_id}
# operationId: updateCustomInstruction
export def "style-rules-custom-instructions updateCustomInstruction" [
  style_id: string
  instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  label: string # Updated label for the custom instruction
  prompt: string # Updated instruction text
  --source-language: string # Optional source language code
]: any -> record<id: string, label: string, prompt: string, source_language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/style_rules/($style_id)/custom_instructions/($instruction_id)")
  let body = {label: $label, prompt: $prompt, source_language: $source_language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom instruction
#
# DELETE /v3/style_rules/{style_id}/custom_instructions/{instruction_id}
# operationId: deleteCustomInstruction
export def "style-rules-custom-instructions delete" [
  style_id: string
  instruction_id: string
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
  let full_url = (build-url $base $"/v3/style_rules/($style_id)/custom_instructions/($instruction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Streaming URL
#
# POST /v3/voice/realtime
# operationId: getVoiceStreamingUrl
export def "voice-realtime post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message-format: string@message-format-completer # Message encoding format for WebSocket communication. Determines how messages are serialized and transmitted. Using `json`,  messages are JSON-encoded and sent as TEXT WebSocket frames. All binary fields (such as audio data) are base64-encoded strings. Using `msgpack`, messages are MessagePack-encoded and sent as BINARY WebSocket frames. All binary fields (such as audio data) contain raw binary data.  For more details, see [Message Encoding](/api-reference/voice#message-encoding). (default: json, e.g. json)
  source_media_content_type: string@source-media-content-type-completer #  The audio format for streaming, which specifies container, codec, and encoding parameters. See the table below for supported formats. If `audio/auto` is specified, the server will auto-detect the container and codec for all supported combinations, except PCM. That requires explicit encoding parameters. All formats need to be single channel audio.    | Content Type                          | Container                                         | Codec                                     |  | :------------------------------------ | :------------------------------------------------ | :---------------------------------------- |  | `audio/auto`                          | Auto-detect: FLAC / Matroska / MPEG / Ogg / WebM  | Auto-detect AAC / FLAC / MP3 / OPUS       |  | `audio/flac`                          | FLAC (flac)                                       | FLAC                                      |  | `audio/mpeg`                          | MPEG (mp3/m4a)                                    | MP3                                       |  | `audio/ogg`                           | Ogg (ogg/oga)                                     | Auto-detect FLAC / OPUS                   |  | `audio/webm`                          | WebM (webm)                                       | OPUS                                      |  | `audio/x-matroska`                    | Matroska (mkv/mka)                                | Auto-detect: AAC / FLAC / MP3 / OPUS      |  | `audio/ogg;codecs=flac`               | Ogg (ogg/oga)                                     | FLAC                                      |  | `audio/ogg;codecs=opus`               | Ogg (ogg/oga)                                     | OPUS                                      |  | `audio/pcm;encoding=alaw;rate=8000`   | -                                                 | PCM A-Law 8000 Hz (G.711)                 |  | `audio/pcm;encoding=ulaw;rate=8000`   | -                                                 | PCM µ-Law 8000 Hz (G.711)                 |  | `audio/pcm;encoding=s16le;rate=8000`  | -                                                 | PCM signed 16-bit little-endian 8000 Hz   |  | `audio/pcm;encoding=s16le;rate=16000` | -                                                 | PCM signed 16-bit little-endian 16000 Hz  |  | `audio/pcm;encoding=s16le;rate=44100` | -                                                 | PCM signed 16-bit little-endian 44100 Hz  |  | `audio/pcm;encoding=s16le;rate=48000` | -                                                 | PCM signed 16-bit little-endian 48000 Hz  |  | `audio/webm;codecs=opus`              | WebM (webm)                                       | OPUS                                      |  | `audio/x-matroska;codecs=aac`         | Matroska (mkv/mka)                                | AAC                                       |  | `audio/x-matroska;codecs=flac`        | Matroska (mkv/mka)                                | FLAC                                      |  | `audio/x-matroska;codecs=mp3`         | Matroska (mkv/mka)                                | MP3                                       |  | `audio/x-matroska;codecs=opus`        | Matroska (mkv/mka)                                | OPUS                                      |    We recommend the following bitrates as good tradeoff between quality and bandwidth:  - AAC: 96 kbps  - FLAC: 256 kbps  (16000 Hz)  - MP3: 128 kbps  - OPUS: 32 kbps (recommendation for low bandwidth scenarios)  - PCM: 256 kbps (16000 Hz, default recommendation)   (e.g. audio/ogg;codecs=opus)
  --source-language: string@source-language-completer # The source language of the audio stream. It can be left empty or must be one of the supported Voice API source languages and comply with IETF BCP 47 language tags. Note: Some source transcription languages are provided through external service partners. See the [supported languages table](/api-reference/voice#show-supported-languages) for details.  (e.g. en)
  --source-language-mode: string@source-language-mode-completer # Controls how the source_language value is used. - `auto`: Treats source language as a hint; server can override - `fixed`: Treats source language as mandatory; server must use this language (default: auto, e.g. fixed)
  --target-languages: list # List of target languages for translation. The stream will emit translations for each language. Language identifiers must comply with IETF BCP 47. See the [supported languages table](/api-reference/voice#show-supported-languages) for details.  (default: [], e.g. [de, fr, es])
  --target-media-languages: list # (closed beta) List of target languages for which to generate synthesized audio. Languages specified here will automatically be added to target_languages if not already present, ensuring you receive both text translation and audio synthesis for these languages. If omitted, only text transcription and translation will be provided (no audio synthesis). Language identifiers must comply with IETF BCP 47. Note: Some translated audio languages are provided through external service partners. See the [supported languages table](/api-reference/voice#show-supported-languages) for details.  (default: [], e.g. [de])
  --target-media-content-type: string@target-media-content-type-completer #  (closed beta) The audio format for synthesized target media streaming.  Specifies container, codec, and encoding parameters for the audio returned in target_media_chunk messages.  If not specified, defaults to audio/webm;codecs=opus.  Only applies when target_media_languages is specified.    | Content Type | Container | Codec |  | :--- | :--- | :--- |  | `audio/flac` | FLAC (flac) | FLAC 24000 Hz |  | `video/mp2t;codecs=aac` | MPEG Transport Stream (Audio only) | AAC 70 kbit/s |  | `video/mp2t;codecs=opus` | MPEG Transport Stream (Audio only) | OPUS 32 kbit/s |  | `audio/ogg` | Ogg (ogg/oga) | OPUS 32 kbit/s |  | `audio/ogg;codecs=flac` | Ogg (ogg/oga) | FLAC 24000 Hz |  | `audio/ogg;codecs=opus` | Ogg (ogg/oga) | OPUS 32 kbit/s |  | `audio/opus` | - | OPUS 32 kbit/s |  | `audio/pcm;encoding=alaw;rate=8000` | - | PCM A-Law 8000 Hz (G.711) |  | `audio/pcm;encoding=ulaw;rate=8000` | - | PCM µ-Law 8000 Hz (G.711) |  | `audio/pcm;encoding=s16le;rate=16000` | - | PCM signed 16-bit little-endian 16000 Hz |  | `audio/pcm;encoding=s16le;rate=24000` | - | PCM signed 16-bit little-endian 24000 Hz |  | `audio/webm` | WebM (webm) | OPUS 32 kbit/s  |  | `audio/webm;codecs=opus` | WebM (webm) | OPUS 32 kbit/s |  | `audio/x-matroska;codecs=aac` | Matroska (mkv/mka) | AAC 70 kbit/s |  | `audio/x-matroska;codecs=flac` | Matroska (mkv/mka) | FLAC 24000 Hz |  | `audio/x-matroska;codecs=opus` | Matroska (mkv/mka) | OPUS 32 kbit/s |    We recommend the following formats as good tradeoffs between quality and bandwidth:  - OPUS (WebM): 32 kbps, recommended for low bandwidth scenarios (default)  - PCM 24kHz: 384 kbps, high quality (default: audio/webm;codecs=opus, e.g. audio/webm;codecs=opus)
  --target-media-voice: string@target-media-voice-completer # (closed beta) Target audio voice selection for synthesized speech. The default voice is language dependent. (e.g. female)
  --spoken-terms-id: string # (beta) The ID of a spoken terms list used to inform transcription. (format: uuid, e.g. 7c4f1080-cfe2-41d4-8269-0e6ec15a0354)
  --glossary-id: string # A unique ID assigned to a glossary. (e.g. def3a26b-3e84-45b3-84ae-0c0aaf3525f7)
  --formality: string@formality-completer-1 # Sets whether the translated text should lean towards formal or informal language. Possible options are:   * `default` - use the default formality for the target language   * `formal`/`more` - for a more formal language   * `informal`/`less` - for a more informal language (default: default, e.g. formal)
]: any -> record<streaming_url: string, token: string, session_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.deepl.com")
  let full_url = (build-url $base "/v3/voice/realtime")
  let body = {message_format: $message_format, source_media_content_type: $source_media_content_type, source_language: $source_language, source_language_mode: $source_language_mode, target_languages: $target_languages, target_media_languages: $target_media_languages, target_media_content_type: $target_media_content_type, target_media_voice: $target_media_voice, spoken_terms_id: $spoken_terms_id, glossary_id: $glossary_id, formality: $formality} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Request Reconnection
#
# GET /v3/voice/realtime
# operationId: requestReconnection
export def "voice-realtime requestReconnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # The latest ephemeral token obtained for the stream. (e.g. VGhpcyBpcyBhIGZha2UgdG9rZW4K)
]: nothing -> record<streaming_url: string, token: string, session_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.deepl.com")
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/voice/realtime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a voice translation job
#
# POST /v1/jobs/voice/translate
# operationId: createVoiceTranslateJob
# --source_file shape: {name: string, content_type: "audio/mpeg"|"audio/wav"|"audio/ogg"|"audio/flac"|"audio/mp4"|"audio/webm", content_length: int}
# --parameters shape: {source_language?: any}
# --targets item shape: {language: string, type: "text/plain"|"application/x-subrip"|"audio/opus"|"audio/flac"|"audio/pcm;encoding=s16le;rate=16000"|"audio/pcm;encoding=s16le;rate=24000"|"audio/pcm;encoding=ulaw;rate=8000"|"audio/pcm;encoding=alaw;rate=8000"|"audio/x-matroska;codecs=aac"|"audio/x-matroska;codecs=flac"|"audio/x-matroska;codecs=opus"|"audio/x-matroska;codecs=pcm_s16le;rate=16000"|"audio/x-matroska;codecs=pcm_s16le;rate=24000"|"video/mp2t;codecs=aac"|"video/mp2t;codecs=opus"|"audio/ogg;codecs=flac"|"audio/ogg;codecs=opus"|"audio/webm;codecs=opus"}
export def "jobs-voice-translate createVoiceTranslateJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Additional fields to include in the response. - `signed_url`: Include pre-signed URLs (`signed_upload_url` on create, `signed_download_url` on status) that can be used without an authorization header.
  source_file: record # Metadata about the source audio file to be uploaded. — shape: {name: string, content_type: "audio/mpeg"|"audio/wav"|"audio/ogg"|"audio/flac"|"audio/mp4"|"audio/webm", content_length: int}
  --parameters: record # Processing parameters for the voice translation job. — shape: {source_language?: any}
  targets: list # One or more translation targets. Each target produces a separate result. — item shape: {language: string, type: "text/plain"|"application/x-subrip"|"audio/opus"|"audio/flac"|"audio/pcm;encoding=s16le;rate=16000"|"audio/pcm;encoding=s16le;rate=24000"|"audio/pcm;encoding=ulaw;rate=8000"|"audio/pcm;encoding=alaw;rate=8000"|"audio/x-matroska;codecs=aac"|"audio/x-matroska;codecs=flac"|"audio/x-matroska;codecs=opus"|"audio/x-matroska;codecs=pcm_s16le;rate=16000"|"audio/x-matroska;codecs=pcm_s16le;rate=24000"|"video/mp2t;codecs=aac"|"video/mp2t;codecs=opus"|"audio/ogg;codecs=flac"|"audio/ogg;codecs=opus"|"audio/webm;codecs=opus"}
]: any -> record<job_id: string, upload_url: string, signature: string, signed_upload_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/jobs/voice/translate" $qp)
  let body = {source_file: $source_file, parameters: $parameters, targets: $targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get voice translation job status
#
# GET /v1/jobs/voice/translate/{job_id}
# operationId: getVoiceTranslateJobStatus
export def "jobs-voice-translate get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Additional fields to include in the response. - `signed_url`: Include pre-signed URLs (`signed_upload_url` on create, `signed_download_url` on status) that can be used without an authorization header.
]: nothing -> record<job_id: string, product: string, operation: string, created_at: string, updated_at: string, usage: record<storage_used: int>, source_file: record<name: string, content_type: string, content_length: int>, parameters: record<source_language: record>, targets: table<language: string, type: string>, results: table<status: string, download_url: string, signature: string, signed_download_url: string, error: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/jobs/voice/translate/($job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit an evaluation job
#
# POST /v1/quality-evaluation
# operationId: submitQualityEvaluation
# --metadata shape: {source_language: string, target_language: string}
# --segments item shape: {source: string, target: string}
export def "quality-evaluation submitQualityEvaluation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  metadata: record # Job-level metadata. — shape: {source_language: string, target_language: string}
  segments: list # The segment pairs to evaluate. Up to 500 segments per request. — item shape: {source: string, target: string}
]: any -> record<job_id: string, poll_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quality-evaluation")
  let body = {metadata: $metadata, segments: $segments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Poll for the evaluation result
#
# GET /v1/quality-evaluation/{job_id}
# operationId: pollQualityEvaluation
export def "quality-evaluation pollQualityEvaluation" [
  job_id: string
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
  let full_url = (build-url $base $"/v1/quality-evaluation/($job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
