# Auto-generated client for Cohere API v1.0.0
# Source: https://docs.cohere.com/openapi/cohere-api.json
# Auth: --token flag or $env.COHERE_API_TOKEN

const BASE_URL = "https://api.cohere.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COHERE_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.cohere.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def stream-completer [] { ["true"] }
def safety-mode-completer [] { ["CONTEXTUAL" "OFF" "STRICT"] }
def tool-choice-completer [] { ["NONE" "REQUIRED"] }
def input-type-completer [] { ["classification" "clustering" "image" "search_document" "search_query"] }
def truncate-completer [] { ["END" "NONE" "START"] }
def truncate-completer-1 [] { ["END" "START"] }
def status-completer [] { ["BATCH_STATUS_CANCELED" "BATCH_STATUS_CANCELING" "BATCH_STATUS_COMPLETED" "BATCH_STATUS_FAILED" "BATCH_STATUS_IN_PROGRESS" "BATCH_STATUS_QUEUED" "BATCH_STATUS_UNSPECIFIED"] }
def prompt-truncation-completer [] { ["AUTO" "AUTO_PRESERVE_ORDER" "OFF"] }
def citation-quality-completer [] { ["ACCURATE" "DISABLED" "ENABLED" "FAST" "OFF"] }
def safety-mode-completer-1 [] { ["CONTEXTUAL" "NONE" "STRICT"] }
def status-completer-1 [] { ["STATUS_DELETED" "STATUS_DEPLOYING_API" "STATUS_FAILED" "STATUS_FINETUNING" "STATUS_PAUSED" "STATUS_QUEUED" "STATUS_READY" "STATUS_TEMPORARILY_OFFLINE" "STATUS_UNSPECIFIED"] }
def return-likelihoods-completer [] { ["ALL" "GENERATION" "NONE"] }
def length-completer [] { ["long" "medium" "short"] }
def format-completer [] { ["bullets" "paragraph"] }
def extractiveness-completer [] { ["high" "low" "medium"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "chat chat-stream" } } | get name | first)
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

