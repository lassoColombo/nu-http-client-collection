# Auto-generated client for OpenAI API v1.2.0
# Source: https://api.apis.guru/v2/specs/openai.com/1.2.0/openapi.json
# Auth: --token flag or $env.OPENAI_API_TOKEN

const BASE_URL = "https://api.openai.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENAI_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.openai.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def response-format-completer [] { ["b64_json" "url"] }
def size-completer [] { ["1024x1024" "256x256" "512x512"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "answers create" } } | get name | first)
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

# Answers the specified question using the provided documents and examples. The endpoint first [searches](/docs/api-reference/searches) over provided documents or files to find relevant context. The relevant context is combined with the provided examples and question to create the prompt for [completion](/docs/api-reference/completions).
#
# POST /answers
# DEPRECATED
# operationId: createAnswer
@deprecated
export def "answers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list<string> # List of documents from which the answer for the input `question` should be derived. If this is an empty list, the question will be answered based on the question-answer examples. You should specify either `documents` or a `file`, but not both. (nullable, e.g. ['Japan is an island country in East Asia, located in the northwest Pacific Ocean.', 'Tokyo is the capital and most populous prefecture of Japan.'])
  examples: list # List of (question, answer) pairs that will help steer the model towards the tone and answer format you'd like. We recommend adding 2 to 3 examples. (e.g. [['What is the capital of Canada?', 'Ottawa'], ['Which province is Ottawa in?', 'Ontario']])
  examples_context: string # A text snippet containing the contextual information used to generate the answers for the `examples` you provide. (e.g. Ottawa, Canada's capital, is located in the east of southern Ontario, near the city of Montréal and the U.S. border.)
  --expand: list # If an object name is in the list, we provide the full information of the object; otherwise, we only provide the object ID. Currently we support `completion` and `file` objects for expansion. (nullable, default: [])
  --file: string # The ID of an uploaded file that contains documents to search over. See [upload file](/docs/api-reference/files/upload) for how to upload a file of the desired format and purpose. You should specify either `documents` or a `file`, but not both. (nullable)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this [tokenizer tool](/tokenizer?view=bpe) (which works for both GPT-2 and GPT-3) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. As an example, you can pass `{"50256": -100}` to prevent the <|endoftext|> token from being generated. (nullable)
  --logprobs: int # Include the log probabilities on the `logprobs` most likely tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response. The maximum value for `logprobs` is 5. If you need more than this, please contact us through our [Help center](https://help.openai.com) and describe your use case. When `logprobs` is set, `completion` will be automatically added into `expand` to get the logprobs. (nullable)
  --max-rerank: int # The maximum number of documents to be ranked by [Search](/docs/api-reference/searches/create) when using `file`. Setting it to a higher value leads to improved accuracy but with increased latency and cost. (nullable, default: 200)
  --max-tokens: int # The maximum number of tokens allowed for the generated answer (nullable, default: 16)
  model: string # ID of the model to use for completion. You can select one of `ada`, `babbage`, `curie`, or `davinci`.
  --n: int # How many answers to generate for each question. (nullable, default: 1)
  question: string # Question to get answered. (e.g. What is the capital of Japan?)
  --return-metadata: oneof<nothing, bool> # A special boolean flag for showing metadata. If set to `true`, each document entry in the returned JSON will contain a "metadata" field. This flag only takes effect when `file` is set. (nullable, default: false)
  --return-prompt: oneof<nothing, bool> # If set to `true`, the returned JSON will include a "prompt" field containing the final prompt that was used to request a completion. This is mainly useful for debugging purposes. (nullable, default: false)
  --search-model: string # ID of the model to use for [Search](/docs/api-reference/searches/create). You can select one of `ada`, `babbage`, `curie`, or `davinci`. (nullable, default: ada)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence. (nullable)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. (nullable, default: 0)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<answers: list<string>, completion: string, model: string, object: string, search_model: string, selected_documents: table<document: int, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/answers")
  let req_body = {"documents": $documents, "examples": $examples, "examples_context": $examples_context, "expand": $expand, "file": $file, "logit_bias": $logit_bias, "logprobs": $logprobs, "max_rerank": $max_rerank, "max_tokens": $max_tokens, "model": $model, "n": $n, "question": $question, "return_metadata": $return_metadata, "return_prompt": $return_prompt, "search_model": $search_model, "stop": $stop, "temperature": $temperature, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transcribes audio into the input language.
#
# POST /audio/transcriptions
# operationId: createTranscription
export def "audio-transcriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The audio file to transcribe, in one of these formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm. (format: binary)
  --language: string # The language of the input audio. Supplying the input language in [ISO-639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format will improve accuracy and latency.
  model: string # ID of the model to use. Only `whisper-1` is currently available.
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/guides/speech-to-text/prompting) should match the audio language.
  --response-format: string # The format of the transcript output, in one of these options: json, text, srt, verbose_json, or vtt. (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit. (default: 0)
]: any -> record<text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/transcriptions")
  let req_body = {"file": $file, "language": $language, "model": $model, "prompt": $prompt, "response_format": $response_format, "temperature": $temperature} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Translates audio into into English.
