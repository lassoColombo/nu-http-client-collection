# Auto-generated client for Pinecone assistant data plane API v2026-04
# Source: https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/assistant_data_2026-04.oas.yaml
# Auth: --token flag or $env.PINECONE_ASSISTANT_DATA_PLANE_API_TOKEN

const BASE_URL = "https://unknown"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PINECONE_ASSISTANT_DATA_PLANE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {Api-Key: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://unknown"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/event-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "files files" } } | get name | first)
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

# List Files
#
# GET /files/{assistant_name}
# operationId: list_files
export def "files files" [
  assistant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # Optional JSON-encoded metadata filter for files. (format: json, e.g. {"genre":{"$eq":"comedy"}})
  --limit: int # Limit on the number of files to return. (e.g. 100)
  --pagination-token: string # Pagination token to continue a previous listing operation. (e.g. dXNlcl9pZD11c2VyXzE=)
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<files: table<name: string, id: string, size: int, metadata: record, created_on: string, updated_on: string, status: string, signed_url: string, multimodal: bool>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pagination_token" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($assistant_name)" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file
#
# POST /files/{assistant_name}
# operationId: upload_file
export def "files file-by-assistant_name" [
  assistant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --multimodal: string # Optional flag to opt in to multimodal file processing (PDFs only). Can be either `true` or `false`. Default is `false`.
  --X-Pinecone-Api-Version: string # Required date-based version header
  file: string # The file to upload. (format: binary)
  --metadata: record # Optional metadata associated with the file. This metadata can be used to filter files when listing them or to restrict search results when querying the assistant. Maximum size is 16KB. (nullable, e.g. {created_by: Jane Doe, published: 2025-10-01, tags: [report, Q4, analytics]})
]: any -> record<id: string, operation_type: string, file_id: string, status: string, created_on: string, completed_on: string, percent_complete: int, error_message: string, ingestion_units: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "multimodal" $multimodal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($assistant_name)" $qp)
  let body = {file: $file, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Describe a file
#
# GET /files/{assistant_name}/{assistant_file_id}
# operationId: describe_file
export def "files file-by-assistant_name-assistant_file_id" [
  assistant_name: string
  assistant_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-url: string # Include the signed URL of the file in the response.
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<name: string, id: string, size: int, metadata: record, created_on: string, updated_on: string, status: string, signed_url: string, multimodal: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_url" $include_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($assistant_name)/($assistant_file_id)" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert a file
#
# PUT /files/{assistant_name}/{assistant_file_id}
# operationId: upsert_file
export def "files file-by-assistant_name-assistant_file_id-1" [
  assistant_name: string
  assistant_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --multimodal: string # Optional flag to opt in to multimodal file processing (PDFs only). Can be either `true` or `false`. Default is `false`.
  --X-Pinecone-Api-Version: string # Required date-based version header
  file: string # The file to upload. (format: binary)
  --metadata: record # Optional metadata associated with the file. This metadata can be used to filter files when listing them or to restrict search results when querying the assistant. Maximum size is 16KB. (nullable, e.g. {created_by: Jane Doe, published: 2025-10-01, tags: [report, Q4, analytics]})
]: any -> record<id: string, operation_type: string, file_id: string, status: string, created_on: string, completed_on: string, percent_complete: int, error_message: string, ingestion_units: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "multimodal" $multimodal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($assistant_name)/($assistant_file_id)" $qp)
  let body = {file: $file, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a file
#
# DELETE /files/{assistant_name}/{assistant_file_id}
# operationId: delete_file
export def "files file-by-assistant_name-assistant_file_id-2" [
  assistant_name: string
  assistant_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<id: string, operation_type: string, file_id: string, status: string, created_on: string, completed_on: string, percent_complete: int, error_message: string, ingestion_units: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($assistant_name)/($assistant_file_id)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List operations
#
# GET /operations/{assistant_name}
# operationId: list_operations
export def "operations operations" [
  assistant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --operation-type: string # Filter operations by type. (e.g. upload_file)
  --status: string # Filter operations by status. (e.g. Processing)
  --limit: int # Limit on the number of operations to return. (e.g. 100)
  --pagination-token: string # Pagination token to continue a previous listing operation. (e.g. dXNlcl9pZD11c2VyXzE=)
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<operations: table<id: string, operation_type: string, file_id: string, status: string, created_on: string, completed_on: string, percent_complete: int, error_message: string, ingestion_units: float>, pagination: record<next: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operation_type" $operation_type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pagination_token" $pagination_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/operations/($assistant_name)" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Describe an operation
#
# GET /operations/{assistant_name}/{operation_id}
# operationId: describe_operation
export def "operations operation" [
  assistant_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<id: string, operation_type: string, file_id: string, status: string, created_on: string, completed_on: string, percent_complete: int, error_message: string, ingestion_units: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/operations/($assistant_name)/($operation_id)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Chat through an OpenAI-compatible interface
#
# POST /chat/{assistant_name}/chat/completions
# operationId: chat_completion_assistant
# --messages item shape: {role?: string, content?: string}
export def "chat-chat-completions assistant" [
  assistant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Pinecone-Api-Version: string # Required date-based version header
  messages: list # The list of messages sent to the assistant, used for context retrieval and generating response with the LLM. — item shape: {role?: string, content?: string}
  --stream: string@bool-completer # If `false`, the assistant returns a single JSON response. If `true`, the assistant returns a stream of responses. (default: false)
  --model: string # The large language model used to generate responses. (default: gpt-4o)
  --temperature: float # Controls the randomness of the model's output: lower values make responses more deterministic, while higher values increase creativity and variability. If the model does not support a temperature parameter, the parameter will be ignored. (format: float, default: 0.0)
  --filter: record # Optional metadata-based filter to restrict which documents are retrieved for the assistant's response context. (e.g. {genre: {$ne: documentary}})
]: any -> record<id: string, choices: table<finish_reason: string, index: int, message: record>, model: string, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chat/($assistant_name)/chat/completions")
  let body = {messages: $messages, stream: $stream, model: $model, temperature: $temperature, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Chat with an assistant
#
# POST /chat/{assistant_name}
# operationId: chat_assistant
# --messages item shape: {role?: string, content?: string}
# --context_options shape: {top_k?: int, snippet_size?: int, multimodal?: bool, include_binary_content?: bool}
export def "chat assistant" [
  assistant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Pinecone-Api-Version: string # Required date-based version header
  messages: list # The list of messages sent to the assistant, used for context retrieval and generating response with the LLM. — item shape: {role?: string, content?: string}
  --stream: string@bool-completer # If `false`, the assistant returns a single JSON response. If `true`, the assistant returns a stream of responses. (default: false)
  --model: string # The large language model used to generate responses. (default: gpt-4o)
  --temperature: float # Controls the randomness of the model's output: lower values make responses more deterministic, while higher values increase creativity and variability. If the model does not support a temperature parameter, the parameter will be ignored. (format: float, default: 0.0)
  --filter: record # Optional metadata-based filter to restrict which documents are retrieved for the assistant's response context. (e.g. {genre: {$ne: documentary}})
  --json-response: string@bool-completer # If `true`, instructs the assistant to return a JSON-formatted response. Cannot be used together with streaming mode. (default: false)
  --include-highlights: string@bool-completer # If `true`, instructs the assistant to include highlights from the referenced documents that support its response. (default: false)
  --context-options: record # Controls the context snippets sent to the LLM. — shape: {top_k?: int, snippet_size?: int, multimodal?: bool, include_binary_content?: bool}
]: any -> record<id: string, finish_reason: string, message: record<role: string, content: string>, model: string, citations: table<position: int, references: list>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int>, context_snippet_count: int, content_filter_results: record<spec: string, results: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chat/($assistant_name)")
  let body = {messages: $messages, stream: $stream, model: $model, temperature: $temperature, filter: $filter, json_response: $json_response, include_highlights: $include_highlights, context_options: $context_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve context from an assistant
#
# POST /chat/{assistant_name}/context
# operationId: context_assistant
# --messages item shape: {role?: string, content?: string}
export def "chat-context assistant" [
  assistant_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  --body-query: string # The query that is used to generate the context. Exactly one of query or messages should be provided.
  --filter: record # Optionally filter which documents can be retrieved using the following metadata fields. (e.g. {genre: {$ne: documentary}})
  --messages: list # The list of messages to use for generating the context. Exactly one of query or messages should be provided. — item shape: {role?: string, content?: string}
  --top-k: int # The maximum number of context snippets to return. Default is 16. Maximum is 64. (e.g. 20)
  --snippet-size: int # The maximum context snippet size. Default is 2048 tokens. Minimum is 512 tokens. Maximum is 8192 tokens. (e.g. 4096)
  --multimodal: string@bool-completer # Whether or not to retrieve image-related context snippets. If `false`, only text snippets are returned. (default: true)
  --include-binary-content: string@bool-completer # If image-related context snippets are returned, this field determines whether or not they should include base64 image data. If `false`, only the image captions are returned. Only available when `multimodal=true`. (default: true)
]: any -> record<id: string, snippets: list<record>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/chat/($assistant_name)/context")
  let body = {query: $body_query, filter: $filter, messages: $messages, top_k: $top_k, snippet_size: $snippet_size, multimodal: $multimodal, include_binary_content: $include_binary_content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