# Chat API (v2)
#
# POST /v2/chat
# operationId: chat-stream
# --tools item shape: {type: "function", function?: record}
# --citation_options shape: {mode?: "ENABLED"|"DISABLED"|"FAST"|"ACCURATE"|"OFF"}
# --thinking shape: {type: "enabled"|"disabled", token_budget?: int}
export def "chat chat-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --stream: string@bool-completer # Defaults to `false`.  When `true`, the response will be a SSE stream of events.  Streaming is beneficial for user interfaces that render the contents of the response piece by piece, as it gets generated.
  model: string # The name of a compatible [Cohere model](https://docs.cohere.com/v2/docs/models).
  messages: list # A list of chat messages in chronological order, representing a conversation between the user and the model.  Messages can be from `User`, `Assistant`, `Tool` and `System` roles. Learn more about messages and roles in [the Chat API guide](https://docs.cohere.com/v2/docs/chat-api).
  --tools: list # A list of tools (functions) available to the model. The model response may contain 'tool_calls' to the specified tools.  Learn more in the [Tool Use guide](https://docs.cohere.com/docs/tools). — item shape: {type: "function", function?: record}
  --strict-tools: string@bool-completer # When set to `true`, tool calls in the Assistant message will be forced to follow the tool definition strictly. Learn more in the [Structured Outputs (Tools) guide](https://docs.cohere.com/docs/structured-outputs-json#structured-outputs-tools).  **Note**: The first few requests with a new set of tools will take longer to process.
  --documents: list # A list of relevant documents that the model can cite to generate a more accurate reply. Each document is either a string or document object with content and metadata.
  --citation-options: record # Options for controlling citation generation. — shape: {mode?: "ENABLED"|"DISABLED"|"FAST"|"ACCURATE"|"OFF"}
  --response-format: any # Configuration for forcing the model output to adhere to the specified format. Supported on [Command R](https://docs.cohere.com/v2/docs/command-r), [Command R+](https://docs.cohere.com/v2/docs/command-r-plus) and newer models.  The model can be forced into outputting JSON objects by setting `{ "type": "json_object" }`.  A [JSON Schema](https://json-schema.org/) can optionally be provided, to ensure a specific structure.  **Note**: When using  `{ "type": "json_object" }` your `message` should always explicitly instruct the model to generate a JSON (eg: _"Generate a JSON ..."_) . Otherwise the model may end up getting stuck generating an infinite stream of characters and eventually run out of context length.  **Note**: When `json_schema` is not specified, the generated object can have up to 5 layers of nesting.  **Limitation**: The parameter is not supported when used in combinations with the `documents` or `tools` parameters.
  --safety-mode: string@safety-mode-completer # Used to select the [safety instruction](https://docs.cohere.com/v2/docs/safety-modes) inserted into the prompt. Defaults to `CONTEXTUAL`. When `OFF` is specified, the safety instruction will be omitted.  Safety modes are not yet configurable in combination with `tools` and `documents` parameters.  **Note**: This parameter is only compatible newer Cohere models, starting with [Command R 08-2024](https://docs.cohere.com/docs/command-r#august-2024-release) and [Command R+ 08-2024](https://docs.cohere.com/docs/command-r-plus#august-2024-release).  **Note**: `command-r7b-12-2024` and newer models only support `"CONTEXTUAL"` and `"STRICT"` modes.
  --max-tokens: int # The maximum number of output tokens the model will generate in the response. If not set, `max_tokens` defaults to the model's maximum output token limit. You can find the maximum output token limits for each model in the [model documentation](https://docs.cohere.com/docs/models).  **Note**: Setting a low value may result in incomplete generations. In such cases, the `finish_reason` field in the response will be set to `"MAX_TOKENS"`.  **Note**: If `max_tokens` is set higher than the model's maximum output token limit, the generation will be capped at that model-specific maximum limit.
  --stop-sequences: list # A list of up to 5 strings that the model will use to stop generation. If the model generates a string that matches any of the strings in the list, it will stop generating tokens and return the generated text up to that point not including the stop sequence.
  --temperature: float # Defaults to `0.3`.  A non-negative float that tunes the degree of randomness in generation. Lower temperatures mean less random generations, and higher temperatures mean more random generations.  Randomness can be further maximized by increasing the  value of the `p` parameter.  (format: double)
  --seed: int # If specified, the backend will make a best effort to sample tokens deterministically, such that repeated requests with the same seed and parameters should return the same result. However, determinism cannot be totally guaranteed.
  --frequency-penalty: float # Defaults to `0.0`, min value of `0.0`, max value of `1.0`. Used to reduce repetitiveness of generated tokens. The higher the value, the stronger a penalty is applied to previously present tokens, proportional to how many times they have already appeared in the prompt or prior generation.  (format: double)
  --presence-penalty: float # Defaults to `0.0`, min value of `0.0`, max value of `1.0`. Used to reduce repetitiveness of generated tokens. Similar to `frequency_penalty`, except that this penalty is applied equally to all tokens that have already appeared, regardless of their exact frequencies.  (format: double)
  --k: int # Ensures that only the top `k` most likely tokens are considered for generation at each step. When `k` is set to `0`, k-sampling is disabled. Defaults to `0`, min value of `0`, max value of `500`.  (default: 0)
  --p: float # Ensures that only the most likely tokens, with total probability mass of `p`, are considered for generation at each step. If both `k` and `p` are enabled, `p` acts after `k`. Defaults to `0.75`. min value of `0.01`, max value of `0.99`.  (format: double, default: 0.75)
  --logprobs: string@bool-completer # Defaults to `false`. When set to `true`, the log probabilities of the generated tokens will be included in the response.
  --tool-choice: string@tool-choice-completer # Used to control whether or not the model will be forced to use a tool when answering. When `REQUIRED` is specified, the model will be forced to use at least one of the user-defined tools, and the `tools` parameter must be passed in the request. When `NONE` is specified, the model will be forced **not** to use one of the specified tools, and give a direct response. If tool_choice isn't specified, then the model is free to choose whether to use the specified tools or not.  **Note**: This parameter is only compatible with models [Command-r7b](https://docs.cohere.com/v2/docs/command-r7b) and newer.
  --thinking: record # Configuration for [reasoning features](https://docs.cohere.com/docs/reasoning). — shape: {type: "enabled"|"disabled", token_budget?: int}
  --priority: int # Controls how early the request is handled. Lower numbers indicate higher priority (default: 0, the highest). When the system is under load, higher-priority requests are processed first and are the least likely to be dropped. (default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/chat")
  let body = {stream: $stream, model: $model, messages: $messages, tools: $tools, strict_tools: $strict_tools, documents: $documents, citation_options: $citation_options, response_format: $response_format, safety_mode: $safety_mode, max_tokens: $max_tokens, stop_sequences: $stop_sequences, temperature: $temperature, seed: $seed, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, k: $k, p: $p, logprobs: $logprobs, tool_choice: $tool_choice, thinking: $thinking, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rerank API (v2)
#
# POST /v2/rerank
# operationId: rerank
export def "rerank rerank" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  model: string # The identifier of the model to use, eg `rerank-v3.5`.
  --body-query: string # The search query
  documents: list # A list of texts that will be compared to the `query`. For optimal performance we recommend against sending more than 1,000 documents in a single request.  **Note**: long documents will automatically be truncated to the value of `max_tokens_per_doc`.  **Note**: structured data should be formatted as YAML strings for best performance.
  --top-n: int # Limits the number of returned rerank results to the specified value. If not passed, all the rerank results will be returned.
  --max-tokens-per-doc: int # Defaults to `4096`. Long documents will be automatically truncated to the specified number of tokens.
  --priority: int # Controls how early the request is handled. Lower numbers indicate higher priority (default: 0, the highest). When the system is under load, higher-priority requests are processed first and are the least likely to be dropped. (default: 0)
]: any -> record<id: string, results: table<index: int, relevance_score: float>, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/rerank")
  let body = {model: $model, query: $body_query, documents: $documents, top_n: $top_n, max_tokens_per_doc: $max_tokens_per_doc, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Embed API (v2)
#
# POST /v2/embed
# operationId: embed
# --inputs item shape: {content: list}
export def "embed embed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --texts: list # An array of strings for the model to embed. Maximum number of texts per call is `96`.
  --images: list # An array of image data URIs for the model to embed.  The image must be a valid [data URI](https://developer.mozilla.org/en-US/docs/Web/URI/Schemes/data). The image must be in either `image/jpeg`, `image/png`, `image/webp`, or `image/gif` format.  Image embeddings are supported with Embed v3.0 and newer models.  For **Embed v3.x** models, the maximum number of images per call is `1`, and each image has a maximum size of `5MB`.  For **Embed v4.0 and newer** models, there is no limit on the number of images per call. The combined size of all images in the request must be at most `20MB`.
  model: string # ID of one of the available [Embedding models](https://docs.cohere.com/docs/cohere-embed).
  input_type: string@input-type-completer # Specifies the type of input passed to the model. Required for embedding models v3 and higher.  - `"search_document"`: Used for embeddings stored in a vector database for search use-cases. - `"search_query"`: Used for embeddings of search queries run against a vector DB to find relevant documents. - `"classification"`: Used for embeddings passed through a text classifier. - `"clustering"`: Used for the embeddings run through a clustering algorithm. - `"image"`: Used for embeddings with image input.
  --inputs: list # An array of inputs for the model to embed. Maximum number of inputs per call is `96`. An input can contain a mix of text and image components. — item shape: {content: list}
  --max-tokens: int # The maximum number of tokens to embed per input. If the input text is longer than this, it will be truncated according to the `truncate` parameter.
  --output-dimension: int # The number of dimensions of the output embedding. This is only available for `embed-v4` and newer models. Possible values are `256`, `512`, `1024`, and `1536`. The default is `1536`.
  --embedding-types: list # Specifies the types of embeddings you want to get back. Can be one or more of the following types.  * `"float"`: Use this when you want to get back the default float embeddings. Supported with all Embed models. * `"int8"`: Use this when you want to get back signed int8 embeddings. Supported with Embed v3.0 and newer Embed models. * `"uint8"`: Use this when you want to get back unsigned int8 embeddings. Supported with Embed v3.0 and newer Embed models. * `"binary"`: Use this when you want to get back signed binary embeddings. Supported with Embed v3.0 and newer Embed models. * `"ubinary"`: Use this when you want to get back unsigned binary embeddings. Supported with Embed v3.0 and newer Embed models. * `"base64"`: Use this when you want to get back base64 embeddings. Supported with Embed v3.0 and newer Embed models. (default: [float])
  --truncate: string@truncate-completer # One of `NONE|START|END` to specify how the API will handle inputs longer than the maximum token length.  Passing `START` will discard the start of the input. `END` will discard the end of the input. In both cases, input is discarded until the remaining input is exactly the maximum input token length for the model.  If `NONE` is selected, when the input exceeds the maximum input token length an error will be returned. (default: END)
  --priority: int # Controls how early the request is handled. Lower numbers indicate higher priority (default: 0, the highest). When the system is under load, higher-priority requests are processed first and are the least likely to be dropped. (default: 0)
]: any -> record<id: string, embeddings: record<float: list<list>, int8: list<list>, uint8: list<list>, binary: list<list>, ubinary: list<list>, base64: list<string>>, texts: list<string>, images: table<width: int, height: int, format: string, bit_depth: int>, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/embed")
  let body = {texts: $texts, images: $images, model: $model, input_type: $input_type, inputs: $inputs, max_tokens: $max_tokens, output_dimension: $output_dimension, embedding_types: $embedding_types, truncate: $truncate, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an Embed Job
#
# POST /v1/embed-jobs
# operationId: create
export def "embed-jobs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  model: string # ID of the embedding model.  Available models and corresponding embedding dimensions:  - `embed-english-v3.0` : 1024 - `embed-multilingual-v3.0` : 1024 - `embed-english-light-v3.0` : 384 - `embed-multilingual-light-v3.0` : 384  (format: string)
  dataset_id: string # ID of a [Dataset](https://docs.cohere.com/docs/datasets). The Dataset must be of type `embed-input` and must have a validation status `Validated`
  input_type: string@input-type-completer # Specifies the type of input passed to the model. Required for embedding models v3 and higher.  - `"search_document"`: Used for embeddings stored in a vector database for search use-cases. - `"search_query"`: Used for embeddings of search queries run against a vector DB to find relevant documents. - `"classification"`: Used for embeddings passed through a text classifier. - `"clustering"`: Used for the embeddings run through a clustering algorithm. - `"image"`: Used for embeddings with image input.
  --name: string # The name of the embed job.
  --embedding-types: list # Specifies the types of embeddings you want to get back. Not required and default is None, which returns the Embed Floats response type. Can be one or more of the following types.  * `"float"`: Use this when you want to get back the default float embeddings. Valid for all models. * `"int8"`: Use this when you want to get back signed int8 embeddings. Valid for v3 and newer model versions. * `"uint8"`: Use this when you want to get back unsigned int8 embeddings. Valid for v3 and newer model versions. * `"binary"`: Use this when you want to get back signed binary embeddings. Valid for v3 and newer model versions. * `"ubinary"`: Use this when you want to get back unsigned binary embeddings. Valid for v3 and newer model versions.
  --truncate: string@truncate-completer-1 # One of `START|END` to specify how the API will handle inputs longer than the maximum token length.  Passing `START` will discard the start of the input. `END` will discard the end of the input. In both cases, input is discarded until the remaining input is exactly the maximum input token length for the model.  (default: END)
]: any -> record<job_id: string, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embed-jobs")
  let body = {model: $model, dataset_id: $dataset_id, input_type: $input_type, name: $name, embedding_types: $embedding_types, truncate: $truncate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Embed Jobs
#
# GET /v1/embed-jobs
# operationId: list
export def "embed-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<embed_jobs: table<job_id: string, name: string, status: string, created_at: string, input_dataset_id: string, output_dataset_id: string, model: string, truncate: string, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embed-jobs")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch an Embed Job
#
# GET /v1/embed-jobs/{id}
# operationId: get
export def "embed-jobs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<job_id: string, name: string, status: string, created_at: string, input_dataset_id: string, output_dataset_id: string, model: string, truncate: string, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/embed-jobs/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an Embed Job
#
# POST /v1/embed-jobs/{id}/cancel
# operationId: cancel
export def "embed-jobs-cancel cancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/embed-jobs/($id)/cancel")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a transcription
#
# POST /v2/audio/transcriptions
# operationId: create
export def "audio-transcriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  model: string # ID of the model to use.
  language: string # The language of the input audio, supplied in [ISO-639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) format.
  --temperature: float # The sampling temperature, between 0 and 1. Higher values like 0.8 make the output more random, while lower values like 0.2 make it more focused and deterministic. (format: double)
  file: string # The audio file object to transcribe. Supported file extensions are flac, mp3, mpeg, mpga, ogg, and wav. (format: binary)
]: any -> record<text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/audio/transcriptions")
  let body = {model: $model, language: $language, temperature: $temperature, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a batch
#
# POST /v2/batches
# operationId: create
export def "batches create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --id: string # read-only. Batch ID.
  name: string # Batch name (e.g. `foobar`).
  --creator-id: string # read-only. User ID of the creator.
  --org-id: string # read-only. Organization ID.
  --status: string@status-completer # The possible stages of a batch life-cycle.   - BATCH_STATUS_UNSPECIFIED: Unspecified status.  - BATCH_STATUS_QUEUED: The batch has been queued.  - BATCH_STATUS_IN_PROGRESS: The batch is in-progress.  - BATCH_STATUS_CANCELING: The batch is being canceled.  - BATCH_STATUS_COMPLETED: The batch has been completed.  - BATCH_STATUS_FAILED: The batch has failed.  - BATCH_STATUS_CANCELED: The batch has been canceled. (default: BATCH_STATUS_UNSPECIFIED)
  --created-at: string # read-only. Creation timestamp. (format: date-time)
  --updated-at: string # read-only. Latest update timestamp. (format: date-time)
  input_dataset_id: string # ID of the dataset the batch reads inputs from.
  --output-dataset-id: string
  --input-tokens: string # read-only. The total number of input tokens in the batch. (format: int64)
  --output-tokens: string # read-only. The total number of output tokens in the batch. (format: int64)
  model: string # The name of the model the batch uses.
  --num-records: int # read-only. The total number of records in the batch.
  --num-successful-records: int # read-only. The current number of successful records in the batch.
  --num-failed-records: int # read-only. The current number of failed records in the batch.
  --status-reason: string # read-only. More details about the reason for the status of a batch job.
]: any -> record<batch: record<id: string, name: string, creator_id: string, org_id: string, status: string, created_at: string, updated_at: string, input_dataset_id: string, output_dataset_id: string, input_tokens: string, output_tokens: string, model: string, num_records: int, num_successful_records: int, num_failed_records: int, status_reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/batches")
  let body = {id: $id, name: $name, creator_id: $creator_id, org_id: $org_id, status: $status, created_at: $created_at, updated_at: $updated_at, input_dataset_id: $input_dataset_id, output_dataset_id: $output_dataset_id, input_tokens: $input_tokens, output_tokens: $output_tokens, model: $model, num_records: $num_records, num_successful_records: $num_successful_records, num_failed_records: $num_failed_records, status_reason: $status_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List batches
#
# GET /v2/batches
# operationId: list
export def "batches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # The maximum number of batches to return. The service may return fewer than this value. If unspecified, at most 50 batches will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `ListBatches` call. Provide this to retrieve the subsequent page.
  --order-by: string # Batches can be ordered by creation time or last updated time. Use `created_at` for creation time or `updated_at` for last updated time.
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<batches: table<id: string, name: string, creator_id: string, org_id: string, status: string, created_at: string, updated_at: string, input_dataset_id: string, output_dataset_id: string, input_tokens: string, output_tokens: string, model: string, num_records: int, num_successful_records: int, num_failed_records: int, status_reason: string>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/batches" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a batch
#
# GET /v2/batches/{id}
# operationId: retrieve
export def "batches get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<batch: record<id: string, name: string, creator_id: string, org_id: string, status: string, created_at: string, updated_at: string, input_dataset_id: string, output_dataset_id: string, input_tokens: string, output_tokens: string, model: string, num_records: int, num_successful_records: int, num_failed_records: int, status_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/batches/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a batch
#
# POST /v2/batches/{id}:cancel
# operationId: cancel
export def "batches cancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/batches/($id):cancel")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Dataset
#
# POST /v1/datasets
# operationId: create
export def "datasets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the uploaded dataset.
  --type: string # The dataset type, which is used to validate the data. The only valid type is `embed-input` used in conjunction with the Embed Jobs API.
  --keep-original-file: string@bool-completer # Indicates if the original file should be stored.
  --skip-malformed-input: string@bool-completer # Indicates whether rows with malformed input should be dropped (instead of failing the validation check). Dropped rows will be returned in the warnings field.
  --keep-fields: list # List of names of fields that will be persisted in the Dataset. By default the Dataset will retain only the required fields indicated in the [schema for the corresponding Dataset type](https://docs.cohere.com/docs/datasets#dataset-types). For example, datasets of type `embed-input` will drop all fields other than the required `text` field. If any of the fields in `keep_fields` are missing from the uploaded file, Dataset validation will fail.
  --optional-fields: list # List of names of fields that will be persisted in the Dataset. By default the Dataset will retain only the required fields indicated in the [schema for the corresponding Dataset type](https://docs.cohere.com/docs/datasets#dataset-types). For example, Datasets of type `embed-input` will drop all fields other than the required `text` field. If any of the fields in `optional_fields` are missing from the uploaded file, Dataset validation will pass.
  --text-separator: string # Raw .txt uploads will be split into entries using the text_separator value.
  --csv-delimiter: string # The delimiter used for .csv uploads.
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  data: string # The file to upload (format: binary)
  --eval-data: string # An optional evaluation file to upload (format: binary)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "keep_original_file" $keep_original_file "scalar") (serialize-qp "skip_malformed_input" $skip_malformed_input "scalar") (serialize-qp "keep_fields" $keep_fields "multi") (serialize-qp "optional_fields" $optional_fields "multi") (serialize-qp "text_separator" $text_separator "scalar") (serialize-qp "csv_delimiter" $csv_delimiter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/datasets" $qp)
  let body = {data: $data, eval_data: $eval_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Datasets
#
# GET /v1/datasets
# operationId: list
export def "datasets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --datasetType: string # optional filter by dataset type
  --before: string # optional filter before a date (format: date-time)
  --after: string # optional filter after a date (format: date-time)
  --limit: float # optional limit to number of results (format: double)
  --offset: float # optional offset to start of results (format: double)
  --validationStatus: string # optional filter by validation status
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<datasets: table<id: string, name: string, created_at: string, updated_at: string, dataset_type: string, validation_status: string, validation_error: string, schema: string, required_fields: list, preserve_fields: list, dataset_parts: list, validation_warnings: list, parse_info: record, metrics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasetType" $datasetType "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "validationStatus" $validationStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/datasets" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dataset Usage
#
# GET /v1/datasets/usage
# operationId: get-usage
export def "datasets-usage get-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<organization_usage: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/datasets/usage")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Dataset
#
# GET /v1/datasets/{id}
# operationId: get
export def "datasets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<dataset: record<id: string, name: string, created_at: string, updated_at: string, dataset_type: string, validation_status: string, validation_error: string, schema: string, required_fields: list<string>, preserve_fields: list<string>, dataset_parts: list<record>, validation_warnings: list<string>, parse_info: record<separator: string, delimiter: string>, metrics: record<finetune_dataset_metrics: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/datasets/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Dataset
#
# DELETE /v1/datasets/{id}
# operationId: delete
export def "datasets delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/datasets/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tokenize
#
# POST /v1/tokenize
# operationId: tokenize
export def "tokenize tokenize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  text: string # The string to be tokenized, the minimum text length is 1 character, and the maximum text length is 65536 characters.
  model: string # The input will be tokenized by the tokenizer that is used by this model.
]: any -> record<tokens: list<int>, token_strings: list<string>, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tokenize")
  let body = {text: $text, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Detokenize
#
# POST /v1/detokenize
# operationId: detokenize
export def "detokenize detokenize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  tokens: list # The list of tokens to be detokenized.
  model: string # An optional parameter to provide the model name. This will ensure that the detokenization is done by the tokenizer used by that model.
]: any -> record<text: string, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/detokenize")
  let body = {tokens: $tokens, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Model
#
# GET /v1/models/{model}
# operationId: get
export def "models get" [
  model: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<name: string, is_deprecated: bool, endpoints: list<string>, finetuned: bool, context_length: float, tokenizer_url: string, default_endpoints: list<string>, features: list<string>, sampling_defaults: record<temperature: float, k: int, p: float, frequency_penalty: float, presence_penalty: float, max_tokens_per_doc: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Models
#
# GET /v1/models
# operationId: list
export def "models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: float # Maximum number of models to include in a page Defaults to `20`, min value of `1`, max value of `1000`. (format: double)
  --page-token: string # Page token provided in the `next_page_token` field of a previous response.
  --endpoint: string # When provided, filters the list of models to only those that are compatible with the specified endpoint.
  --default-only: string@bool-completer # When provided, filters the list of models to only the default model to the endpoint. This parameter is only valid when `endpoint` is provided.
  --Authorization: string # Bearer authentication
]: nothing -> record<models: table<name: string, is_deprecated: bool, endpoints: list, finetuned: bool, context_length: float, tokenizer_url: string, default_endpoints: list, features: list, sampling_defaults: record>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "endpoint" $endpoint "scalar") (serialize-qp "default_only" $default_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/models" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Chat API (v1)
#
# POST /v1/chat
# operationId: chat-stream
# --connectors item shape: {id: string, user_access_token?: string, continue_on_failure?: bool, options?: record}
# --tools item shape: {name: string, description: string, parameter_definitions?: record}
# --tool_results item shape: {call: record, outputs: list}
export def "chat chat-stream-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --Accepts: string # Pass text/event-stream to receive the streamed response as server-sent events. The default is `\n` delimited events.
  message: string # Text input for the model to respond to.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --model: string # The name of a compatible [Cohere model](https://docs.cohere.com/docs/models) or the ID of a [fine-tuned](https://docs.cohere.com/docs/chat-fine-tuning) model.  Compatible Deployments: Cohere Platform, Private Deployments
  --stream: string@bool-completer # Defaults to `false`.  When `true`, the response will be a JSON stream of events. The final event will contain the complete response, and will have an `event_type` of `"stream-end"`.  Streaming is beneficial for user interfaces that render the contents of the response piece by piece, as it gets generated.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --preamble: string # When specified, the default Cohere preamble will be replaced with the provided one. Preambles are a part of the prompt used to adjust the model's overall behavior and conversation style, and use the `SYSTEM` role.  The `SYSTEM` role is also used for the contents of the optional `chat_history=` parameter. When used with the `chat_history=` parameter it adds content throughout a conversation. Conversely, when used with the `preamble=` parameter it adds content at the start of the conversation only.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --chat-history: list # A list of previous messages between the user and the model, giving the model conversational context for responding to the user's `message`.  Each item represents a single message in the chat history, excluding the current user turn. It has two properties: `role` and `message`. The `role` identifies the sender (`CHATBOT`, `SYSTEM`, or `USER`), while the `message` contains the text content.  The chat_history parameter should not be used for `SYSTEM` messages in most cases. Instead, to add a `SYSTEM` role message at the beginning of a conversation, the `preamble` parameter should be used.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --conversation-id: string # An alternative to `chat_history`.  Providing a `conversation_id` creates or resumes a persisted conversation with the specified ID. The ID can be any non empty string.  Compatible Deployments: Cohere Platform
  --prompt-truncation: string@prompt-truncation-completer # Defaults to `AUTO` when `connectors` are specified and `OFF` in all other cases.  Dictates how the prompt will be constructed.  With `prompt_truncation` set to "AUTO", some elements from `chat_history` and `documents` will be dropped in an attempt to construct a prompt that fits within the model's context length limit. During this process the order of the documents and chat history will be changed and ranked by relevance.  With `prompt_truncation` set to "AUTO_PRESERVE_ORDER", some elements from `chat_history` and `documents` will be dropped in an attempt to construct a prompt that fits within the model's context length limit. During this process the order of the documents and chat history will be preserved as they are inputted into the API.  With `prompt_truncation` set to "OFF", no elements will be dropped. If the sum of the inputs exceeds the model's context length limit, a `TooManyTokens` error will be returned.  Compatible Deployments:  - AUTO: Cohere Platform Only  - AUTO_PRESERVE_ORDER: Azure, AWS Sagemaker/Bedrock, Private Deployments
  --connectors: list # Accepts `{"id": "web-search"}`, and/or the `"id"` for a custom [connector](https://docs.cohere.com/docs/connectors), if you've [created](https://docs.cohere.com/v1/docs/creating-and-deploying-a-connector) one.  When specified, the model's reply will be enriched with information found by querying each of the connectors (RAG).  Compatible Deployments: Cohere Platform — item shape: {id: string, user_access_token?: string, continue_on_failure?: bool, options?: record}
  --search-queries-only: string@bool-completer # Defaults to `false`.  When `true`, the response will only contain a list of generated search queries, but no search will take place, and no reply from the model to the user's `message` will be generated.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --documents: list # A list of relevant documents that the model can cite to generate a more accurate reply. Each document is a string-string dictionary.  Example: ``` [   { "title": "Tall penguins", "text": "Emperor penguins are the tallest." },   { "title": "Penguin habitats", "text": "Emperor penguins only live in Antarctica." }, ] ```  Keys and values from each document will be serialized to a string and passed to the model. The resulting generation will include citations that reference some of these documents.  Some suggested keys are "text", "author", and "date". For better generation quality, it is recommended to keep the total word count of the strings in the dictionary to under 300 words.  An `id` field (string) can be optionally supplied to identify the document in the citations. This field will not be passed to the model.  An `_excludes` field (array of strings) can be optionally supplied to omit some key-value pairs from being shown to the model. The omitted fields will still show up in the citation object. The "_excludes" field will not be passed to the model.  See ['Document Mode'](https://docs.cohere.com/docs/retrieval-augmented-generation-rag#document-mode) in the guide for more information.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --citation-quality: string@citation-quality-completer # Defaults to `"enabled"`. Citations are enabled by default for models that support it, but can be turned off by setting `"type": "disabled"`.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --temperature: float # Defaults to `0.3`.  A non-negative float that tunes the degree of randomness in generation. Lower temperatures mean less random generations, and higher temperatures mean more random generations.  Randomness can be further maximized by increasing the  value of the `p` parameter.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments  (format: double)
  --max-tokens: int # The maximum number of tokens the model will generate as part of the response. Note: Setting a low value may result in incomplete generations.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --max-input-tokens: int # The maximum number of input tokens to send to the model. If not specified, `max_input_tokens` is the model's context length limit minus a small buffer.  Input will be truncated according to the `prompt_truncation` parameter.  Compatible Deployments: Cohere Platform
  --k: int # Ensures only the top `k` most likely tokens are considered for generation at each step. Defaults to `0`, min value of `0`, max value of `500`.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments  (default: 0)
  --p: float # Ensures that only the most likely tokens, with total probability mass of `p`, are considered for generation at each step. If both `k` and `p` are enabled, `p` acts after `k`. Defaults to `0.75`. min value of `0.01`, max value of `0.99`.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments  (format: double, default: 0.75)
  --seed: int # If specified, the backend will make a best effort to sample tokens deterministically, such that repeated requests with the same seed and parameters should return the same result. However, determinism cannot be totally guaranteed.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --stop-sequences: list # A list of up to 5 strings that the model will use to stop generation. If the model generates a string that matches any of the strings in the list, it will stop generating tokens and return the generated text up to that point not including the stop sequence.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --frequency-penalty: float # Defaults to `0.0`, min value of `0.0`, max value of `1.0`.  Used to reduce repetitiveness of generated tokens. The higher the value, the stronger a penalty is applied to previously present tokens, proportional to how many times they have already appeared in the prompt or prior generation.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments  (format: double)
  --presence-penalty: float # Defaults to `0.0`, min value of `0.0`, max value of `1.0`.  Used to reduce repetitiveness of generated tokens. Similar to `frequency_penalty`, except that this penalty is applied equally to all tokens that have already appeared, regardless of their exact frequencies.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments  (format: double)
  --raw-prompting: string@bool-completer # When enabled, the user's prompt will be sent to the model without any pre-processing.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --tools: list # A list of available tools (functions) that the model may suggest invoking before producing a text response.  When `tools` is passed (without `tool_results`), the `text` field in the response will be `""` and the `tool_calls` field in the response will be populated with a list of tool calls that need to be made. If no calls need to be made, the `tool_calls` array will be empty.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments — item shape: {name: string, description: string, parameter_definitions?: record}
  --tool-results: list # A list of results from invoking tools recommended by the model in the previous chat turn. Results are used to produce a text response and will be referenced in citations. When using `tool_results`, `tools` must be passed as well. Each tool_result contains information about how it was invoked, as well as a list of outputs in the form of dictionaries.  **Note**: `outputs` must be a list of objects. If your tool returns a single object (eg `{"status": 200}`), make sure to wrap it in a list. ``` tool_results = [   {     "call": {       "name": <tool name>,       "parameters": {         <param name>: <param value>       }     },     "outputs": [{       <key>: <value>     }]   },   ... ] ``` **Note**: Chat calls with `tool_results` should not be included in the Chat history to avoid duplication of the message text.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments — item shape: {call: record, outputs: list}
  --force-single-step: string@bool-completer # Forces the chat to be single step. Defaults to `false`.
  --response-format: any # Configuration for forcing the model output to adhere to the specified format. Supported on [Command R 03-2024](https://docs.cohere.com/docs/command-r), [Command R+ 04-2024](https://docs.cohere.com/docs/command-r-plus) and newer models.  The model can be forced into outputting JSON objects (with up to 5 levels of nesting) by setting `{ "type": "json_object" }`.  A [JSON Schema](https://json-schema.org/) can optionally be provided, to ensure a specific structure.  **Note**: When using  `{ "type": "json_object" }` your `message` should always explicitly instruct the model to generate a JSON (eg: _"Generate a JSON ..."_) . Otherwise the model may end up getting stuck generating an infinite stream of characters and eventually run out of context length. **Limitation**: The parameter is not supported in RAG mode (when any of `connectors`, `documents`, `tools`, `tool_results` are provided).
  --safety-mode: string@safety-mode-completer-1 # Used to select the [safety instruction](https://docs.cohere.com/docs/safety-modes) inserted into the prompt. Defaults to `CONTEXTUAL`. When `NONE` is specified, the safety instruction will be omitted.  Safety modes are not yet configurable in combination with `tools`, `tool_results` and `documents` parameters.  **Note**: This parameter is only compatible newer Cohere models, starting with [Command R 08-2024](https://docs.cohere.com/docs/command-r#august-2024-release) and [Command R+ 08-2024](https://docs.cohere.com/docs/command-r-plus#august-2024-release).  **Note**: `command-r7b-12-2024` and newer models only support `"CONTEXTUAL"` and `"STRICT"` modes.  Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chat")
  let body = {message: $message, model: $model, stream: $stream, preamble: $preamble, chat_history: $chat_history, conversation_id: $conversation_id, prompt_truncation: $prompt_truncation, connectors: $connectors, search_queries_only: $search_queries_only, documents: $documents, citation_quality: $citation_quality, temperature: $temperature, max_tokens: $max_tokens, max_input_tokens: $max_input_tokens, k: $k, p: $p, seed: $seed, stop_sequences: $stop_sequences, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, raw_prompting: $raw_prompting, tools: $tools, tool_results: $tool_results, force_single_step: $force_single_step, response_format: $response_format, safety_mode: $safety_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name, "Accepts": $Accepts} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rerank API (v1)
#
# POST /v1/rerank
# operationId: rerank
export def "rerank rerank-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --model: string # The identifier of the model to use, eg `rerank-v3.5`.
  --body-query: string # The search query
  documents: list # A list of document objects or strings to rerank. If a document is provided the text fields is required and all other fields will be preserved in the response.  The total max chunks (length of documents * max_chunks_per_doc) must be less than 10000.  We recommend a maximum of 1,000 documents for optimal endpoint performance.
  --top-n: int # The number of most relevant documents or indices to return, defaults to the length of the documents
  --rank-fields: list # If a JSON object is provided, you can specify which keys you would like to have considered for reranking. The model will rerank based on order of the fields passed in (i.e. rank_fields=['title','author','text'] will rerank using the values in title, author, text  sequentially. If the length of title, author, and text exceeds the context length of the model, the chunking will not re-consider earlier fields). If not provided, the model will use the default text field for ranking.
  --return-documents: string@bool-completer # - If false, returns results without the doc text - the api will return a list of {index, relevance score} where index is inferred from the list passed into the request. - If true, returns results with the doc text passed in - the api will return an ordered list of {index, text, relevance score} where index + text refers to the list passed into the request. (default: false)
  --max-chunks-per-doc: int # The maximum number of chunks to produce internally from a document (default: 10)
]: any -> record<id: string, results: table<document: record, index: int, relevance_score: float>, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rerank")
  let body = {model: $model, query: $body_query, documents: $documents, top_n: $top_n, rank_fields: $rank_fields, return_documents: $return_documents, max_chunks_per_doc: $max_chunks_per_doc} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Embed API (v1)
