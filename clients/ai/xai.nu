# Auto-generated client for xAI's REST API v1.0.0
# Source: https://docs.x.ai/openapi.json
# Auth: --token flag or $env.XAI_S_REST_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o XAI_S_REST_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["original" "text"] }
def order-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-key request" } } | get name | first)
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

# Get information about an API key, including name, status, permissions and users who created or modified this key.
#
# GET /v1/api-key
# operationId: handle_get_api_key_info_request
export def "api-key request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acls: list<string>, api_key_blocked: bool, api_key_disabled: bool, api_key_id: string, create_time: string, modified_by: string, modify_time: string, name: string, redacted_api_key: string, team_blocked: bool, team_id: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/api-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a chat response from text/image chat prompts. This is the endpoint for making requests to chat and image understanding models.
#
# POST /v1/chat/completions
# operationId: handle_generic_completion_request
export def "chat-completions request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deferred: string@bool-completer # If set to `true`, the request returns a `request_id`. You can then get the deferred response by GET `/v1/chat/deferred-completion/{request_id}`. (nullable, default: false)
  --frequency-penalty: float # (Not supported by reasoning models) Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. (nullable, format: float, default: 0)
  --logit-bias: record # (Unsupported) A JSON object that maps tokens (specified by their token ID in the tokenizer) to an associated bias value from -100 to 100. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. (nullable)
  --logprobs: string@bool-completer # Whether to return log probabilities of the output tokens or not. If true, returns the log probabilities of each output token returned in the content of message. Not supported by models `grok-4.20` and newer; the field will be silently ignored if set. (nullable, default: false)
  --max-completion-tokens: int # An upper bound for the number of tokens that can be generated for a completion, only applies to visible output tokens (i.e. does not apply to tokens used for reasoning or function calls). Defaults to None, meaning the model will generate as many tokens as needed up until the model's maximum context length. (nullable, format: int32, e.g. 8192)
  --max-tokens: int # \[DEPRECATED\] The maximum number of tokens that can be generated in the chat completion. Deprecated in favor of `max_completion_tokens`. (nullable, format: int32, e.g. 8192)
  --messages: list # A list of messages that make up the chat conversation. Different models support different message types, such as image and text.
  --model: string # Model name for the model to use. Obtainable from <https://console.x.ai/team/default/models> or <https://docs.x.ai/docs/models>. (e.g. latest)
  --n: int # How many chat completion choices to generate for each input message. Note that you will be charged based on the number of generated tokens across all of the choices. Keep n as 1 to minimize costs. (nullable, format: int32, default: 1, e.g. 1)
  --parallel-tool-calls: string@bool-completer # If set to false, the model can perform maximum one tool call. (nullable, default: true, e.g. false)
  --presence-penalty: float # (Not supported by `grok-3` and reasoning models) Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. (nullable, format: float, default: 0)
  --prompt-cache-key: string # A stable cache key for best-effort sticky routing / prompt-cache hits across requests sharing a prompt prefix. Plumbed to `x-grok-conv-id`, same as on `/v1/responses`. (nullable)
  --reasoning-effort: string # Constrains how hard a reasoning model thinks before responding. Only supported by `grok-4.3`. Possible values are `none` (disables reasoning completely), `low` (this is the default if not specified), `medium` and `high` (uses the most reasoning tokens). (nullable)
  --response-format: any
  --search-parameters: any
  --seed: int # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same `seed` and parameters should return the same result. Determinism is not guaranteed, and you should refer to the `system_fingerprint` response parameter to monitor changes in the backend. (nullable, format: int32)
  --service-tier: any
  --stop: list # (Not supported by reasoning models) Up to 4 sequences where the API will stop generating further tokens. (nullable)
  --stream: string@bool-completer # If set, partial message deltas will be sent. Tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a `data: [DONE]` message. (nullable, default: false, e.g. true)
  --stream-options: any
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. (nullable, format: float, default: 1, e.g. 0.2)
  --tool-choice: any
  --tools: list # A list of tools the model may call in JSON-schema. Currently, only functions are supported as a tool. Use this to provide a list of functions the model may generate JSON inputs for. A max of 128 functions are supported. (nullable)
  --top-logprobs: int # An integer between 0 and 8 specifying the number of most likely tokens to return at each token position, each with an associated log probability. logprobs must be set to true if this parameter is used. Not supported by models `grok-4.20` and newer; the field will be silently ignored if set. (nullable, format: int32)
  --top-p: float # An alternative to sampling with `temperature`, called nucleus sampling, where the model considers the results of the tokens with `top_p` probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. It is generally recommended to alter this or `temperature` but not both. (nullable, format: float, default: 1)
  --user: string # A unique identifier representing your end-user, which can help xAI to monitor and detect abuse. (nullable)
  --web-search-options: any
]: any -> record<choices: table<finish_reason: string, index: int, logprobs: any, message: record>, citations: list<string>, created: int, id: string, model: string, object: string, output_files: table<file_id: string, name: string>, service_tier: string, system_fingerprint: string, usage: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chat/completions")
  let body = {deferred: $deferred, frequency_penalty: $frequency_penalty, logit_bias: $logit_bias, logprobs: $logprobs, max_completion_tokens: $max_completion_tokens, max_tokens: $max_tokens, messages: $messages, model: $model, n: $n, parallel_tool_calls: $parallel_tool_calls, presence_penalty: $presence_penalty, prompt_cache_key: $prompt_cache_key, reasoning_effort: $reasoning_effort, response_format: $response_format, search_parameters: $search_parameters, seed: $seed, service_tier: $service_tier, stop: $stop, stream: $stream, stream_options: $stream_options, temperature: $temperature, tool_choice: $tool_choice, tools: $tools, top_logprobs: $top_logprobs, top_p: $top_p, user: $user, web_search_options: $web_search_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Tries to fetch a result for a previously-started deferred completion. Returns `200 Success` with the response body, if the request has been completed. Returns `202 Accepted` when the request is pending processing.
#
# GET /v1/chat/deferred-completion/{request_id}
# operationId: handle_get_deferred_completion_request
export def "chat-deferred-completion request" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<choices: table<finish_reason: string, index: int, logprobs: any, message: record>, citations: list<string>, created: int, id: string, model: string, object: string, output_files: table<file_id: string, name: string>, service_tier: string, system_fingerprint: string, usage: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/chat/deferred-completion/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# (Legacy - Not supported by reasoning models) Create a text completion response. This endpoint is compatible with the Anthropic API.
#
# POST /v1/complete
# operationId: handle_generic_complete_request
export def "complete request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-tokens-to-sample: int # The maximum number of tokens to generate before stopping. (format: int32)
  --metadata: any
  --model: string # Model to use for completion.
  --prompt: string # Prompt for the model to perform completion on.
  --stop-sequences: list # (Not supported by reasoning models) Up to 4 sequences where the API will stop generating further tokens. (nullable)
  --stream: string@bool-completer # (Unsupported) If set, partial message deltas will be sent. Tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a `data: [DONE]` message. (nullable)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. (nullable, format: float, default: 1, e.g. 0.2)
  --top-k: int # (Unsupported) When generating next tokens, randomly selecting the next token from the k most likely options. (nullable, format: int32)
  --top-p: float # An alternative to sampling with `temperature`, called nucleus sampling, where the model considers the results of the tokens with `top_p` probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. It is generally recommended to alter this or `temperature` but not both. (nullable, format: float, default: 1)
]: any -> record<completion: string, id: string, model: string, stop_reason: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/complete")
  let body = {max_tokens_to_sample: $max_tokens_to_sample, metadata: $metadata, model: $model, prompt: $prompt, stop_sequences: $stop_sequences, stream: $stream, temperature: $temperature, top_k: $top_k, top_p: $top_p} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# (Legacy - Not supported by reasoning models) Create a text completion response for a given prompt. Replaced by /v1/chat/completions.
