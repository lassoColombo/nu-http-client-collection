# Auto-generated client for Anthropic API v0.0.0
# Source: https://storage.googleapis.com/stainless-sdk-openapi-specs/anthropic/anthropic-5ce93251152bd7c4c288dacdf5a445383825ba50bc472ff9e9821ee9455e3564.yml
# Auth: --token flag or $env.ANTHROPIC_API_TOKEN

const BASE_URL = "https://api.anthropic.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ANTHROPIC_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.anthropic.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def service-tier-completer [] { ["auto" "standard_only"] }
def view-completer [] { ["basic" "full"] }
def order-completer [] { ["asc" "desc"] }
def operation-completer [] { ["created" "deleted" "modified"] }
def type-completer [] { ["file"] }
def status-completer [] { ["active" "paused"] }
def trigger-type-completer [] { ["manual" "schedule"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "messages post" } } | get name | first)
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

# Create a Message
#
# POST /v1/messages
# operationId: messages_post
# --messages item shape: {content: any, role: "user"|"assistant"|"system"}
# --metadata shape: {user_id?: any}
# --output_config shape: {effort?: any, format?: any}
@deprecated --flag temperature
@deprecated --flag top-k
@deprecated --flag top-p
export def "messages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  model: any # The model that will complete your prompt.  See [models](https://docs.anthropic.com/en/docs/models-overview) for additional details and options.
  messages: list # Input messages.  Our models are trained to operate on alternating `user` and `assistant` conversational turns. When creating a new `Message`, you specify the prior conversational turns with the `messages` parameter, and the model then generates the next `Message` in the conversation. Consecutive `user` or `assistant` turns in your request will be combined into a single turn.  Each input message must be an object with a `role` and `content`. You can specify a single `user`-role message, or you can include multiple `user` and `assistant` messages.  If the final message uses the `assistant` role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.  Example with a single `user` message:  ```json [{"role": "user", "content": "Hello, Claude"}] ```  Example with multiple conversational turns:  ```json [   {"role": "user", "content": "Hello there."},   {"role": "assistant", "content": "Hi, I'm Claude. How can I help you?"},   {"role": "user", "content": "Can you explain LLMs in plain English?"}, ] ```  Example with a partially-filled response from Claude:  ```json [   {"role": "user", "content": "What's the Greek name for Sun? (A) Sol (B) Helios (C) Sun"},   {"role": "assistant", "content": "The best answer is ("}, ] ```  Each input message `content` may be either a single `string` or an array of content blocks, where each block has a specific `type`. Using a `string` for `content` is shorthand for an array of one content block of type `"text"`. The following input messages are equivalent:  ```json {"role": "user", "content": "Hello, Claude"} ```  ```json {"role": "user", "content": [{"type": "text", "text": "Hello, Claude"}]} ```  See [input examples](https://docs.claude.com/en/api/messages-examples).  Note that if you want to include a [system prompt](https://docs.claude.com/en/docs/system-prompts), you can use the top-level `system` parameter — there is no `"system"` role for input messages in the Messages API.  There is a limit of 100,000 messages in a single request. — item shape: {content: any, role: "user"|"assistant"|"system"}
  --cache-control: any # Top-level cache control automatically applies a cache_control marker to the last cacheable block in the request.
  --container: any # Container identifier for reuse across requests.
  --inference-geo: any # Specifies the geographic region for inference processing. If not specified, the workspace's `default_inference_geo` is used.
  max_tokens: int # The maximum number of tokens to generate before stopping.  Note that our models may stop _before_ reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.  Set to `0` to populate the [prompt cache](https://docs.claude.com/en/docs/build-with-claude/prompt-caching#pre-warming-the-cache) without generating a response.  Different models have different maximum values for this parameter.  See [models](https://docs.claude.com/en/docs/models-overview) for details.
  --metadata: record # shape: {user_id?: any}
  --output-config: record # shape: {effort?: any, format?: any}
  --service-tier: string@service-tier-completer # Determines whether to use priority capacity (if available) or standard capacity for this request.  Anthropic offers different levels of service for your API requests. See [service-tiers](https://docs.claude.com/en/api/service-tiers) for details.
  --stop-sequences: list # Custom text sequences that will cause the model to stop generating.  Our models will normally stop when they have naturally completed their turn, which will result in a response `stop_reason` of `"end_turn"`.  If you want the model to stop generating when it encounters custom strings of text, you can use the `stop_sequences` parameter. If the model encounters one of the custom sequences, the response `stop_reason` value will be `"stop_sequence"` and the response `stop_sequence` value will contain the matched stop sequence.
  --stream: string@bool-completer # Whether to incrementally stream the response using server-sent events.  See [streaming](https://docs.claude.com/en/api/messages-streaming) for details.
  --system: any # System prompt.  A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.claude.com/en/docs/system-prompts).
  --temperature: float # Amount of randomness injected into the response.  Defaults to `1.0`. Ranges from `0.0` to `1.0`. Use `temperature` closer to `0.0` for analytical / multiple choice, and closer to `1.0` for creative and generative tasks.  Note that even with `temperature` of `0.0`, the results will not be fully deterministic. (DEPRECATED)
  --thinking: any # Configuration for enabling Claude's extended thinking.  When enabled, responses include `thinking` content blocks showing Claude's thinking process before the final answer. Requires a minimum budget of 1,024 tokens and counts towards your `max_tokens` limit.  See [extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) for details.
  --tool-choice: any # How the model should use the provided tools. The model can use a specific tool, any available tool, decide by itself, or not use tools at all.
  --tools: list # Definitions of tools that the model may use.  If you include `tools` in your API request, the model may return `tool_use` content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using `tool_result` content blocks.  There are two types of tools: **client tools** and **server tools**. The behavior described below applies to client tools. For [server tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview#server-tools), see their individual documentation as each has its own behavior (e.g., the [web search tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-search-tool)).  Each tool definition includes:  * `name`: Name of the tool. * `description`: Optional, but strongly-recommended description of the tool. * `input_schema`: [JSON schema](https://json-schema.org/draft/2020-12) for the tool `input` shape that the model will produce in `tool_use` output content blocks.  For example, if you defined `tools` as:  ```json [   {     "name": "get_stock_price",     "description": "Get the current stock price for a given ticker symbol.",     "input_schema": {       "type": "object",       "properties": {         "ticker": {           "type": "string",           "description": "The stock ticker symbol, e.g. AAPL for Apple Inc."         }       },       "required": ["ticker"]     }   } ] ```  And then asked the model "What's the S&P 500 at today?", the model might produce `tool_use` content blocks in the response like this:  ```json [   {     "type": "tool_use",     "id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "name": "get_stock_price",     "input": { "ticker": "^GSPC" }   } ] ```  You might then run your `get_stock_price` tool with `{"ticker": "^GSPC"}` as an input, and return the following back to the model in a subsequent `user` message:  ```json [   {     "type": "tool_result",     "tool_use_id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "content": "259.75 USD"   } ] ```  Tools can be used for workflows that include running client-side tools and functions, or more generally whenever you want the model to produce a particular JSON structure of output.  See our [guide](https://docs.claude.com/en/docs/tool-use) for more details.
  --top-k: int # Only sample from the top K options for each subsequent token.  Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).  Recommended for advanced use cases only. (DEPRECATED)
  --top-p: float # Use nucleus sampling.  In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by `top_p`.  Recommended for advanced use cases only. (DEPRECATED)
]: any -> record<id: string, type: string, role: string, content: list<any>, model: any, stop_reason: any, stop_sequence: any, stop_details: any, usage: record<cache_creation: any, cache_creation_input_tokens: any, cache_read_input_tokens: any, inference_geo: any, input_tokens: int, output_tokens: int, output_tokens_details: any, server_tool_use: any, service_tier: any>, container: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages")
  let body = {model: $model, messages: $messages, cache_control: $cache_control, container: $container, inference_geo: $inference_geo, max_tokens: $max_tokens, metadata: $metadata, output_config: $output_config, service_tier: $service_tier, stop_sequences: $stop_sequences, stream: $stream, system: $system, temperature: $temperature, thinking: $thinking, tool_choice: $tool_choice, tools: $tools, top_k: $top_k, top_p: $top_p} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Text Completion
#
# POST /v1/complete
# operationId: complete_post
# --metadata shape: {user_id?: any}
@deprecated --flag temperature
@deprecated --flag top-p
@deprecated --flag top-k
export def "complete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  model: any # The model that will complete your prompt.  See [models](https://docs.anthropic.com/en/docs/models-overview) for additional details and options.
  prompt: string # The prompt that you want Claude to complete.  For proper response generation you will need to format your prompt using alternating `\n\nHuman:` and `\n\nAssistant:` conversational turns. For example:  ``` "\n\nHuman: {userQuestion}\n\nAssistant:" ```  See [prompt validation](https://docs.claude.com/en/api/prompt-validation) and our guide to [prompt design](https://docs.claude.com/en/docs/intro-to-prompting) for more details.
  max_tokens_to_sample: int # The maximum number of tokens to generate before stopping.  Note that our models may stop _before_ reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.
  --stop-sequences: list # Sequences that will cause the model to stop generating.  Our models stop on `"\n\nHuman:"`, and may include additional built-in stop sequences in the future. By providing the stop_sequences parameter, you may include additional strings that will cause the model to stop generating.
  --temperature: float # Amount of randomness injected into the response.  Defaults to `1.0`. Ranges from `0.0` to `1.0`. Use `temperature` closer to `0.0` for analytical / multiple choice, and closer to `1.0` for creative and generative tasks.  Note that even with `temperature` of `0.0`, the results will not be fully deterministic. (DEPRECATED)
  --top-p: float # Use nucleus sampling.  In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by `top_p`.  Recommended for advanced use cases only. (DEPRECATED)
  --top-k: int # Only sample from the top K options for each subsequent token.  Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).  Recommended for advanced use cases only. (DEPRECATED)
  --metadata: record # shape: {user_id?: any}
  --stream: string@bool-completer # Whether to incrementally stream the response using server-sent events.  See [streaming](https://docs.claude.com/en/api/streaming) for details.
]: any -> record<completion: string, id: string, model: any, stop_reason: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/complete")
  let body = {model: $model, prompt: $prompt, max_tokens_to_sample: $max_tokens_to_sample, stop_sequences: $stop_sequences, temperature: $temperature, top_p: $top_p, top_k: $top_k, metadata: $metadata, stream: $stream} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Models