#
# POST /v1/embed
# Discriminator (response): response_type
# operationId: embed
export def "embed embed-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --texts: list # An array of strings for the model to embed. Maximum number of texts per call is `96`.
  --images: list # An array of image data URIs for the model to embed.  The image must be a valid [data URI](https://developer.mozilla.org/en-US/docs/Web/URI/Schemes/data). The image must be in either `image/jpeg`, `image/png`, `image/webp`, or `image/gif` format.  Image embeddings are supported with Embed v3.0 and newer models.  For **Embed v3.x** models, the maximum number of images per call is `1`, and each image has a maximum size of `5MB`.  For **Embed v4.0 and newer** models, there is no limit on the number of images per call. The combined size of all images in the request must be at most `20MB`.
  --model: string # ID of one of the available [Embedding models](https://docs.cohere.com/docs/cohere-embed).
  --input-type: string@input-type-completer # Specifies the type of input passed to the model. Required for embedding models v3 and higher.  - `"search_document"`: Used for embeddings stored in a vector database for search use-cases. - `"search_query"`: Used for embeddings of search queries run against a vector DB to find relevant documents. - `"classification"`: Used for embeddings passed through a text classifier. - `"clustering"`: Used for the embeddings run through a clustering algorithm. - `"image"`: Used for embeddings with image input.
  --embedding-types: list # Specifies the types of embeddings you want to get back. Not required and default is None, which returns the Embed Floats response type. Can be one or more of the following types.  * `"float"`: Use this when you want to get back the default float embeddings. Supported with all Embed models. * `"int8"`: Use this when you want to get back signed int8 embeddings. Supported with Embed v3.0 and newer Embed models. * `"uint8"`: Use this when you want to get back unsigned int8 embeddings. Supported with Embed v3.0 and newer Embed models. * `"binary"`: Use this when you want to get back signed binary embeddings. Supported with Embed v3.0 and newer Embed models. * `"ubinary"`: Use this when you want to get back unsigned binary embeddings. Supported with Embed v3.0 and newer Embed models.
  --truncate: string@truncate-completer # One of `NONE|START|END` to specify how the API will handle inputs longer than the maximum token length.  Passing `START` will discard the start of the input. `END` will discard the end of the input. In both cases, input is discarded until the remaining input is exactly the maximum input token length for the model.  If `NONE` is selected, when the input exceeds the maximum input token length an error will be returned. (default: END)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embed")
  let body = {texts: $texts, images: $images, model: $model, input_type: $input_type, embedding_types: $embedding_types, truncate: $truncate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check API key
#
# POST /v1/check-api-key
# operationId: check-api-key
export def "check-api-key check-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<valid: bool, organization_id: string, owner_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/check-api-key")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Classify
#
# POST /v1/classify
# operationId: classify
# --examples item shape: {text?: string, label?: string}
export def "classify classify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  inputs: list # A list of up to 96 texts to be classified. Each one must be a non-empty string. There is, however, no consistent, universal limit to the length a particular input can be. We perform classification on the first `x` tokens of each input, and `x` varies depending on which underlying model is powering classification. The maximum token length for each model is listed in the "max tokens" column [here](https://docs.cohere.com/docs/models). Note: by default the `truncate` parameter is set to `END`, so tokens exceeding the limit will be automatically dropped. This behavior can be disabled by setting `truncate` to `NONE`, which will result in validation errors for longer texts.
  --examples: list # An array of examples to provide context to the model. Each example is a text string and its associated label/class. Each unique label requires at least 2 examples associated with it; the maximum number of examples is 2500, and each example has a maximum length of 512 tokens. The values should be structured as `{text: "...",label: "..."}`. Note: [Fine-tuned Models](https://docs.cohere.com/docs/classify-fine-tuning) trained on classification examples don't require the `examples` parameter to be passed in explicitly. — item shape: {text?: string, label?: string}
  --model: string # ID of a [Fine-tuned](https://docs.cohere.com/v2/docs/classify-starting-the-training) Classify model
  --preset: string # The ID of a custom playground preset. You can create presets in the [playground](https://dashboard.cohere.com/playground). If you use a preset, all other parameters become optional, and any included parameters will override the preset's parameters.
  --truncate: string@truncate-completer # One of `NONE|START|END` to specify how the API will handle inputs longer than the maximum token length. Passing `START` will discard the start of the input. `END` will discard the end of the input. In both cases, input is discarded until the remaining input is exactly the maximum input token length for the model. If `NONE` is selected, when the input exceeds the maximum input token length an error will be returned. (default: END)
]: any -> record<id: string, classifications: table<id: string, input: string, prediction: string, predictions: list, confidence: float, confidences: list, labels: record, classification_type: string>, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/classify")
  let body = {inputs: $inputs, examples: $examples, model: $model, preset: $preset, truncate: $truncate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Connectors
#
# GET /v1/connectors
# operationId: list
export def "connectors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Maximum number of connectors to return [0, 100]. (format: double, default: 30)
  --offset: float # Number of connectors to skip before returning results [0, inf]. (format: double, default: 0)
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<connectors: table<id: string, organization_id: string, name: string, description: string, url: string, created_at: string, updated_at: string, excludes: list, auth_type: string, oauth: record, auth_status: string, active: bool, continue_on_failure: bool>, total_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connectors" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Connector
#
# POST /v1/connectors
# operationId: create
# --oauth shape: {client_id?: string, client_secret?: string, authorize_url?: string, token_url?: string, scope?: string}
# --service_auth shape: {type: "bearer"|"basic"|"noscheme", token: string}
export def "connectors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  name: string # A human-readable name for the connector.
  --description: string # A description of the connector.
  --body-url: string # The URL of the connector that will be used to search for documents.
  --excludes: list # A list of fields to exclude from the prompt (fields remain in the document).
  --oauth: record # shape: {client_id?: string, client_secret?: string, authorize_url?: string, token_url?: string, scope?: string}
  --active: string@bool-completer # Whether the connector is active or not. (default: true)
  --continue-on-failure: string@bool-completer # Whether a chat request should continue or not if the request to this connector fails. (default: false)
  --service-auth: record # shape: {type: "bearer"|"basic"|"noscheme", token: string}
]: any -> record<connector: record<id: string, organization_id: string, name: string, description: string, url: string, created_at: string, updated_at: string, excludes: list<string>, auth_type: string, oauth: record<client_id: string, client_secret: string, authorize_url: string, token_url: string, scope: string>, auth_status: string, active: bool, continue_on_failure: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connectors")
  let body = {name: $name, description: $description, url: $body_url, excludes: $excludes, oauth: $oauth, active: $active, continue_on_failure: $continue_on_failure, service_auth: $service_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Connector
#
# GET /v1/connectors/{id}
# operationId: get
export def "connectors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<connector: record<id: string, organization_id: string, name: string, description: string, url: string, created_at: string, updated_at: string, excludes: list<string>, auth_type: string, oauth: record<client_id: string, client_secret: string, authorize_url: string, token_url: string, scope: string>, auth_status: string, active: bool, continue_on_failure: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Connector
#
# PATCH /v1/connectors/{id}
# operationId: update
# --oauth shape: {client_id?: string, client_secret?: string, authorize_url?: string, token_url?: string, scope?: string}
# --service_auth shape: {type: "bearer"|"basic"|"noscheme", token: string}
export def "connectors update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --name: string # A human-readable name for the connector.
  --body-url: string # The URL of the connector that will be used to search for documents.
  --excludes: list # A list of fields to exclude from the prompt (fields remain in the document).
  --oauth: record # shape: {client_id?: string, client_secret?: string, authorize_url?: string, token_url?: string, scope?: string}
  --active: string@bool-completer # default: true
  --continue-on-failure: string@bool-completer # default: false
  --service-auth: record # shape: {type: "bearer"|"basic"|"noscheme", token: string}
]: any -> record<connector: record<id: string, organization_id: string, name: string, description: string, url: string, created_at: string, updated_at: string, excludes: list<string>, auth_type: string, oauth: record<client_id: string, client_secret: string, authorize_url: string, token_url: string, scope: string>, auth_status: string, active: bool, continue_on_failure: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($id)")
  let body = {name: $name, url: $body_url, excludes: $excludes, oauth: $oauth, active: $active, continue_on_failure: $continue_on_failure, service_auth: $service_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Connector
#
# DELETE /v1/connectors/{id}
# operationId: delete
export def "connectors delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authorize with oAuth
#
# POST /v1/connectors/{id}/oauth/authorize
# operationId: o-auth-authorize
export def "connectors-oauth-authorize o-auth-authorize" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after-token-redirect: string # The URL to redirect to after the connector has been authorized.
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<redirect_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after_token_redirect" $after_token_redirect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($id)/oauth/authorize" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists fine-tuned models.
#
# GET /v1/finetuning/finetuned-models
# operationId: list-finetuned-models
export def "finetuning-finetuned-models list-finetuned-models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Maximum number of results to be returned by the server. If 0, defaults to 50.
  --page-token: string # Request a specific page of the list results.
  --order-by: string # Comma separated list of fields. For example: "created_at,name". The default sorting order is ascending. To specify descending order for a field, append " desc" to the field name. For example: "created_at desc,name".  Supported sorting fields:   - created_at (default)
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<finetuned_models: table<id: string, name: string, creator_id: string, organization_id: string, settings: record, status: string, created_at: string, updated_at: string, completed_at: string, last_used: string>, next_page_token: string, total_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/finetuning/finetuned-models" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trains and deploys a fine-tuned model.
#
# POST /v1/finetuning/finetuned-models
# operationId: create-finetuned-model
# --settings shape: {base_model: record, dataset_id: string, hyperparameters?: record, multi_label?: bool, wandb?: record}
export def "finetuning-finetuned-models create-finetuned-model" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --id: string # read-only. FinetunedModel ID.
  name: string # FinetunedModel name (e.g. `foobar`).
  --creator-id: string # read-only. User ID of the creator.
  --organization-id: string # read-only. Organization ID.
  settings: record # The configuration used for fine-tuning. — shape: {base_model: record, dataset_id: string, hyperparameters?: record, multi_label?: bool, wandb?: record}
  --status: string@status-completer-1 # The possible stages of a fine-tuned model life-cycle.   - STATUS_UNSPECIFIED: Unspecified status.  - STATUS_FINETUNING: The fine-tuned model is being fine-tuned.  - STATUS_DEPLOYING_API: Deprecated: The fine-tuned model is being deployed.  - STATUS_READY: The fine-tuned model is ready to receive requests.  - STATUS_FAILED: The fine-tuned model failed.  - STATUS_DELETED: The fine-tuned model was deleted.  - STATUS_TEMPORARILY_OFFLINE: Deprecated: The fine-tuned model is temporarily unavailable.  - STATUS_PAUSED: Deprecated: The fine-tuned model is paused (Vanilla only).  - STATUS_QUEUED: The fine-tuned model is queued for training. (default: STATUS_UNSPECIFIED)
  --created-at: string # read-only. Creation timestamp. (format: date-time)
  --updated-at: string # read-only. Latest update timestamp. (format: date-time)
  --completed-at: string # read-only. Timestamp for the completed fine-tuning. (format: date-time)
  --last-used: string # read-only. Deprecated: Timestamp for the latest request to this fine-tuned model. (format: date-time)
]: any -> record<finetuned_model: record<id: string, name: string, creator_id: string, organization_id: string, settings: record<base_model: record, dataset_id: string, hyperparameters: record, multi_label: bool, wandb: record>, status: string, created_at: string, updated_at: string, completed_at: string, last_used: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/finetuning/finetuned-models")
  let body = {id: $id, name: $name, creator_id: $creator_id, organization_id: $organization_id, settings: $settings, status: $status, created_at: $created_at, updated_at: $updated_at, completed_at: $completed_at, last_used: $last_used} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a fine-tuned model.