#
# POST /v1/completions
# operationId: handle_sample_request
export def "completions request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --best-of: int # (Unsupported) Generates multiple completions internally and returns the top-scoring one. Not functional yet. (nullable, format: int32)
  --echo: string@bool-completer # Option to include the original prompt in the response along with the generated completion. (nullable)
  --frequency-penalty: float # (Unsupported) Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. (nullable, format: float)
  --logit-bias: record # (Unsupported) Accepts a JSON object that maps tokens to an associated bias value from -100 to 100. You can use this tokenizer tool to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token. (nullable)
  --logprobs: string@bool-completer # Include the log probabilities on the `logprobs` most likely output tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the logprob of the sampled token, so there may be up to `logprobs+1` elements in the response. Not supported by models `grok-4.20` and newer; the field will be silently ignored if set. (nullable)
  --max-tokens: int # Limits the number of tokens that can be produced in the output. Ensure the sum of prompt tokens and `max_tokens` does not exceed the model's context limit. (nullable, format: int32)
  --model: string # Specifies the model to be used for the request.
  --n: int # Determines how many completion sequences to produce for each prompt. Be cautious with its use due to high token consumption; adjust `max_tokens` and stop sequences accordingly. (nullable, format: int32)
  --presence-penalty: float # (Not supported by `grok-3` and reasoning models) Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. (nullable, format: float)
  --prompt: any
  --seed: int # If specified, our system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result. Determinism is not guaranteed, and you should refer to the system_fingerprint response parameter to monitor changes in the backend. (nullable, format: int32)
  --stop: list # (Not supported by reasoning models) Up to 4 sequences where the API will stop generating further tokens. (nullable)
  --stream: string@bool-completer # Whether to stream back partial progress. If set, tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a `data: [DONE]` message. (nullable)
  --stream-options: any
  --suffix: string # (Unsupported) Optional string to append after the generated text. (nullable)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. (nullable, format: float, default: 1, e.g. 0.2)
  --top-p: float # An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with `top_p` probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or temperature but not both. (nullable, format: float)
  --user: string # A unique identifier representing your end-user, which can help xAI to monitor and detect abuse. (nullable)
]: any -> record<choices: table<finish_reason: string, index: int, text: string>, created: int, id: string, model: string, object: string, system_fingerprint: string, usage: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/completions")
  let body = {best_of: $best_of, echo: $echo, frequency_penalty: $frequency_penalty, logit_bias: $logit_bias, logprobs: $logprobs, max_tokens: $max_tokens, model: $model, n: $n, presence_penalty: $presence_penalty, prompt: $prompt, seed: $seed, stop: $stop, stream: $stream, stream_options: $stream_options, suffix: $suffix, temperature: $temperature, top_p: $top_p, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for content related to the query within the given collections.
#
# POST /v1/documents/search
# operationId: handle_document_search_request_v2
# --source shape: {collection_ids: list, rag_pipeline?: any}
export def "documents-search v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Optional metadata filter string to apply to search results. Uses AIP-160 filter syntax for querying document metadata. Supports comparison operators: `=`, `!=`, `>`, `>=`, `<`, `<=` Supports logical operators: `AND`, `OR` Supports range syntax: `field:10..20` (inclusive) Examples: `author = "John"` or `year > 2020 AND category = "finance"` (nullable)
  --group-by: any
  --instructions: string # User-defined instructions to be included in the search query. Defaults to generic search instructions. (nullable)
  --limit: int # The number of chunks to return. Will always return the top matching chunks. Optional, defaults to 10. (nullable, format: int32)
  --body-query: string # The query to search for which will be embedded using the same embedding model as the one used for the source to query.
  --ranking-metric: any
  --retrieval-mode: any
  --body-source: record # DocumentsSource defines the source of documents to search over. — shape: {collection_ids: list, rag_pipeline?: any}
]: any -> record<matches: table<chunk_content: string, chunk_id: string, collection_ids: list, fields: record, file_id: string, page_number: int, score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/documents/search")
  let body = {filter: $filter, group_by: $group_by, instructions: $instructions, limit: $limit, query: $body_query, ranking_metric: $ranking_metric, retrieval_mode: $retrieval_mode, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all embedding models available to the authenticating API key with full information. Additional information compared to /v1/models includes modalities, fingerprint and alias(es).
#
# GET /v1/embedding-models
# operationId: handle_embedding_models_list_request
export def "embedding-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<models: table<aliases: list, created: int, fingerprint: string, id: string, input_modalities: list, object: string, output_modalities: list, owned_by: string, prompt_image_token_price: int, prompt_text_token_price: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embedding-models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get full information about an embedding model with its model_id.
#
# GET /v1/embedding-models/{model_id}
# operationId: handle_embedding_model_get_request
export def "embedding-models request" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: list<string>, created: int, fingerprint: string, id: string, input_modalities: list<string>, object: string, output_modalities: list<string>, owned_by: string, prompt_image_token_price: int, prompt_text_token_price: int, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/embedding-models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an embedding vector representation corresponding to the input text. This is the endpoint for making requests to embedding models.
#
# POST /v1/embeddings
# operationId: handle_embedding_request
export def "embeddings request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dimensions: int # The number of dimensions the resulting output embeddings should have. (nullable, format: int32)
  --encoding-format: string # The format to return the embeddings in. Can be either `float` or `base64`. (nullable)
  --input: any
  --model: string # ID of the model to use. (e.g. v1)
  --preview: string@bool-completer # Flag to use the new format of the API. (nullable)
  --user: string # A unique identifier representing your end-user, which can help xAI to monitor and detect abuse. (nullable)
]: any -> record<data: table<embedding: any, index: int, object: string>, model: string, object: string, usage: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embeddings")
  let body = {dimensions: $dimensions, encoding_format: $encoding_format, input: $input, model: $model, preview: $preview, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List files owned by the authenticated team, paginated. The response always returns a `pagination_token`; pass it back as a query parameter to fetch the next page. The end of the list is reached when the returned `data` array is shorter than `limit`.
#
# GET /v1/files
# operationId: handle_list_files_request
export def "files request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to be returned in a single response. (format: int32)
  --order: string # The ordering to sort the returned files. Use `asc` for ascending and `desc` for descending order.
  --sort-by: string # The field to sort by. Valid options: `created_at`, `filename`, `size`. Defaults to `created_at`.
  --pagination-token: string # The pagination token returned by the previous list files request.
  --after: string # Only included for compatibility. Use `pagination_token` instead.
  --filter: string # AIP-160 filter expression to narrow down results.  **Filterable fields:**  | Field | Type | Description | |-------|------|-------------| | `name` (or `file_name`) | string | Fuzzy match on filename | | `file_id` | string | Exact match on file ID | | `size_bytes` | integer | File size in bytes | | `content_type` | string | Partial match on MIME type (e.g. `"pdf"` matches `"application/pdf"`) | | `created_at` | timestamp | RFC 3339 timestamp (e.g. `"2024-01-01T00:00:00Z"`) | | `expires_at` | timestamp | RFC 3339 timestamp | | `upload_status` | string | Upload status (`"Complete"`) | | `user_defined_id` | string | Exact match on user-defined ID |  **Operators:** `=`, `!=`, `>`, `>=`, `<`, `<=`  **Logical:** `AND`, `OR`, `NOT`  **Examples:** - `name:"quarterly report"` — fuzzy match on filename - `content_type = "pdf"` — files with PDF content type - `size_bytes > 1000000 AND created_at > "2024-01-01T00:00:00Z"` — files larger than 1 MB created after Jan 1, 2024 - `file_id = "file_abc123"` — exact file ID match
]: nothing -> record<data: table<bytes: int, created_at: int, expires_at: int, filename: string, id: string, object: string, public_url: string, public_url_expires_at: int, purpose: string>, pagination_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "pagination_token" $pagination_token "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file to xAI's storage. Returns the file's metadata. Files can be referenced by ID anywhere a `file_id` is accepted (e.g. chat attachments). Maximum file size: 50 MB. Files are kept until you delete them, or until `expires_after` elapses if set at upload time.
#
# POST /v1/files
# operationId: handle_upload_file_request
export def "files request-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-after: int # Optional TTL in seconds (measured from upload time). Must be between 3600 (1 hour) and 2592000 (30 days). If unset the file does not expire.  Accepts either a plain integer or the OpenAI SDK deepObject form (`expires_after[anchor]=created_at` + `expires_after[seconds]=N`) as separate multipart fields. The anchor+seconds form must arrive before the `file` part. (nullable, format: int64)
  file: string # The file to upload. The filename from the multipart `Content-Disposition: filename=` header is recorded as the file's `filename`. (format: binary)
  --purpose: string # Optional purpose label, accepted for OpenAI SDK compatibility. xAI does not enforce or interpret this field. Setting `"assistants"` is the conventional choice. (nullable)
]: any -> record<bytes: int, created_at: int, expires_at: int, filename: string, id: string, object: string, public_url: string, public_url_expires_at: int, purpose: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/files")
  let body = {expires_after: $expires_after, file: $file, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve metadata for a single file by ID. Errors with 404 if the file doesn't exist, has been deleted, or has passed its `expires_at`.
#
# GET /v1/files/{file_id}
# operationId: handle_retrieve_file_request
export def "files request-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<bytes: int, created_at: int, expires_at: int, filename: string, id: string, object: string, public_url: string, public_url_expires_at: int, purpose: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a file by ID. After this returns, the file no longer appears in `GET /v1/files`, content download returns 404, and the ID can no longer be referenced in chat attachments.
#
# DELETE /v1/files/{file_id}
# operationId: handle_delete_file_request
export def "files request-by-file_id-1" [
  file_id: string
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
  let full_url = (build-url $base $"/v1/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download the contents of a file as a stream of raw bytes. The response `Content-Type` is `application/octet-stream`. Use this for the binary payload; use `GET /v1/files/{file_id}` for metadata only.
#
# GET /v1/files/{file_id}/content
# operationId: handle_download_file_content_request
export def "files-content request" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format of the downloaded content.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/files/($file_id)/content" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a permanent, unauthenticated public URL for an existing file. The underlying file is unaffected and can still be fetched through the authenticated content endpoint. Use this when you want to share a stored asset (image, video, PDF) outside your API-keyed environment. Public URLs can be revoked at any time via `POST /v1/files/{file_id}/public-url/revoke`.
#
# POST /v1/files/{file_id}/public-url
# operationId: handle_create_public_url_request
export def "files-public-url request" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-after: int # Seconds from now until the public URL expires. Must be between `3600` (1 hour) and `2592000` (30 days). Omit to inherit the file's expiry (if it has one) or to make the URL valid indefinitely. (nullable, format: int64)
]: any -> record<expires_at: int, public_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)/public-url")
  let body = {expires_after: $expires_after} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke the active public URL for a file. The underlying file remains available through the authenticated content endpoint. Revoke is idempotent — calling it on a file without an active public URL returns `revoked: false` without an error.
#
# POST /v1/files/{file_id}/public-url/revoke
# operationId: handle_revoke_public_url_request
export def "files-public-url-revoke request" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, public_url: string, revoked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)/public-url/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all image generation models available to the authenticating API key with full information. Additional information compared to /v1/models includes modalities, fingerprint and alias(es).
#
# GET /v1/image-generation-models
# operationId: handle_image_generation_models_list_request
export def "image-generation-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<models: table<aliases: list, created: int, fingerprint: string, id: string, image_price: int, input_modalities: list, max_prompt_length: int, object: string, output_modalities: list, owned_by: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/image-generation-models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get full information about an image generation model with its model_id.
#
# GET /v1/image-generation-models/{model_id}
# operationId: handle_image_generation_model_get_request
export def "image-generation-models request" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: list<string>, created: int, fingerprint: string, id: string, image_price: int, input_modalities: list<string>, max_prompt_length: int, object: string, output_modalities: list<string>, owned_by: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/image-generation-models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an image based on a prompt. This is the endpoint for making edit requests to image generation models.
#
# POST /v1/images/edits
# operationId: handle_edit_image_request
# --images item shape: {file_id?: string, url?: string}
export def "images-edits request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aspect-ratio: any
  --image: any
  --images: list # List of input images for multi-reference editing. Mutually exclusive with `image`. When multiple images are provided, refer to them as \<IMAGE_0\>, \<IMAGE_1\>, etc. in the prompt. — item shape: {file_id?: string, url?: string}
  --model: string # Model to be used. (nullable, e.g. grok-imagine-image)
  --n: int # Number of image edits to be generated. (nullable, format: int32)
  prompt: string # Prompt for image editing.
  --resolution: any
  --response-format: string # Response format to return the image in. Can be `url` or `b64_json`. If `b64_json` is specified, the image will be returned as a base64-encoded string instead of a url to the generated image file. (nullable, default: url)
  --storage-options: any
  --user: string # A unique identifier representing your end-user, which can help xAI to monitor and detect abuse. (nullable)
]: any -> record<data: table<b64_json: string, file_output: any, mime_type: string, storage_error: string, url: string>, usage: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/images/edits")
  let body = {aspect_ratio: $aspect_ratio, image: $image, images: $images, model: $model, n: $n, prompt: $prompt, resolution: $resolution, response_format: $response_format, storage_options: $storage_options, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate an image based on a prompt. This is the endpoint for making generation requests to image generation models.
#
# POST /v1/images/generations
# operationId: handle_generate_image_request
export def "images-generations request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aspect-ratio: any
  --model: string # Model to be used. (nullable, e.g. grok-imagine-image)
  --n: int # Number of images to be generated (nullable, format: int32, default: 1)
  --prompt: string # Prompt for image generation.
  --resolution: any
  --response-format: string # Response format to return the image in. Can be url or b64_json. If b64_json is specified, the image will be returned as a base64-encoded string instead of a url to the generated image file. (nullable, default: url)
  --storage-options: any
  --user: string # A unique identifier representing your end-user, which can help xAI to monitor and detect abuse. (nullable)
]: any -> record<data: table<b64_json: string, file_output: any, mime_type: string, storage_error: string, url: string>, usage: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/images/generations")
  let body = {aspect_ratio: $aspect_ratio, model: $model, n: $n, prompt: $prompt, resolution: $resolution, response_format: $response_format, storage_options: $storage_options, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all chat and image understanding models available to the authenticating API key with full information. Additional information compared to /v1/models includes modalities, fingerprint and alias(es).
#
# GET /v1/language-models
# operationId: handle_language_models_list_request
export def "language-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<models: table<aliases: list, cached_prompt_text_token_price: int, cached_prompt_text_token_price_long_context: int, completion_text_token_price: int, completion_text_token_price_long_context: int, created: int, fingerprint: string, id: string, input_modalities: list, long_context_threshold: int, object: string, output_modalities: list, owned_by: string, prompt_image_token_price: int, prompt_text_token_price: int, prompt_text_token_price_long_context: int, search_price: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/language-models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get full information about a chat or image understanding model with its model_id.
#
# GET /v1/language-models/{model_id}
# operationId: handle_language_model_get_request
export def "language-models request" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: list<string>, cached_prompt_text_token_price: int, cached_prompt_text_token_price_long_context: int, completion_text_token_price: int, completion_text_token_price_long_context: int, created: int, fingerprint: string, id: string, input_modalities: list<string>, long_context_threshold: int, object: string, output_modalities: list<string>, owned_by: string, prompt_image_token_price: int, prompt_text_token_price: int, prompt_text_token_price_long_context: int, search_price: int, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/language-models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about the currently authenticated caller. Works with both API keys and OAuth tokens. Returns identity, team, and ZDR status.
#
# GET /v1/me
# operationId: handle_get_me_request
export def "me request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_key: any, oauth: any, team_blocked: bool, team_id: string, user_id: string, zdr_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a messages response. This endpoint is compatible with the Anthropic API.
#
# POST /v1/messages
# operationId: handle_generic_messages_request
# --messages item shape: {content: any, role: string}
# --tools item shape: {cache_control?: any, description: string, input_schema: record, name: string}
export def "messages request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-tokens: int # The maximum number of tokens to generate before stopping. The model may stop before the max_tokens when it reaches the stop sequence. (format: int32)
  --messages: list # Input messages. — item shape: {content: any, role: string}
  --metadata: any
  --model: string # Model name for the model to use. (e.g. latest)
  --stop-sequences: list # (Not supported by reasoning models) Up to 4 sequences where the API will stop generating further tokens. (nullable)
  --stream: string@bool-completer # If set, partial message deltas will be sent. Tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a `data: [DONE]` message. (nullable)
  --system: any
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. It may not work well with reasoning models. (nullable, format: float, default: 1)
  --tool-choice: any
  --tools: list # A list of tools the model may call in JSON-schema. Currently, only functions are supported as a tool. Use this to provide a list of functions the model may generate JSON inputs for. A max of 128 functions are supported. (nullable) — item shape: {cache_control?: any, description: string, input_schema: record, name: string}
  --top-k: int # (Unsupported) When generating next tokens, randomly selecting the next token from the k most likely options. (nullable, format: int32)
  --top-p: float # An alternative to sampling with `temperature`, called nucleus sampling, where the model considers the results of the tokens with `top_p` probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. It is generally recommended to alter this or `temperature` but not both. (nullable, format: float, default: 1)
]: any -> record<content: list<any>, id: string, model: string, role: string, stop_reason: string, stop_sequence: string, type: string, usage: record<cache_creation_input_tokens: int, cache_read_input_tokens: int, input_tokens: int, output_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages")
  let body = {max_tokens: $max_tokens, messages: $messages, metadata: $metadata, model: $model, stop_sequences: $stop_sequences, stream: $stream, system: $system, temperature: $temperature, tool_choice: $tool_choice, tools: $tools, top_k: $top_k, top_p: $top_p} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all models available to the authenticating API key, including model names (ID), creation times, and pricing.