#
# GET /v1/models
# operationId: models_list
export def "models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately before this object.
  --after-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately after this object.
  --limit: int # Number of items to return per page.  Defaults to `20`. Ranges from `1` to `1000`. (default: 20)
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<data: table<capabilities: any, created_at: string, display_name: string, id: string, max_input_tokens: any, max_tokens: any, type: string>, first_id: any, has_more: bool, last_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before_id" $before_id "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/models" $qp)
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Model
#
# GET /v1/models/{model_id}
# operationId: models_get
export def "models get-by-model_id" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<capabilities: any, created_at: string, display_name: string, id: string, max_input_tokens: any, max_tokens: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model_id)")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Message Batch
#
# POST /v1/messages/batches
# operationId: message_batches_post
# --requests item shape: {custom_id: string, params: record}
export def "messages-batches post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  requests: list # List of requests for prompt completion. Each is an individual request to create a Message. — item shape: {custom_id: string, params: record}
]: any -> record<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record<canceled: int, errored: int, expired: int, processing: int, succeeded: int>, results_url: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batches")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Message Batches
#
# GET /v1/messages/batches
# operationId: message_batches_list
export def "messages-batches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately before this object.
  --after-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately after this object.
  --limit: int # Number of items to return per page.  Defaults to `20`. Ranges from `1` to `1000`. (default: 20)
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<data: table<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record, results_url: any, type: string>, first_id: any, has_more: bool, last_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before_id" $before_id "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/messages/batches" $qp)
  let extra_headers = {"anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Message Batch
#
# GET /v1/messages/batches/{message_batch_id}
# operationId: message_batches_retrieve
export def "messages-batches get-by-message_batch_id" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record<canceled: int, errored: int, expired: int, processing: int, succeeded: int>, results_url: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)")
  let extra_headers = {"anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Message Batch
#
# DELETE /v1/messages/batches/{message_batch_id}
# operationId: message_batches_delete
export def "messages-batches delete-by-message_batch_id" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)")
  let extra_headers = {"anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a Message Batch
#
# POST /v1/messages/batches/{message_batch_id}/cancel
# operationId: message_batches_cancel
export def "messages-batches-cancel cancel" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
]: nothing -> record<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record<canceled: int, errored: int, expired: int, processing: int, succeeded: int>, results_url: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)/cancel")
  let extra_headers = {"anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Message Batch results
#
# GET /v1/messages/batches/{message_batch_id}/results
# operationId: message_batches_results
export def "messages-batches-results results" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)/results")
  let extra_headers = {"anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/x-jsonl"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count tokens in a Message
#
# POST /v1/messages/count_tokens
# operationId: messages_count_tokens_post
# --messages item shape: {content: any, role: "user"|"assistant"|"system"}
# --output_config shape: {effort?: any, format?: any}
export def "messages-count-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --cache-control: any # Top-level cache control automatically applies a cache_control marker to the last cacheable block in the request.
  messages: list # Input messages.  Our models are trained to operate on alternating `user` and `assistant` conversational turns. When creating a new `Message`, you specify the prior conversational turns with the `messages` parameter, and the model then generates the next `Message` in the conversation. Consecutive `user` or `assistant` turns in your request will be combined into a single turn.  Each input message must be an object with a `role` and `content`. You can specify a single `user`-role message, or you can include multiple `user` and `assistant` messages.  If the final message uses the `assistant` role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.  Example with a single `user` message:  ```json [{"role": "user", "content": "Hello, Claude"}] ```  Example with multiple conversational turns:  ```json [   {"role": "user", "content": "Hello there."},   {"role": "assistant", "content": "Hi, I'm Claude. How can I help you?"},   {"role": "user", "content": "Can you explain LLMs in plain English?"}, ] ```  Example with a partially-filled response from Claude:  ```json [   {"role": "user", "content": "What's the Greek name for Sun? (A) Sol (B) Helios (C) Sun"},   {"role": "assistant", "content": "The best answer is ("}, ] ```  Each input message `content` may be either a single `string` or an array of content blocks, where each block has a specific `type`. Using a `string` for `content` is shorthand for an array of one content block of type `"text"`. The following input messages are equivalent:  ```json {"role": "user", "content": "Hello, Claude"} ```  ```json {"role": "user", "content": [{"type": "text", "text": "Hello, Claude"}]} ```  See [input examples](https://docs.claude.com/en/api/messages-examples).  Note that if you want to include a [system prompt](https://docs.claude.com/en/docs/system-prompts), you can use the top-level `system` parameter — there is no `"system"` role for input messages in the Messages API.  There is a limit of 100,000 messages in a single request. — item shape: {content: any, role: "user"|"assistant"|"system"}
  model: any # The model that will complete your prompt.  See [models](https://docs.anthropic.com/en/docs/models-overview) for additional details and options.
  --output-config: record # shape: {effort?: any, format?: any}
  --system: any # System prompt.  A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.claude.com/en/docs/system-prompts).
  --thinking: any # Configuration for enabling Claude's extended thinking.  When enabled, responses include `thinking` content blocks showing Claude's thinking process before the final answer. Requires a minimum budget of 1,024 tokens and counts towards your `max_tokens` limit.  See [extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) for details.
  --tool-choice: any # How the model should use the provided tools. The model can use a specific tool, any available tool, decide by itself, or not use tools at all.
  --tools: list # Definitions of tools that the model may use.  If you include `tools` in your API request, the model may return `tool_use` content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using `tool_result` content blocks.  There are two types of tools: **client tools** and **server tools**. The behavior described below applies to client tools. For [server tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview#server-tools), see their individual documentation as each has its own behavior (e.g., the [web search tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-search-tool)).  Each tool definition includes:  * `name`: Name of the tool. * `description`: Optional, but strongly-recommended description of the tool. * `input_schema`: [JSON schema](https://json-schema.org/draft/2020-12) for the tool `input` shape that the model will produce in `tool_use` output content blocks.  For example, if you defined `tools` as:  ```json [   {     "name": "get_stock_price",     "description": "Get the current stock price for a given ticker symbol.",     "input_schema": {       "type": "object",       "properties": {         "ticker": {           "type": "string",           "description": "The stock ticker symbol, e.g. AAPL for Apple Inc."         }       },       "required": ["ticker"]     }   } ] ```  And then asked the model "What's the S&P 500 at today?", the model might produce `tool_use` content blocks in the response like this:  ```json [   {     "type": "tool_use",     "id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "name": "get_stock_price",     "input": { "ticker": "^GSPC" }   } ] ```  You might then run your `get_stock_price` tool with `{"ticker": "^GSPC"}` as an input, and return the following back to the model in a subsequent `user` message:  ```json [   {     "type": "tool_result",     "tool_use_id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "content": "259.75 USD"   } ] ```  Tools can be used for workflows that include running client-side tools and functions, or more generally whenever you want the model to produce a particular JSON structure of output.  See our [guide](https://docs.claude.com/en/docs/tool-use) for more details.
]: any -> record<input_tokens: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/count_tokens")
  let body = {cache_control: $cache_control, messages: $messages, model: $model, output_config: $output_config, system: $system, thinking: $thinking, tool_choice: $tool_choice, tools: $tools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Message
#
# POST /v1/messages?beta=true
# operationId: beta_messages_post
# --messages item shape: {content: any, role: "user"|"assistant"|"system"}
# --mcp_servers item shape: {authorization_token?: any, name: string, tool_configuration?: any, type: string, url: string}
# --metadata shape: {user_id?: any}
# --output_config shape: {effort?: any, format?: any, task_budget?: any}
@deprecated --flag output-format
@deprecated --flag temperature
@deprecated --flag top-k
@deprecated --flag top-p
export def "messages-betatrue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  model: any # The model that will complete your prompt.  See [models](https://docs.anthropic.com/en/docs/models-overview) for additional details and options.
  messages: list # Input messages.  Our models are trained to operate on alternating `user` and `assistant` conversational turns. When creating a new `Message`, you specify the prior conversational turns with the `messages` parameter, and the model then generates the next `Message` in the conversation. Consecutive `user` or `assistant` turns in your request will be combined into a single turn.  Each input message must be an object with a `role` and `content`. You can specify a single `user`-role message, or you can include multiple `user` and `assistant` messages.  If the final message uses the `assistant` role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.  Example with a single `user` message:  ```json [{"role": "user", "content": "Hello, Claude"}] ```  Example with multiple conversational turns:  ```json [   {"role": "user", "content": "Hello there."},   {"role": "assistant", "content": "Hi, I'm Claude. How can I help you?"},   {"role": "user", "content": "Can you explain LLMs in plain English?"}, ] ```  Example with a partially-filled response from Claude:  ```json [   {"role": "user", "content": "What's the Greek name for Sun? (A) Sol (B) Helios (C) Sun"},   {"role": "assistant", "content": "The best answer is ("}, ] ```  Each input message `content` may be either a single `string` or an array of content blocks, where each block has a specific `type`. Using a `string` for `content` is shorthand for an array of one content block of type `"text"`. The following input messages are equivalent:  ```json {"role": "user", "content": "Hello, Claude"} ```  ```json {"role": "user", "content": [{"type": "text", "text": "Hello, Claude"}]} ```  See [input examples](https://docs.claude.com/en/api/messages-examples).  Note that if you want to include a [system prompt](https://docs.claude.com/en/docs/system-prompts), you can use the top-level `system` parameter — there is no `"system"` role for input messages in the Messages API.  There is a limit of 100,000 messages in a single request. — item shape: {content: any, role: "user"|"assistant"|"system"}
  --cache-control: any # Top-level cache control automatically applies a cache_control marker to the last cacheable block in the request.
  --container: any # Container identifier for reuse across requests.
  --context-management: any # Context management configuration.  This allows you to control how Claude manages context across multiple requests, such as whether to clear function results or not.
  --diagnostics: any # Request-level diagnostics. Supply `previous_message_id` to have the response include `diagnostics.cache_miss_reason` explaining any prompt-cache divergence from that prior request.
  --fallback-credit-token: any # The `fallback_credit_token` from a prior refusal's `stop_details`.  When a preceding request was refused and returned a `fallback_credit_token`, pass that code here on the retry to have the retry's cache-creation tokens for the prefix that was warm on the refused model billed at the cache-read rate. Must be redeemed by the same organization and workspace, with the same request body (optionally extended by one appended `assistant` message whose content is the partial text — with any trailing whitespace stripped from the final text block — and paired server-tool blocks streamed before the refusal; the appended-assistant form is not available for requests with `output_format` set or forced `tool_choice`), on an eligible fallback model, on the same platform, and within 5 minutes of the refusal; a mismatch is a 400. A token minted mid-server-tool-loop whose partial content was continuable may only be redeemed with the appended-assistant form — if an exact-body retry is rejected with a 400 saying the token must be redeemed by continuing the partial response, retry with the appended-assistant form instead.  When the appended-assistant form is used on a model that otherwise disallows assistant-turn prefill, this token also authorizes that one prefill.
  --fallbacks: any # Opt-in server-side retry on one or more substitute models when the requested model declines for policy reasons. Tried in order: if the first entry also declines, the second is tried, and so on.
  --inference-geo: any # Specifies the geographic region for inference processing. If not specified, the workspace's `default_inference_geo` is used.
  max_tokens: int # The maximum number of tokens to generate before stopping.  Note that our models may stop _before_ reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.  Set to `0` to populate the [prompt cache](https://docs.claude.com/en/docs/build-with-claude/prompt-caching#pre-warming-the-cache) without generating a response.  Different models have different maximum values for this parameter.  See [models](https://docs.claude.com/en/docs/models-overview) for details.
  --mcp-servers: list # MCP servers to be utilized in this request — item shape: {authorization_token?: any, name: string, tool_configuration?: any, type: string, url: string}
  --metadata: record # shape: {user_id?: any}
  --output-config: record # shape: {effort?: any, format?: any, task_budget?: any}
  --output-format: any # Deprecated: Use `output_config.format` instead. See [structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)  A schema to specify Claude's output format in responses. This parameter will be removed in a future release. (DEPRECATED)
  --service-tier: string@service-tier-completer # Determines whether to use priority capacity (if available) or standard capacity for this request.  Anthropic offers different levels of service for your API requests. See [service-tiers](https://docs.claude.com/en/api/service-tiers) for details.
  --speed: any # The inference speed mode for this request. `"fast"` enables high output-tokens-per-second inference.
  --stop-sequences: list # Custom text sequences that will cause the model to stop generating.  Our models will normally stop when they have naturally completed their turn, which will result in a response `stop_reason` of `"end_turn"`.  If you want the model to stop generating when it encounters custom strings of text, you can use the `stop_sequences` parameter. If the model encounters one of the custom sequences, the response `stop_reason` value will be `"stop_sequence"` and the response `stop_sequence` value will contain the matched stop sequence.
  --stream: string@bool-completer # Whether to incrementally stream the response using server-sent events.  See [streaming](https://docs.claude.com/en/api/messages-streaming) for details.
  --system: any # System prompt.  A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.claude.com/en/docs/system-prompts).
  --temperature: float # Amount of randomness injected into the response.  Defaults to `1.0`. Ranges from `0.0` to `1.0`. Use `temperature` closer to `0.0` for analytical / multiple choice, and closer to `1.0` for creative and generative tasks.  Note that even with `temperature` of `0.0`, the results will not be fully deterministic. (DEPRECATED)
  --thinking: any # Configuration for enabling Claude's extended thinking.  When enabled, responses include `thinking` content blocks showing Claude's thinking process before the final answer. Requires a minimum budget of 1,024 tokens and counts towards your `max_tokens` limit.  See [extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) for details.
  --tool-choice: any # How the model should use the provided tools. The model can use a specific tool, any available tool, decide by itself, or not use tools at all.
  --tools: list # Definitions of tools that the model may use.  If you include `tools` in your API request, the model may return `tool_use` content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using `tool_result` content blocks.  There are two types of tools: **client tools** and **server tools**. The behavior described below applies to client tools. For [server tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview#server-tools), see their individual documentation as each has its own behavior (e.g., the [web search tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-search-tool)).  Each tool definition includes:  * `name`: Name of the tool. * `description`: Optional, but strongly-recommended description of the tool. * `input_schema`: [JSON schema](https://json-schema.org/draft/2020-12) for the tool `input` shape that the model will produce in `tool_use` output content blocks.  For example, if you defined `tools` as:  ```json [   {     "name": "get_stock_price",     "description": "Get the current stock price for a given ticker symbol.",     "input_schema": {       "type": "object",       "properties": {         "ticker": {           "type": "string",           "description": "The stock ticker symbol, e.g. AAPL for Apple Inc."         }       },       "required": ["ticker"]     }   } ] ```  And then asked the model "What's the S&P 500 at today?", the model might produce `tool_use` content blocks in the response like this:  ```json [   {     "type": "tool_use",     "id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "name": "get_stock_price",     "input": { "ticker": "^GSPC" }   } ] ```  You might then run your `get_stock_price` tool with `{"ticker": "^GSPC"}` as an input, and return the following back to the model in a subsequent `user` message:  ```json [   {     "type": "tool_result",     "tool_use_id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "content": "259.75 USD"   } ] ```  Tools can be used for workflows that include running client-side tools and functions, or more generally whenever you want the model to produce a particular JSON structure of output.  See our [guide](https://docs.claude.com/en/docs/tool-use) for more details.
  --top-k: int # Only sample from the top K options for each subsequent token.  Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).  Recommended for advanced use cases only. (DEPRECATED)
  --top-p: float # Use nucleus sampling.  In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by `top_p`.  Recommended for advanced use cases only. (DEPRECATED)
  --user-profile-id: any # The user profile ID to attribute this request to. Use when acting on behalf of a party other than your organization.
]: any -> record<id: string, type: string, role: string, content: list<any>, model: any, stop_reason: any, stop_sequence: any, stop_details: any, usage: record<cache_creation: any, cache_creation_input_tokens: any, cache_read_input_tokens: any, inference_geo: any, input_tokens: int, iterations: any, output_tokens: int, output_tokens_details: any, server_tool_use: any, service_tier: any, speed: any>, diagnostics: any, context_management: any, container: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages?beta=true")
  let body = {model: $model, messages: $messages, cache_control: $cache_control, container: $container, context_management: $context_management, diagnostics: $diagnostics, fallback_credit_token: $fallback_credit_token, fallbacks: $fallbacks, inference_geo: $inference_geo, max_tokens: $max_tokens, mcp_servers: $mcp_servers, metadata: $metadata, output_config: $output_config, output_format: $output_format, service_tier: $service_tier, speed: $speed, stop_sequences: $stop_sequences, stream: $stream, system: $system, temperature: $temperature, thinking: $thinking, tool_choice: $tool_choice, tools: $tools, top_k: $top_k, top_p: $top_p, user_profile_id: $user_profile_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Models
#
# GET /v1/models?beta=true
# operationId: beta_models_list
export def "models-betatrue list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately before this object.
  --after-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately after this object.
  --limit: int # Number of items to return per page.  Defaults to `20`. Ranges from `1` to `1000`. (default: 20)
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<data: table<allowed_fallback_models: any, capabilities: any, created_at: string, display_name: string, id: string, max_input_tokens: any, max_tokens: any, type: string>, first_id: any, has_more: bool, last_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before_id" $before_id "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/models?beta=true" $qp)
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Model
#
# GET /v1/models/{model_id}?beta=true
# operationId: beta_models_get
export def "models get-by-model_id-1" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<allowed_fallback_models: any, capabilities: any, created_at: string, display_name: string, id: string, max_input_tokens: any, max_tokens: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model_id)?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Message Batch
#
# POST /v1/messages/batches?beta=true
# operationId: beta_message_batches_post
# --requests item shape: {custom_id: string, params: record}
export def "messages-batches-betatrue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  requests: list # List of requests for prompt completion. Each is an individual request to create a Message. — item shape: {custom_id: string, params: record}
]: any -> record<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record<canceled: int, errored: int, expired: int, processing: int, succeeded: int>, results_url: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batches?beta=true")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Message Batches
#
# GET /v1/messages/batches?beta=true
# operationId: beta_message_batches_list
export def "messages-batches-betatrue list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately before this object.
  --after-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately after this object.
  --limit: int # Number of items to return per page.  Defaults to `20`. Ranges from `1` to `1000`. (default: 20)
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<data: table<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record, results_url: any, type: string>, first_id: any, has_more: bool, last_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before_id" $before_id "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/messages/batches?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Message Batch
#
# GET /v1/messages/batches/{message_batch_id}?beta=true
# operationId: beta_message_batches_retrieve
export def "messages-batches get-by-message_batch_id-1" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record<canceled: int, errored: int, expired: int, processing: int, succeeded: int>, results_url: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Message Batch
#
# DELETE /v1/messages/batches/{message_batch_id}?beta=true
# operationId: beta_message_batches_delete
export def "messages-batches delete-by-message_batch_id-1" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a Message Batch
#
# POST /v1/messages/batches/{message_batch_id}/cancel?beta=true
# operationId: beta_message_batches_cancel
export def "messages-batches-cancel-betatrue cancel" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
]: nothing -> record<archived_at: any, cancel_initiated_at: any, created_at: string, ended_at: any, expires_at: string, id: string, processing_status: string, request_counts: record<canceled: int, errored: int, expired: int, processing: int, succeeded: int>, results_url: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)/cancel?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Message Batch results
#
# GET /v1/messages/batches/{message_batch_id}/results?beta=true
# operationId: beta_message_batches_results
export def "messages-batches-results-betatrue results" [
  message_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/batches/($message_batch_id)/results?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/x-jsonl"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Count tokens in a Message
#
# POST /v1/messages/count_tokens?beta=true
# operationId: beta_messages_count_tokens_post
# --mcp_servers item shape: {authorization_token?: any, name: string, tool_configuration?: any, type: string, url: string}
# --messages item shape: {content: any, role: "user"|"assistant"|"system"}
# --output_config shape: {effort?: any, format?: any, task_budget?: any}
@deprecated --flag output-format
export def "messages-count-tokens-betatrue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --cache-control: any # Top-level cache control automatically applies a cache_control marker to the last cacheable block in the request.
  --context-management: any # Context management configuration.  This allows you to control how Claude manages context across multiple requests, such as whether to clear function results or not.
  --mcp-servers: list # MCP servers to be utilized in this request — item shape: {authorization_token?: any, name: string, tool_configuration?: any, type: string, url: string}
  messages: list # Input messages.  Our models are trained to operate on alternating `user` and `assistant` conversational turns. When creating a new `Message`, you specify the prior conversational turns with the `messages` parameter, and the model then generates the next `Message` in the conversation. Consecutive `user` or `assistant` turns in your request will be combined into a single turn.  Each input message must be an object with a `role` and `content`. You can specify a single `user`-role message, or you can include multiple `user` and `assistant` messages.  If the final message uses the `assistant` role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.  Example with a single `user` message:  ```json [{"role": "user", "content": "Hello, Claude"}] ```  Example with multiple conversational turns:  ```json [   {"role": "user", "content": "Hello there."},   {"role": "assistant", "content": "Hi, I'm Claude. How can I help you?"},   {"role": "user", "content": "Can you explain LLMs in plain English?"}, ] ```  Example with a partially-filled response from Claude:  ```json [   {"role": "user", "content": "What's the Greek name for Sun? (A) Sol (B) Helios (C) Sun"},   {"role": "assistant", "content": "The best answer is ("}, ] ```  Each input message `content` may be either a single `string` or an array of content blocks, where each block has a specific `type`. Using a `string` for `content` is shorthand for an array of one content block of type `"text"`. The following input messages are equivalent:  ```json {"role": "user", "content": "Hello, Claude"} ```  ```json {"role": "user", "content": [{"type": "text", "text": "Hello, Claude"}]} ```  See [input examples](https://docs.claude.com/en/api/messages-examples).  Note that if you want to include a [system prompt](https://docs.claude.com/en/docs/system-prompts), you can use the top-level `system` parameter — there is no `"system"` role for input messages in the Messages API.  There is a limit of 100,000 messages in a single request. — item shape: {content: any, role: "user"|"assistant"|"system"}
  model: any # The model that will complete your prompt.  See [models](https://docs.anthropic.com/en/docs/models-overview) for additional details and options.
  --output-config: record # shape: {effort?: any, format?: any, task_budget?: any}
  --output-format: any # Deprecated: Use `output_config.format` instead. See [structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)  A schema to specify Claude's output format in responses. This parameter will be removed in a future release. (DEPRECATED)
  --speed: any # The inference speed mode for this request. `"fast"` enables high output-tokens-per-second inference.
  --system: any # System prompt.  A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.claude.com/en/docs/system-prompts).
  --thinking: any # Configuration for enabling Claude's extended thinking.  When enabled, responses include `thinking` content blocks showing Claude's thinking process before the final answer. Requires a minimum budget of 1,024 tokens and counts towards your `max_tokens` limit.  See [extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) for details.
  --tool-choice: any # How the model should use the provided tools. The model can use a specific tool, any available tool, decide by itself, or not use tools at all.
  --tools: list # Definitions of tools that the model may use.  If you include `tools` in your API request, the model may return `tool_use` content blocks that represent the model's use of those tools. You can then run those tools using the tool input generated by the model and then optionally return results back to the model using `tool_result` content blocks.  There are two types of tools: **client tools** and **server tools**. The behavior described below applies to client tools. For [server tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview#server-tools), see their individual documentation as each has its own behavior (e.g., the [web search tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-search-tool)).  Each tool definition includes:  * `name`: Name of the tool. * `description`: Optional, but strongly-recommended description of the tool. * `input_schema`: [JSON schema](https://json-schema.org/draft/2020-12) for the tool `input` shape that the model will produce in `tool_use` output content blocks.  For example, if you defined `tools` as:  ```json [   {     "name": "get_stock_price",     "description": "Get the current stock price for a given ticker symbol.",     "input_schema": {       "type": "object",       "properties": {         "ticker": {           "type": "string",           "description": "The stock ticker symbol, e.g. AAPL for Apple Inc."         }       },       "required": ["ticker"]     }   } ] ```  And then asked the model "What's the S&P 500 at today?", the model might produce `tool_use` content blocks in the response like this:  ```json [   {     "type": "tool_use",     "id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "name": "get_stock_price",     "input": { "ticker": "^GSPC" }   } ] ```  You might then run your `get_stock_price` tool with `{"ticker": "^GSPC"}` as an input, and return the following back to the model in a subsequent `user` message:  ```json [   {     "type": "tool_result",     "tool_use_id": "toolu_01D7FLrfh4GYq7yT1ULFeyMV",     "content": "259.75 USD"   } ] ```  Tools can be used for workflows that include running client-side tools and functions, or more generally whenever you want the model to produce a particular JSON structure of output.  See our [guide](https://docs.claude.com/en/docs/tool-use) for more details.
]: any -> record<context_management: any, input_tokens: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/count_tokens?beta=true")
  let body = {cache_control: $cache_control, context_management: $context_management, mcp_servers: $mcp_servers, messages: $messages, model: $model, output_config: $output_config, output_format: $output_format, speed: $speed, system: $system, thinking: $thinking, tool_choice: $tool_choice, tools: $tools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload File
#
# POST /v1/files?beta=true
# operationId: beta_upload_file_v1_files_post
export def "files-betatrue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  file: string # The file to upload (format: binary)
]: any -> record<created_at: string, downloadable: bool, filename: string, id: string, mime_type: string, scope: any, size_bytes: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/files?beta=true")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Files
#
# GET /v1/files?beta=true
# operationId: beta_list_files_v1_files_get
export def "files-betatrue get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately before this object.
  --after-id: string # ID of the object to use as a cursor for pagination. When provided, returns the page of results immediately after this object.
  --limit: int # Number of items to return per page.  Defaults to `20`. Ranges from `1` to `1000`. (default: 20)
  --scope-id: string # Filter by scope ID. Only returns files associated with the specified scope (e.g., a session ID).
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<data: table<created_at: string, downloadable: bool, filename: string, id: string, mime_type: string, scope: any, size_bytes: int, type: string>, first_id: any, has_more: bool, last_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before_id" $before_id "scalar") (serialize-qp "after_id" $after_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "scope_id" $scope_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/files?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get File Metadata
#
# GET /v1/files/{file_id}?beta=true
# operationId: beta_get_file_metadata_v1_files__file_id__get
export def "files get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<created_at: string, downloadable: bool, filename: string, id: string, mime_type: string, scope: any, size_bytes: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete File
#
# DELETE /v1/files/{file_id}?beta=true
# operationId: beta_delete_file_v1_files__file_id__delete
export def "files delete" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download File
#
# GET /v1/files/{file_id}/content?beta=true
# operationId: beta_download_file_v1_files__file_id__content_get
export def "files-content-betatrue get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)/content?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Skill
#
# POST /v1/skills?beta=true
# operationId: beta_create_skill_v1_skills_post
export def "skills-betatrue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --display-title: any # Display title for the skill.  This is a human-readable label that is not included in the prompt sent to the model.
  --files: any # Files to upload for the skill.  All files must be in the same top-level directory and must include a SKILL.md file at the root of that directory.
]: any -> record<created_at: string, display_title: any, id: string, latest_version: any, source: string, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/skills?beta=true")
  let body = {display_title: $display_title, files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Skills
#
# GET /v1/skills?beta=true
# operationId: beta_list_skills_v1_skills_get
export def "skills-betatrue get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Pagination token for fetching a specific page of results.  Pass the value from a previous response's `next_page` field to get the next page of results.
  --limit: int # Number of results to return per page.  Maximum value is 100. Defaults to 20. (default: 20)
  --qp-source: string # Filter skills by source.  If provided, only skills from the specified source will be returned: * `"custom"`: only return user-created skills * `"anthropic"`: only return Anthropic-created skills
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<data: table<created_at: string, display_title: any, id: string, latest_version: any, source: string, type: string, updated_at: string>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/skills?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Skill
#
# GET /v1/skills/{skill_id}?beta=true
# operationId: beta_get_skill_v1_skills__skill_id__get
export def "skills get" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<created_at: string, display_title: any, id: string, latest_version: any, source: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/skills/($skill_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Skill
#
# DELETE /v1/skills/{skill_id}?beta=true
# operationId: beta_delete_skill_v1_skills__skill_id__delete
export def "skills delete" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/skills/($skill_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Skill Version
#
# POST /v1/skills/{skill_id}/versions?beta=true
# operationId: beta_create_skill_version_v1_skills__skill_id__versions_post
export def "skills-versions-betatrue post" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --files: any # Files to upload for the skill.  All files must be in the same top-level directory and must include a SKILL.md file at the root of that directory.
]: any -> record<created_at: string, description: string, directory: string, id: string, name: string, skill_id: string, type: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/skills/($skill_id)/versions?beta=true")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Skill Versions
#
# GET /v1/skills/{skill_id}/versions?beta=true
# operationId: beta_list_skill_versions_v1_skills__skill_id__versions_get
export def "skills-versions-betatrue get" [
  skill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: string # Optionally set to the `next_page` token from the previous response.
  --limit: string # Number of items to return per page.  Defaults to `20`. Ranges from `1` to `1000`.
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<data: table<created_at: string, description: string, directory: string, id: string, name: string, skill_id: string, type: string, version: string>, has_more: bool, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/skills/($skill_id)/versions?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Skill Version
#
# GET /v1/skills/{skill_id}/versions/{version}?beta=true
# operationId: beta_get_skill_version_v1_skills__skill_id__versions__version__get
export def "skills-versions get" [
  skill_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<created_at: string, description: string, directory: string, id: string, name: string, skill_id: string, type: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/skills/($skill_id)/versions/($version)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Skill Version
#
# DELETE /v1/skills/{skill_id}/versions/{version}?beta=true
# operationId: beta_delete_skill_version_v1_skills__skill_id__versions__version__delete
export def "skills-versions delete" [
  skill_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> record<id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/skills/($skill_id)/versions/($version)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Skill Version Content
#
# GET /v1/skills/{skill_id}/versions/{version}/content?beta=true
# operationId: beta_download_skill_version_content_v1_skills__skill_id__versions__version__content_get
export def "skills-versions-content-betatrue get" [
  skill_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string # Your unique API key for authentication.  This key is required in the header of all API requests, to authenticate your account and access Anthropic's services. Get your API key through the [Console](https://console.anthropic.com/settings/keys). Each key is scoped to a Workspace.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/skills/($skill_id)/versions/($version)/content?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Environment
#
# POST /v1/environments?beta=true
# operationId: beta_create_environment_v1_environments_post
export def "environments-betatrue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --config: any # Environment configuration
  --description: any # Optional description of the environment
  --metadata: record # User-provided metadata key-value pairs
  name: string # Human-readable name for the environment
  --scope: any # The visibility scope for this environment. 'organization' makes the environment visible to all accounts. 'account' restricts visibility to the owning account only. Only applicable for self-hosted environments. If not specified, defaults based on organization type.
]: any -> record<archived_at: any, config: any, created_at: string, description: string, id: string, metadata: record, name: string, scope: string, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environments?beta=true")
  let body = {config: $config, description: $description, metadata: $metadata, name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Environments
#
# GET /v1/environments?beta=true
# operationId: beta_list_environments_v1_environments_get
export def "environments-betatrue get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of environments to return (default: 20)
  --page: string # Opaque cursor from previous response for pagination. Pass the `next_page` value from the previous response.
  --include-archived: string@bool-completer # Include archived environments in the response (default: false)
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string
]: nothing -> record<data: table<archived_at: any, config: any, created_at: string, description: string, id: string, metadata: record, name: string, scope: string, type: string, updated_at: string>, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/environments?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Environment
#
# GET /v1/environments/{environment_id}?beta=true
# operationId: beta_get_environment_v1_environments__environment_id__get
export def "environments get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string
]: nothing -> record<archived_at: any, config: any, created_at: string, description: string, id: string, metadata: record, name: string, scope: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Environment
#
# POST /v1/environments/{environment_id}?beta=true
# operationId: beta_update_environment_v1_environments__environment_id__post
export def "environments post" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --config: any # Updated environment configuration
  --description: any # Updated description of the environment
  --metadata: record # User-provided metadata key-value pairs. Set a value to null or empty string to delete the key.
  --name: any # Updated name for the environment
  --scope: any # The visibility scope for this environment. 'organization' makes the environment visible to all accounts. 'account' restricts visibility to the owning account only.
]: any -> record<archived_at: any, config: any, created_at: string, description: string, id: string, metadata: record, name: string, scope: string, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)?beta=true")
  let body = {config: $config, description: $description, metadata: $metadata, name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Environment
#
# DELETE /v1/environments/{environment_id}?beta=true
# operationId: beta_delete_environment_v1_environments__environment_id__delete
export def "environments delete" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string
]: nothing -> record<id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Environment
#
# POST /v1/environments/{environment_id}/archive?beta=true
# operationId: beta_archive_environment_v1_environments__environment_id__archive_post
export def "environments-archive-betatrue post" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
]: nothing -> record<archived_at: any, config: any, created_at: string, description: string, id: string, metadata: record, name: string, scope: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)/archive?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Queue Statistics
#
# GET /v1/environments/{environment_id}/work/stats?beta=true
# operationId: beta_get_environment_stats_v1_environments__environment_id__work_stats_get
export def "environments-work-stats-betatrue get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string
  --authorization: string
]: nothing -> record<depth: int, oldest_queued_at: any, pending: int, type: string, workers_polling: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work/stats?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Poll for Work
#
# GET /v1/environments/{environment_id}/work/poll?beta=true
# operationId: beta_poll_work_v1_environments__environment_id__work_poll_get
export def "environments-work-poll-betatrue get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --block-ms: string # How long to wait for work to arrive before returning. Must be 1-999 in milliseconds. Defaults to non-blocking (returns immediately if no work is available).
  --reclaim-older-than-ms: string # Reclaim unacknowledged work items older than this many milliseconds. If omitted, uses the default (5000ms).
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --Anthropic-Worker-ID: string # Unique identifier for the specific worker polling, used to track aggregated environment-level work metrics in Console
  --authorization: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "block_ms" $block_ms "scalar") (serialize-qp "reclaim_older_than_ms" $reclaim_older_than_ms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work/poll?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "Anthropic-Worker-ID": $Anthropic_Worker_ID, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Acknowledge Work
#
# POST /v1/environments/{environment_id}/work/{work_id}/ack?beta=true
# operationId: beta_acknowledge_work_v1_environments__environment_id__work__work_id__ack_post
export def "environments-work-ack-betatrue post" [
  environment_id: string
  work_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --authorization: string
]: nothing -> record<acknowledged_at: any, created_at: string, data: record<id: string, type: string>, environment_id: string, id: string, latest_heartbeat_at: any, metadata: record, started_at: any, state: string, stop_requested_at: any, stopped_at: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work/($work_id)/ack?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Record Heartbeat
#
# POST /v1/environments/{environment_id}/work/{work_id}/heartbeat?beta=true
# operationId: beta_record_heartbeat_v1_environments__environment_id__work__work_id__heartbeat_post
export def "environments-work-heartbeat-betatrue post" [
  environment_id: string
  work_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --desired-ttl-seconds: string # Desired TTL in seconds
  --expected-last-heartbeat: string # Expected last_heartbeat for conditional update (optimistic concurrency). Use literal 'NO_HEARTBEAT' to claim an unclaimed lease (first heartbeat). For subsequent heartbeats, echo the server's previous last_heartbeat value exactly. Returns 412 Precondition Failed if the actual value doesn't match.
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --authorization: string
]: nothing -> record<last_heartbeat: string, lease_extended: bool, state: string, ttl_seconds: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "desired_ttl_seconds" $desired_ttl_seconds "scalar") (serialize-qp "expected_last_heartbeat" $expected_last_heartbeat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work/($work_id)/heartbeat?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop Work
#
# POST /v1/environments/{environment_id}/work/{work_id}/stop?beta=true
# operationId: beta_stop_work_v1_environments__environment_id__work__work_id__stop_post
export def "environments-work-stop-betatrue post" [
  environment_id: string
  work_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --authorization: string
  --force: string@bool-completer # If true, immediately stop work without graceful shutdown (default: false)
]: any -> record<acknowledged_at: any, created_at: string, data: record<id: string, type: string>, environment_id: string, id: string, latest_heartbeat_at: any, metadata: record, started_at: any, state: string, stop_requested_at: any, stopped_at: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work/($work_id)/stop?beta=true")
  let body = {force: $force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Work Item
#
# GET /v1/environments/{environment_id}/work/{work_id}?beta=true
# operationId: beta_get_work_v1_environments__environment_id__work__work_id__get
export def "environments-work get" [
  environment_id: string
  work_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --x-api-key: string
]: nothing -> record<acknowledged_at: any, created_at: string, data: record<id: string, type: string>, environment_id: string, id: string, latest_heartbeat_at: any, metadata: record, started_at: any, state: string, stop_requested_at: any, stopped_at: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work/($work_id)?beta=true")
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "x-api-key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Work Item
#
# POST /v1/environments/{environment_id}/work/{work_id}?beta=true
# operationId: beta_update_work_v1_environments__environment_id__work__work_id__post
export def "environments-work post" [
  environment_id: string
  work_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  metadata: record # Metadata patch. Set a key to a string to upsert it, or to null to delete it. Omit the field to preserve existing metadata.
]: any -> record<acknowledged_at: any, created_at: string, data: record<id: string, type: string>, environment_id: string, id: string, latest_heartbeat_at: any, metadata: record, started_at: any, state: string, stop_requested_at: any, stopped_at: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work/($work_id)?beta=true")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Work Items
#
# GET /v1/environments/{environment_id}/work?beta=true
# operationId: beta_list_work_v1_environments__environment_id__work_get
export def "environments-work-betatrue get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of work items to return (default: 20)
  --page: string # Opaque cursor from previous response for pagination
  --anthropic-beta: string # Optional header to specify the beta version(s) you want to use.  To use multiple betas, use a comma separated list like `beta1,beta2` or specify the header multiple times for each beta.
  --anthropic-version: string # The version of the Claude API you want to use.  Read more about versioning and our version history [here](https://docs.claude.com/en/api/versioning).
  --authorization: string
]: nothing -> record<data: table<acknowledged_at: any, created_at: string, data: record, environment_id: string, id: string, latest_heartbeat_at: any, metadata: record, started_at: any, state: string, stop_requested_at: any, stopped_at: any, type: string>, next_page: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/environments/($environment_id)/work?beta=true" $qp)
  let extra_headers = {"anthropic-beta": $anthropic_beta, "anthropic-version": $anthropic_version, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a memory
#
# POST /v1/memory_stores/{memory_store_id}/memories?beta=true
# operationId: BetaCreateMemory
export def "memory-stores-memories-betatrue BetaCreateMemory" [
  memory_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer # Query parameter for view
  --anthropic-version: string
  --anthropic-beta: string
  path: string # Hierarchical path for the new memory, e.g. `/projects/foo/notes.md`. Must start with `/`, contain at least one non-empty segment, and be at most 1,024 bytes. Must not contain empty segments, `.` or `..` segments, control or format characters, and must be NFC-normalized. Paths are case-sensitive.
  --content: string # UTF-8 text content for the new memory. Maximum 100 kB (102,400 bytes). Required; pass `""` explicitly to create an empty memory. (nullable)
]: any -> record<type: string, id: string, memory_store_id: string, path: string, content: string, content_size_bytes: int, content_sha256: string, memory_version_id: string, created_at: record, updated_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memories?beta=true" $qp)
  let body = {path: $path, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List memories
#
# GET /v1/memory_stores/{memory_store_id}/memories?beta=true
# operationId: BetaListMemories
export def "memory-stores-memories-betatrue BetaListMemories" [
  memory_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path-prefix: string # Optional path prefix filter (raw string-prefix match; include a trailing slash for directory-scoped lists). This value appears in request URLs. Do not include secrets or personally identifiable information.
  --depth: int # Query parameter for depth (format: int32)
  --order-by: string # Query parameter for order_by
  --order: string@order-completer # Query parameter for order
  --limit: int # Query parameter for limit (format: int32)
  --page: string # Query parameter for page
  --view: string@view-completer # Query parameter for view
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: list<record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path_prefix" $path_prefix "scalar") (serialize-qp "depth" $depth "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memories?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a memory
#
# GET /v1/memory_stores/{memory_store_id}/memories/{memory_id}?beta=true
# operationId: BetaGetMemory
export def "memory-stores-memories BetaGetMemory" [
  memory_store_id: string
  memory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer # Query parameter for view
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, memory_store_id: string, path: string, content: string, content_size_bytes: int, content_sha256: string, memory_version_id: string, created_at: record, updated_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memories/($memory_id)?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a memory
#
# POST /v1/memory_stores/{memory_store_id}/memories/{memory_id}?beta=true
# operationId: BetaUpdateMemory
export def "memory-stores-memories BetaUpdateMemory" [
  memory_store_id: string
  memory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer # Query parameter for view
  --anthropic-version: string
  --anthropic-beta: string
  --content: string # New UTF-8 text content for the memory. Maximum 100 kB (102,400 bytes). Omit to leave the content unchanged (e.g., for a rename-only update). (nullable)
  --path: string # New path for the memory (a rename). Must start with `/`, contain at least one non-empty segment, and be at most 1,024 bytes. Must not contain empty segments, `.` or `..` segments, control or format characters, and must be NFC-normalized. Paths are case-sensitive. The memory's `id` is preserved across renames. Omit to leave the path unchanged. (nullable)
  --precondition: any # Optional optimistic-concurrency precondition. When supplied, the update applies only if the memory's current state matches; on mismatch the request returns `memory_precondition_failed_error` (HTTP 409). When omitted, the update is unconditional.
]: any -> record<type: string, id: string, memory_store_id: string, path: string, content: string, content_size_bytes: int, content_sha256: string, memory_version_id: string, created_at: record, updated_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memories/($memory_id)?beta=true" $qp)
  let body = {content: $content, path: $path, precondition: $precondition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a memory
#
# DELETE /v1/memory_stores/{memory_store_id}/memories/{memory_id}?beta=true
# operationId: BetaDeleteMemory
export def "memory-stores-memories BetaDeleteMemory" [
  memory_store_id: string
  memory_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expected-content-sha256: string # Query parameter for expected_content_sha256
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expected_content_sha256" $expected_content_sha256 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memories/($memory_id)?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List memory versions
#
# GET /v1/memory_stores/{memory_store_id}/memory_versions?beta=true
# operationId: BetaListMemoryVersions
export def "memory-stores-memory-versions-betatrue BetaListMemoryVersions" [
  memory_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --memory-id: string # Query parameter for memory_id
  --session-id: string # Query parameter for session_id
  --api-key-id: string # Query parameter for api_key_id
  --operation: string@operation-completer # Query parameter for operation
  --created-atgte: string # Return versions created at or after this time (inclusive). (format: date-time)
  --created-atlte: string # Return versions created at or before this time (inclusive). (format: date-time)
  --limit: int # Query parameter for limit (format: int32)
  --page: string # Query parameter for page
  --view: string@view-completer # Query parameter for view
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, memory_store_id: string, memory_id: string, path: string, operation: record, content: string, content_size_bytes: int, content_sha256: string, created_by: record, created_at: record, redacted_at: record, redacted_by: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "memory_id" $memory_id "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "api_key_id" $api_key_id "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "created_at[gte]" $created_atgte "scalar") (serialize-qp "created_at[lte]" $created_atlte "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memory_versions?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a memory version
#
# GET /v1/memory_stores/{memory_store_id}/memory_versions/{memory_version_id}?beta=true
# operationId: BetaGetMemoryVersion
export def "memory-stores-memory-versions BetaGetMemoryVersion" [
  memory_store_id: string
  memory_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer # Query parameter for view
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, memory_store_id: string, memory_id: string, path: string, operation: record, content: string, content_size_bytes: int, content_sha256: string, created_by: record, created_at: record, redacted_at: record, redacted_by: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memory_versions/($memory_version_id)?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redact a memory version
#
# POST /v1/memory_stores/{memory_store_id}/memory_versions/{memory_version_id}/redact?beta=true
# operationId: BetaRedactMemoryVersion
export def "memory-stores-memory-versions-redact-betatrue BetaRedactMemoryVersion" [
  memory_store_id: string
  memory_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, memory_store_id: string, memory_id: string, path: string, operation: record, content: string, content_size_bytes: int, content_sha256: string, created_by: record, created_at: record, redacted_at: record, redacted_by: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/memory_versions/($memory_version_id)/redact?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a memory store
#
# POST /v1/memory_stores?beta=true
# Discriminator (response): type = memory_store
# operationId: BetaCreateMemoryStore
export def "memory-stores-betatrue BetaCreateMemoryStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  name: string # Human-readable name for the store. Required; 1–255 characters; no control characters. The mount-path slug under `/mnt/memory/` is derived from this name (lowercased, non-alphanumeric runs collapsed to a hyphen). Names need not be unique within a workspace.
  --description: string # Free-text description of what the store contains, up to 1024 characters. Included in the agent's system prompt when the store is attached, so word it to be useful to the agent.
  --metadata: record # Arbitrary key-value tags for your own bookkeeping (such as the end user a store belongs to). Up to 16 pairs; keys 1–64 characters; values up to 512 characters. Not visible to the agent.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/memory_stores?beta=true")
  let body = {name: $name, description: $description, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List memory stores
#
# GET /v1/memory_stores?beta=true
# operationId: BetaListMemoryStores
export def "memory-stores-betatrue BetaListMemoryStores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of stores to return per page. Must be between 1 and 100. Defaults to 20 when omitted. (format: int32)
  --page: string # Opaque pagination cursor (a `page_...` value). Pass the `next_page` value from a previous response to fetch the next page; omit for the first page.
  --include-archived: string@bool-completer # When `true`, archived stores are included in the results. Defaults to `false` (archived stores are excluded).
  --created-atgte: string # Return only stores whose `created_at` is at or after this time (inclusive). Sent on the wire as `created_at[gte]`. (format: date-time)
  --created-atlte: string # Return only stores whose `created_at` is at or before this time (inclusive). Sent on the wire as `created_at[lte]`. (format: date-time)
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, name: string, description: string, created_at: record, updated_at: record, metadata: record, archived_at: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "created_at[gte]" $created_atgte "scalar") (serialize-qp "created_at[lte]" $created_atlte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/memory_stores?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a memory store
#
# GET /v1/memory_stores/{memory_store_id}?beta=true
# Discriminator (response): type = memory_store
# operationId: BetaGetMemoryStore
export def "memory-stores BetaGetMemoryStore" [
  memory_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a memory store
#
# POST /v1/memory_stores/{memory_store_id}?beta=true
# Discriminator (response): type = memory_store
# operationId: BetaUpdateMemoryStore
export def "memory-stores BetaUpdateMemoryStore" [
  memory_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --name: string # New human-readable name for the store. 1–255 characters; no control characters. Renaming changes the slug used for the store's `mount_path` in sessions created after the update. (nullable)
  --description: string # New description for the store, up to 1024 characters. Pass an empty string to clear it. (nullable)
  --metadata: record # Metadata patch. Set a key to a string to upsert it, or to null to delete it. Omit the field to preserve. The stored bag is limited to 16 keys (up to 64 chars each) with values up to 512 chars. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)?beta=true")
  let body = {name: $name, description: $description, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a memory store
#
# DELETE /v1/memory_stores/{memory_store_id}?beta=true
# Discriminator (response): type = memory_store_deleted
# operationId: BetaDeleteMemoryStore
export def "memory-stores BetaDeleteMemoryStore" [
  memory_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a memory store
#
# POST /v1/memory_stores/{memory_store_id}/archive?beta=true
# Discriminator (response): type = memory_store
# operationId: BetaArchiveMemoryStore
export def "memory-stores-archive-betatrue BetaArchiveMemoryStore" [
  memory_store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/memory_stores/($memory_store_id)/archive?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Profile
#
# POST /v1/user_profiles?beta=true
# operationId: BetaCreateUserProfile
export def "user-profiles-betatrue BetaCreateUserProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --external-id: string # Platform's own identifier for this user. Not enforced unique. Maximum 255 characters. (nullable)
  --name: string # Display name of the entity this profile represents. Required when relationship is `resold` (the resold-to company's name); optional otherwise. Maximum 255 characters. (nullable)
  --relationship: any # How the entity relates to the platform. `external` (default): an individual end-user. `resold`: a company the platform resells Claude access to. `internal`: the platform's own usage.
  --metadata: record # Free-form key-value data to attach to this user profile. Maximum 16 keys, with keys up to 64 characters and values up to 512 characters. Values must be non-empty strings.
]: any -> record<id: string, type: string, external_id: string, name: string, relationship: record, trust_grants: record, created_at: record, metadata: record, updated_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/user_profiles?beta=true")
  let body = {external_id: $external_id, name: $name, relationship: $relationship, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List User Profiles
#
# GET /v1/user_profiles?beta=true
# operationId: BetaListUserProfiles
export def "user-profiles-betatrue BetaListUserProfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Query parameter for limit (format: int32)
  --page: string # Query parameter for page
  --order: string@order-completer # Query parameter for order
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<id: string, type: string, external_id: string, name: string, relationship: record, trust_grants: record, created_at: record, metadata: record, updated_at: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/user_profiles?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Profile
#
# GET /v1/user_profiles/{user_profile_id}?beta=true
# operationId: BetaGetUserProfile
export def "user-profiles BetaGetUserProfile" [
  user_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<id: string, type: string, external_id: string, name: string, relationship: record, trust_grants: record, created_at: record, metadata: record, updated_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/user_profiles/($user_profile_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Profile
#
# POST /v1/user_profiles/{user_profile_id}?beta=true
# operationId: BetaUpdateUserProfile
export def "user-profiles BetaUpdateUserProfile" [
  user_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --external-id: string # If present, replaces the stored external_id. Omit to leave unchanged. Maximum 255 characters. (nullable)
  --metadata: record # Key-value pairs to merge into the stored metadata. Keys provided overwrite existing values. To remove a key, set its value to an empty string. Keys not provided are left unchanged. Maximum 16 keys, with keys up to 64 characters and values up to 512 characters.
  --name: string # If present, replaces the stored name. Omit to leave unchanged. Maximum 255 characters. (nullable)
  --relationship: any # If present, replaces the stored relationship. Omit to leave unchanged. (nullable)
]: any -> record<id: string, type: string, external_id: string, name: string, relationship: record, trust_grants: record, created_at: record, metadata: record, updated_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/user_profiles/($user_profile_id)?beta=true")
  let body = {external_id: $external_id, metadata: $metadata, name: $name, relationship: $relationship} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Enrollment URL
#
# POST /v1/user_profiles/{user_profile_id}/enrollment_url?beta=true
# operationId: BetaCreateEnrollmentUrl
export def "user-profiles-enrollment-url-betatrue BetaCreateEnrollmentUrl" [
  user_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<url: string, expires_at: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/user_profiles/($user_profile_id)/enrollment_url?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Session
#
# POST /v1/sessions?beta=true
# operationId: BetaCreateSession
export def "sessions-betatrue BetaCreateSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  agent: any # Agent identifier. Accepts the `agent` ID string, which pins the latest version for the session, or an `agent` object with both id and version specified.
  environment_id: string # ID of the `environment` defining the container configuration for this session.
  --title: string # Human-readable session title. (nullable)
  --metadata: record # Arbitrary key-value metadata attached to the session. Maximum 16 pairs, keys up to 64 chars, values up to 512 chars.
  --resources: list # Resources (e.g. repositories, files) to mount into the session's container.
  --vault-ids: list # Vault IDs for stored credentials the agent can use during the session.
]: any -> record<type: string, id: string, status: string, created_at: string, updated_at: string, environment_id: string, title: string, metadata: record, agent: record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, multiagent: record>, resources: list<record>, vault_ids: list<string>, outcome_evaluations: table<type: string, outcome_id: string, description: string, result: string, iteration: int, completed_at: record, explanation: string>, usage: record<input_tokens: int, output_tokens: int, cache_read_input_tokens: int, cache_creation: record<ephemeral_1h_input_tokens: int, ephemeral_5m_input_tokens: int>>, stats: record<duration_seconds: float, active_seconds: float>, archived_at: record, deployment_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sessions?beta=true")
  let body = {agent: $agent, environment_id: $environment_id, title: $title, metadata: $metadata, resources: $resources, vault_ids: $vault_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Sessions
#
# GET /v1/sessions?beta=true
# operationId: BetaListSessions
export def "sessions-betatrue BetaListSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return. (format: int32)
  --page: string # Opaque pagination cursor from a previous response.
  --include-archived: string@bool-completer # When true, includes archived sessions. Default: false (exclude archived).
  --created-atgte: string # Return sessions created at or after this time (inclusive). (format: date-time)
  --created-atgt: string # Return sessions created after this time (exclusive). (format: date-time)
  --created-atlte: string # Return sessions created at or before this time (inclusive). (format: date-time)
  --created-atlt: string # Return sessions created before this time (exclusive). (format: date-time)
  --agent-id: string # Filter sessions created with this agent ID.
  --agent-version: int # Filter by agent version. Only applies when agent_id is also set. (format: int32)
  --order: string@order-completer # Sort direction for results, ordered by created_at. Defaults to desc (newest first).
  --memory-store-id: string # Filter sessions whose resources contain a memory_store with this memory store ID.
  --deployment-id: string # Filter sessions created by this deployment ID.
  --statuses: list # Filter by session status. Repeat the parameter to match any of multiple statuses.
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, status: string, created_at: string, updated_at: string, environment_id: string, title: string, metadata: record, agent: record, resources: list, vault_ids: list, outcome_evaluations: list, usage: record, stats: record, archived_at: record, deployment_id: string>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "created_at[gte]" $created_atgte "scalar") (serialize-qp "created_at[gt]" $created_atgt "scalar") (serialize-qp "created_at[lte]" $created_atlte "scalar") (serialize-qp "created_at[lt]" $created_atlt "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "agent_version" $agent_version "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "memory_store_id" $memory_store_id "scalar") (serialize-qp "deployment_id" $deployment_id "scalar") (serialize-qp "statuses[]" $statuses "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sessions?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Session
#
# GET /v1/sessions/{session_id}?beta=true
# operationId: BetaGetSession
export def "sessions BetaGetSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, status: string, created_at: string, updated_at: string, environment_id: string, title: string, metadata: record, agent: record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, multiagent: record>, resources: list<record>, vault_ids: list<string>, outcome_evaluations: table<type: string, outcome_id: string, description: string, result: string, iteration: int, completed_at: record, explanation: string>, usage: record<input_tokens: int, output_tokens: int, cache_read_input_tokens: int, cache_creation: record<ephemeral_1h_input_tokens: int, ephemeral_5m_input_tokens: int>>, stats: record<duration_seconds: float, active_seconds: float>, archived_at: record, deployment_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Session
#
# POST /v1/sessions/{session_id}?beta=true
# operationId: BetaUpdateSession
export def "sessions BetaUpdateSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --title: string # Human-readable session title. (nullable)
  --metadata: record # Metadata patch. Set a key to a string to upsert it, or to null to delete it. Omit the field to preserve. (nullable)
  --vault-ids: list # Vault IDs (`vlt_*`) to attach to the session. Not yet supported; requests setting this field are rejected. Reserved for future use.
  --agent: any # Agent configuration update. Only `tools` and `mcp_servers` are updatable mid-session. Only valid for sessions created from an agent or deployment reference. The session must not be running.
]: any -> record<type: string, id: string, status: string, created_at: string, updated_at: string, environment_id: string, title: string, metadata: record, agent: record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, multiagent: record>, resources: list<record>, vault_ids: list<string>, outcome_evaluations: table<type: string, outcome_id: string, description: string, result: string, iteration: int, completed_at: record, explanation: string>, usage: record<input_tokens: int, output_tokens: int, cache_read_input_tokens: int, cache_creation: record<ephemeral_1h_input_tokens: int, ephemeral_5m_input_tokens: int>>, stats: record<duration_seconds: float, active_seconds: float>, archived_at: record, deployment_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)?beta=true")
  let body = {title: $title, metadata: $metadata, vault_ids: $vault_ids, agent: $agent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Session
#
# DELETE /v1/sessions/{session_id}?beta=true
# operationId: BetaDeleteSession
export def "sessions BetaDeleteSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Events
#
# GET /v1/sessions/{session_id}/events?beta=true
# operationId: BetaListEvents
export def "sessions-events-betatrue BetaListEvents" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Query parameter for limit (format: int32)
  --page: string # Opaque pagination cursor from a previous response's next_page.
  --order: string@order-completer # Sort direction for results, ordered by created_at. Defaults to asc (chronological).
  --types: list # Filter by event type. Values match the `type` field on returned events (for example, `user.message` or `agent.tool_use`). Omit to return all event types.
  --created-atgte: string # Return events created at or after this time (inclusive). (format: date-time)
  --created-atgt: string # Return events created after this time (exclusive). (format: date-time)
  --created-atlte: string # Return events created at or before this time (inclusive). (format: date-time)
  --created-atlt: string # Return events created before this time (exclusive). (format: date-time)
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: list<record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "types[]" $types "multi") (serialize-qp "created_at[gte]" $created_atgte "scalar") (serialize-qp "created_at[gt]" $created_atgt "scalar") (serialize-qp "created_at[lte]" $created_atlte "scalar") (serialize-qp "created_at[lt]" $created_atlt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/sessions/($session_id)/events?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Events
#
# POST /v1/sessions/{session_id}/events?beta=true
# operationId: BetaSendEvents
export def "sessions-events-betatrue BetaSendEvents" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  events: list # Events to send to the `session`.
]: any -> record<data: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/events?beta=true")
  let body = {events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stream Events
#
# GET /v1/sessions/{session_id}/events/stream?beta=true
# Discriminator (response): type = user.message, user.interrupt, user.tool_confirmation, user.custom_tool_result, agent.custom_tool_use, agent.message, agent.thinking, agent.mcp_tool_use, agent.mcp_tool_result, agent.tool_use, agent.tool_result, agent.thread_message_received, agent.thread_message_sent, agent.thread_context_compacted, session.error, session.status_rescheduled, session.status_running, session.status_idle, session.status_terminated, session.thread_created, span.outcome_evaluation_start, span.outcome_evaluation_end, span.model_request_start, span.model_request_end, span.outcome_evaluation_ongoing, user.define_outcome, session.deleted, session.thread_status_running, session.thread_status_idle, session.thread_status_terminated, user.tool_result, session.thread_status_rescheduled, session.updated, system.message
# operationId: BetaStreamSessionEvents
export def "sessions-events-stream-betatrue BetaStreamSessionEvents" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/events/stream?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Session
#
# POST /v1/sessions/{session_id}/archive?beta=true
# operationId: BetaArchiveSession
export def "sessions-archive-betatrue BetaArchiveSession" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, status: string, created_at: string, updated_at: string, environment_id: string, title: string, metadata: record, agent: record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, multiagent: record>, resources: list<record>, vault_ids: list<string>, outcome_evaluations: table<type: string, outcome_id: string, description: string, result: string, iteration: int, completed_at: record, explanation: string>, usage: record<input_tokens: int, output_tokens: int, cache_read_input_tokens: int, cache_creation: record<ephemeral_1h_input_tokens: int, ephemeral_5m_input_tokens: int>>, stats: record<duration_seconds: float, active_seconds: float>, archived_at: record, deployment_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/archive?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Session Threads
#
# GET /v1/sessions/{session_id}/threads?beta=true
# operationId: BetaListSessionThreads
export def "sessions-threads-betatrue BetaListSessionThreads" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum results per page. Defaults to 1000. (format: int32)
  --page: string # Opaque pagination cursor from a previous response's next_page. Forward-only.
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, session_id: string, status: record, agent: record, parent_thread_id: string, created_at: record, updated_at: record, archived_at: record, usage: record, stats: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/sessions/($session_id)/threads?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Session Thread
#
# GET /v1/sessions/{session_id}/threads/{thread_id}?beta=true
# operationId: BetaGetSessionThread
export def "sessions-threads BetaGetSessionThread" [
  session_id: string
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, session_id: string, status: record, agent: record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>>, parent_thread_id: string, created_at: record, updated_at: record, archived_at: record, usage: record<input_tokens: int, output_tokens: int, cache_read_input_tokens: int, cache_creation: record<ephemeral_1h_input_tokens: int, ephemeral_5m_input_tokens: int>>, stats: record<duration_seconds: float, startup_seconds: float, active_seconds: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/threads/($thread_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Session Thread Events
#
# GET /v1/sessions/{session_id}/threads/{thread_id}/events?beta=true
# operationId: BetaListSessionThreadEvents
export def "sessions-threads-events-betatrue BetaListSessionThreadEvents" [
  session_id: string
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Query parameter for limit (format: int32)
  --page: string # Query parameter for page
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: list<record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/sessions/($session_id)/threads/($thread_id)/events?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stream Session Thread Events
#
# GET /v1/sessions/{session_id}/threads/{thread_id}/stream?beta=true
# Discriminator (response): type = user.message, user.interrupt, user.tool_confirmation, user.custom_tool_result, agent.custom_tool_use, agent.message, agent.thinking, agent.mcp_tool_use, agent.mcp_tool_result, agent.tool_use, agent.tool_result, agent.thread_message_received, agent.thread_message_sent, agent.thread_context_compacted, session.error, session.status_rescheduled, session.status_running, session.status_idle, session.status_terminated, session.thread_created, span.outcome_evaluation_start, span.outcome_evaluation_end, span.model_request_start, span.model_request_end, span.outcome_evaluation_ongoing, user.define_outcome, session.deleted, session.thread_status_running, session.thread_status_idle, session.thread_status_terminated, user.tool_result, session.thread_status_rescheduled, session.updated, system.message
# operationId: BetaStreamSessionThreadEvents
export def "sessions-threads-stream-betatrue BetaStreamSessionThreadEvents" [
  session_id: string
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/threads/($thread_id)/stream?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Session Thread
#
# POST /v1/sessions/{session_id}/threads/{thread_id}/archive?beta=true
# operationId: BetaArchiveSessionThread
export def "sessions-threads-archive-betatrue BetaArchiveSessionThread" [
  session_id: string
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, session_id: string, status: record, agent: record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>>, parent_thread_id: string, created_at: record, updated_at: record, archived_at: record, usage: record<input_tokens: int, output_tokens: int, cache_read_input_tokens: int, cache_creation: record<ephemeral_1h_input_tokens: int, ephemeral_5m_input_tokens: int>>, stats: record<duration_seconds: float, startup_seconds: float, active_seconds: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/threads/($thread_id)/archive?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Session Resources
#
# GET /v1/sessions/{session_id}/resources?beta=true
# operationId: BetaListResources
export def "sessions-resources-betatrue BetaListResources" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of resources to return per page (max 1000). If omitted, returns all resources. (format: int32)
  --page: string # Opaque cursor from a previous response's next_page field.
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: list<record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/sessions/($session_id)/resources?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Session Resource
#
# POST /v1/sessions/{session_id}/resources?beta=true
# Discriminator (request): type = file
# operationId: BetaAddResource
export def "sessions-resources-betatrue BetaAddResource" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  type: string@type-completer
  --file-id: string # ID of a previously uploaded file.
  --mount-path: string # Mount path in the container. Defaults to `/mnt/session/uploads/<file_id>`. (nullable)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/resources?beta=true")
  let body = {type: $type, file_id: $file_id, mount_path: $mount_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Session Resource
#
# GET /v1/sessions/{session_id}/resources/{resource_id}?beta=true
# Discriminator (response): type = github_repository, file, memory_store
# operationId: BetaGetResource
export def "sessions-resources BetaGetResource" [
  session_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/resources/($resource_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Session Resource
#
# DELETE /v1/sessions/{session_id}/resources/{resource_id}?beta=true
# operationId: BetaDeleteResource
export def "sessions-resources BetaDeleteResource" [
  session_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/resources/($resource_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Session Resource
#
# POST /v1/sessions/{session_id}/resources/{resource_id}?beta=true
# Discriminator (response): type = github_repository, file, memory_store
# operationId: BetaUpdateResource
export def "sessions-resources BetaUpdateResource" [
  session_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  authorization_token: string # New authorization token for the resource. Currently only `github_repository` resources support token rotation.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($session_id)/resources/($resource_id)?beta=true")
  let body = {authorization_token: $authorization_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Agent
#
# POST /v1/agents?beta=true
# operationId: BetaCreateAgent
export def "agents-betatrue BetaCreateAgent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  name: string # Human-readable name for the agent.
  model: any # Model identifier. Accepts the [model string](https://platform.claude.com/docs/en/about-claude/models/overview#latest-models-comparison), e.g. `claude-opus-4-6`, or a `model_config` object for additional configuration control
  --description: string # Description of what the agent does. (nullable)
  --system: string # System prompt for the agent. (nullable)
  --tools: list # Tool configurations available to the agent. Maximum of 128 tools across all toolsets allowed.
  --mcp-servers: list # MCP servers this agent connects to. Maximum 20. Names must be unique within the array.
  --skills: list # Skills available to the agent.
  --metadata: record # Arbitrary key-value metadata. Maximum 16 pairs, keys up to 64 chars, values up to 512 chars.
  --multiagent: any # Multiagent orchestration configuration. Currently supports the `coordinator` topology with a roster of 1-20 agents. (nullable)
]: any -> record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, metadata: record, created_at: string, updated_at: string, archived_at: record, multiagent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/agents?beta=true")
  let body = {name: $name, model: $model, description: $description, system: $system, tools: $tools, mcp_servers: $mcp_servers, skills: $skills, metadata: $metadata, multiagent: $multiagent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Agents
#
# GET /v1/agents?beta=true
# operationId: BetaListAgents
export def "agents-betatrue BetaListAgents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum results per page. Default 20, maximum 100. (format: int32)
  --page: string # Opaque pagination cursor from a previous response.
  --created-atgte: string # Return agents created at or after this time (inclusive). (format: date-time)
  --created-atlte: string # Return agents created at or before this time (inclusive). (format: date-time)
  --include-archived: string@bool-completer # Include archived agents in results. Defaults to false.
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, version: int, name: string, description: string, model: record, system: string, tools: list, mcp_servers: list, skills: list, metadata: record, created_at: string, updated_at: string, archived_at: record, multiagent: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "created_at[gte]" $created_atgte "scalar") (serialize-qp "created_at[lte]" $created_atlte "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/agents?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Agent
#
# GET /v1/agents/{agent_id}?beta=true
# operationId: BetaGetAgent
export def "agents BetaGetAgent" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # Agent version. Omit for the most recent version. Must be at least 1 if specified. (format: int32)
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, metadata: record, created_at: string, updated_at: string, archived_at: record, multiagent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/agents/($agent_id)?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Agent
#
# POST /v1/agents/{agent_id}?beta=true
# operationId: BetaUpdateAgent
export def "agents BetaUpdateAgent" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  version: int # The agent's current version, used to prevent concurrent overwrites. Obtain this value from a create or retrieve response. The request fails if this does not match the server's current version. (format: int32)
  --name: string # Human-readable name. Must be non-empty. Omit to preserve. Cannot be cleared.
  --description: string # Description. Omit to preserve; send empty string or null to clear. (nullable)
  --model: any # Model identifier. Accepts the [model string](https://platform.claude.com/docs/en/about-claude/models/overview#latest-models-comparison), e.g. `claude-opus-4-6`, or a `model_config` object for additional configuration control. Omit to preserve. Cannot be cleared.
  --system: string # System prompt. Omit to preserve; send empty string or null to clear. (nullable)
  --tools: list # Tool configurations available to the agent. Full replacement. Omit to preserve; send empty array or null to clear. Maximum of 128 tools across all toolsets allowed. (nullable)
  --mcp-servers: list # MCP servers. Full replacement. Omit to preserve; send empty array or null to clear. Names must be unique. Maximum 20. (nullable)
  --skills: list # Skills. Full replacement. Omit to preserve; send empty array or null to clear. (nullable)
  --metadata: record # Metadata patch. Set a key to a string to upsert it, or to null to delete it. Omit the field to preserve. The stored bag is limited to 16 keys (up to 64 chars each) with values up to 512 chars. (nullable)
  --multiagent: any # Multiagent orchestration configuration. Full replacement. Omit to preserve; send null to clear. (nullable)
]: any -> record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, metadata: record, created_at: string, updated_at: string, archived_at: record, multiagent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($agent_id)?beta=true")
  let body = {version: $version, name: $name, description: $description, model: $model, system: $system, tools: $tools, mcp_servers: $mcp_servers, skills: $skills, metadata: $metadata, multiagent: $multiagent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive Agent
#
# POST /v1/agents/{agent_id}/archive?beta=true
# operationId: BetaArchiveAgent
export def "agents-archive-betatrue BetaArchiveAgent" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, version: int, name: string, description: string, model: record<id: any, speed: record>, system: string, tools: list<record>, mcp_servers: list<record>, skills: list<any>, metadata: record, created_at: string, updated_at: string, archived_at: record, multiagent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($agent_id)/archive?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Agent Versions
#
# GET /v1/agents/{agent_id}/versions?beta=true
# operationId: BetaListAgentVersions
export def "agents-versions-betatrue BetaListAgentVersions" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum results per page. Default 20, maximum 100. (format: int32)
  --page: string # Opaque pagination cursor.
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, version: int, name: string, description: string, model: record, system: string, tools: list, mcp_servers: list, skills: list, metadata: record, created_at: string, updated_at: string, archived_at: record, multiagent: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/agents/($agent_id)/versions?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Deployment
#
# POST /v1/deployments?beta=true
# operationId: BetaCreateDeployment
export def "deployments-betatrue BetaCreateDeployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  name: string # Human-readable name for the deployment.
  --description: string # Description of what the deployment does. (nullable)
  agent: any # Agent to deploy. Accepts the `agent` ID string, which pins the latest version, or an `agent` object with both id and version specified. The agent must exist and not be archived.
  environment_id: string # ID of the `environment` defining the container configuration for sessions created from this deployment.
  --vault-ids: list # Vault IDs for stored credentials the agent can use during sessions created from this deployment. Maximum 50.
  initial_events: list # Events to send to each session immediately after creation. At least 1, maximum 50.
  --resources: list # Resources (e.g. repositories, files) to mount into each session's container. Maximum 500.
  --metadata: record # Arbitrary key-value metadata. Maximum 16 pairs, keys up to 64 chars, values up to 512 chars.
  --schedule: any # Optional recurring cron schedule. When present, the deployment fires automatically. Both expression and timezone are required when schedule is set. (nullable)
]: any -> record<type: string, id: string, name: string, description: string, agent: record<type: string, id: string, version: int>, environment_id: string, vault_ids: list<string>, initial_events: list<record>, resources: list<record>, metadata: record, schedule: record, status: record, paused_reason: record, created_at: record, updated_at: record, archived_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/deployments?beta=true")
  let body = {name: $name, description: $description, agent: $agent, environment_id: $environment_id, vault_ids: $vault_ids, initial_events: $initial_events, resources: $resources, metadata: $metadata, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Deployments
#
# GET /v1/deployments?beta=true
# operationId: BetaListDeployments
export def "deployments-betatrue BetaListDeployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum results per page. Default 20, maximum 100. (format: int32)
  --page: string # Opaque pagination cursor.
  --agent-id: string # Filter by agent ID.
  --status: string@status-completer # Filter by status: active or paused. Omit for both. To include archived deployments, use include_archived instead; the two cannot be combined.
  --created-atgte: string # Return deployments created at or after this time (inclusive). (format: date-time)
  --created-atlte: string # Return deployments created at or before this time (inclusive). (format: date-time)
  --include-archived: string@bool-completer # When true, includes archived deployments. Default: false (exclude archived).
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, name: string, description: string, agent: record, environment_id: string, vault_ids: list, initial_events: list, resources: list, metadata: record, schedule: record, status: record, paused_reason: record, created_at: record, updated_at: record, archived_at: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "created_at[gte]" $created_atgte "scalar") (serialize-qp "created_at[lte]" $created_atlte "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/deployments?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment
#
# GET /v1/deployments/{deployment_id}?beta=true
# operationId: BetaGetDeployment
export def "deployments BetaGetDeployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, name: string, description: string, agent: record<type: string, id: string, version: int>, environment_id: string, vault_ids: list<string>, initial_events: list<record>, resources: list<record>, metadata: record, schedule: record, status: record, paused_reason: record, created_at: record, updated_at: record, archived_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployments/($deployment_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Deployment
#
# POST /v1/deployments/{deployment_id}?beta=true
# operationId: BetaUpdateDeployment
export def "deployments BetaUpdateDeployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --name: string # Human-readable name. Must be non-empty. Omit to preserve. Cannot be cleared.
  --description: string # Description. Omit to preserve; send empty string or null to clear. (nullable)
  --agent: any # Agent to deploy. Accepts the `agent` ID string, which re-pins to the latest version, or an `agent` object with both id and version specified. Omit to preserve. Cannot be cleared.
  --environment-id: string # ID of the `environment` where sessions run. Omit to preserve. Cannot be cleared.
  --vault-ids: list # Vault IDs. Full replacement. Omit to preserve; send empty array or null to clear. Maximum 50. (nullable)
  --initial-events: list # Initial events. Full replacement. Omit to preserve. Cannot be cleared. At least 1, maximum 50.
  --resources: list # Session resources. Full replacement. Omit to preserve; send empty array or null to clear. Maximum 500. (nullable)
  --metadata: record # Metadata patch. Set a key to a string to upsert it, or to null to delete it. Omit the field to preserve. The stored bag is limited to 16 keys (up to 64 chars each) with values up to 512 chars. (nullable)
  --schedule: any # Cron schedule. Full replacement. Omit to preserve; send null to clear (revert to manual-only). (nullable)
]: any -> record<type: string, id: string, name: string, description: string, agent: record<type: string, id: string, version: int>, environment_id: string, vault_ids: list<string>, initial_events: list<record>, resources: list<record>, metadata: record, schedule: record, status: record, paused_reason: record, created_at: record, updated_at: record, archived_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployments/($deployment_id)?beta=true")
  let body = {name: $name, description: $description, agent: $agent, environment_id: $environment_id, vault_ids: $vault_ids, initial_events: $initial_events, resources: $resources, metadata: $metadata, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive Deployment
#
# POST /v1/deployments/{deployment_id}/archive?beta=true
# operationId: BetaArchiveDeployment
export def "deployments-archive-betatrue BetaArchiveDeployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, name: string, description: string, agent: record<type: string, id: string, version: int>, environment_id: string, vault_ids: list<string>, initial_events: list<record>, resources: list<record>, metadata: record, schedule: record, status: record, paused_reason: record, created_at: record, updated_at: record, archived_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployments/($deployment_id)/archive?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause Deployment
#
# POST /v1/deployments/{deployment_id}/pause?beta=true
# operationId: BetaPauseDeployment
export def "deployments-pause-betatrue BetaPauseDeployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, name: string, description: string, agent: record<type: string, id: string, version: int>, environment_id: string, vault_ids: list<string>, initial_events: list<record>, resources: list<record>, metadata: record, schedule: record, status: record, paused_reason: record, created_at: record, updated_at: record, archived_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployments/($deployment_id)/pause?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause Deployment
#
# POST /v1/deployments/{deployment_id}/unpause?beta=true
# operationId: BetaUnpauseDeployment
export def "deployments-unpause-betatrue BetaUnpauseDeployment" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, name: string, description: string, agent: record<type: string, id: string, version: int>, environment_id: string, vault_ids: list<string>, initial_events: list<record>, resources: list<record>, metadata: record, schedule: record, status: record, paused_reason: record, created_at: record, updated_at: record, archived_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployments/($deployment_id)/unpause?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run Deployment Now
#
# POST /v1/deployments/{deployment_id}/run?beta=true
# operationId: BetaRunDeploymentNow
export def "deployments-run-betatrue BetaRunDeploymentNow" [
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, deployment_id: string, trigger_context: record, session_id: string, error: record, agent: record<type: string, id: string, version: int>, created_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployments/($deployment_id)/run?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Deployment Runs
#
# GET /v1/deployment_runs?beta=true
# operationId: BetaListDeploymentRuns
export def "deployment-runs-betatrue BetaListDeploymentRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum results per page. Default 20, maximum 1000. (format: int32)
  --page: string # Opaque pagination cursor. Pass next_page from the previous response. Invalid or expired cursors return 400.
  --deployment-id: string # Filter to a specific deployment. Omit to list across all deployments in the workspace. Filtering by a non-existent deployment_id returns 200 with empty data.
  --trigger-type: string@trigger-type-completer # Filter runs by what triggered them. Omit to return all runs.
  --has-error: string@bool-completer # Filter: true for runs with non-null error, false for runs with non-null session_id. Omit for all.
  --created-atgte: string # Return runs created at or after this time (inclusive). (format: date-time)
  --created-atlte: string # Return runs created at or before this time (inclusive). (format: date-time)
  --created-atgt: string # Return runs created strictly after this time (exclusive). (format: date-time)
  --created-atlt: string # Return runs created strictly before this time (exclusive). (format: date-time)
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, deployment_id: string, trigger_context: record, session_id: string, error: record, agent: record, created_at: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "deployment_id" $deployment_id "scalar") (serialize-qp "trigger_type" $trigger_type "scalar") (serialize-qp "has_error" $has_error "scalar") (serialize-qp "created_at[gte]" $created_atgte "scalar") (serialize-qp "created_at[lte]" $created_atlte "scalar") (serialize-qp "created_at[gt]" $created_atgt "scalar") (serialize-qp "created_at[lt]" $created_atlt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/deployment_runs?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Deployment Run
#
# GET /v1/deployment_runs/{deployment_run_id}?beta=true
# operationId: BetaGetDeploymentRun
export def "deployment-runs BetaGetDeploymentRun" [
  deployment_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, deployment_id: string, trigger_context: record, session_id: string, error: record, agent: record<type: string, id: string, version: int>, created_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/deployment_runs/($deployment_run_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Vault
#
# POST /v1/vaults?beta=true
# operationId: BetaCreateVault
export def "vaults-betatrue BetaCreateVault" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  display_name: string # Human-readable name for the vault. 1-255 characters.
  --metadata: record # Arbitrary key-value metadata to attach to the vault. Maximum 16 pairs, keys up to 64 chars, values up to 512 chars.
]: any -> record<type: string, id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vaults?beta=true")
  let body = {display_name: $display_name, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Vaults
#
# GET /v1/vaults?beta=true
# operationId: BetaListVaults
export def "vaults-betatrue BetaListVaults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of vaults to return per page. Defaults to 20, maximum 100. (format: int32)
  --page: string # Opaque pagination token from a previous `list_vaults` response.
  --include-archived: string@bool-completer # Whether to include archived vaults in the results.
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/vaults?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Vault
#
# GET /v1/vaults/{vault_id}?beta=true
# operationId: BetaGetVault
export def "vaults BetaGetVault" [
  vault_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Vault
#
# POST /v1/vaults/{vault_id}?beta=true
# operationId: BetaUpdateVault
export def "vaults BetaUpdateVault" [
  vault_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --display-name: string # Updated human-readable name for the vault. 1-255 characters. (nullable)
  --metadata: record # Metadata patch. Set a key to a string to upsert it, or to null to delete it. Omitted keys are preserved. (nullable)
]: any -> record<type: string, id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)?beta=true")
  let body = {display_name: $display_name, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Vault
#
# DELETE /v1/vaults/{vault_id}?beta=true
# operationId: BetaDeleteVault
export def "vaults BetaDeleteVault" [
  vault_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Vault
#
# POST /v1/vaults/{vault_id}/archive?beta=true
# operationId: BetaArchiveVault
export def "vaults-archive-betatrue BetaArchiveVault" [
  vault_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/archive?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Credential
#
# POST /v1/vaults/{vault_id}/credentials?beta=true
# operationId: BetaCreateCredential
export def "vaults-credentials-betatrue BetaCreateCredential" [
  vault_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --body-auth: any # Authentication configuration for the credential.
  --display-name: string # Human-readable name for the credential. Up to 255 characters. (nullable)
  --metadata: record # Arbitrary key-value metadata to attach to the credential. Maximum 16 pairs, keys up to 64 chars, values up to 512 chars.
]: any -> record<type: string, id: string, vault_id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record, auth: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/credentials?beta=true")
  let body = {auth: $body_auth, display_name: $display_name, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Credentials
#
# GET /v1/vaults/{vault_id}/credentials?beta=true
# operationId: BetaListCredentials
export def "vaults-credentials-betatrue BetaListCredentials" [
  vault_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of credentials to return per page. Defaults to 20, maximum 100. (format: int32)
  --page: string # Opaque pagination token from a previous `list_credentials` response.
  --include-archived: string@bool-completer # Whether to include archived credentials in the results.
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<data: table<type: string, id: string, vault_id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record, auth: record>, next_page: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/credentials?beta=true" $qp)
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Credential
#
# GET /v1/vaults/{vault_id}/credentials/{credential_id}?beta=true
# operationId: BetaGetCredential
export def "vaults-credentials BetaGetCredential" [
  vault_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, vault_id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record, auth: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/credentials/($credential_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Credential
#
# POST /v1/vaults/{vault_id}/credentials/{credential_id}?beta=true
# operationId: BetaUpdateCredential
export def "vaults-credentials BetaUpdateCredential" [
  vault_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
  --display-name: string # Updated human-readable name for the credential. 1-255 characters. (nullable)
  --metadata: record # Metadata patch. Set a key to a string to upsert it, or to null to delete it. Omitted keys are preserved. (nullable)
  --body-auth: any # Updated authentication configuration. The `type` is immutable; the variant sent must match the stored credential's type.
]: any -> record<type: string, id: string, vault_id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record, auth: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/credentials/($credential_id)?beta=true")
  let body = {display_name: $display_name, metadata: $metadata, auth: $body_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Credential
#
# DELETE /v1/vaults/{vault_id}/credentials/{credential_id}?beta=true
# operationId: BetaDeleteCredential
export def "vaults-credentials BetaDeleteCredential" [
  vault_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-api-key: string
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/credentials/($credential_id)?beta=true")
  let extra_headers = {"x-api-key": $x_api_key, "anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Credential
#
# POST /v1/vaults/{vault_id}/credentials/{credential_id}/archive?beta=true
# operationId: BetaArchiveCredential
export def "vaults-credentials-archive-betatrue BetaArchiveCredential" [
  vault_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, id: string, vault_id: string, display_name: string, metadata: record, created_at: string, updated_at: string, archived_at: record, auth: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/credentials/($credential_id)/archive?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Credential
#
# POST /v1/vaults/{vault_id}/credentials/{credential_id}/mcp_oauth_validate?beta=true
# operationId: BetaValidateCredential
export def "vaults-credentials-mcp-oauth-validate-betatrue BetaValidateCredential" [
  vault_id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --anthropic-version: string
  --anthropic-beta: string
]: nothing -> record<type: string, credential_id: string, vault_id: string, status: record, validated_at: record, has_refresh_token: bool, mcp_probe: record<method: string, http_response: record<status_code: int, content_type: string, body: string, body_truncated: bool>>, refresh: record<status: record, http_response: record<status_code: int, content_type: string, body: string, body_truncated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/vaults/($vault_id)/credentials/($credential_id)/mcp_oauth_validate?beta=true")
  let extra_headers = {"anthropic-version": $anthropic_version, "anthropic-beta": $anthropic_beta} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