#
# PATCH /v1/finetuning/finetuned-models/{id}
# operationId: update-finetuned-model
# --settings shape: {base_model: record, dataset_id: string, hyperparameters?: record, multi_label?: bool, wandb?: record}
export def "finetuning-finetuned-models update-finetuned-model" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  name: string # FinetunedModel name (e.g. `foobar`).
  --creator-id: string # User ID of the creator.
  --organization-id: string # Organization ID.
  settings: record # The configuration used for fine-tuning. — shape: {base_model: record, dataset_id: string, hyperparameters?: record, multi_label?: bool, wandb?: record}
  --status: string@status-completer-1 # The possible stages of a fine-tuned model life-cycle.   - STATUS_UNSPECIFIED: Unspecified status.  - STATUS_FINETUNING: The fine-tuned model is being fine-tuned.  - STATUS_DEPLOYING_API: Deprecated: The fine-tuned model is being deployed.  - STATUS_READY: The fine-tuned model is ready to receive requests.  - STATUS_FAILED: The fine-tuned model failed.  - STATUS_DELETED: The fine-tuned model was deleted.  - STATUS_TEMPORARILY_OFFLINE: Deprecated: The fine-tuned model is temporarily unavailable.  - STATUS_PAUSED: Deprecated: The fine-tuned model is paused (Vanilla only).  - STATUS_QUEUED: The fine-tuned model is queued for training. (default: STATUS_UNSPECIFIED)
  --created-at: string # Creation timestamp. (format: date-time)
  --updated-at: string # Latest update timestamp. (format: date-time)
  --completed-at: string # Timestamp for the completed fine-tuning. (format: date-time)
  --last-used: string # Deprecated: Timestamp for the latest request to this fine-tuned model. (format: date-time)
]: any -> record<finetuned_model: record<id: string, name: string, creator_id: string, organization_id: string, settings: record<base_model: record, dataset_id: string, hyperparameters: record, multi_label: bool, wandb: record>, status: string, created_at: string, updated_at: string, completed_at: string, last_used: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/finetuning/finetuned-models/($id)")
  let body = {name: $name, creator_id: $creator_id, organization_id: $organization_id, settings: $settings, status: $status, created_at: $created_at, updated_at: $updated_at, completed_at: $completed_at, last_used: $last_used} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a fine-tuned model by ID.