#
# GET /v1/models
# operationId: handle_models_list_request
export def "models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<cached_prompt_text_token_price: int, cached_prompt_text_token_price_long_context: int, completion_text_token_price: int, completion_text_token_price_long_context: int, created: int, id: string, image_price: int, long_context_threshold: int, object: string, owned_by: string, prompt_image_token_price: int, prompt_text_token_price: int, prompt_text_token_price_long_context: int>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get information about a model with its model_id, including pricing.
#
# GET /v1/models/{model_id}
# operationId: handle_model_get_request
export def "models request" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cached_prompt_text_token_price: int, cached_prompt_text_token_price_long_context: int, completion_text_token_price: int, completion_text_token_price_long_context: int, created: int, id: string, image_price: int, long_context_threshold: int, object: string, owned_by: string, prompt_image_token_price: int, prompt_text_token_price: int, prompt_text_token_price_long_context: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generates a response based on text or image prompts. The response ID can be used to retrieve the response later or to continue the conversation without repeating prior context. New responses will be stored for 30 days and then permanently deleted.
#
# POST /v1/responses
# operationId: handle_generic_model_request
export def "responses request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --background: string@bool-completer # (Unsupported) Whether to process the response asynchronously in the background. (nullable, default: false)
  --context-management: list # Optional context-management directives (e.g. compaction). Parsed but not yet executed. (nullable)
  --include: list # What additional output data to include in the response. Currently the only supported value is `reasoning.encrypted_content` which returns an encrypted version of the reasoning tokens. (nullable)
  input: any # Content of the input passed to a `/v1/response` request.
  --instructions: string # An alternate way to specify the system prompt. Note that this cannot be used alongside `previous_response_id`, where the system prompt of the previous message will be used. (nullable)
  --logprobs: string@bool-completer # Whether to return log probabilities of the output tokens or not. If true, returns the log probabilities of each output token returned in the content of message. Not supported by models `grok-4.20` and newer; the field will be silently ignored if set. (nullable, default: false)
  --max-output-tokens: int # Max number of tokens that can be generated in a response. This includes both output and reasoning tokens. (nullable, format: int32)
  --max-turns: int # Maximum number of agentic tool calling turns allowed for this request. If not set, defaults to the server's global cap. This parameter will be ignored for any non-agentic requests. (nullable, format: int32)
  --metadata: any # Not supported. Only maintained for compatibility reasons.
  --model: string # Model name for the model to use. Obtainable from <https://console.x.ai/team/default/models> or <https://docs.x.ai/docs/models>. (e.g. latest)
  --parallel-tool-calls: string@bool-completer # Whether to allow the model to run parallel tool calls. (nullable, default: true)
  --previous-response-id: string # The ID of the previous response from the model. (nullable)
  --prompt-cache-key: string # Plumbed to x-grok-conv-id for Open Responses compatibility, used for routing. (nullable)
  --reasoning: any
  --search-parameters: any
  --service-tier: any
  --store: string@bool-completer # Whether to store the input message(s) and model response for later retrieval. (nullable, default: true)
  --stream: string@bool-completer # If set, partial message deltas will be sent. Tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a `data: [DONE]` message. (nullable, default: false, e.g. true)
  --temperature: float # What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. (nullable, format: float, default: 1, e.g. 0.2)
  --text: any
  --tool-choice: any
  --tools: list # A list of tools the model may call in JSON-schema. Currently, only functions and web search are supported as tools. A max of 128 tools are supported.`web_search_preview` tool, if specified, will be overridden by `search_parameters`. (nullable)
  --top-logprobs: int # An integer between 0 and 8 specifying the number of most likely tokens to return at each token position, each with an associated log probability. logprobs must be set to true if this parameter is used. Not supported by models `grok-4.20` and newer; the field will be silently ignored if set. (nullable, format: int32)
  --top-p: float # An alternative to sampling with `temperature`, called nucleus sampling, where the model considers the results of the tokens with `top_p` probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. It is generally recommended to alter this or `temperature` but not both. (nullable, format: float, default: 1)
  --truncation: string # Not supported. Only maintained for compatibility reasons. (nullable)
  --user: string # A unique identifier representing your end-user, which can help xAI to monitor and detect abuse. (nullable)
]: any -> record<background: bool, completed_at: int, created_at: int, error: any, frequency_penalty: float, id: string, incomplete_details: any, instructions: string, max_output_tokens: int, max_tool_calls: int, metadata: any, model: string, object: string, output: list<any>, parallel_tool_calls: bool, presence_penalty: float, previous_response_id: string, prompt_cache_key: string, reasoning: any, safety_identifier: string, service_tier: any, status: string, store: bool, temperature: float, text: record<format: any>, tool_choice: any, tools: list<any>, top_logprobs: int, top_p: float, truncation: string, usage: any, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/responses")
  let body = {background: $background, context_management: $context_management, include: $include, input: $input, instructions: $instructions, logprobs: $logprobs, max_output_tokens: $max_output_tokens, max_turns: $max_turns, metadata: $metadata, model: $model, parallel_tool_calls: $parallel_tool_calls, previous_response_id: $previous_response_id, prompt_cache_key: $prompt_cache_key, reasoning: $reasoning, search_parameters: $search_parameters, service_tier: $service_tier, store: $store, stream: $stream, temperature: $temperature, text: $text, tool_choice: $tool_choice, tools: $tools, top_logprobs: $top_logprobs, top_p: $top_p, truncation: $truncation, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compacts a full Responses API input window into a shorter canonical window.
#
# POST /v1/responses/compact
# operationId: handle_compact_request
export def "responses-compact request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  input: any # Content of the input passed to a `/v1/response` request.
  model: string # Model to use for compaction summarization (required).
]: any -> record<created_at: int, id: string, model: string, object: string, output: list<any>, usage: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/responses/compact")
  let body = {input: $input, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a previously generated response.
#
# GET /v1/responses/{response_id}
# operationId: handle_get_stored_completion_request
export def "responses request-by-response_id" [
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<background: bool, completed_at: int, created_at: int, error: any, frequency_penalty: float, id: string, incomplete_details: any, instructions: string, max_output_tokens: int, max_tool_calls: int, metadata: any, model: string, object: string, output: list<any>, parallel_tool_calls: bool, presence_penalty: float, previous_response_id: string, prompt_cache_key: string, reasoning: any, safety_identifier: string, service_tier: any, status: string, store: bool, temperature: float, text: record<format: any>, tool_choice: any, tools: list<any>, top_logprobs: int, top_p: float, truncation: string, usage: any, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/responses/($response_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a previously generated response.
#
# DELETE /v1/responses/{response_id}
# operationId: handle_delete_stored_completion_request
export def "responses request-by-response_id-1" [
  response_id: string
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
  let full_url = (build-url $base $"/v1/responses/($response_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List input items for a previously generated response.
#
# GET /v1/responses/{response_id}/input_items
# operationId: handle_list_input_items
export def "responses-input-items items" [
  response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return (1-100, default 20). (format: int32)
  --order: string@order-completer # Sort order: asc or desc. Default asc.
  --after: string # Cursor for pagination. Returns items after this item ID.
]: nothing -> record<data: table<id: string>, first_id: string, has_more: bool, last_id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/responses/($response_id)/input_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/skills
#
# operationId: handle_list_skills_request
export def "skills request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of objects to be returned in a single response. (format: int32)
  --after: string # Identifier for the last item from the previous pagination request.
  --order: string # Sort order. Use `asc` for ascending and `desc` for descending order.
]: nothing -> record<data: table<created_at: int, default_version: string, description: string, id: string, latest_version: string, name: string, object: string>, first_id: string, has_more: bool, last_id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/skills" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/skills
#
# operationId: handle_upload_skill_request
export def "skills request-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  files: list # Skill zip file or one file from a directory upload. Clients may send this field once with a zip file, or repeatedly with directory files.
]: any -> record<created_at: int, default_version: string, description: string, id: string, latest_version: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/skills")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# GET /v1/skills/{skill_id}
#
# operationId: handle_retrieve_skill_request
export def "skills request-by-skill_id" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: int, default_version: string, description: string, id: string, latest_version: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/skills/($skill_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/skills/{skill_id}
#
# operationId: handle_delete_skill_request
export def "skills request-by-skill_id-1" [
  skill_id: string
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
  let full_url = (build-url $base $"/v1/skills/($skill_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/skills/{skill_id}/content
#
# operationId: handle_download_skill_content_request
export def "skills-content request" [
  skill_id: string
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
  let full_url = (build-url $base $"/v1/skills/($skill_id)/content")
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tokenize text with the specified model
#
# POST /v1/tokenize-text
# operationId: handle_tokenize_text_request
export def "tokenize-text request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string # The model to tokenize with.
  --text: string # The text content to be tokenized.
  --user: string # Optional user identifier. (nullable)
]: any -> record<token_ids: table<string_token: string, token_bytes: list, token_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokenize-text")
  let body = {model: $model, text: $text, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all video generation models available to the authenticating API key with full information.
#
# GET /v1/video-generation-models
# operationId: handle_video_generation_models_list_request
export def "video-generation-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<models: table<aliases: list, created: int, fingerprint: string, id: string, input_modalities: list, object: string, output_modalities: list, owned_by: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/video-generation-models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get full information about a video generation model with its model_id.
#
# GET /v1/video-generation-models/{model_id}
# operationId: handle_video_generation_model_get_request
export def "video-generation-models request" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: list<string>, created: int, fingerprint: string, id: string, input_modalities: list<string>, object: string, output_modalities: list<string>, owned_by: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/video-generation-models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a video based on a prompt. This is an asynchronous operation that returns a request_id for polling.
#
# POST /v1/videos/edits
# operationId: handle_edit_video_request
# --video shape: {file_id?: string, url?: string}
export def "videos-edits request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model: string # Model to be used. (nullable, e.g. grok-imagine-video)
  --output: any
  prompt: string # Prompt for video editing.
  --storage-options: any
  --user: string # A unique identifier representing your end-user. (nullable)
  video: record # Video input for editing and extension requests. Accepts a public URL, a base64-encoded data URL, or a file_id from the xAI Files API. — shape: {file_id?: string, url?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/videos/edits")
  let body = {model: $model, output: $output, prompt: $prompt, storage_options: $storage_options, user: $user, video: $video} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Extend a video by generating continuation content. This is an asynchronous operation that returns a request_id for polling.
#
# POST /v1/videos/extensions
# operationId: handle_extend_video_request
# --video shape: {file_id?: string, url?: string}
export def "videos-extensions request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --duration: int # Duration of the extension segment to generate in seconds (1-10). Defaults to 6 seconds if not specified. (nullable, format: int32)
  --model: string # Model to be used. (nullable, e.g. grok-imagine-video)
  --output: any
  prompt: string # Prompt describing what should happen next in the video.
  --storage-options: any
  video: record # Video input for editing and extension requests. Accepts a public URL, a base64-encoded data URL, or a file_id from the xAI Files API. — shape: {file_id?: string, url?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/videos/extensions")
  let body = {duration: $duration, model: $model, output: $output, prompt: $prompt, storage_options: $storage_options, video: $video} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a video from a text prompt and optionally an image. This is an asynchronous operation that returns a request_id for polling.
#
# POST /v1/videos/generations
# operationId: handle_generate_video_request
# --reference_images item shape: {file_id?: string, url?: string}
export def "videos-generations request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aspect-ratio: any
  --duration: int # Video duration in seconds. Range: [1, 15]. Default: 8. Also accepts `seconds` for OpenAI API compatibility. Accepts both number (8) and string ("8") values. (nullable, format: int32, default: 8)
  --image: any
  --model: string # Model to be used. (nullable, e.g. grok-imagine-video)
  --output: any
  --prompt: string # Prompt for video generation. Required for text-to-video (T2V) and reference-to-video (R2V). Optional for image-to-video (I2V) — when omitted, the model generates a video from the image alone.
  --reference-images: list # Optional reference images for reference-to-video (R2V) generation. When provided generates video using these images as style/content references. — item shape: {file_id?: string, url?: string}
  --resolution: any
  --storage-options: any
  --user: string # A unique identifier representing your end-user. (nullable)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/videos/generations")
  let body = {aspect_ratio: $aspect_ratio, duration: $duration, image: $image, model: $model, output: $output, prompt: $prompt, reference_images: $reference_images, resolution: $resolution, storage_options: $storage_options, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the result of a deferred video generation request.
#
# GET /v1/videos/{request_id}
# operationId: handle_get_deferred_video_request
export def "videos request" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: any, model: string, progress: int, status: string, usage: any, video: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/videos/($request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