#
# POST /audio/translations
# operationId: createTranslation
export def "audio-translations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The audio file to translate, in one of these formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm. (format: binary)
  model: string # ID of the model to use. Only `whisper-1` is currently available.
  --prompt: string # An optional text to guide the model's style or continue a previous audio segment. The [prompt](/docs/guides/speech-to-text/prompting) should be in English.
  --response-format: string # The format of the transcript output, in one of these options: json, text, srt, verbose_json, or vtt. (default: json)
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit. (default: 0)
]: any -> record<text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audio/translations")
  let req_body = {"file": $file, "model": $model, "prompt": $prompt, "response_format": $response_format, "temperature": $temperature} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Creates a completion for the chat message
#
# POST /chat/completions
# operationId: createChatCompletion
# --messages item shape: {content: string, name?: string, role: "system"|"user"|"assistant"}
export def "chat-completions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --frequency-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the tokenizer) to an associated bias value from -100 to 100. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. (nullable)
  --max-tokens: int # The maximum number of tokens allowed for the generated answer. By default, the number of tokens the model can return will be (4096 - prompt tokens). (default: inf)
  messages: list # The messages to generate chat completions for, in the [chat format](/docs/guides/chat/introduction). — item shape: {content: string, name?: string, role: "system"|"user"|"assistant"}
  model: string # ID of the model to use. Currently, only `gpt-3.5-turbo` and `gpt-3.5-turbo-0301` are supported.
  --n: int # How many chat completion choices to generate for each input message. (nullable, default: 1, e.g. 1)
  --presence-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens.
  --stream: oneof<nothing, bool> # If set, partial message deltas will be sent, like in ChatGPT. Tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. (nullable, default: false)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (nullable, default: 1, e.g. 1)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<choices: table<finish_reason: string, index: int, message: record>, created: int, id: string, model: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chat/completions")
  let req_body = {"frequency_penalty": $frequency_penalty, "logit_bias": $logit_bias, "max_tokens": $max_tokens, "messages": $messages, "model": $model, "n": $n, "presence_penalty": $presence_penalty, "stop": $stop, "stream": $stream, "temperature": $temperature, "top_p": $top_p, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Classifies the specified `query` using provided examples. The endpoint first [searches](/docs/api-reference/searches) over the labeled examples to select the ones most relevant for the particular query. Then, the relevant examples are combined with the query to construct a prompt to produce the final label via the [completions](/docs/api-reference/completions) endpoint. Labeled examples can be provided via an uploaded `file`, or explicitly listed in the request using the `examples` parameter for quick tests and small scale use cases.
#
# POST /classifications
# DEPRECATED
# operationId: createClassification
@deprecated
export def "classifications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --examples: list # A list of examples with labels, in the following format: `[["The movie is so interesting.", "Positive"], ["It is quite boring.", "Negative"], ...]` All the label strings will be normalized to be capitalized. You should specify either `examples` or `file`, but not both. (nullable, e.g. [['Do not see this film.', 'Negative'], ['Smart, provocative and blisteringly funny.', 'Positive']])
  --expand: list # If an object name is in the list, we provide the full information of the object; otherwise, we only provide the object ID. Currently we support `completion` and `file` objects for expansion. (nullable, default: [])
  --file: string # The ID of the uploaded file that contains training examples. See [upload file](/docs/api-reference/files/upload) for how to upload a file of the desired format and purpose. You should specify either `examples` or `file`, but not both. (nullable)
  --labels: list<string> # The set of categories being classified. If not specified, candidate labels will be automatically collected from the examples you provide. All the label strings will be normalized to be capitalized. (nullable, e.g. [Positive, Negative])
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this [tokenizer tool](/tokenizer?view=bpe) (which works for both GPT-2 and GPT-3) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. As an example, you can pass `{"50256": -100}` to prevent the <|endoftext|> token from being generated. (nullable)
  --logprobs: int # Include the log probabilities on the `logprobs` most likely tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response. The maximum value for `logprobs` is 5. If you need more than this, please contact us through our [Help center](https://help.openai.com) and describe your use case. When `logprobs` is set, `completion` will be automatically added into `expand` to get the logprobs. (nullable)
  --max-examples: int # The maximum number of examples to be ranked by [Search](/docs/api-reference/searches/create) when using `file`. Setting it to a higher value leads to improved accuracy but with increased latency and cost. (nullable, default: 200)
  model: string # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models/overview) for descriptions of them.
  query: string # Query to be classified. (e.g. The plot is not very attractive.)
  --return-metadata: oneof<nothing, bool> # A special boolean flag for showing metadata. If set to `true`, each document entry in the returned JSON will contain a "metadata" field. This flag only takes effect when `file` is set. (nullable, default: false)
  --return-prompt: oneof<nothing, bool> # If set to `true`, the returned JSON will include a "prompt" field containing the final prompt that was used to request a completion. This is mainly useful for debugging purposes. (nullable, default: false)
  --search-model: string # ID of the model to use for [Search](/docs/api-reference/searches/create). You can select one of `ada`, `babbage`, `curie`, or `davinci`. (nullable, default: ada)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. (nullable, default: 0, e.g. 0)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<completion: string, label: string, model: string, object: string, search_model: string, selected_examples: table<document: int, label: string, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications")
  let req_body = {"examples": $examples, "expand": $expand, "file": $file, "labels": $labels, "logit_bias": $logit_bias, "logprobs": $logprobs, "max_examples": $max_examples, "model": $model, "query": $query, "return_metadata": $return_metadata, "return_prompt": $return_prompt, "search_model": $search_model, "temperature": $temperature, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a completion for the provided prompt and parameters
#
# POST /completions
# operationId: createCompletion
export def "completions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --best-of: int # Generates `best_of` completions server-side and returns the "best" (the one with the highest log probability per token). Results cannot be streamed. When used with `n`, `best_of` controls the number of candidate completions and `n` specifies how many to return – `best_of` must be greater than `n`. **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`. (nullable, default: 1)
  --echo: oneof<nothing, bool> # Echo back the prompt in addition to the completion (nullable, default: false)
  --frequency-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --logit-bias: record # Modify the likelihood of specified tokens appearing in the completion. Accepts a json object that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this [tokenizer tool](/tokenizer?view=bpe) (which works for both GPT-2 and GPT-3) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. As an example, you can pass `{"50256": -100}` to prevent the <|endoftext|> token from being generated. (nullable)
  --logprobs: int # Include the log probabilities on the `logprobs` most likely tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response. The maximum value for `logprobs` is 5. If you need more than this, please contact us through our [Help center](https://help.openai.com) and describe your use case. (nullable)
  --max-tokens: int # The maximum number of [tokens](/tokenizer) to generate in the completion. The token count of your prompt plus `max_tokens` cannot exceed the model's context length. Most models have a context length of 2048 tokens (except for the newest models, which support 4096). (nullable, default: 16, e.g. 16)
  model: string # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models/overview) for descriptions of them.
  --n: int # How many completions to generate for each prompt. **Note:** Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max_tokens` and `stop`. (nullable, default: 1, e.g. 1)
  --presence-penalty: float # Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. [See more information about frequency and presence penalties.](/docs/api-reference/parameter-details) (nullable, default: 0)
  --prompt: any # The prompt(s) to generate completions for, encoded as a string, array of strings, array of tokens, or array of token arrays. Note that <|endoftext|> is the document separator that the model sees during training, so if a prompt is not specified the model will generate as if from the beginning of a new document. (nullable, default: <|endoftext|>)
  --stop: any # Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence. (nullable)
  --stream: oneof<nothing, bool> # Whether to stream back partial progress. If set, tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. (nullable, default: false)
  --suffix: string # The suffix that comes after a completion of inserted text. (nullable, e.g. test.)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (nullable, default: 1, e.g. 1)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<choices: table<finish_reason: string, index: int, logprobs: record, text: string>, created: int, id: string, model: string, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/completions")
  let req_body = {"best_of": $best_of, "echo": $echo, "frequency_penalty": $frequency_penalty, "logit_bias": $logit_bias, "logprobs": $logprobs, "max_tokens": $max_tokens, "model": $model, "n": $n, "presence_penalty": $presence_penalty, "prompt": $prompt, "stop": $stop, "stream": $stream, "suffix": $suffix, "temperature": $temperature, "top_p": $top_p, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new edit for the provided input, instruction, and parameters.
#
# POST /edits
# operationId: createEdit
export def "edits create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --input: string # The input text to use as a starting point for the edit. (nullable, default: , e.g. What day of the wek is it?)
  instruction: string # The instruction that tells the model how to edit the prompt. (e.g. Fix the spelling mistakes.)
  model: string # ID of the model to use. You can use the `text-davinci-edit-001` or `code-davinci-edit-001` model with this endpoint.
  --n: int # How many edits to generate for the input and instruction. (nullable, default: 1, e.g. 1)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. (nullable, default: 1, e.g. 1)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (nullable, default: 1, e.g. 1)
]: any -> record<choices: table<finish_reason: string, index: int, logprobs: record, text: string>, created: int, object: string, usage: record<completion_tokens: int, prompt_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/edits")
  let req_body = {"input": $input, "instruction": $instruction, "model": $model, "n": $n, "temperature": $temperature, "top_p": $top_p} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates an embedding vector representing the input text.
#
# POST /embeddings
# operationId: createEmbedding
export def "embeddings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: any # Input text to get embeddings for, encoded as a string or array of tokens. To get embeddings for multiple inputs in a single request, pass an array of strings or array of token arrays. Each input must not exceed 8192 tokens in length. (e.g. The quick brown fox jumped over the lazy dog)
  model: string # ID of the model to use. You can use the [List models](/docs/api-reference/models/list) API to see all of your available models, or see our [Model overview](/docs/models/overview) for descriptions of them.
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<data: table<embedding: list, index: int, object: string>, model: string, object: string, usage: record<prompt_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/embeddings")
  let req_body = {"input": $input, "model": $model, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the currently available (non-finetuned) models, and provides basic information about each one such as the owner and availability.
#
# GET /engines
# DEPRECATED
# operationId: listEngines
@deprecated
export def "engines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: int, id: string, object: string, ready: bool>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/engines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a model instance, providing basic information about it such as the owner and availability.
#
# GET /engines/{engine_id}
# DEPRECATED
# operationId: retrieveEngine
@deprecated
export def "engines get" [
  engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: int, id: string, object: string, ready: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($engine_id | is-empty) { error make --unspanned { msg: "path parameter 'engine_id' must be non-empty" } }
  let full_url = (build-url $base ({engine_id: (encode-path-segment $engine_id)} | format pattern "/engines/{engine_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# The search endpoint computes similarity scores between provided query and documents. Documents can be passed directly to the API if there are no more than 200 of them. To go beyond the 200 document limit, documents can be processed offline and then used for efficient retrieval at query time. When `file` is set, the search endpoint searches over all the documents in the given file and returns up to the `max_rerank` number of documents. These documents will be returned along with their search scores. The similarity score is a positive score that usually ranges from 0 to 300 (but can sometimes go higher), where a score above 200 usually means the document is semantically similar to the query.
#
# POST /engines/{engine_id}/search
# DEPRECATED
# operationId: createSearch
@deprecated
export def "engines-search create" [
  engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list<string> # Up to 200 documents to search over, provided as a list of strings. The maximum document length (in tokens) is 2034 minus the number of tokens in the query. You should specify either `documents` or a `file`, but not both. (nullable, e.g. ['White House', 'hospital', 'school'])
  --file: string # The ID of an uploaded file that contains documents to search over. You should specify either `documents` or a `file`, but not both. (nullable)
  --max-rerank: int # The maximum number of documents to be re-ranked and returned by search. This flag only takes effect when `file` is set. (nullable, default: 200)
  query: string # Query to search against the documents. (e.g. the president)
  --return-metadata: oneof<nothing, bool> # A special boolean flag for showing metadata. If set to `true`, each document entry in the returned JSON will contain a "metadata" field. This flag only takes effect when `file` is set. (nullable, default: false)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<data: table<document: int, object: string, score: float>, model: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($engine_id | is-empty) { error make --unspanned { msg: "path parameter 'engine_id' must be non-empty" } }
  let full_url = (build-url $base ({engine_id: (encode-path-segment $engine_id)} | format pattern "/engines/{engine_id}/search"))
  let req_body = {"documents": $documents, "file": $file, "max_rerank": $max_rerank, "query": $query, "return_metadata": $return_metadata, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of files that belong to the user's organization.
#
# GET /files
# operationId: listFiles
export def "files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload a file that contains document(s) to be used across various endpoints/features. Currently, the size of all the files uploaded by one organization can be up to 1 GB. Please contact us if you need to increase the storage limit.
#
# POST /files
# operationId: createFile
export def "files create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Name of the [JSON Lines](https://jsonlines.readthedocs.io/en/latest/) file to be uploaded. If the `purpose` is set to "fine-tune", each line is a JSON record with "prompt" and "completion" fields representing your [training examples](/docs/guides/fine-tuning/prepare-training-data). (format: binary)
  purpose: string # The intended purpose of the uploaded documents. Use "fine-tune" for [Fine-tuning](/docs/api-reference/fine-tunes). This allows us to validate the format of the uploaded file.
]: any -> record<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let req_body = {"file": $file, "purpose": $purpose} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete a file.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information about a specific file.
#
# GET /files/{file_id}
# operationId: retrieveFile
export def "files get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the contents of the specified file
#
# GET /files/{file_id}/content
# operationId: downloadFile
export def "files-content download" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/files/{file_id}/content"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List your organization's fine-tuning jobs
#
# GET /fine-tunes
# operationId: listFineTunes
export def "fine-tunes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created_at: int, events: list, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: list, status: string, training_files: list, updated_at: int, validation_files: list>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine-tunes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a job that fine-tunes a specified model from a given dataset. Response includes details of the enqueued job including job status and the name of the fine-tuned models once complete. [Learn more about Fine-tuning](/docs/guides/fine-tuning)
#
# POST /fine-tunes
# operationId: createFineTune
export def "fine-tunes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-size: int # The batch size to use for training. The batch size is the number of training examples used to train a single forward and backward pass. By default, the batch size will be dynamically configured to be ~0.2% of the number of examples in the training set, capped at 256 - in general, we've found that larger batch sizes tend to work better for larger datasets. (nullable)
  --classification-betas: list<float> # If this is provided, we calculate F-beta scores at the specified beta values. The F-beta score is a generalization of F-1 score. This is only used for binary classification. With a beta of 1 (i.e. the F-1 score), precision and recall are given the same weight. A larger beta score puts more weight on recall and less on precision. A smaller beta score puts more weight on precision and less on recall. (nullable, e.g. [0.6, 1, 1.5, 2])
  --classification-n-classes: int # The number of classes in a classification task. This parameter is required for multiclass classification. (nullable)
  --classification-positive-class: string # The positive class in binary classification. This parameter is needed to generate precision, recall, and F1 metrics when doing binary classification. (nullable)
  --compute-classification-metrics: oneof<nothing, bool> # If set, we calculate classification-specific metrics such as accuracy and F-1 score using the validation set at the end of every epoch. These metrics can be viewed in the [results file](/docs/guides/fine-tuning/analyzing-your-fine-tuned-model). In order to compute classification metrics, you must provide a `validation_file`. Additionally, you must specify `classification_n_classes` for multiclass classification or `classification_positive_class` for binary classification. (nullable, default: false)
  --learning-rate-multiplier: float # The learning rate multiplier to use for training. The fine-tuning learning rate is the original learning rate used for pretraining multiplied by this value. By default, the learning rate multiplier is the 0.05, 0.1, or 0.2 depending on final `batch_size` (larger learning rates tend to perform better with larger batch sizes). We recommend experimenting with values in the range 0.02 to 0.2 to see what produces the best results. (nullable)
  --model: string # The name of the base model to fine-tune. You can select one of "ada", "babbage", "curie", "davinci", or a fine-tuned model created after 2022-04-21. To learn more about these models, see the [Models](https://platform.openai.com/docs/models) documentation. (nullable, default: curie)
  --n-epochs: int # The number of epochs to train the model for. An epoch refers to one full cycle through the training dataset. (nullable, default: 4)
  --prompt-loss-weight: float # The weight to use for loss on the prompt tokens. This controls how much the model tries to learn to generate the prompt (as compared to the completion which always has a weight of 1.0), and can add a stabilizing effect to training when completions are short. If prompts are extremely long (relative to completions), it may make sense to reduce this weight so as to avoid over-prioritizing learning the prompt. (nullable, default: 0.01)
  --suffix: string # A string of up to 40 characters that will be added to your fine-tuned model name. For example, a `suffix` of "custom-model-name" would produce a model name like `ada:ft-your-org:custom-model-name-2022-02-15-04-21-04`. (nullable)
  training_file: string # The ID of an uploaded file that contains training data. See [upload file](/docs/api-reference/files/upload) for how to upload a file. Your dataset must be formatted as a JSONL file, where each training example is a JSON object with the keys "prompt" and "completion". Additionally, you must upload your file with the purpose `fine-tune`. See the [fine-tuning guide](/docs/guides/fine-tuning/creating-training-data) for more details. (e.g. file-ajSREls59WBbvgSzJSVWxMCB)
  --validation-file: string # The ID of an uploaded file that contains validation data. If you provide this file, the data is used to generate validation metrics periodically during fine-tuning. These metrics can be viewed in the [fine-tuning results file](/docs/guides/fine-tuning/analyzing-your-fine-tuned-model). Your train and validation data should be mutually exclusive. Your dataset must be formatted as a JSONL file, where each validation example is a JSON object with the keys "prompt" and "completion". Additionally, you must upload your file with the purpose `fine-tune`. See the [fine-tuning guide](/docs/guides/fine-tuning/creating-training-data) for more details. (nullable, e.g. file-XjSREls59WBbvgSzJSVWxMCa)
]: any -> record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fine-tunes")
  let req_body = {"batch_size": $batch_size, "classification_betas": $classification_betas, "classification_n_classes": $classification_n_classes, "classification_positive_class": $classification_positive_class, "compute_classification_metrics": $compute_classification_metrics, "learning_rate_multiplier": $learning_rate_multiplier, "model": $model, "n_epochs": $n_epochs, "prompt_loss_weight": $prompt_loss_weight, "suffix": $suffix, "training_file": $training_file, "validation_file": $validation_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets info about the fine-tune job. [Learn more about Fine-tuning](/docs/guides/fine-tuning)
#
# GET /fine-tunes/{fine_tune_id}
# operationId: retrieveFineTune
export def "fine-tunes get" [
  fine_tune_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fine_tune_id | is-empty) { error make --unspanned { msg: "path parameter 'fine_tune_id' must be non-empty" } }
  let full_url = (build-url $base ({fine_tune_id: (encode-path-segment $fine_tune_id)} | format pattern "/fine-tunes/{fine_tune_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Immediately cancel a fine-tune job.
#
# POST /fine-tunes/{fine_tune_id}/cancel
# operationId: cancelFineTune
export def "fine-tunes-cancel cancel" [
  fine_tune_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: int, events: table<created_at: int, level: string, message: string, object: string>, fine_tuned_model: string, hyperparams: record, id: string, model: string, object: string, organization_id: string, result_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, status: string, training_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>, updated_at: int, validation_files: table<bytes: int, created_at: int, filename: string, id: string, object: string, purpose: string, status: string, status_details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fine_tune_id | is-empty) { error make --unspanned { msg: "path parameter 'fine_tune_id' must be non-empty" } }
  let full_url = (build-url $base ({fine_tune_id: (encode-path-segment $fine_tune_id)} | format pattern "/fine-tunes/{fine_tune_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get fine-grained status updates for a fine-tune job.
#
# GET /fine-tunes/{fine_tune_id}/events
# operationId: listFineTuneEvents
export def "fine-tunes-events list" [
  fine_tune_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # Whether to stream events for the fine-tune job. If set to true, events will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available. The stream will terminate with a `data: [DONE]` message when the job is finished (succeeded, cancelled, or failed). If set to false, only events generated so far will be returned. (default: false)
]: nothing -> record<data: table<created_at: int, level: string, message: string, object: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($fine_tune_id | is-empty) { error make --unspanned { msg: "path parameter 'fine_tune_id' must be non-empty" } }
  let qp = [(serialize-qp "stream" $stream "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fine_tune_id: (encode-path-segment $fine_tune_id)} | format pattern "/fine-tunes/{fine_tune_id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"stream": $stream} | compact), body: null}
}

# Creates an edited or extended image given an original image and a prompt.
#
# POST /images/edits
# operationId: createImageEdit
export def "images-edits create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # The image to edit. Must be a valid PNG file, less than 4MB, and square. If mask is not provided, image must have transparency, which will be used as the mask. (format: binary)
  --mask: string # An additional image whose fully transparent areas (e.g. where alpha is zero) indicate where `image` should be edited. Must be a valid PNG file, less than 4MB, and have the same dimensions as `image`. (format: binary)
  --n: int # The number of images to generate. Must be between 1 and 10. (nullable, default: 1, e.g. 1)
  prompt: string # A text description of the desired image(s). The maximum length is 1000 characters. (e.g. A cute baby sea otter wearing a beret)
  --response-format: string@response-format-completer # The format in which the generated images are returned. Must be one of `url` or `b64_json`. (nullable, default: url, e.g. url)
  --size: string@size-completer # The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024`. (nullable, default: 1024x1024, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<created: int, data: table<b64_json: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/edits")
  let req_body = {"image": $image, "mask": $mask, "n": $n, "prompt": $prompt, "response_format": $response_format, "size": $size, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image" "mask"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Creates an image given a prompt.
#
# POST /images/generations
# operationId: createImage
export def "images-generations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --n: int # The number of images to generate. Must be between 1 and 10. (nullable, default: 1, e.g. 1)
  prompt: string # A text description of the desired image(s). The maximum length is 1000 characters. (e.g. A cute baby sea otter)
  --response-format: string@response-format-completer # The format in which the generated images are returned. Must be one of `url` or `b64_json`. (nullable, default: url, e.g. url)
  --size: string@size-completer # The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024`. (nullable, default: 1024x1024, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<created: int, data: table<b64_json: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/generations")
  let req_body = {"n": $n, "prompt": $prompt, "response_format": $response_format, "size": $size, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a variation of a given image.
#
# POST /images/variations
# operationId: createImageVariation
export def "images-variations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # The image to use as the basis for the variation(s). Must be a valid PNG file, less than 4MB, and square. (format: binary)
  --n: int # The number of images to generate. Must be between 1 and 10. (nullable, default: 1, e.g. 1)
  --response-format: string@response-format-completer # The format in which the generated images are returned. Must be one of `url` or `b64_json`. (nullable, default: url, e.g. url)
  --size: string@size-completer # The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024`. (nullable, default: 1024x1024, e.g. 1024x1024)
  --user: string # A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](/docs/guides/safety-best-practices/end-user-ids). (e.g. user-1234)
]: any -> record<created: int, data: table<b64_json: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/variations")
  let req_body = {"image": $image, "n": $n, "response_format": $response_format, "size": $size, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Lists the currently available models, and provides basic information about each one such as the owner and availability.
#
# GET /models
# operationId: listModels
export def "models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: int, id: string, object: string, owned_by: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a fine-tuned model. You must have the Owner role in your organization.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deleted: bool, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($model | is-empty) { error make --unspanned { msg: "path parameter 'model' must be non-empty" } }
  let full_url = (build-url $base ({model: (encode-path-segment $model)} | format pattern "/models/{model}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a model instance, providing basic information about the model such as the owner and permissioning.
#
# GET /models/{model}
# operationId: retrieveModel
export def "models get" [
  model: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: int, id: string, object: string, owned_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($model | is-empty) { error make --unspanned { msg: "path parameter 'model' must be non-empty" } }
  let full_url = (build-url $base ({model: (encode-path-segment $model)} | format pattern "/models/{model}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Classifies if text violates OpenAI's Content Policy
#
# POST /moderations
# operationId: createModeration
export def "moderations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: any # The input text to classify
  --model: string # Two content moderations models are available: `text-moderation-stable` and `text-moderation-latest`. The default is `text-moderation-latest` which will be automatically upgraded over time. This ensures you are always using our most accurate model. If you use `text-moderation-stable`, we will provide advanced notice before updating the model. Accuracy of `text-moderation-stable` may be slightly lower than for `text-moderation-latest`. (default: text-moderation-latest, e.g. text-moderation-stable)
]: any -> record<id: string, model: string, results: table<categories: record, category_scores: record, flagged: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderations")
  let req_body = {"input": $input, "model": $model} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