#
# GET /v1/finetuning/finetuned-models/{id}
# operationId: get-finetuned-model
export def "finetuning-finetuned-models get-finetuned-model" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<finetuned_model: record<id: string, name: string, creator_id: string, organization_id: string, settings: record<base_model: record, dataset_id: string, hyperparameters: record, multi_label: bool, wandb: record>, status: string, created_at: string, updated_at: string, completed_at: string, last_used: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/finetuning/finetuned-models/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a fine-tuned model.
#
# DELETE /v1/finetuning/finetuned-models/{id}
# operationId: delete-finetuned-model
export def "finetuning-finetuned-models delete-finetuned-model" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/finetuning/finetuned-models/($id)")
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch history of statuses for a fine-tuned model.
#
# GET /v1/finetuning/finetuned-models/{finetuned_model_id}/events
# operationId: list-events
export def "finetuning-finetuned-models-events list-events" [
  finetuned_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Maximum number of results to be returned by the server. If 0, defaults to 50.
  --page-token: string # Request a specific page of the list results.
  --order-by: string # Comma separated list of fields. For example: "created_at,name". The default sorting order is ascending. To specify descending order for a field, append " desc" to the field name. For example: "created_at desc,name".  Supported sorting fields:   - created_at (default)
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<events: table<user_id: string, status: string, created_at: string>, next_page_token: string, total_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/finetuning/finetuned-models/($finetuned_model_id)/events" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve training metrics for fine-tuned models.
#
# GET /v1/finetuning/finetuned-models/{finetuned_model_id}/training-step-metrics
# operationId: list-training-step-metrics
export def "finetuning-finetuned-models-training-step-metrics list-training-step-metrics" [
  finetuned_model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Maximum number of results to be returned by the server. If 0, defaults to 50.
  --page-token: string # Request a specific page of the list results.
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
]: nothing -> record<step_metrics: table<created_at: string, step_number: int, metrics: record>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/finetuning/finetuned-models/($finetuned_model_id)/training-step-metrics" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate
#
# POST /v1/generate
# operationId: generate-stream
export def "generate generate-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  prompt: string # The input text that serves as the starting point for generating the response. Note: The prompt will be pre-processed and modified before reaching the model.
  --model: string # The identifier of the model to generate with. Currently available models are `command` (default), `command-nightly` (experimental), `command-light`, and `command-light-nightly` (experimental). Smaller, "light" models are faster, while larger models will perform better. [Custom models](https://docs.cohere.com/docs/training-custom-models) can also be supplied with their full ID.
  --num-generations: int # The maximum number of generations that will be returned. Defaults to `1`, min value of `1`, max value of `5`.
  --stream: string@bool-completer # When `true`, the response will be a JSON stream of events. Streaming is beneficial for user interfaces that render the contents of the response piece by piece, as it gets generated.  The final event will contain the complete response, and will contain an `is_finished` field set to `true`. The event will also contain a `finish_reason`, which can be one of the following: - `COMPLETE` - the model sent back a finished reply - `MAX_TOKENS` - the reply was cut off because the model reached the maximum number of tokens for its context length - `ERROR` - something went wrong when generating the reply - `ERROR_TOXIC` - the model generated a reply that was deemed toxic
  --max-tokens: int # The maximum number of tokens the model will generate as part of the response. Note: Setting a low value may result in incomplete generations.  This parameter is off by default, and if it's not specified, the model will continue generating until it emits an EOS completion token. See [BPE Tokens](/bpe-tokens-wiki) for more details.  Can only be set to `0` if `return_likelihoods` is set to `ALL` to get the likelihood of the prompt.
  --truncate: string@truncate-completer # One of `NONE|START|END` to specify how the API will handle inputs longer than the maximum token length.  Passing `START` will discard the start of the input. `END` will discard the end of the input. In both cases, input is discarded until the remaining input is exactly the maximum input token length for the model.  If `NONE` is selected, when the input exceeds the maximum input token length an error will be returned. (default: END)
  --temperature: float # A non-negative float that tunes the degree of randomness in generation. Lower temperatures mean less random generations. See [Temperature](/temperature-wiki) for more details. Defaults to `0.75`, min value of `0.0`, max value of `5.0`.  (format: double)
  --seed: int # If specified, the backend will make a best effort to sample tokens deterministically, such that repeated requests with the same seed and parameters should return the same result. However, determinism cannot be totally guaranteed. Compatible Deployments: Cohere Platform, Azure, AWS Sagemaker/Bedrock, Private Deployments
  --preset: string # Identifier of a custom preset. A preset is a combination of parameters, such as prompt, temperature etc. You can create presets in the [playground](https://dashboard.cohere.com/playground/generate). When a preset is specified, the `prompt` parameter becomes optional, and any included parameters will override the preset's parameters.
  --end-sequences: list # The generated text will be cut at the beginning of the earliest occurrence of an end sequence. The sequence will be excluded from the text.
  --stop-sequences: list # The generated text will be cut at the end of the earliest occurrence of a stop sequence. The sequence will be included the text.
  --k: int # Ensures only the top `k` most likely tokens are considered for generation at each step. Defaults to `0`, min value of `0`, max value of `500`.
  --p: float # Ensures that only the most likely tokens, with total probability mass of `p`, are considered for generation at each step. If both `k` and `p` are enabled, `p` acts after `k`. Defaults to `0.75`. min value of `0.01`, max value of `0.99`.  (format: double)
  --frequency-penalty: float # Used to reduce repetitiveness of generated tokens. The higher the value, the stronger a penalty is applied to previously present tokens, proportional to how many times they have already appeared in the prompt or prior generation.  Using `frequency_penalty` in combination with `presence_penalty` is not supported on newer models.  (format: double)
  --presence-penalty: float # Defaults to `0.0`, min value of `0.0`, max value of `1.0`.  Can be used to reduce repetitiveness of generated tokens. Similar to `frequency_penalty`, except that this penalty is applied equally to all tokens that have already appeared, regardless of their exact frequencies.  Using `frequency_penalty` in combination with `presence_penalty` is not supported on newer models.  (format: double)
  --return-likelihoods: string@return-likelihoods-completer # One of `GENERATION|NONE` to specify how and if the token likelihoods are returned with the response. Defaults to `NONE`.  If `GENERATION` is selected, the token likelihoods will only be provided for generated text.  WARNING: `ALL` is deprecated, and will be removed in a future release. (default: NONE)
  --raw-prompting: string@bool-completer # When enabled, the user's prompt will be sent to the model without any pre-processing.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/generate")
  let body = {prompt: $prompt, model: $model, num_generations: $num_generations, stream: $stream, max_tokens: $max_tokens, truncate: $truncate, temperature: $temperature, seed: $seed, preset: $preset, end_sequences: $end_sequences, stop_sequences: $stop_sequences, k: $k, p: $p, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, return_likelihoods: $return_likelihoods, raw_prompting: $raw_prompting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Summarize
#
# POST /v1/summarize
# operationId: summarize
export def "summarize summarize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  text: string # The text to generate a summary for. Can be up to 100,000 characters long. Currently the only supported language is English.
  --length: string@length-completer # One of `short`, `medium`, `long`, or `auto` defaults to `auto`. Indicates the approximate length of the summary. If `auto` is selected, the best option will be picked based on the input text. (default: medium)
  --format: string@format-completer # One of `paragraph`, `bullets`, or `auto`, defaults to `auto`. Indicates the style in which the summary will be delivered - in a free form paragraph or in bullet points. If `auto` is selected, the best option will be picked based on the input text. (default: paragraph)
  --model: string # The identifier of the model to generate the summary with. Currently available models are `command` (default), `command-nightly` (experimental), `command-light`, and `command-light-nightly` (experimental). Smaller, "light" models are faster, while larger models will perform better.
  --extractiveness: string@extractiveness-completer # One of `low`, `medium`, `high`, or `auto`, defaults to `auto`. Controls how close to the original text the summary is. `high` extractiveness summaries will lean towards reusing sentences verbatim, while `low` extractiveness summaries will tend to paraphrase more. If `auto` is selected, the best option will be picked based on the input text. (default: low)
  --temperature: float # Ranges from 0 to 5. Controls the randomness of the output. Lower values tend to generate more “predictable” output, while higher values tend to generate more “creative” output. The sweet spot is typically between 0 and 1. (format: double, default: 0.3)
  --additional-command: string # A free-form instruction for modifying how the summaries get generated. Should complete the sentence "Generate a summary _". Eg. "focusing on the next steps" or "written by Yoda"
]: any -> record<id: string, summary: string, meta: record<api_version: record<version: string, is_deprecated: bool, is_experimental: bool>, billed_units: record<images: float, input_tokens: float, image_tokens: float, output_tokens: float, search_units: float, classifications: float>, tokens: record<input_tokens: float, output_tokens: float>, cached_tokens: float, warnings: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/summarize")
  let body = {text: $text, length: $length, format: $format, model: $model, extractiveness: $extractiveness, temperature: $temperature, additional_command: $additional_command} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Chat prompt (v2)
#
# POST /v2/prompt
# operationId: prompt
# --tools item shape: {type: "function", function?: record}
# --citation_options shape: {mode?: "ENABLED"|"DISABLED"|"FAST"|"ACCURATE"|"OFF"}
# --thinking shape: {type: "enabled"|"disabled", token_budget?: int}
export def "prompt prompt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer authentication
  --X-Client-Name: string # The name of the project that is making the request.
  --stream: string@bool-completer # Defaults to `false`.  When `true`, the response will be a SSE stream of events.  Streaming is beneficial for user interfaces that render the contents of the response piece by piece, as it gets generated.
  model: string # The name of a compatible [Cohere model](https://docs.cohere.com/v2/docs/models).
  messages: list # A list of chat messages in chronological order, representing a conversation between the user and the model.  Messages can be from `User`, `Assistant`, `Tool` and `System` roles. Learn more about messages and roles in [the Chat API guide](https://docs.cohere.com/v2/docs/chat-api).
  --tools: list # A list of tools (functions) available to the model. The model response may contain 'tool_calls' to the specified tools.  Learn more in the [Tool Use guide](https://docs.cohere.com/docs/tools). — item shape: {type: "function", function?: record}
  --strict-tools: string@bool-completer # When set to `true`, tool calls in the Assistant message will be forced to follow the tool definition strictly. Learn more in the [Structured Outputs (Tools) guide](https://docs.cohere.com/docs/structured-outputs-json#structured-outputs-tools).  **Note**: The first few requests with a new set of tools will take longer to process.
  --documents: list # A list of relevant documents that the model can cite to generate a more accurate reply. Each document is either a string or document object with content and metadata.
  --citation-options: record # Options for controlling citation generation. — shape: {mode?: "ENABLED"|"DISABLED"|"FAST"|"ACCURATE"|"OFF"}
  --response-format: any # Configuration for forcing the model output to adhere to the specified format. Supported on [Command R](https://docs.cohere.com/v2/docs/command-r), [Command R+](https://docs.cohere.com/v2/docs/command-r-plus) and newer models.  The model can be forced into outputting JSON objects by setting `{ "type": "json_object" }`.  A [JSON Schema](https://json-schema.org/) can optionally be provided, to ensure a specific structure.  **Note**: When using  `{ "type": "json_object" }` your `message` should always explicitly instruct the model to generate a JSON (eg: _"Generate a JSON ..."_) . Otherwise the model may end up getting stuck generating an infinite stream of characters and eventually run out of context length.  **Note**: When `json_schema` is not specified, the generated object can have up to 5 layers of nesting.  **Limitation**: The parameter is not supported when used in combinations with the `documents` or `tools` parameters.
  --safety-mode: string@safety-mode-completer # Used to select the [safety instruction](https://docs.cohere.com/v2/docs/safety-modes) inserted into the prompt. Defaults to `CONTEXTUAL`. When `OFF` is specified, the safety instruction will be omitted.  Safety modes are not yet configurable in combination with `tools` and `documents` parameters.  **Note**: This parameter is only compatible newer Cohere models, starting with [Command R 08-2024](https://docs.cohere.com/docs/command-r#august-2024-release) and [Command R+ 08-2024](https://docs.cohere.com/docs/command-r-plus#august-2024-release).  **Note**: `command-r7b-12-2024` and newer models only support `"CONTEXTUAL"` and `"STRICT"` modes.
  --max-tokens: int # The maximum number of output tokens the model will generate in the response. If not set, `max_tokens` defaults to the model's maximum output token limit. You can find the maximum output token limits for each model in the [model documentation](https://docs.cohere.com/docs/models).  **Note**: Setting a low value may result in incomplete generations. In such cases, the `finish_reason` field in the response will be set to `"MAX_TOKENS"`.  **Note**: If `max_tokens` is set higher than the model's maximum output token limit, the generation will be capped at that model-specific maximum limit.
  --stop-sequences: list # A list of up to 5 strings that the model will use to stop generation. If the model generates a string that matches any of the strings in the list, it will stop generating tokens and return the generated text up to that point not including the stop sequence.
  --temperature: float # Defaults to `0.3`.  A non-negative float that tunes the degree of randomness in generation. Lower temperatures mean less random generations, and higher temperatures mean more random generations.  Randomness can be further maximized by increasing the  value of the `p` parameter.  (format: double)
  --seed: int # If specified, the backend will make a best effort to sample tokens deterministically, such that repeated requests with the same seed and parameters should return the same result. However, determinism cannot be totally guaranteed.
  --frequency-penalty: float # Defaults to `0.0`, min value of `0.0`, max value of `1.0`. Used to reduce repetitiveness of generated tokens. The higher the value, the stronger a penalty is applied to previously present tokens, proportional to how many times they have already appeared in the prompt or prior generation.  (format: double)
  --presence-penalty: float # Defaults to `0.0`, min value of `0.0`, max value of `1.0`. Used to reduce repetitiveness of generated tokens. Similar to `frequency_penalty`, except that this penalty is applied equally to all tokens that have already appeared, regardless of their exact frequencies.  (format: double)
  --k: int # Ensures that only the top `k` most likely tokens are considered for generation at each step. When `k` is set to `0`, k-sampling is disabled. Defaults to `0`, min value of `0`, max value of `500`.  (default: 0)
  --p: float # Ensures that only the most likely tokens, with total probability mass of `p`, are considered for generation at each step. If both `k` and `p` are enabled, `p` acts after `k`. Defaults to `0.75`. min value of `0.01`, max value of `0.99`.  (format: double, default: 0.75)
  --logprobs: string@bool-completer # Defaults to `false`. When set to `true`, the log probabilities of the generated tokens will be included in the response.
  --tool-choice: string@tool-choice-completer # Used to control whether or not the model will be forced to use a tool when answering. When `REQUIRED` is specified, the model will be forced to use at least one of the user-defined tools, and the `tools` parameter must be passed in the request. When `NONE` is specified, the model will be forced **not** to use one of the specified tools, and give a direct response. If tool_choice isn't specified, then the model is free to choose whether to use the specified tools or not.  **Note**: This parameter is only compatible with models [Command-r7b](https://docs.cohere.com/v2/docs/command-r7b) and newer.
  --thinking: record # Configuration for [reasoning features](https://docs.cohere.com/docs/reasoning). — shape: {type: "enabled"|"disabled", token_budget?: int}
  --priority: int # Controls how early the request is handled. Lower numbers indicate higher priority (default: 0, the highest). When the system is under load, higher-priority requests are processed first and are the least likely to be dropped. (default: 0)
]: any -> record<prompt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/prompt")
  let body = {stream: $stream, model: $model, messages: $messages, tools: $tools, strict_tools: $strict_tools, documents: $documents, citation_options: $citation_options, response_format: $response_format, safety_mode: $safety_mode, max_tokens: $max_tokens, stop_sequences: $stop_sequences, temperature: $temperature, seed: $seed, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, k: $k, p: $p, logprobs: $logprobs, tool_choice: $tool_choice, thinking: $thinking, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Client-Name": $X_Client_Name} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
