# Auto-generated client for Vectara REST API v2 v2.0
# Source: https://docs.vectara.com/vectara-oas-v2.yaml
# Auth: --token flag or $env.VECTARA_REST_API_V2_TOKEN

const BASE_URL = "https://api.vectara.io"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VECTARA_REST_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.vectara.io"] }
def auth-scheme-completer [] { ["bearer" "x-api-key"] }

# Completers for enum parameters
def wait-for-completer [] { ["indexed" "searchable"] }
def type-completer [] { ["core" "structured"] }
def accept-completer [] { ["application/json" "text/event-stream"] }
def level-completer [] { ["document" "part"] }
def type-completer-1 [] { ["anthropic" "openai-compatible" "openai-responses" "vertex-ai"] }
def ownership-completer [] { ["customer" "platform"] }
def type-completer-2 [] { ["openai-compatible" "vllm-compatible"] }
def api-key-role-completer [] { ["personal" "serving" "serving_and_indexing"] }
def type-completer-3 [] { ["client_credentials"] }
def type-completer-4 [] { ["mcp"] }
def transport-completer [] { ["sse" "streamable-http"] }
def type-completer-5 [] { ["client" "lambda"] }
def language-completer [] { ["python"] }
def type-completer-6 [] { ["client" "lambda" "mcp"] }
def type-completer-7 [] { ["initial"] }
def template-type-completer [] { ["velocity"] }
def type-completer-8 [] { ["compact" "input_message" "interrupt" "tool_output"] }
def sort-by-completer [] { ["created_at" "updated_at"] }
def order-by-completer [] { ["asc" "desc"] }
def mode-completer [] { ["auto" "manual"] }
def type-completer-9 [] { ["gchat" "slack"] }
def sync-mode-completer [] { ["full_refresh" "incremental"] }
def source-type-completer [] { ["google_drive" "s3" "sharepoint" "web"] }
def status-completer [] { ["active" "error" "initializing" "paused"] }
def status-completer-1 [] { ["pending" "retrying"] }
def origin-completer [] { ["manual" "pipeline"] }
def status-completer-2 [] { ["cancelled" "completed" "failed" "running"] }
def order-completer [] { ["asc" "desc"] }
def status-completer-3 [] { ["error" "ok"] }
def error-type-completer [] { ["actions_limit_reached" "context_limit_exceeded" "internal" "llm_generation_error" "step_transition_limit_exceeded" "stream_error"] }
def operation-completer [] { ["chat" "compaction" "execute_tool" "guardrail" "image_read" "invoke_agent" "output" "step_transition" "thinking"] }
def tool-error-type-completer [] { ["dependency_failed" "execution_error" "invalid_configuration" "invalid_input" "not_found" "timeout"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "corpora createCorpus" } } | get name | first)
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

# Create a corpus
#
# POST /v2/corpora
# operationId: createCorpus
# --filter_attributes item shape: {name: string, level: "document"|"part", description?: string, indexed?: bool, type: "integer"|"real_number"|"text"|"boolean"|"list[integer]"|"list[real_number]"|"list[text]"}
# --custom_dimensions item shape: {name: string, description?: string, indexing_default?: float, querying_default?: float}
@deprecated --flag encoder-id
export def "corpora createCorpus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  key: string # A user-provided key for a corpus. (e.g. my-corpus)
  --name: string # The name for the corpus. This value defaults to the key. (e.g. My corpus)
  --description: string # Description of the corpus. (e.g. Documents with important information for my prompt.)
  --save-history: oneof<nothing, bool> # Indicates whether to save corpus queries to query history by default. (default: false)
  --queries-are-answers: oneof<nothing, bool> # Queries made to this corpus are considered answers, and not questions. (default: false)
  --documents-are-questions: oneof<nothing, bool> # Documents inside this corpus are considered questions, and not answers. (default: false)
  --encoder-id: string # *Deprecated*: Use `encoder_name` instead. (DEPRECATED, e.g. enc_1)
  --encoder-name: string # The encoder used by the corpus, `boomerang-2023-q3`. (e.g. boomerang-2023-q3)
  --filter-attributes: list # The new filter attributes of the corpus. If unset then the corpus will not have filter attributes. (default: []) — item shape: {name: string, level: "document"|"part", description?: string, indexed?: bool, type: "integer"|"real_number"|"text"|"boolean"|"list[integer]"|"list[real_number]"|"list[text]"}
  --custom-dimensions: list # A custom dimension is an additional numerical field attached to a document part. You can then multiply this numerical field with a query time custom dimension of the same name. This allows boosting (or burying) document parts for arbitrary reasons. This feature is only enabled for Pro and Enterprise customers. (default: []) — item shape: {name: string, description?: string, indexing_default?: float, querying_default?: float}
]: any -> record<id: string, key: string, name: string, description: string, enabled: bool, chat_history_corpus: bool, queries_are_answers: bool, documents_are_questions: bool, encoder_id: string, encoder_name: string, save_history: bool, filter_attributes: table<name: string, level: string, description: string, indexed: bool, type: string>, custom_dimensions: table<name: string, description: string, indexing_default: float, querying_default: float>, limits: record<used_docs: int, used_parts: int, used_bytes: int, used_characters: int, max_bytes: int, max_metadata_bytes: int, index_rate: int>, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/corpora")
  let body = {key: $key, name: $name, description: $description, save_history: $save_history, queries_are_answers: $queries_are_answers, documents_are_questions: $documents_are_questions, encoder_id: $encoder_id, encoder_name: $encoder_name, filter_attributes: $filter_attributes, custom_dimensions: $custom_dimensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List corpora
#
# GET /v2/corpora
# operationId: listCorpora
export def "corpora listCorpora" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of corpora to return at one time. (format: int32, default: 10)
  --filter: string # A regular expression to filter the corpora by their name or summary. (e.g. Vectara Content)
  --corpus-id: list # Filter corpora to only include corpora with these IDs. (e.g. [crp_12345])
  --page-key: string # Used to retrieve the next page of corpora after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<corpora: table<id: string, key: string, name: string, description: string, enabled: bool, chat_history_corpus: bool, queries_are_answers: bool, documents_are_questions: bool, encoder_id: string, encoder_name: string, save_history: bool, filter_attributes: list, custom_dimensions: list, limits: record, created_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "corpus_id" $corpus_id "multi") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/corpora" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve metadata about a corpus
#
# GET /v2/corpora/{corpus_key}
# operationId: getCorpus
export def "corpora get" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, key: string, name: string, description: string, enabled: bool, chat_history_corpus: bool, queries_are_answers: bool, documents_are_questions: bool, encoder_id: string, encoder_name: string, save_history: bool, filter_attributes: table<name: string, level: string, description: string, indexed: bool, type: string>, custom_dimensions: table<name: string, description: string, indexing_default: float, querying_default: float>, limits: record<used_docs: int, used_parts: int, used_bytes: int, used_characters: int, max_bytes: int, max_metadata_bytes: int, index_rate: int>, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a corpus and all its data
#
# DELETE /v2/corpora/{corpus_key}
# operationId: deleteCorpus
export def "corpora delete" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a corpus
#
# PATCH /v2/corpora/{corpus_key}
# operationId: updateCorpus
export def "corpora updateCorpus" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --enabled: oneof<nothing, bool> # Set whether or not the corpus is enabled. If unset then the corpus will remain in the same state. (e.g. false)
  --name: string # The name for the corpus. If unset or null, then the corpus will remain in the same state. (e.g. new-corpus-name)
  --description: string # Description of the corpus. If unset or null, then the corpus will remain in the same state. (e.g. New description of the corpus.)
  --save-history: oneof<nothing, bool> # Indicates whether to save corpus queries to query history by default.
]: any -> record<id: string, key: string, name: string, description: string, enabled: bool, chat_history_corpus: bool, queries_are_answers: bool, documents_are_questions: bool, encoder_id: string, encoder_name: string, save_history: bool, filter_attributes: table<name: string, level: string, description: string, indexed: bool, type: string>, custom_dimensions: table<name: string, description: string, indexing_default: float, querying_default: float>, limits: record<used_docs: int, used_parts: int, used_bytes: int, used_characters: int, max_bytes: int, max_metadata_bytes: int, index_rate: int>, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)")
  let body = {enabled: $enabled, name: $name, description: $description, save_history: $save_history} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove all documents and data in a corpus
#
# POST /v2/corpora/{corpus_key}/reset
# operationId: resetCorpus
export def "corpora-reset resetCorpus" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/reset")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace the filter attributes of a corpus
#
# POST /v2/corpora/{corpus_key}/replace_filter_attributes
# operationId: replaceFilterAttributes
# --filter_attributes item shape: {name: string, level: "document"|"part", description?: string, indexed?: bool, type: "integer"|"real_number"|"text"|"boolean"|"list[integer]"|"list[real_number]"|"list[text]"}
export def "corpora-replace-filter-attributes replaceFilterAttributes" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  filter_attributes: list # The new filter attributes. — item shape: {name: string, level: "document"|"part", description?: string, indexed?: bool, type: "integer"|"real_number"|"text"|"boolean"|"list[integer]"|"list[real_number]"|"list[text]"}
]: any -> record<job_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/replace_filter_attributes")
  let body = {filter_attributes: $filter_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compute the current size of a corpus
#
# POST /v2/corpora/{corpus_key}/compute_size
# operationId: computeCorpusSize
export def "corpora-compute-size computeCorpusSize" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<used_docs: int, used_parts: int, used_characters: int, used_metadata_characters: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/compute_size")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get filter attribute statistics for corpus metadata
#
# GET /v2/corpora/{corpus_key}/filter_attribute_stats
# operationId: getFilterAttributeStats
export def "corpora-filter-attribute-stats get" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Comma-separated list of qualified field names to retrieve statistics for (e.g., 'doc.category,part.status'). If omitted, returns statistics for all filter attributes in the corpus. Field names must match the qualified format 'level.fieldname' where level is either 'doc' or 'part'. (e.g. doc.category,doc.year,part.status)
  --metadata-filter: string # Optional metadata filter expression to pre-filter documents or parts before computing statistics. Uses the same SQL-style filter syntax as query operations. When provided, statistics reflect only the filtered subset of the corpus. (e.g. doc.year >= 2020 AND doc.category = 'financial')
  --max-values: int # Maximum number of distinct values to return per field in the 'values' array, ordered by occurrence count (descending). (format: int32, default: 100, e.g. 50)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<filter_attribute_stats: table<name: string, type: string, description: string, values: list, stats: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "metadata_filter" $metadata_filter "scalar") (serialize-qp "max_values" $max_values "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/filter_attribute_stats" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a file to the corpus
#
# POST /v2/corpora/{corpus_key}/upload_file
# operationId: uploadFile
# --chunking_strategy shape: {type: "max_chars_chunking_strategy"|"sentence_chunking_strategy", max_chars_per_chunk?: int}
# --table_extraction_config shape: {extract_tables: bool, extractor?: record, generation?: record}
export def "corpora-upload-file uploadFile" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --metadata: record # Arbitrary object that will be attached as document metadata to the extracted document. (e.g. {department: engineering, doc_type": architecture_diagram})
  --chunking-strategy: record # Choose how to split documents into chunks during indexing. This is optional - if you do not set a chunking strategy, the platform uses the default strategy which creates one chunk (docpart) per sentence. — shape: {type: "max_chars_chunking_strategy"|"sentence_chunking_strategy", max_chars_per_chunk?: int}
  --table-extraction-config: record # Configuration for table extraction from the document. This is optional and if not provided, the platform does not extract tables from PDF files. — shape: {extract_tables: bool, extractor?: record, generation?: record}
  --filename: string # Optional multipart section to override the filename. (e.g. system_design_v1.pdf)
  file: string # Binary file contents. The file name of the file will be used as the document ID. (format: binary)
]: any -> record<id: string, metadata: record, tables: table<id: string, title: string, data: record, description: string>, images: table<id: string, title: string, caption: string, description: string, mime_type: string>, parts: table<text: string, metadata: record, table_id: string, image_id: string, context: string, custom_dimensions: record>, storage_usage: record<bytes_used: int, metadata_bytes_used: int>, extraction_usage: record<table_extraction_used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/upload_file")
  let body = {metadata: $metadata, chunking_strategy: $chunking_strategy, table_extraction_config: $table_extraction_config, filename: $filename, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Add a document to a corpus
#
# POST /v2/corpora/{corpus_key}/documents
# Discriminator (request): type = core, structured
# operationId: createCorpusDocument
# --tables item shape: {id?: string, title?: string, data?: record, description?: string}
# --images item shape: {id: string, title?: string, caption?: string, image_data: record, description?: string}
# --document_parts item shape: {text: string, metadata?: record, table_id?: string, image_id?: string, image_part_mode?: "text"|"image"|"image_and_text", context?: string, custom_dimensions?: record}
# --sections item shape: {id?: int, title?: string, text: string, metadata?: record, tables?: list, images?: list, sections?: list}
# --chunking_strategy shape: {type: "max_chars_chunking_strategy"|"sentence_chunking_strategy", max_chars_per_chunk?: int}
export def "corpora-documents createCorpusDocument" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait-for: string@wait-for-completer # Controls how long the request waits before returning a response. - `searchable` (default): Waits until the document is fully indexed and immediately searchable. Use this when you need to query the document immediately after indexing. - `indexed`: Waits until the document is durably stored and will be included in future search results. This is faster but the document may not appear in search results for a brief period after the response.  Both modes return a successful response once the specified condition is met.  (default: searchable)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --id: string # The document ID must be unique within the corpus. (e.g. Invoice-403)
  type: string@type-completer # When the type of the indexed document is `core` the rest of the object is expected to follow this schema. This schema allows precise specification of document chunks that get directly translated to retrieve search results. (default: core)
  --metadata: record # Arbitrary object of document level metadata. Properties of this object can be used by document filters if defined as a corpus filter attribute. (e.g. {title: Customer Billing Information, lang: eng})
  --tables: list # The tables that this document contains. — item shape: {id?: string, title?: string, data?: record, description?: string}
  --images: list # The images that this document contains. — item shape: {id: string, title?: string, caption?: string, image_data: record, description?: string}
  --document-parts: list # Parts of the document that make up the document. — item shape: {text: string, metadata?: record, table_id?: string, image_id?: string, image_part_mode?: "text"|"image"|"image_and_text", context?: string, custom_dimensions?: record}
  --title: string # The title of the document.
  --description: string # The description of the document. (e.g. Comprehensive report on EuroBank’s environmental, social, and governance initiatives for 2024.)
  --custom-dimensions: record # The custom dimensions as additional weights. (nullable)
  --sections: list # The subsection of the document. — item shape: {id?: int, title?: string, text: string, metadata?: record, tables?: list, images?: list, sections?: list}
  --chunking-strategy: record # Choose how to split documents into chunks during indexing. This is optional - if you do not set a chunking strategy, the platform uses the default strategy which creates one chunk (docpart) per sentence. — shape: {type: "max_chars_chunking_strategy"|"sentence_chunking_strategy", max_chars_per_chunk?: int}
]: any -> record<id: string, metadata: record, tables: table<id: string, title: string, data: record, description: string>, images: table<id: string, title: string, caption: string, description: string, mime_type: string>, parts: table<text: string, metadata: record, table_id: string, image_id: string, context: string, custom_dimensions: record>, storage_usage: record<bytes_used: int, metadata_bytes_used: int>, extraction_usage: record<table_extraction_used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait_for" $wait_for "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents" $qp)
  let body = {id: $id, type: $type, metadata: $metadata, tables: $tables, images: $images, document_parts: $document_parts, title: $title, description: $description, custom_dimensions: $custom_dimensions, sections: $sections, chunking_strategy: $chunking_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the documents in the corpus
#
# GET /v2/corpora/{corpus_key}/documents
# operationId: listCorpusDocuments
export def "corpora-documents listCorpusDocuments" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of documents to return at one time. (format: int32, default: 10)
  --metadata-filter: string # Filter documents by metadata. Uses the same expression as a query metadata filter, but only allows filtering on document metadata.
  --page-key: string # Used to retrieve the next page of documents after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<documents: table<id: string, metadata: record, tables: list, images: list, parts: list, storage_usage: record, extraction_usage: record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "metadata_filter" $metadata_filter "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk delete documents from a corpus
#
# DELETE /v2/corpora/{corpus_key}/documents
# Discriminator (response): response_type = async, success
# operationId: bulkDeleteCorpusDocuments
export def "corpora-documents bulkDeleteCorpusDocuments" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata-filter: string # Filter documents by metadata. Uses the same expression as a query metadata filter. Example: `doc.status = 'archived' AND doc.year < 2020`
  --document-ids: string # Comma-separated list of document IDs to delete. Maximum 10,000 IDs per request.
  --async: oneof<nothing, bool> # Whether to perform the deletion asynchronously. - `true` (default): Returns immediately with job_id to track progress (HTTP 202) - `false`: Waits for completion and returns deletion results (HTTP 200)  When `async=false`, the operation will wait for the deletion to complete up to the timeout specified in the `Request-Timeout` or `Request-Timeout-Millis` header. If no timeout header is provided, defaults to 7 days. If the operation times out, returns HTTP 504 with job_id to track via Jobs API.  The workflow continues running in the background even if the API wait times out.  (default: true)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata_filter" $metadata_filter "scalar") (serialize-qp "document_ids" $document_ids "scalar") (serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a document
#
# DELETE /v2/corpora/{corpus_key}/documents/{document_id}
# operationId: deleteCorpusDocument
export def "corpora-documents delete" [
  corpus_key: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents/($document_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a document
#
# GET /v2/corpora/{corpus_key}/documents/{document_id}
# operationId: getCorpusDocument
export def "corpora-documents get" [
  corpus_key: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, metadata: record, tables: table<id: string, title: string, data: record, description: string>, images: table<id: string, title: string, caption: string, description: string, mime_type: string>, parts: table<text: string, metadata: record, table_id: string, image_id: string, context: string, custom_dimensions: record>, storage_usage: record<bytes_used: int, metadata_bytes_used: int>, extraction_usage: record<table_extraction_used: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents/($document_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update document, merging the metadata.
#
# PATCH /v2/corpora/{corpus_key}/documents/{document_id}
# operationId: updateCorpusDocument
export def "corpora-documents updateCorpusDocument" [
  corpus_key: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --metadata: record # The metadata for a document as an arbitrary object. Properties of this object can be used by document level filter attributes. (e.g. {title: 2024 ESG Annual Report – EuroBank, region: EU, industry: banking, year: 2024})
]: any -> record<id: string, metadata: record, tables: table<id: string, title: string, data: record, description: string>, images: table<id: string, title: string, caption: string, description: string, mime_type: string>, parts: table<text: string, metadata: record, table_id: string, image_id: string, context: string, custom_dimensions: record>, storage_usage: record<bytes_used: int, metadata_bytes_used: int>, extraction_usage: record<table_extraction_used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents/($document_id)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace the document metadata.
#
# PUT /v2/corpora/{corpus_key}/documents/{document_id}/metadata
# operationId: replaceCorpusDocumentMetadata
export def "corpora-documents-metadata replaceCorpusDocumentMetadata" [
  corpus_key: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --metadata: record # The metadata for a document as an arbitrary object. Properties of this object can be used by document level filter attributes. (e.g. {title: 2024 ESG Annual Report – EuroBank, region: EU, industry: banking, year: 2024})
]: any -> record<id: string, metadata: record, tables: table<id: string, title: string, data: record, description: string>, images: table<id: string, title: string, caption: string, description: string, mime_type: string>, parts: table<text: string, metadata: record, table_id: string, image_id: string, context: string, custom_dimensions: record>, storage_usage: record<bytes_used: int, metadata_bytes_used: int>, extraction_usage: record<table_extraction_used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents/($document_id)/metadata")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Summarize a document
#
# POST /v2/corpora/{corpus_key}/documents/{document_id}/summarize
# operationId: summarizeCorpusDocument
export def "corpora-documents-summarize summarizeCorpusDocument" [
  corpus_key: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  llm_name: string # The name of the LLM. (e.g. mockingbird-2.0)
  --prompt-template: string # The prompt template to use when generating the summary. Vectara manages both system and user roles and prompts for the generative LLM out of the box by default. However, users can override the `prompt_template` via this variable. The `prompt_template` is in the form of an Apache Velocity template. For more details on how to configure the `prompt_template`, see the [long-form documentation](https://docs.vectara.com/docs/prompts/vectara-prompt-engine). (e.g. Provide a concise summary of the document.)
  --model-parameters: record # Optional parameters for the specified model used when generating the summary.
  --stream-response: oneof<nothing, bool> # Indicates whether the response should be streamed or not. (default: false)
]: any -> record<summary: string, rendered_prompt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents/($document_id)/summarize")
  let body = {llm_name: $llm_name, prompt_template: $prompt_template, model_parameters: $model_parameters, stream_response: $stream_response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an image from a document
#
# GET /v2/corpora/{corpus_key}/documents/{document_id}/images/{image_id}
# operationId: getImage
export def "corpora-documents-images get" [
  corpus_key: string
  document_id: string
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, title: string, caption: string, image_data: record<data: string, mime_type: string>, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/documents/($document_id)/images/($image_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query across metadata fields in a corpus
#
# POST /v2/corpora/{corpus_key}/metadata_query
# operationId: queryMetadata
# --queries item shape: {field: string, query: string, weight?: float, fuzzy?: bool, prefix?: int}
export def "corpora-metadata-query queryMetadata" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --level: string@level-completer # Whether to search document-level or part-level metadata. Document-level returns unique documents, part-level can return multiple parts from the same document. (default: document)
  queries: list # List of field-specific queries to apply fuzzy matching. (e.g. [{field: title, query: lease agreement, weight: 2}, {field: category, query: contract, weight: 1}]) — item shape: {field: string, query: string, weight?: float, fuzzy?: bool, prefix?: int}
  --metadata-filter: string # Optional filter expression to narrow down results before fuzzy matching is applied.  This uses the same expression format as document listing filters and applies exact matching.  (e.g. doc.Status = 'Active')
  --limit: int # Sets the maximum number of documents to return. (default: 10)
  --offset: int # Starting position for pagination. (default: 0)
]: any -> record<documents: table<doc_id: string, score: float, metadata: record>, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/metadata_query")
  let body = {level: $level, queries: $queries, metadata_filter: $metadata_filter, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simple Single Corpus Query
#
# GET /v2/corpora/{corpus_key}/query
# operationId: searchCorpus
export def "corpora-query searchCorpus" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query string for the corpus, which is the question the user is asking.
  --limit: int # The maximum number of top retrieval results to rerank and return. (default: 10)
  --offset: int # The position from which to start in the result set. (default: 0)
  --save-history: oneof<nothing, bool> # Indicates whether to save the query in the query history.
  --intelligent-query-rewriting: oneof<nothing, bool> # [Tech Preview] Indicates whether to enable intelligent query rewriting. When enabled, the platform will attempt to extract metadata filter and rewrite the query to improve search results. Read [here](https://docs.vectara.com/docs/search-and-retrieval/intelligent-query-rewriting) for more details. (default: false)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<summary: string, response_language: string, search_results: list<record>, factual_consistency_score: float, rendered_prompt: string, warnings: list<string>, rewritten_queries: table<corpus_key: string, filter_extraction: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "save_history" $save_history "scalar") (serialize-qp "intelligent_query_rewriting" $intelligent_query_rewriting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/query" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Advanced Single Corpus Query
#
# POST /v2/corpora/{corpus_key}/query
# operationId: queryCorpus
# --generation shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
export def "corpora-query queryCorpus" [
  corpus_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --body-query: string # The search query string, which is the question the user is asking.
  --search: any # The parameters to search one corpus.
  --generation: record # The parameters to control generation. — shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
  --stream-response: oneof<nothing, bool> # Indicates whether the response should be streamed or not. (default: false)
  --save-history: oneof<nothing, bool> # Indicates whether to save the query to query history.
  --intelligent-query-rewriting: oneof<nothing, bool> # [Tech Preview] Indicates whether to enable intelligent query rewriting. When enabled, the platform will attempt to extract metadata filter and rewrite the query to improve search results. Read [here](https://docs.vectara.com/docs/search-and-retrieval/intelligent-query-rewriting) for more details. (default: false)
]: any -> record<summary: string, response_language: string, search_results: list<record>, factual_consistency_score: float, rendered_prompt: string, warnings: list<string>, rewritten_queries: table<corpus_key: string, filter_extraction: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/corpora/($corpus_key)/query")
  let body = {query: $body_query, search: $search, generation: $generation, stream_response: $stream_response, save_history: $save_history, intelligent_query_rewriting: $intelligent_query_rewriting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Multiple Corpora Query
#
# POST /v2/query
# operationId: query
# --generation shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
export def "query query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --body-query: string # The search query string, which is the question the user is asking. (e.g. Am I allowed to bring pets to work?)
  search: any # The parameters to search one or more corpora.
  --generation: record # The parameters to control generation. — shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
  --stream-response: oneof<nothing, bool> # Indicates whether the response should be streamed or not. (default: false)
  --save-history: oneof<nothing, bool> # Indicates whether to save the query to query history.
  --intelligent-query-rewriting: oneof<nothing, bool> # [Tech Preview] Indicates whether to enable intelligent query rewriting. When enabled, the platform will attempt to extract metadata filter and rewrite the query to improve search results. Read [here](https://docs.vectara.com/docs/search-and-retrieval/intelligent-query-rewriting) for more details. (default: false)
]: any -> record<summary: string, response_language: string, search_results: list<record>, factual_consistency_score: float, rendered_prompt: string, warnings: list<string>, rewritten_queries: table<corpus_key: string, filter_extraction: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/query")
  let body = {query: $body_query, search: $search, generation: $generation, stream_response: $stream_response, save_history: $save_history, intelligent_query_rewriting: $intelligent_query_rewriting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a query history
#
# GET /v2/queries/{query_id}
# operationId: getQueryHistory
export def "queries get" [
  query_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, query: record<query: string, search: record<corpora: list, offset: int, limit: int, context_configuration: record, reranker: record, max_by: string>, generation: record<enabled: bool, generation_preset_name: string, prompt_name: string, max_used_search_results: int, prompt_template: string, prompt_text: string, max_response_characters: int, response_language: string, model_parameters: record, citations: record, enable_factual_consistency_score: bool>, stream_response: bool, save_history: bool, intelligent_query_rewriting: bool>, chat_id: string, latency_millis: int, started_at: string, agent_key: string, session_key: string, spans: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/queries/($query_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the history of previous queries
#
# GET /v2/queries
# operationId: getQueryHistories
export def "queries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --corpus-key: string # Specifies the `corpus_key` used in the query. (e.g. my_corpus_key)
  --started-after: string # Queries that started after a particular ISO date-time. (format: date-time)
  --started-before: string # Queries that started before a particular ISO date-time. (format: date-time)
  --chat-id: string # Specifies the chat_id of the query, this will return all queries in the specified chat. (e.g. cht_123456789)
  --history-id: string # Specifies the history_id of the query that you want to use as a filter.
  --limit: int # Specifies the maximum number of query history listed. (default: 10)
  --page-key: string # Used to retrieve the next page of query histories after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<queries: table<id: string, query: string, corpus_key: string, started_at: string, latency_millis: int, chat_id: string, generation: string, factual_consistency_score: float, agent_key: string, session_key: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "corpus_key" $corpus_key "scalar") (serialize-qp "started_after" $started_after "scalar") (serialize-qp "started_before" $started_before "scalar") (serialize-qp "chat_id" $chat_id "scalar") (serialize-qp "history_id" $history_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/queries" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a chat
#
# POST /v2/chats
# DEPRECATED
# operationId: createChat
# --generation shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
# --chat shape: {store?: bool}
@deprecated
export def "chats createChat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --body-query: string # The chat message or question. (e.g. What are the carbon reduction efforts by EU banks in 2023?)
  search: any # The parameters to search one or more corpora.
  --generation: record # The parameters to control generation. — shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
  --chat: record # Parameters to control chat behavior. — shape: {store?: bool}
  --save-history: oneof<nothing, bool> # Indicates whether to save the chat in both the chat and query history. This overrides `chat.store`. (default: true)
  --intelligent-query-rewriting: oneof<nothing, bool> # [Tech Preview] Indicates whether to enable intelligent query rewriting. When enabled, the platform will attempt to extract metadata filter and rewrite the query to improve search results. Read [here](https://docs.vectara.com/docs/search-and-retrieval/intelligent-query-rewriting) for more details. (default: false)
  --stream-response: oneof<nothing, bool> # Indicates whether the response should be streamed or not. (default: false)
]: any -> record<chat_id: string, turn_id: string, answer: string, response_language: string, search_results: list<record>, factual_consistency_score: float, rendered_prompt: string, warnings: list<string>, rephrased_query: string, rewritten_queries: table<corpus_key: string, filter_extraction: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/chats")
  let body = {query: $body_query, search: $search, generation: $generation, chat: $chat, save_history: $save_history, intelligent_query_rewriting: $intelligent_query_rewriting, stream_response: $stream_response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List chats
#
# GET /v2/chats
# DEPRECATED
# operationId: listChats
@deprecated
export def "chats listChats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of results to return in the list. (format: int32, default: 1000)
  --page-key: string # Used to retrieve the next page of chats after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<chats: table<id: string, first_query: string, first_answer: string, enabled: bool, created_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/chats" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a chat
#
# GET /v2/chats/{chat_id}
# DEPRECATED
# operationId: getChat
@deprecated
export def "chats get" [
  chat_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, first_query: string, first_answer: string, enabled: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/chats/($chat_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a chat
#
# DELETE /v2/chats/{chat_id}
# DEPRECATED
# operationId: deleteChat
@deprecated
export def "chats delete" [
  chat_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/chats/($chat_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new turn in the chat
#
# POST /v2/chats/{chat_id}/turns
# DEPRECATED
# operationId: createChatTurn
# --generation shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
# --chat shape: {store?: bool}
@deprecated
export def "chats-turns createChatTurn" [
  chat_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --body-query: string # The chat message or question. (e.g. What are the carbon reduction efforts by EU banks in 2023?)
  search: any # The parameters to search one or more corpora.
  --generation: record # The parameters to control generation. — shape: {enabled?: bool, generation_preset_name?: string, prompt_name?: string, max_used_search_results?: int, prompt_template?: string, prompt_text?: string, max_response_characters?: int, response_language?: "auto"|"eng"|"deu"|"fra"|"zho"|"kor"|"ara"|"rus"|"tha"|"nld"|"ita"|"por"|"spa"|"jpn"|"pol"|"tur"|"vie"|"ind"|"ces"|"ukr"|"ell"|"heb"|"fas"|"hin"|"urd"|"swe"|"ben"|"msa"|"ron", model_parameters?: record, citations?: record, enable_factual_consistency_score?: bool}
  --chat: record # Parameters to control chat behavior. — shape: {store?: bool}
  --save-history: oneof<nothing, bool> # Indicates whether to save the chat in both the chat and query history. This overrides `chat.store`. (default: true)
  --intelligent-query-rewriting: oneof<nothing, bool> # [Tech Preview] Indicates whether to enable intelligent query rewriting. When enabled, the platform will attempt to extract metadata filter and rewrite the query to improve search results. Read [here](https://docs.vectara.com/docs/search-and-retrieval/intelligent-query-rewriting) for more details. (default: false)
  --stream-response: oneof<nothing, bool> # Indicates whether the response should be streamed or not. (default: false)
]: any -> record<chat_id: string, turn_id: string, answer: string, response_language: string, search_results: list<record>, factual_consistency_score: float, rendered_prompt: string, warnings: list<string>, rephrased_query: string, rewritten_queries: table<corpus_key: string, filter_extraction: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/chats/($chat_id)/turns")
  let body = {query: $body_query, search: $search, generation: $generation, chat: $chat, save_history: $save_history, intelligent_query_rewriting: $intelligent_query_rewriting, stream_response: $stream_response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List turns in a chat
#
# GET /v2/chats/{chat_id}/turns
# DEPRECATED
# operationId: listChatTurns
@deprecated
export def "chats-turns listChatTurns" [
  chat_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<turns: table<id: string, chat_id: string, query: string, answer: string, enabled: bool, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/chats/($chat_id)/turns")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a turn
#
# GET /v2/chats/{chat_id}/turns/{turn_id}
# DEPRECATED
# operationId: getChatTurn
@deprecated
export def "chats-turns get" [
  chat_id: string
  turn_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, chat_id: string, query: string, answer: string, enabled: bool, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/chats/($chat_id)/turns/($turn_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a turn
#
# DELETE /v2/chats/{chat_id}/turns/{turn_id}
# DEPRECATED
# operationId: deleteChatTurn
@deprecated
export def "chats-turns delete" [
  chat_id: string
  turn_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/chats/($chat_id)/turns/($turn_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a turn
#
# PATCH /v2/chats/{chat_id}/turns/{turn_id}
# DEPRECATED
# operationId: updateChatTurn
@deprecated
export def "chats-turns updateChatTurn" [
  chat_id: string
  turn_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --enabled: oneof<nothing, bool> # Indicates whether to disable a turn. It will disable this turn and all subsequent turns. Enabling a turn is not implemented. (e.g. false)
]: any -> record<id: string, chat_id: string, query: string, answer: string, enabled: bool, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/chats/($chat_id)/turns/($turn_id)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an LLM
#
# POST /v2/llms
# Discriminator (request): type = openai-compatible, openai-responses, vertex-ai, anthropic
# operationId: createLLM
# --auth shape: {type: "api_key"|"service_account", api_key?: string, key_json?: string}
# --capabilities shape: {image_support?: bool, context_limit?: int, tool_calling?: bool, structured_outputs?: bool, requires_role_alternation?: bool}
export def "llms createLLM" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-1 # Must be "vertex-ai" for Google Cloud Vertex AI Gemini models (default: vertex-ai)
  --name: string # Name to reference the LLM. This will be used in other endpoints (like query) when using this LLM. If this name conflicts with a global LLM (a LLM that is preconfigured with the Vectara platform), then it will override that LLM for all usages.
  --description: string # Description of the LLM. (default: )
  --model: string # The model name to use (e.g. gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-experimental-1219, etc).
  --uri: string # The base URI for the Gemini API. You can provide URIs in various formats — the system will normalize them automatically, stripping any model path, method suffix, or query parameters.  **Vertex AI** (for service account auth): Provide the project/location base URI. Example: `https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR-PROJECT/locations/us-central1`  **Google AI Studio** (for API key auth): Provide the Generative Language API base URI. Example: `https://generativelanguage.googleapis.com/v1beta`  Full URIs copied from Google docs also work — the model path and `:generateContent` suffix will be stripped and rebuilt automatically from the `model` field.  (format: uri, e.g. https://us-central1-aiplatform.googleapis.com/v1/projects/my-project/locations/us-central1)
  --body-auth: record # Authentication configuration for Vertex AI — shape: {type: "api_key"|"service_account", api_key?: string, key_json?: string}
  --headers: record # Additional HTTP headers to include with requests to the Gemini API.
  --idle-timeout-seconds: int # Maximum time in seconds the platform will wait for the model to send data before considering the connection stale and terminating it. For example, this is used as the SSE idle timeout during streaming — if no new server-sent events arrive within this window the stream is closed with an error. If unset, the platform falls back to its default read timeout for that provider (typically 60 seconds for OpenAI / Anthropic; provider SDK default for Vertex). On update, omit the field to leave the configured value unchanged or send an explicit null to clear it. (nullable, format: int32, e.g. 300)
  --test-model-parameters: record # Any additional parameters that are required for the LLM during the test call.
  --capabilities: record # Capabilities of a Large Language Model. If not provided when creating an LLM, capabilities are automatically inferred from the model name and provider type. Any explicitly provided fields override the inferred defaults. — shape: {image_support?: bool, context_limit?: int, tool_calling?: bool, structured_outputs?: bool, requires_role_alternation?: bool}
]: any -> record<id: string, name: string, description: string, enabled: bool, default: bool, capabilities: record<image_support: bool, context_limit: int, tool_calling: bool, structured_outputs: bool, requires_role_alternation: bool>, ownership: string, type: string, model: string, uri: string, headers: record, idle_timeout_seconds: int, auth: record, prompts: list<record<id: string, name: string, description: string, enabled: bool, default: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/llms")
  let body = {type: $type, name: $name, description: $description, model: $model, uri: $uri, auth: $body_auth, headers: $headers, idle_timeout_seconds: $idle_timeout_seconds, test_model_parameters: $test_model_parameters, capabilities: $capabilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List LLMs
#
# GET /v2/llms
# operationId: listLLMs
export def "llms listLLMs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression to match names and descriptions of the LLMs.
  --limit: int # The maximum number of results to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of LLMs after the limit has been reached. This parameter is not needed for the first page of results.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<llms: table<id: string, name: string, description: string, enabled: bool, default: bool, capabilities: record, ownership: string, type: string, model: string, uri: string, headers: record, idle_timeout_seconds: int, auth: record, prompts: list>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/llms" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an LLM
#
# GET /v2/llms/{llm_id}
# operationId: getLLM
export def "llms get" [
  llm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, name: string, description: string, enabled: bool, default: bool, capabilities: record<image_support: bool, context_limit: int, tool_calling: bool, structured_outputs: bool, requires_role_alternation: bool>, ownership: string, type: string, model: string, uri: string, headers: record, idle_timeout_seconds: int, auth: record, prompts: list<record<id: string, name: string, description: string, enabled: bool, default: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/llms/($llm_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an LLM
#
# DELETE /v2/llms/{llm_id}
# operationId: deleteLLM
export def "llms delete" [
  llm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/llms/($llm_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an LLM
#
# PATCH /v2/llms/{llm_id}
# Discriminator (request): type = openai-compatible, openai-responses, vertex-ai, anthropic
# operationId: updateLLM
# --auth shape: {type: "api_key"|"service_account", api_key?: string, key_json?: string}
# --capabilities shape: {image_support?: bool, context_limit?: int, tool_calling?: bool, structured_outputs?: bool, requires_role_alternation?: bool}
export def "llms updateLLM" [
  llm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-1 # Must be "vertex-ai" for Google Cloud Vertex AI Gemini models (default: vertex-ai)
  --model: string # The model identifier to use for this LLM.
  --uri: string # The base URI for the Gemini API. Accepts Vertex AI or Google AI Studio URIs in any format. See the create endpoint for full details and examples.  (format: uri)
  --description: string # Description of the LLM.
  --body-auth: record # Authentication configuration for Vertex AI — shape: {type: "api_key"|"service_account", api_key?: string, key_json?: string}
  --headers: record # Additional HTTP headers to include with requests to the Gemini API.
  --idle-timeout-seconds: int # Maximum time in seconds the platform will wait for the model to send data before considering the connection stale and terminating it. For example, this is used as the SSE idle timeout during streaming — if no new server-sent events arrive within this window the stream is closed with an error. If unset, the platform falls back to its default read timeout for that provider (typically 60 seconds for OpenAI / Anthropic; provider SDK default for Vertex). On update, omit the field to leave the configured value unchanged or send an explicit null to clear it. (nullable, format: int32, e.g. 300)
  --enabled: oneof<nothing, bool> # Whether the LLM is enabled.
  --test-model-parameters: record # Any additional parameters that are required for the LLM during the test call.
  --capabilities: record # Capabilities of a Large Language Model. If not provided when creating an LLM, capabilities are automatically inferred from the model name and provider type. Any explicitly provided fields override the inferred defaults. — shape: {image_support?: bool, context_limit?: int, tool_calling?: bool, structured_outputs?: bool, requires_role_alternation?: bool}
]: any -> record<id: string, name: string, description: string, enabled: bool, default: bool, capabilities: record<image_support: bool, context_limit: int, tool_calling: bool, structured_outputs: bool, requires_role_alternation: bool>, ownership: string, type: string, model: string, uri: string, headers: record, idle_timeout_seconds: int, auth: record, prompts: list<record<id: string, name: string, description: string, enabled: bool, default: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/llms/($llm_id)")
  let body = {type: $type, model: $model, uri: $uri, description: $description, auth: $body_auth, headers: $headers, idle_timeout_seconds: $idle_timeout_seconds, enabled: $enabled, test_model_parameters: $test_model_parameters, capabilities: $capabilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a model response for the given chat conversation
#
# POST /v2/llms/chat/completions
# operationId: createChatCompletion
# --messages item shape: {role: string, content: any, name?: string}
# --response_format shape: {type: "json_schema"|"json_object"|"text", json_schema?: record}
export def "llms-chat-completions createChatCompletion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  model: string # The ID of the model to use. This field is required.
  messages: list # An ordered array of messages that represent the full context of the conversation to date. Each message includes a `role` and `content`. — item shape: {role: string, content: any, name?: string}
  --stream: oneof<nothing, bool> # Optional. When set to `true`, the API streams partial message deltas as they become available, similar to ChatGPT's streaming mode. (default: false)
  --response-format: record # Specifies the format the model must output. - `text`: Plain text responses (default). - `json_object`: Ensures the response is valid JSON. - `json_schema`: Ensures the response conforms to the provided JSON schema. — shape: {type: "json_schema"|"json_object"|"text", json_schema?: record}
]: any -> record<object: string, choices: table<index: int, message: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/llms/chat/completions")
  let body = {model: $model, messages: $messages, stream: $stream, response_format: $response_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List generation presets
#
# GET /v2/generation_presets
# operationId: listGenerationPresets
export def "generation-presets listGenerationPresets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --llm-name: string # Filter presets by the LLM name. (e.g. mockingbird-2.0)
  --filter: string # A regular expression to match names and descriptions of the generation presets. (e.g. mockingbird.*)
  --limit: int # The maximum number of results to return in the list. (format: int32, default: 10, e.g. 50)
  --page-key: string # Used to retrieve the next page of generation presets after the limit has been reached. This parameter is not needed for the first page of results.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<generation_presets: table<id: string, name: string, description: string, llm_name: string, prompt_template: string, max_used_search_results: int, max_tokens: int, temperature: float, frequency_penalty: float, presence_penalty: float, additional_model_params: record, enabled: bool, default: bool, ownership: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "llm_name" $llm_name "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/generation_presets" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a generation preset
#
# POST /v2/generation_presets
# operationId: createGenerationPreset
export def "generation-presets createGenerationPreset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --id: string # The ID of the generation preset. (e.g. gnp_123)
  name: string # Name of the generation preset to be used with configuring generation. (e.g. Mockingbird 2.0)
  --description: string # Description of the generation preset. (e.g. Mockingbird LLM 2.0 prompt for summarizing query results as an answer. Designed for RAG.)
  llm_name: string # Name of the model that these presets are used with. The list of available names can be fetched by the `GET /v2/llms` endpoint. (e.g. mockingbird-2.0)
  prompt_template: string # Preset template used to render the prompt sent to generation.
  --max-used-search-results: int # Preset maximum number of search results that will be available to the prompt. (format: int32, e.g. 50)
  --max-tokens: int # Preset maximum number of tokens to be returned by the generation. (format: int32, e.g. 500)
  --temperature: float # The sampling temperature to use. Higher values make the output more random, while lower values make it more focused and deterministic. (format: float, e.g. 0.4)
  --frequency-penalty: float # Higher values penalize new tokens based on their existing frequency in the generation so far, decreasing the model's likelihood to repeat the same line verbatim. (format: float, e.g. 0.2)
  --presence-penalty: float # Higher values penalize new tokens based on whether they appear in the generation so far, increasing the model's likelihood to talk about new topics. (format: float, e.g. 0.2)
  --additional-model-params: record # Additional model parameters beyond the standard fields above.
  --enabled: oneof<nothing, bool> # Indicates whether the prompt is enabled.
  --default: oneof<nothing, bool> # Indicates if this prompt is the default prompt used with the LLM.
  --ownership: string@ownership-completer # Indicates whether the generation preset is provided by the platform or created by the customer. Platform presets are pre-configured and cannot be modified or deleted. Customer presets are created and managed by the customer. (e.g. platform)
]: any -> record<id: string, name: string, description: string, llm_name: string, prompt_template: string, max_used_search_results: int, max_tokens: int, temperature: float, frequency_penalty: float, presence_penalty: float, additional_model_params: record, enabled: bool, default: bool, ownership: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/generation_presets")
  let body = {id: $id, name: $name, description: $description, llm_name: $llm_name, prompt_template: $prompt_template, max_used_search_results: $max_used_search_results, max_tokens: $max_tokens, temperature: $temperature, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, additional_model_params: $additional_model_params, enabled: $enabled, default: $default, ownership: $ownership} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace a generation preset
#
# PUT /v2/generation_presets/{generation_preset_id}
# operationId: replaceGenerationPreset
export def "generation-presets replaceGenerationPreset" [
  generation_preset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --id: string # The ID of the generation preset. (e.g. gnp_123)
  name: string # Name of the generation preset to be used with configuring generation. (e.g. Mockingbird 2.0)
  --description: string # Description of the generation preset. (e.g. Mockingbird LLM 2.0 prompt for summarizing query results as an answer. Designed for RAG.)
  llm_name: string # Name of the model that these presets are used with. The list of available names can be fetched by the `GET /v2/llms` endpoint. (e.g. mockingbird-2.0)
  prompt_template: string # Preset template used to render the prompt sent to generation.
  --max-used-search-results: int # Preset maximum number of search results that will be available to the prompt. (format: int32, e.g. 50)
  --max-tokens: int # Preset maximum number of tokens to be returned by the generation. (format: int32, e.g. 500)
  --temperature: float # The sampling temperature to use. Higher values make the output more random, while lower values make it more focused and deterministic. (format: float, e.g. 0.4)
  --frequency-penalty: float # Higher values penalize new tokens based on their existing frequency in the generation so far, decreasing the model's likelihood to repeat the same line verbatim. (format: float, e.g. 0.2)
  --presence-penalty: float # Higher values penalize new tokens based on whether they appear in the generation so far, increasing the model's likelihood to talk about new topics. (format: float, e.g. 0.2)
  --additional-model-params: record # Additional model parameters beyond the standard fields above.
  --enabled: oneof<nothing, bool> # Indicates whether the prompt is enabled.
  --default: oneof<nothing, bool> # Indicates if this prompt is the default prompt used with the LLM.
  --ownership: string@ownership-completer # Indicates whether the generation preset is provided by the platform or created by the customer. Platform presets are pre-configured and cannot be modified or deleted. Customer presets are created and managed by the customer. (e.g. platform)
]: any -> record<id: string, name: string, description: string, llm_name: string, prompt_template: string, max_used_search_results: int, max_tokens: int, temperature: float, frequency_penalty: float, presence_penalty: float, additional_model_params: record, enabled: bool, default: bool, ownership: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/generation_presets/($generation_preset_id)")
  let body = {id: $id, name: $name, description: $description, llm_name: $llm_name, prompt_template: $prompt_template, max_used_search_results: $max_used_search_results, max_tokens: $max_tokens, temperature: $temperature, frequency_penalty: $frequency_penalty, presence_penalty: $presence_penalty, additional_model_params: $additional_model_params, enabled: $enabled, default: $default, ownership: $ownership} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a generation preset
#
# DELETE /v2/generation_presets/{generation_preset_id}
# operationId: deleteGenerationPreset
export def "generation-presets delete" [
  generation_preset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/generation_presets/($generation_preset_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluate factual consistency
#
# POST /v2/evaluate_factual_consistency
# operationId: evaluateFactualConsistency
# --model_parameters shape: {model_name?: string}
export def "evaluate-factual-consistency evaluateFactualConsistency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --model-parameters: record # The model parameters for the evaluation. — shape: {model_name?: string}
  generated_text: string # The generated text (e.g., summary or answer) to evaluate for factual consistency.
  source_texts: list # The source documents or text snippets against which to evaluate factual consistency.
]: any -> record<score: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/evaluate_factual_consistency")
  let body = {model_parameters: $model_parameters, generated_text: $generated_text, source_texts: $source_texts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an encoder
#
# POST /v2/encoders
# Discriminator (request): type = openai-compatible, vllm-compatible
# operationId: createEncoder
# --auth shape: {type: "bearer"|"header"|"oauth_client_credentials", token?: string, header?: string, value?: string, client_id?: string, client_secret?: string, token_endpoint?: string, scopes?: list}
export def "encoders createEncoder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-2 # Must be "openai-compatible" for OpenAI and OpenAI-compatible text-embedding APIs. (default: openai-compatible)
  --name: string # A unique name for the encoder. (e.g. openai-text-encoder)
  --description: string # A description of what this encoder does. (e.g. Text encoder for product catalog search)
  --output-dimensions: int # The number of dimensions in the output embedding vector. If provided and the model supports truncation, the response will be truncated to this number of dimensions. (format: int32)
  --uri: string # The URI endpoint for the embedding API (can be OpenAI or any compatible embedding API endpoint) (format: uri, e.g. https://api.openai.com/v1/embeddings)
  --model: string # The model name to use for embeddings (e.g. text-embedding-ada-002)
  --body-auth: record # Authentication configuration for connecting to a remote service. — shape: {type: "bearer"|"header"|"oauth_client_credentials", token?: string, header?: string, value?: string, client_id?: string, client_secret?: string, token_endpoint?: string, scopes?: list}
  --image-encoding: oneof<nothing, bool> # Whether the encoder produces image embeddings, either of an image alone or jointly with accompanying text. When `true`, the endpoint must accept image-embedding requests; the create call validates this and fails if the endpoint does not support them. (default: false)
]: any -> record<id: string, name: string, type: string, output_dimensions: int, description: string, default: bool, enabled: bool, image_encoding: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/encoders")
  let body = {type: $type, name: $name, description: $description, output_dimensions: $output_dimensions, uri: $uri, model: $model, auth: $body_auth, image_encoding: $image_encoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List encoders
#
# GET /v2/encoders
# operationId: listEncoders
export def "encoders listEncoders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression against encoder names and descriptions. (e.g. vectara.*)
  --limit: int # The maximum number of results to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of encoders after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<encoders: table<id: string, name: string, type: string, output_dimensions: int, description: string, default: bool, enabled: bool, image_encoding: bool>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/encoders" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List rerankers
#
# GET /v2/rerankers
# operationId: listRerankers
export def "rerankers listRerankers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression against reranker names and descriptions. (e.g. vectara.*)
  --limit: int # The maximum number of rerankers to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of rerankers after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<rerankers: table<id: string, name: string, description: string, enabled: bool>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rerankers" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List supported table extractors
#
# GET /v2/table_extractors
# operationId: listTableExtractors
export def "table-extractors listTableExtractors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<table_extractors: table<name: string, is_default: bool, description: string, generation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/table_extractors")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List hallucination correctors
#
# GET /v2/hallucination_correctors
# operationId: listHallucinationCorrectors
export def "hallucination-correctors listHallucinationCorrectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression applied to the name and description fields. Use this to return only hallucination correctors that match specific keywords or naming conventions.
  --limit: int # The maximum number of hallucination correctors to return in the list. Defaults to 10. Range is between 1 and 100. (format: int32, default: 10)
  --page-key: string # Retrieves the next page of hallucination correctors after reaching the limit.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<hallucination_correctors: table<id: string, name: string, type: string, description: string, enabled: bool>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/hallucination_correctors" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Corrects hallucinations in generated text based on source documents
#
# POST /v2/hallucination_correctors/correct_hallucinations
# operationId: correctHallucinations
# --documents item shape: {text: string}
export def "hallucination-correctors-correct-hallucinations correctHallucinations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  generated_text: string # The generated text to be evaluated. The hallucination corrector reviews this text and applies corrections based on the provided source documents.
  documents: list # The source documents that were used to generate the text. — item shape: {text: string}
  model_name: string # The name of the LLM model to use for hallucination correction. (e.g. vhc-large-1.0)
  --body-query: string # Optional query that provides context for the expected response format and factual information. When provided, enables query-aware hallucination correction that considers the specific response format and factual context expected for the query.
]: any -> record<corrections: table<original_text: string, corrected_text: string, explanation: string>, corrected_text: string, model: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/hallucination_correctors/correct_hallucinations")
  let body = {generated_text: $generated_text, documents: $documents, model_name: $model_name, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List jobs
#
# GET /v2/jobs
# operationId: listJobs
export def "jobs listJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --corpus-key: list # The unique key identifying the corpus with the job.
  --after: string # Filter by jobs created after a particular date-time. (format: date-time)
  --state: list # Filter by jobs in particular states.
  --limit: int # The maximum number of jobs to return at one time. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of jobs after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<jobs: table<id: string, type: string, corpus_keys: list, state: string, created_at: string, started_at: string, completed_at: string, created_by_username: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "corpus_key" $corpus_key "multi") (serialize-qp "after" $after "scalar") (serialize-qp "state" $state "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/jobs" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a job by ID
#
# GET /v2/jobs/{job_id}
# operationId: getJob
export def "jobs get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, type: string, corpus_keys: list<string>, state: string, created_at: string, started_at: string, completed_at: string, created_by_username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/jobs/($job_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user in the current customer account
#
# POST /v2/users
# operationId: createUser
# --corpus_roles item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
# --agent_roles item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  email: string # The email address for the user. (format: email)
  --username: string # The username for the user. The value defaults to the email.
  --description: string # The description of the user.
  --api-roles: list # The customer-level role names assigned to the user.
  --corpus-roles: list # Corpus-specific role assignments for the user. — item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
  --agent-roles: list # Agent-specific role assignments for the user. — item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
]: any -> record<id: string, email: string, username: string, enabled: bool, description: string, created_at: string, updated_at: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>, one_time_code: string, one_time_code_link: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users")
  let body = {email: $email, username: $username, description: $description, api_roles: $api_roles, corpus_roles: $corpus_roles, agent_roles: $agent_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users in the account
#
# GET /v2/users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of users to return at one time. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of users after the limit has been reached.
  --corpus-key: string # Filter users by access to this corpus. (e.g. my-corpus)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<users: table<id: string, email: string, username: string, enabled: bool, description: string, created_at: string, updated_at: string, api_roles: list, corpus_roles: list, agent_roles: list, api_policy: record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar") (serialize-qp "corpus_key" $corpus_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /v2/users/{username}
# operationId: getUser
export def "users get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, email: string, username: string, enabled: bool, description: string, created_at: string, updated_at: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($username)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /v2/users/{username}
# operationId: updateUser
# --corpus_roles item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
# --agent_roles item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
export def "users updateUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --enabled: oneof<nothing, bool> # Indicates whether to enable or disable the user.
  --api-roles: list # The new customer-level role names of the user.
  --corpus-roles: list # New corpus-specific role assignments for the user. — item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
  --agent-roles: list # New agent-specific role assignments for the user. — item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
  --description: string # The description of the user.
]: any -> record<id: string, email: string, username: string, enabled: bool, description: string, created_at: string, updated_at: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($username)")
  let body = {enabled: $enabled, api_roles: $api_roles, corpus_roles: $corpus_roles, agent_roles: $agent_roles, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /v2/users/{username}
# operationId: deleteUser
export def "users delete" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($username)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset the password for a user
#
# POST /v2/users/{username}/reset_password
# operationId: resetUserPassword
export def "users-reset-password resetUserPassword" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<one_time_code: string, one_time_code_link: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($username)/reset_password")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API key
#
# POST /v2/api_keys
# operationId: createApiKey
# --corpus_roles item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
# --agent_roles item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
@deprecated --flag corpus-keys
export def "api-keys createApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  name: string # The human-readable name of the API key.
  --api-roles: list # Customer-level roles for this API key.
  --api-key-role: string@api-key-role-completer # Role of the API key. A serving API key can only perform query type requests on its corpora. A serving and indexing key can perform both indexing and query type requests on its corpora. A personal API key has all the same permissions as the creator of the API key.
  --corpus-keys: list # Deprecated: Use corpus_roles instead. Corpora this API key has roles on. (DEPRECATED)
  --corpus-roles: list # Corpus-specific role assignments for this API key. — item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
  --agent-roles: list # Agent-specific role assignments for this API key. — item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
]: any -> record<id: string, name: string, secret_key: string, enabled: bool, api_roles: list<string>, api_key_role: string, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/api_keys")
  let body = {name: $name, api_roles: $api_roles, api_key_role: $api_key_role, corpus_keys: $corpus_keys, corpus_roles: $corpus_roles, agent_roles: $agent_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List API keys
#
# GET /v2/api_keys
# operationId: listApiKeys
export def "api-keys listApiKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max number of API keys to return at one time. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of API keys after the limit has been reached.
  --corpus-key: string # Filters the API keys to only those with permissions on the specified corpus key. (e.g. my-corpus)
  --api-key-role: string@api-key-role-completer # Filter API keys by their role.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<api_keys: table<id: string, name: string, secret_key: string, enabled: bool, api_roles: list, api_key_role: string, corpus_roles: list, agent_roles: list, api_policy: record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar") (serialize-qp "corpus_key" $corpus_key "scalar") (serialize-qp "api_key_role" $api_key_role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/api_keys" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an API key
#
# GET /v2/api_keys/{api_key_id}
# operationId: getApiKey
export def "api-keys get" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, name: string, secret_key: string, enabled: bool, api_roles: list<string>, api_key_role: string, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api_keys/($api_key_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an API key
#
# PATCH /v2/api_keys/{api_key_id}
# operationId: updateApiKey
export def "api-keys updateApiKey" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --enabled: oneof<nothing, bool> # Indicates whether to disable or enable an API key.
]: any -> record<id: string, name: string, secret_key: string, enabled: bool, api_roles: list<string>, api_key_role: string, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api_keys/($api_key_id)")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an API key
#
# DELETE /v2/api_keys/{api_key_id}
# operationId: deleteApiKey
export def "api-keys delete" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/api_keys/($api_key_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an App Client
#
# POST /v2/app_clients
# Discriminator (request): type = client_credentials
# operationId: createAppClient
# --corpus_roles item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
# --agent_roles item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
export def "app-clients createAppClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # Name of the client credentials.
  --description: string # Description of the client credentials.
  type: string@type-completer-3 # This will always be the value `client_credentials`. (default: client_credentials)
  --api-roles: list # API roles that the client credentials will have.
  --corpus-roles: list # Corpus-specific role assignments for this App Client. — item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
  --agent-roles: list # Agent-specific role assignments for this App Client. — item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
]: any -> record<id: string, name: string, description: string, client_id: string, client_secret: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/app_clients")
  let body = {name: $name, description: $description, type: $type, api_roles: $api_roles, corpus_roles: $corpus_roles, agent_roles: $agent_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List App Clients
#
# GET /v2/app_clients
# operationId: listAppClient
export def "app-clients listAppClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of App Clients to return at one time. (format: int32, default: 10)
  --filter: string # Regular expression to filter the names of the App Clients.
  --page-key: string # Used to retrieve the next page of App Clients after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<app_clients: table<id: string, name: string, description: string, client_id: string, client_secret: string, api_roles: list, corpus_roles: list, agent_roles: list, api_policy: record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/app_clients" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an App Client
#
# GET /v2/app_clients/{app_client_id}
# operationId: getAppClient
export def "app-clients get" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, name: string, description: string, client_id: string, client_secret: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/app_clients/($app_client_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an App Client
#
# PATCH /v2/app_clients/{app_client_id}
# operationId: updateAppClient
# --corpus_roles item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
# --agent_roles item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
export def "app-clients updateAppClient" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --description: string # The new App Client description.
  --api-roles: list # The new roles attached to the App Client. These roles will replace the current roles.
  --corpus-roles: list # The new corpus role assignments. These will replace the current corpus roles. — item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
  --agent-roles: list # The new agent role assignments. These will replace the current agent roles. — item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
]: any -> record<id: string, name: string, description: string, client_id: string, client_secret: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>, api_policy: record<name: string, allowed_operations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/app_clients/($app_client_id)")
  let body = {description: $description, api_roles: $api_roles, corpus_roles: $corpus_roles, agent_roles: $agent_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an App Client
#
# DELETE /v2/app_clients/{app_client_id}
# operationId: deleteAppClient
export def "app-clients delete" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/app_clients/($app_client_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request an access token
#
# POST /oauth/token
# operationId: getOAuthToken
export def "oauth-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # The client ID of the application
  client_secret: string # The client secret of the application
  grant_type: any
]: any -> record<access_token: string, token_type: string, expires_in: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token")
  let body = {client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List tool servers
#
# GET /v2/tool_servers
# operationId: listToolServers
export def "tool-servers listToolServers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression against tool server names and descriptions to filter the results. (e.g. rag.*)
  --type: string@type-completer-4 # Filter tool servers by type. (e.g. mcp)
  --enabled: oneof<nothing, bool> # Filter tool servers by enabled status. (e.g. true)
  --limit: int # The maximum number of tool servers to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of tool servers after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<tool_servers: table<id: string, name: string, type: string, description: string, uri: string, headers: record, transport: string, enabled: bool, metadata: record, created_at: string, updated_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/tool_servers" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tool server
#
# POST /v2/tool_servers
# operationId: createToolServer
# --auth shape: {type: "bearer"|"header"|"oauth_client_credentials", token?: string, header?: string, value?: string, client_id?: string, client_secret?: string, token_endpoint?: string, scopes?: list}
export def "tool-servers createToolServer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  name: string # The human-readable name of a tool server. (e.g. RAG Search Server)
  type: string@type-completer-4 # The type of tool server. (e.g. mcp)
  --description: string # A detailed description of what this tool server does. (e.g. Provides RAG search capabilities for documents.)
  uri: string # The URI of the tool server. (format: uri, e.g. https://api.example.com/rag_search)
  --headers: record # Optional HTTP headers to include when connecting to the server.
  transport: string@transport-completer # Transport protocol for MCP server connections. Both use Server-Sent Events (SSE). - `sse`: Legacy format (https://modelcontextprotocol.io/specification/2024-11-05/basic/transports) - `streamable-http`: New format (https://modelcontextprotocol.io/specification/2025-03-26/basic/transports)  (e.g. sse)
  --body-auth: record # Authentication configuration for connecting to a remote service. — shape: {type: "bearer"|"header"|"oauth_client_credentials", token?: string, header?: string, value?: string, client_id?: string, client_secret?: string, token_endpoint?: string, scopes?: list}
  --enabled: oneof<nothing, bool> # Whether the tool server is currently enabled and available for use. (default: true)
  --metadata: record # Arbitrary metadata associated with the tool server.
]: any -> record<id: string, name: string, type: string, description: string, uri: string, headers: record, transport: string, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tool_servers")
  let body = {name: $name, type: $type, description: $description, uri: $uri, headers: $headers, transport: $transport, auth: $body_auth, enabled: $enabled, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tool Server
#
# GET /v2/tool_servers/{tool_server_id}
# operationId: getToolServer
export def "tool-servers get" [
  tool_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, name: string, type: string, description: string, uri: string, headers: record, transport: string, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tool_servers/($tool_server_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tool server
#
# PATCH /v2/tool_servers/{tool_server_id}
# operationId: updateToolServer
# --auth shape: {type: "bearer"|"header"|"oauth_client_credentials", token?: string, header?: string, value?: string, client_id?: string, client_secret?: string, token_endpoint?: string, scopes?: list}
export def "tool-servers updateToolServer" [
  tool_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # The human-readable name of a tool server. (e.g. RAG Search Server)
  --description: string # A detailed description of what this tool server does. (e.g. Provides Vectara specific functionalities.)
  --uri: string # The URI of the tool server. (format: uri, e.g. https://api.example.com/vectara_mcp/sse/)
  --headers: record # Optional HTTP headers to include when connecting to the server.
  --transport: string@transport-completer # Transport protocol for MCP server connections. Both use Server-Sent Events (SSE). - `sse`: Legacy format (https://modelcontextprotocol.io/specification/2024-11-05/basic/transports) - `streamable-http`: New format (https://modelcontextprotocol.io/specification/2025-03-26/basic/transports)  (e.g. sse)
  --body-auth: record # Authentication configuration for connecting to a remote service. — shape: {type: "bearer"|"header"|"oauth_client_credentials", token?: string, header?: string, value?: string, client_id?: string, client_secret?: string, token_endpoint?: string, scopes?: list}
  --enabled: oneof<nothing, bool> # Whether the tool server is currently enabled and available for use.
  --metadata: record # Arbitrary metadata associated with the tool server.
]: any -> record<id: string, name: string, type: string, description: string, uri: string, headers: record, transport: string, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tool_servers/($tool_server_id)")
  let body = {name: $name, description: $description, uri: $uri, headers: $headers, transport: $transport, auth: $body_auth, enabled: $enabled, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete tool server
#
# DELETE /v2/tool_servers/{tool_server_id}
# operationId: deleteToolServer
export def "tool-servers delete" [
  tool_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tool_servers/($tool_server_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Synchronize tool server
#
# POST /v2/tool_servers/{tool_server_id}/sync
# operationId: syncToolServer
export def "tool-servers-sync syncToolServer" [
  tool_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tool_servers/($tool_server_id)/sync")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tool
#
# POST /v2/tools
# Discriminator (request): type = lambda, client
# operationId: createTool
# --execution_configuration shape: {max_execution_time_seconds?: int, max_memory_mb?: int}
export def "tools createTool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-5 # This should always be `lambda`. (default: lambda, e.g. lambda)
  --name: string # The unique name of the tool (used as the function identifier). (e.g. calculate_customer_score)
  --title: string # Human-readable title of the tool displayed in the UI. (e.g. Customer Score Calculator)
  --description: string # A detailed description of what the function does, when to use it, and what it returns. (e.g. Calculate a customer score based on order history and revenue. Returns a score between 0-100.)
  --language: string@language-completer # The programming language. Currently only 'python' (Python 3.12) is supported. (default: python, e.g. python)
  --code: string # The Python 3.12 code for the function.  **Required**: Must define a `process()` entry point function. Use type annotations on parameters for automatic schema discovery.  **Parameters**: Passed as keyword arguments matched to the function signature.  **Return types**: Can return any JSON-serializable type (strings, numbers, booleans, lists, or objects).  **Parameter Descriptions**: Use docstrings to provide descriptions for parameters (Google, NumPy, ReST, and Epydoc styles are supported). These descriptions are automatically extracted and included in the input schema, giving agents better context about how to use each parameter.  **Example with Google-style docstring:** ```python def process(order_count: int, total_revenue: float, days_active: int = 1) -> dict:     """Calculate customer engagement score.      Args:         order_count: The number of orders placed by the customer.         total_revenue: Total revenue in USD from the customer.         days_active: Number of days the customer was active (default: 1).      Returns:         A dict with the calculated score.     """     score = (order_count * 10 + total_revenue * 0.1) / days_active     return {'score': round(score, 2)} ```  This produces an input schema with descriptions: ```json {   "type": "object",   "properties": {     "order_count": {       "type": "integer",       "description": "The number of orders placed by the customer."     },     "total_revenue": {       "type": "number",       "description": "Total revenue in USD from the customer."     },     "days_active": {       "type": "integer",       "description": "Number of days the customer was active (default: 1)."     }   },   "required": ["order_count", "total_revenue"] } ```  **Example: Returning a number** ```python def process(x: int, y: int) -> int:     return x + y ```  **Example: Returning a string** ```python def process(name: str) -> str:     return f"Hello, {name}!" ```  **Example: Returning a boolean** ```python def process(value: int, threshold: int) -> bool:     return value > threshold ```  **Example: Returning a list** ```python from typing import List  def process(items: List[str]) -> List[str]:     return sorted(items) ```  **Example: Returning an object (dict)** ```python def process(order_count: int, total_revenue: float, days_active: int = 1) -> dict:     score = (order_count * 10 + total_revenue * 0.1) / days_active     return {'score': round(score, 2), 'rating': 'high' if score > 100 else 'low'} ```  For complex types, use the `typing` module:  ```python from typing import List  def process(items: List[str], count: int) -> dict:     return {'total': len(items) * count} ```  **Object parameters must use TypedDict**: Bare `dict` and `Dict[K, V]` parameters are not supported and will be rejected during validation. All object-typed parameters must use `TypedDict` to define explicit fields. This ensures the agent receives a clear schema for each parameter.  ```python from typing import TypedDict, Optional  class Adjustment(TypedDict, total=False):     monthly_premium: float     target_income_age: int     illustrated_rate: float  def process(client_id: str, adjustment: Adjustment) -> dict:     return {"client_id": client_id, "adjustment": adjustment} ```  TypedDict supports inheritance, `Optional` fields, nested TypedDicts, and `total=False` to make all fields optional.  **Constraining parameters to specific values with Literal**: Use `Literal` to restrict a parameter to a fixed set of allowed values. This generates an `enum` constraint in the JSON schema, helping the agent choose valid options.  ```python from typing import Literal  def process(status: Literal["active", "inactive", "pending"], priority: Literal[1, 2, 3]) -> dict:     return {"status": status, "priority": priority} ```  (e.g. def process(order_count: int, total_revenue: float, days_active: int = 1) -> dict:     score = (order_count * 10 + total_revenue * 0.1) / days_active     return {'score': round(score, 2)} )
  --execution-configuration: record # Execution configuration for the function. — shape: {max_execution_time_seconds?: int, max_memory_mb?: int}
  --input-schema: any # JSON Schema describing the arguments the LLM should produce when invoking this tool. These arguments are forwarded verbatim to the client in the `tool_input` event.  (e.g. {type: object, properties: {document_url: {type: string, description: URL of the document to be signed.}}, required: [document_url]})
  --output-schema: any # Optional JSON Schema describing the structure the client must submit as the tool output. When set, submitted outputs are validated against this schema before being returned to the agent.  (e.g. {type: object, properties: {signed_document_url: {type: string}}, required: [signed_document_url]})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tools")
  let body = {type: $type, name: $name, title: $title, description: $description, language: $language, code: $code, execution_configuration: $execution_configuration, input_schema: $input_schema, output_schema: $output_schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List tools
#
# GET /v2/tools
# operationId: listTools
export def "tools listTools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression against tool names and descriptions to filter the results. (e.g. rag.*)
  --type: string@type-completer-6 # Filter tools by type. (e.g. mcp)
  --enabled: oneof<nothing, bool> # Filter tools by enabled status. (e.g. true)
  --category: list # Filter tools by category. Pass one or more category values to include only those categories. When omitted, tools in the "experimental" category are excluded by default. To include experimental tools, explicitly pass `category=experimental`. (e.g. [retrieval, utilities])
  --tool-server-id: string # Filter tools by the tool server they belong to. (e.g. tsr_rag_search)
  --limit: int # The maximum number of tools to return in the list. (format: int32, default: 50)
  --page-key: string # Used to retrieve the next page of tools after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<tools: list<any>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "category" $category "multi") (serialize-qp "tool_server_id" $tool_server_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/tools" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test Lambda tool without creation
#
# POST /v2/tools/test
# operationId: testLambdaToolWithoutCreation
# --execution_configuration shape: {max_execution_time_seconds?: int, max_memory_mb?: int}
export def "tools-test testLambdaToolWithoutCreation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --language: string@language-completer # The programming language. Currently only 'python' (Python 3.12) is supported. (default: python, e.g. python)
  code: string # The Python 3.12 code for the function. Must define a `process()` entry point. Object parameters must use `TypedDict`; bare `dict` and `Dict[K, V]` parameters are rejected. See the `code` field on `CreateLambdaToolRequest` for full details and examples.  (e.g. def process(order_count: int, total_revenue: float) -> dict:     score = order_count * 10 + total_revenue * 0.1     return {'score': round(score, 2)} )
  --execution-configuration: record # Execution configuration for the function. — shape: {max_execution_time_seconds?: int, max_memory_mb?: int}
  test_input: record # The input parameters to test the function with. Will be validated against the discovered input schema. (e.g. {order_count: 10, total_revenue: 500})
  --timeout-seconds: int # Maximum execution time in seconds for this test. Overrides execution_configuration if specified. (e.g. 10)
]: any -> record<validation: record<status: string, errors: list<string>>, input_schema: record, output_schema: record, execution: record<success: bool, output: record, error: record<message: string, traceback: string>, latency_millis: int, memory_used_mb: int, validation_results: record<input_valid: bool, output_valid: bool, validation_errors: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tools/test")
  let body = {language: $language, code: $code, execution_configuration: $execution_configuration, test_input: $test_input, timeout_seconds: $timeout_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get tool
#
# GET /v2/tools/{tool_id}
# Discriminator (response): type = dynamic_vectara, mcp, corpora_search, web_search, web_get, lambda, sub_agent, artifact_create, artifact_read, artifact_grep, image_read, document_conversion, get_document_text, client
# operationId: getTool
export def "tools get" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tools/($tool_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update tool
#
# PATCH /v2/tools/{tool_id}
# Discriminator (request): type = mcp, lambda, client
# operationId: updateTool
# --execution_configuration shape: {max_execution_time_seconds?: int, max_memory_mb?: int}
export def "tools updateTool" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-6 # This should always be `mcp`. (default: mcp, e.g. mcp)
  --enabled: oneof<nothing, bool> # Whether the tool is enabled.
  --title: string # Updated user-friendly display name for the tool. (e.g. Updated Calculator Tool)
  --description: string # Updated description of what the tool does. (e.g. An updated tool that performs advanced calculations)
  --code: string # Updated code for the lambda function. Use function parameter type annotations for automatic schema discovery. Object parameters must use `TypedDict`; bare `dict` and `Dict[K, V]` parameters are rejected. See the `code` field on `CreateLambdaToolRequest` for full details and examples.  (e.g. def process(value: float) -> dict:     return {"result": value * 2} )
  --execution-configuration: record # Execution configuration for the function. — shape: {max_execution_time_seconds?: int, max_memory_mb?: int}
  --input-schema: any # Updated JSON Schema for the arguments the LLM produces when invoking this tool.
  --output-schema: any # Updated JSON Schema for the structure the client must submit as the tool output. Pass an empty object to clear the schema and accept any output.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tools/($tool_id)")
  let body = {type: $type, enabled: $enabled, title: $title, description: $description, code: $code, execution_configuration: $execution_configuration, input_schema: $input_schema, output_schema: $output_schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete tool
#
# DELETE /v2/tools/{tool_id}
# operationId: deleteTool
export def "tools delete" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tools/($tool_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test Lambda tool
#
# POST /v2/tools/{tool_id}/test
# Discriminator (response): type = success, error
# operationId: testTool
export def "tools-test testTool" [
  tool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  input: record # The input parameters to pass to the function. Must match the tool's input schema. (e.g. {number: 42, text: Hello, world!})
  --timeout-seconds: int # Maximum execution time in seconds. If not specified, uses the tool's configured timeout. (e.g. 10)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tools/($tool_id)/test")
  let body = {input: $input, timeout_seconds: $timeout_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create instruction
#
# POST /v2/instructions
# Discriminator (request): type = initial
# operationId: createInstruction
export def "instructions createInstruction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/instructions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List instructions
#
# GET /v2/instructions
# operationId: listInstructions
export def "instructions listInstructions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression against instruction names and descriptions to filter the results. (e.g. support.*)
  --type: string@type-completer-7 # Filter instructions by type. (e.g. initial)
  --enabled: oneof<nothing, bool> # Filter instructions by enabled status. (e.g. true)
  --limit: int # The maximum number of instructions to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of instructions after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<instructions: list<any>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/instructions" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get instruction
#
# GET /v2/instructions/{instruction_id}
# Discriminator (response): type = initial
# operationId: getInstruction
export def "instructions get" [
  instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The specific version of the instruction to retrieve. If not specified, the latest version will be returned. (e.g. 1)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/instructions/($instruction_id)" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update instruction
#
# PATCH /v2/instructions/{instruction_id}
# Discriminator (request): type = initial
# operationId: updateInstruction
export def "instructions updateInstruction" [
  instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-7 # The type of instruction to update. (default: initial, e.g. initial)
  --name: string # The human-readable name of an instruction. (e.g. Customer Support Initial Instruction)
  --description: string # A detailed description of what this instruction does. (e.g. Enhanced initial context and guidelines for customer support interactions)
  --template: string # The instruction template content using the specified template engine.  Available Velocity variables: - `$agent.name` - Agent name - `$agent.key` - Agent key - `$agent.metadata` - Agent metadata map - `$session.key` - Session key - `$session.metadata` - Session metadata map (includes user-provided context from test/runtime) - `$currentDate` - Current date/time in ISO 8601 format (e.g., "2025-10-24T15:30:45Z") - `$tools` - List of tool maps, each with `name` and `description` fields  Example: `You are a helpful customer support agent. Agent: $agent.name. Today is $currentDate. Available tools: #foreach($tool in $tools)${tool.name}#if($foreach.hasNext), #end#end`  (e.g. You are an expert customer support agent for $agent.name. Available tools: #foreach($tool in $tools)${tool.name}#if($foreach.hasNext), #end#end)
  --template-type: string@template-type-completer # The templating engine used for instructions. (default: velocity, e.g. velocity)
  --metadata: record # Arbitrary metadata associated with the instruction. (e.g. {version: 1.1.0, author: support-team, last_reviewed: 2024-01-15})
  --enabled: oneof<nothing, bool> # Whether the instruction is enabled. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/instructions/($instruction_id)")
  let body = {type: $type, name: $name, description: $description, template: $template, template_type: $template_type, metadata: $metadata, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete instruction
#
# DELETE /v2/instructions/{instruction_id}
# operationId: deleteInstruction
export def "instructions delete" [
  instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/instructions/($instruction_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test instruction
#
# POST /v2/instructions/{instruction_id}/test
# operationId: testInstruction
export def "instructions-test testInstruction" [
  instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # The specific version of the instruction to test. If not specified, the latest version will be used. (e.g. 1)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --context: record # Context data to use when rendering the instruction template. This will be merged into `$session.metadata` for template access.  Example: If you provide `{"currentDate": "2024-01-15"}`, you can access it in the template as `$session.metadata.currentDate`.  (e.g. {currentDate: 2024-01-15, companyName: Acme Corp})
  --tools: list # List of tools to include in the instruction context for testing. (default: [], e.g. [])
]: any -> record<rendered_instruction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/instructions/($instruction_id)/test" $qp)
  let body = {context: $context, tools: $tools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete instruction version
#
# DELETE /v2/instructions/{instruction_id}/versions/{version}
# operationId: deleteInstructionVersion
export def "instructions-versions delete" [
  instruction_id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/instructions/($instruction_id)/versions/($version)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create agent
#
# POST /v2/agents
# operationId: createAgent
# --model shape: {name: string, parameters?: record, retry_configuration?: record}
# --first_step shape: {name: string, type?: string, instructions: list, output_parser: any, reminders?: list, next_steps?: list, allowed_tools?: list, allowed_skills?: list, reentry_step?: string}
# --compaction shape: {enabled?: bool, threshold_percent?: int, keep_recent_inputs?: int, compaction_message?: string, tool_event_policy?: "exclude"|"include_outputs"|"include_all"}
# --tool_output_offloading shape: {enabled?: bool, mode?: "artifact"|"truncate", context_percentage?: float, max_threshold_bytes?: int, min_threshold_bytes?: int, headroom_percentage?: float}
export def "agents createAgent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: string # A unique key that identifies an agent. (e.g. customer_support)
  name: string # The human-readable name of an agent. (e.g. Customer Support Agent)
  --description: string # A detailed description of the agent's purpose and capabilities. (e.g. An AI agent specialized in handling customer support inquiries using company documentation and support tools.)
  tool_configurations: record # A map of tool configurations available to the agent. The key is the name of the tool configuration and the value is the AgentToolConfiguration. (e.g. {customer_search: {type: corpora_search, argument_override: {query: customer support documentation}}})
  --skills: record # A map of skills available to the agent, keyed by skill name. Skills provide specialized instructions that can be invoked during agent execution.  (e.g. {code_review: {description: Reviews code for best practices., content: When reviewing code...}})
  model: record # Configuration for the model used in this step, including the model name and arbitrary parameters. — shape: {name: string, parameters?: record, retry_configuration?: record}
  --first-step: record # The entry point step for an agent, with a unique name. See AgentStep for full step documentation. — shape: {name: string, type?: string, instructions: list, output_parser: any, reminders?: list, next_steps?: list, allowed_tools?: list, allowed_skills?: list, reentry_step?: string}
  --first-step-name: string # Name of a step in the steps map to use as the entry point. This is the preferred way to define the entry point - define all steps in the steps map and reference the entry point by name here.  (e.g. classifier)
  --steps: record # A map of named steps keyed by step name. Steps can transition to other steps defined here via next_steps.  (e.g. {sales_handler: {instructions: [{type: inline, template: Handle sales inquiries}], output_parser: {type: default}}, support_handler: {instructions: [{type: inline, template: Handle support requests}], output_parser: {type: default}}})
  --metadata: record # Arbitrary metadata associated with the agent for customization and configuration. (default: {}, e.g. {department: customer_service, version: 1.0.0, owner: support-team})
  --enabled: oneof<nothing, bool> # Whether the agent should be enabled upon creation. (default: true, e.g. true)
  --compaction: record # Configuration for automatic context compaction. — shape: {enabled?: bool, threshold_percent?: int, keep_recent_inputs?: int, compaction_message?: string, tool_event_policy?: "exclude"|"include_outputs"|"include_all"}
  --tool-output-offloading: record # Controls how large tool outputs are kept from overwhelming the agent context window.  Tool outputs are inspected as they are produced. A small output is always passed through unchanged. A larger output is handled in one of two cases: when the output on its own is big enough to dominate the context, or when adding it to the conversation would leave too little room for the agent to continue. In either case the output is handled according to `mode` — stored as an artifact and replaced with a compact reference, or truncated in place with the head and tail preserved and the middle omitted. When stored as an artifact, the agent is expected to have artifact_read, artifact_grep, or artifact_jq configured so it can retrieve the full content on demand.  All fields are optional; omitted fields fall back to defaults. — shape: {enabled?: bool, mode?: "artifact"|"truncate", context_percentage?: float, max_threshold_bytes?: int, min_threshold_bytes?: int, headroom_percentage?: float}
]: any -> record<key: string, name: string, description: string, tool_configurations: record, skills: record, model: record<name: string, parameters: record, retry_configuration: record<enabled: bool, max_retries: int, initial_backoff_ms: int, max_backoff_ms: int, backoff_factor: float>>, first_step: record<name: string, type: string, instructions: list<any>, output_parser: record, reminders: list<any>, next_steps: list<record>, allowed_tools: list<string>, allowed_skills: list<string>, reentry_step: string>, first_step_name: string, steps: record, metadata: record, enabled: bool, compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, tool_output_offloading: record<enabled: bool, mode: string, context_percentage: float, max_threshold_bytes: int, min_threshold_bytes: int, headroom_percentage: float>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/agents")
  let body = {key: $key, name: $name, description: $description, tool_configurations: $tool_configurations, skills: $skills, model: $model, first_step: $first_step, first_step_name: $first_step_name, steps: $steps, metadata: $metadata, enabled: $enabled, compaction: $compaction, tool_output_offloading: $tool_output_offloading} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List agents
#
# GET /v2/agents
# operationId: listAgents
export def "agents listAgents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression against agent names and descriptions to filter the results. (e.g. support.*)
  --enabled: oneof<nothing, bool> # Filter agents by enabled status. (e.g. true)
  --limit: int # The maximum number of agents to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of agents after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<agents: table<key: string, name: string, description: string, tool_configurations: record, skills: record, model: record, first_step: record, first_step_name: string, steps: record, metadata: record, enabled: bool, compaction: record, tool_output_offloading: record, created_at: string, updated_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/agents" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent
#
# GET /v2/agents/{agent_key}
# operationId: getAgent
export def "agents get" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<key: string, name: string, description: string, tool_configurations: record, skills: record, model: record<name: string, parameters: record, retry_configuration: record<enabled: bool, max_retries: int, initial_backoff_ms: int, max_backoff_ms: int, backoff_factor: float>>, first_step: record<name: string, type: string, instructions: list<any>, output_parser: record, reminders: list<any>, next_steps: list<record>, allowed_tools: list<string>, allowed_skills: list<string>, reentry_step: string>, first_step_name: string, steps: record, metadata: record, enabled: bool, compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, tool_output_offloading: record<enabled: bool, mode: string, context_percentage: float, max_threshold_bytes: int, min_threshold_bytes: int, headroom_percentage: float>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update agent
#
# PATCH /v2/agents/{agent_key}
# operationId: updateAgent
# --model shape: {name: string, parameters?: record, retry_configuration?: record}
# --first_step shape: {name?: string, type?: string, instructions?: list, output_parser?: any, reminders?: list, next_steps?: list, allowed_tools?: list, allowed_skills?: list, reentry_step?: string}
# --compaction shape: {enabled?: bool, threshold_percent?: int, keep_recent_inputs?: int, compaction_message?: string, tool_event_policy?: "exclude"|"include_outputs"|"include_all"}
# --tool_output_offloading shape: {enabled?: bool, mode?: "artifact"|"truncate", context_percentage?: float, max_threshold_bytes?: int, min_threshold_bytes?: int, headroom_percentage?: float}
export def "agents updateAgent" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # The human-readable name of an agent. (e.g. Customer Support Agent)
  --description: string # A detailed description of the agent's purpose and capabilities. Set to null to clear. (nullable, e.g. An enhanced AI agent specialized in handling customer support inquiries.)
  --tool-configurations: record # A map of tool configurations available to the agent. Set to null to clear all tools. Individual map values set to null will delete that tool configuration.  (nullable, e.g. {customer_search: {type: corpora_search, argument_override: {query: customer support documentation}}})
  --skills: record # A map of skills available to the agent. Set to null to clear all skills. Individual map values set to null will delete that skill.  (nullable)
  --model: record # Configuration for the model used in this step, including the model name and arbitrary parameters. — shape: {name: string, parameters?: record, retry_configuration?: record}
  --first-step: record # Partial update for the first (entry point) step. Omitted fields are preserved. Includes an optional name field to rename the first step. — shape: {name?: string, type?: string, instructions?: list, output_parser?: any, reminders?: list, next_steps?: list, allowed_tools?: list, allowed_skills?: list, reentry_step?: string}
  --first-step-name: string # Reassign the entry point to an existing step by name. This is the preferred way to change the entry point. The named step must exist in the steps map.
  --metadata: record # Arbitrary metadata associated with the agent. Set to null to clear. (nullable, e.g. {department: customer_service, version: 1.1.0, owner: support-team, last_reviewed: 2024-01-15})
  --enabled: oneof<nothing, bool> # Whether the agent is enabled. Set to null to reset to default (true). (nullable, e.g. true)
  --compaction: record # Configuration for automatic context compaction. — shape: {enabled?: bool, threshold_percent?: int, keep_recent_inputs?: int, compaction_message?: string, tool_event_policy?: "exclude"|"include_outputs"|"include_all"}
  --tool-output-offloading: record # Controls how large tool outputs are kept from overwhelming the agent context window.  Tool outputs are inspected as they are produced. A small output is always passed through unchanged. A larger output is handled in one of two cases: when the output on its own is big enough to dominate the context, or when adding it to the conversation would leave too little room for the agent to continue. In either case the output is handled according to `mode` — stored as an artifact and replaced with a compact reference, or truncated in place with the head and tail preserved and the middle omitted. When stored as an artifact, the agent is expected to have artifact_read, artifact_grep, or artifact_jq configured so it can retrieve the full content on demand.  All fields are optional; omitted fields fall back to defaults. — shape: {enabled?: bool, mode?: "artifact"|"truncate", context_percentage?: float, max_threshold_bytes?: int, min_threshold_bytes?: int, headroom_percentage?: float}
  --steps: record # A map of additional named steps keyed by step name for partial update. Only provided keys are modified; missing keys are preserved. Set a key's value to null to delete that step.  (nullable, e.g. {sales_handler: {instructions: [{type: inline, template: Handle sales inquiries}]}})
]: any -> record<key: string, name: string, description: string, tool_configurations: record, skills: record, model: record<name: string, parameters: record, retry_configuration: record<enabled: bool, max_retries: int, initial_backoff_ms: int, max_backoff_ms: int, backoff_factor: float>>, first_step: record<name: string, type: string, instructions: list<any>, output_parser: record, reminders: list<any>, next_steps: list<record>, allowed_tools: list<string>, allowed_skills: list<string>, reentry_step: string>, first_step_name: string, steps: record, metadata: record, enabled: bool, compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, tool_output_offloading: record<enabled: bool, mode: string, context_percentage: float, max_threshold_bytes: int, min_threshold_bytes: int, headroom_percentage: float>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)")
  let body = {name: $name, description: $description, tool_configurations: $tool_configurations, skills: $skills, model: $model, first_step: $first_step, first_step_name: $first_step_name, metadata: $metadata, enabled: $enabled, compaction: $compaction, tool_output_offloading: $tool_output_offloading, steps: $steps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace agent
#
# PUT /v2/agents/{agent_key}
# operationId: replaceAgent
# --model shape: {name: string, parameters?: record, retry_configuration?: record}
# --first_step shape: {name: string, type?: string, instructions: list, output_parser: any, reminders?: list, next_steps?: list, allowed_tools?: list, allowed_skills?: list, reentry_step?: string}
# --compaction shape: {enabled?: bool, threshold_percent?: int, keep_recent_inputs?: int, compaction_message?: string, tool_event_policy?: "exclude"|"include_outputs"|"include_all"}
# --tool_output_offloading shape: {enabled?: bool, mode?: "artifact"|"truncate", context_percentage?: float, max_threshold_bytes?: int, min_threshold_bytes?: int, headroom_percentage?: float}
export def "agents replaceAgent" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: string # A unique key that identifies an agent. (e.g. customer_support)
  name: string # The human-readable name of an agent. (e.g. Customer Support Agent)
  --description: string # A detailed description of the agent's purpose and capabilities. (e.g. An AI agent specialized in handling customer support inquiries using company documentation and support tools.)
  tool_configurations: record # A map of tool configurations available to the agent. The key is the name of the tool configuration and the value is the AgentToolConfiguration. (e.g. {customer_search: {type: corpora_search, argument_override: {query: customer support documentation}}})
  --skills: record # A map of skills available to the agent, keyed by skill name. Skills provide specialized instructions that can be invoked during agent execution.  (e.g. {code_review: {description: Reviews code for best practices., content: When reviewing code...}})
  model: record # Configuration for the model used in this step, including the model name and arbitrary parameters. — shape: {name: string, parameters?: record, retry_configuration?: record}
  --first-step: record # The entry point step for an agent, with a unique name. See AgentStep for full step documentation. — shape: {name: string, type?: string, instructions: list, output_parser: any, reminders?: list, next_steps?: list, allowed_tools?: list, allowed_skills?: list, reentry_step?: string}
  --first-step-name: string # Name of a step in the steps map to use as the entry point. This is the preferred way to define the entry point - define all steps in the steps map and reference the entry point by name here.  (e.g. classifier)
  --steps: record # A map of named steps keyed by step name. Steps can transition to other steps defined here via next_steps.  (e.g. {sales_handler: {instructions: [{type: inline, template: Handle sales inquiries}], output_parser: {type: default}}, support_handler: {instructions: [{type: inline, template: Handle support requests}], output_parser: {type: default}}})
  --metadata: record # Arbitrary metadata associated with the agent for customization and configuration. (default: {}, e.g. {department: customer_service, version: 1.0.0, owner: support-team})
  --enabled: oneof<nothing, bool> # Whether the agent should be enabled upon creation. (default: true, e.g. true)
  --compaction: record # Configuration for automatic context compaction. — shape: {enabled?: bool, threshold_percent?: int, keep_recent_inputs?: int, compaction_message?: string, tool_event_policy?: "exclude"|"include_outputs"|"include_all"}
  --tool-output-offloading: record # Controls how large tool outputs are kept from overwhelming the agent context window.  Tool outputs are inspected as they are produced. A small output is always passed through unchanged. A larger output is handled in one of two cases: when the output on its own is big enough to dominate the context, or when adding it to the conversation would leave too little room for the agent to continue. In either case the output is handled according to `mode` — stored as an artifact and replaced with a compact reference, or truncated in place with the head and tail preserved and the middle omitted. When stored as an artifact, the agent is expected to have artifact_read, artifact_grep, or artifact_jq configured so it can retrieve the full content on demand.  All fields are optional; omitted fields fall back to defaults. — shape: {enabled?: bool, mode?: "artifact"|"truncate", context_percentage?: float, max_threshold_bytes?: int, min_threshold_bytes?: int, headroom_percentage?: float}
]: any -> record<key: string, name: string, description: string, tool_configurations: record, skills: record, model: record<name: string, parameters: record, retry_configuration: record<enabled: bool, max_retries: int, initial_backoff_ms: int, max_backoff_ms: int, backoff_factor: float>>, first_step: record<name: string, type: string, instructions: list<any>, output_parser: record, reminders: list<any>, next_steps: list<record>, allowed_tools: list<string>, allowed_skills: list<string>, reentry_step: string>, first_step_name: string, steps: record, metadata: record, enabled: bool, compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, tool_output_offloading: record<enabled: bool, mode: string, context_percentage: float, max_threshold_bytes: int, min_threshold_bytes: int, headroom_percentage: float>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)")
  let body = {key: $key, name: $name, description: $description, tool_configurations: $tool_configurations, skills: $skills, model: $model, first_step: $first_step, first_step_name: $first_step_name, steps: $steps, metadata: $metadata, enabled: $enabled, compaction: $compaction, tool_output_offloading: $tool_output_offloading} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete agent
#
# DELETE /v2/agents/{agent_key}
# operationId: deleteAgent
export def "agents delete" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create agent session
#
# POST /v2/agents/{agent_key}/sessions
# operationId: createAgentSession
# --from_session shape: {agent_key?: string, session_key: string, include_up_to_event_id?: string, compact_up_to_event_id?: string}
export def "agents-sessions createAgentSession" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: string # A unique key that identifies an agent session. (e.g. customer_support_chat)
  --name: string # Human-readable name for the session. (e.g. Customer Support Session)
  --description: string # A short description of the session's purpose. If omitted, one is auto-generated once the session has produced events. Pass an empty string to suppress auto-generation.  (e.g. Helping customer troubleshoot issues)
  --metadata: record # Arbitrary metadata associated with the session. (default: {}, e.g. {customer_id: 12345, priority: medium, channel: web_chat})
  --enabled: oneof<nothing, bool> # Whether the session should be enabled upon creation. (default: true, e.g. true)
  --tti-minutes: int # Time-to-idle in minutes for the session. If no events occur in the session for this duration, the session will be automatically deleted. If set to 0, the session will not expire. (format: int64, default: 0, e.g. 60)
  --secrets: record # Session-scoped secrets to store on the new session. Map of secret name to plaintext value. Encrypted at rest with the owning agent's encryption key. Referenced from tool `argument_override` via `{"$ref": "session.secrets.<name>"}`. Returned masked (`****`) on reads.  (e.g. {slack_user_token: xoxp-your-token-here})
  --from-session: record # Create a new session by forking an existing one. By default, copies all visible events and artifacts from the source session without compaction. Optionally specify exactly one of include_up_to_event_id or compact_up_to_event_id to control which events are included and whether they are compacted. These two fields are mutually exclusive. — shape: {agent_key?: string, session_key: string, include_up_to_event_id?: string, compact_up_to_event_id?: string}
]: any -> record<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record<input_tokens: record<count: int>, output_tokens: record<count: int, reasoning_tokens: int>, total_tokens: int, model_context_window: int>, effective_compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, alias_key: string, secrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions")
  let body = {key: $key, name: $name, description: $description, metadata: $metadata, enabled: $enabled, tti_minutes: $tti_minutes, secrets: $secrets, from_session: $from_session} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List agent sessions
#
# GET /v2/agents/{agent_key}/sessions
# operationId: listAgentSessions
export def "agents-sessions listAgentSessions" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string # A regular expression against session names and descriptions to filter the results. (e.g. support.*)
  --metadata-filter: string # A filter expression to narrow the list to sessions whose metadata matches. Field names refer to keys on the session's `metadata` object. Syntax is similar to a SQL WHERE clause, the same as the `metadata_filter` used in query requests. See [metadata filters documentation](https://docs.vectara.com/docs/learn/metadata-search-filtering/filter-overview) for more information.  Examples: - `user_role = 'premium'` - `tier >= 2 AND region = 'us'` - `user LIKE '%@example.com'` - `tier IN ('premium', 'enterprise')` - `tier IS NULL` - `"profile.country" = 'US'` (nested fields use a quoted dotted path) - `1 IN user_ids` (value present in an array)  (e.g. user_role = 'premium' AND tier >= 2)
  --limit: int # The maximum number of sessions to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of sessions after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<sessions: table<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record, effective_compaction: record, alias_key: string, secrets: record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "metadata_filter" $metadata_filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent session
#
# GET /v2/agents/{agent_key}/sessions/{session_key}
# operationId: getAgentSession
export def "agents-sessions get" [
  agent_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record<input_tokens: record<count: int>, output_tokens: record<count: int, reasoning_tokens: int>, total_tokens: int, model_context_window: int>, effective_compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, alias_key: string, secrets: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update agent session
#
# PATCH /v2/agents/{agent_key}/sessions/{session_key}
# operationId: updateAgentSession
export def "agents-sessions updateAgentSession" [
  agent_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # Human-readable name for the session. (e.g. Updated Session Name)
  --description: string # A short description of the session's purpose. Pass an empty string to suppress auto-generation.  (e.g. Updated session description)
  --metadata: record # Arbitrary metadata associated with the session. (e.g. {customer_id: 12345, priority: high, status: escalated})
  --enabled: oneof<nothing, bool> # Whether the session is enabled. (e.g. false)
  --tti-minutes: int # Time-to-idle in minutes for the session. If no events occur in the session for this duration, the session will be automatically deleted. If set to 0, the session will not expire. (format: int64, e.g. 60)
  --secrets: record # Patch the session's secrets. Names present in the map are added or replaced; names absent from the map are left unchanged. A name mapped to `null` is removed. Values are encrypted at rest with the owning agent's encryption key and returned masked on reads.  (e.g. {slack_user_token: xoxp-rotated-token, old_token_to_remove: })
]: any -> record<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record<input_tokens: record<count: int>, output_tokens: record<count: int, reasoning_tokens: int>, total_tokens: int, model_context_window: int>, effective_compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, alias_key: string, secrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)")
  let body = {name: $name, description: $description, metadata: $metadata, enabled: $enabled, tti_minutes: $tti_minutes, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete agent session
#
# DELETE /v2/agents/{agent_key}/sessions/{session_key}
# operationId: deleteAgentSession
export def "agents-sessions delete" [
  agent_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Interact with an agent
#
# POST /v2/agents/{agent_key}/sessions/{session_key}/events
# Discriminator (request): type = input_message, interrupt, compact, tool_output
# operationId: createAgentInput
export def "agents-sessions-events createAgentInput" [
  agent_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-8 # default: input_message
]: any -> record<events: list<record>, session_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/events")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List events in agent session
#
# GET /v2/agents/{agent_key}/sessions/{session_key}/events
# operationId: listAgentEvents
export def "agents-sessions-events listAgentEvents" [
  agent_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of events to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of events after the limit has been reached.
  --include-hidden: oneof<nothing, bool> # Include hidden events (compacted or manually hidden) in the response. Defaults to false. (default: false)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<events: list<record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar") (serialize-qp "include_hidden" $include_hidden "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/events" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List outstanding client tool calls for an agent session
#
# GET /v2/agents/{agent_key}/sessions/{session_key}/outstanding_client_tool_calls
# operationId: listOutstandingClientToolCalls
export def "agents-sessions-outstanding-client-tool-calls listOutstandingClientToolCalls" [
  agent_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<client_tool_calls: table<event_id: string, tool_configuration_name: string, tool_name: string, arguments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/outstanding_client_tool_calls")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get event in agent session
#
# GET /v2/agents/{agent_key}/sessions/{session_key}/events/{event_id}
# Discriminator (response): type = input_message, skill_load, artifact_upload, tool_input, tool_output, thinking, agent_output, structured_output, context_limit_exceeded, step_transition_limit_exceeded, session_interrupted, client_tool_pending, image_read, step_transition, compaction
# operationId: getAgentEvent
export def "agents-sessions-events get" [
  agent_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/events/($event_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete event
#
# DELETE /v2/agents/{agent_key}/sessions/{session_key}/events/{event_id}
# operationId: deleteAgentEvent
export def "agents-sessions-events delete" [
  agent_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/events/($event_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hide event
#
# POST /v2/agents/{agent_key}/sessions/{session_key}/events/{event_id}/hide
# Discriminator (response): type = input_message, skill_load, artifact_upload, tool_input, tool_output, thinking, agent_output, structured_output, context_limit_exceeded, step_transition_limit_exceeded, session_interrupted, client_tool_pending, image_read, step_transition, compaction
# operationId: hideAgentEvent
export def "agents-sessions-events-hide hideAgentEvent" [
  agent_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/events/($event_id)/hide")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unhide event
#
# POST /v2/agents/{agent_key}/sessions/{session_key}/events/{event_id}/unhide
# Discriminator (response): type = input_message, skill_load, artifact_upload, tool_input, tool_output, thinking, agent_output, structured_output, context_limit_exceeded, step_transition_limit_exceeded, session_interrupted, client_tool_pending, image_read, step_transition, compaction
# operationId: unhideAgentEvent
export def "agents-sessions-events-unhide unhideAgentEvent" [
  agent_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/events/($event_id)/unhide")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List session artifacts
#
# GET /v2/agents/{agent_key}/sessions/{session_key}/artifacts
# operationId: listSessionArtifacts
export def "agents-sessions-artifacts listSessionArtifacts" [
  agent_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of artifacts to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of artifacts after the limit has been reached.
  --sort-by: string@sort-by-completer # The field to sort results by. (default: created_at)
  --order-by: string@order-by-completer # The ordering direction of the results. (default: desc)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<artifacts: table<artifact_id: string, filename: string, mime_type: string, size_bytes: int, checksum_sha256: string, metadata: record, description: string, ttl_days: int, created_at: string, updated_at: string, data: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/artifacts" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get session artifact
#
# GET /v2/agents/{agent_key}/sessions/{session_key}/artifacts/{artifact_id}
# operationId: getSessionArtifact
export def "agents-sessions-artifacts get" [
  agent_key: string
  session_key: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<artifact_id: string, filename: string, mime_type: string, size_bytes: int, checksum_sha256: string, metadata: record, description: string, ttl_days: int, created_at: string, updated_at: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/sessions/($session_key)/artifacts/($artifact_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create agent schedule
#
# POST /v2/agents/{agent_key}/schedules
# operationId: createAgentSchedule
export def "agents-schedules createAgentSchedule" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: string # A unique key that identifies an agent schedule. Uses "key" terminology (instead of "id") for consistency with other Vectara API resources (AgentKey, SessionKey, CorpusKey, etc.).  (e.g. daily-report)
  name: string # The human-readable name of an agent schedule. (e.g. Daily Summary Report)
  --description: string # Optional detailed description of the schedule's purpose.
  message: list # The input message to send to the agent on each scheduled execution.
  schedule: any # Configuration for when and how often the schedule should execute.
  --enabled: oneof<nothing, bool> # Whether the schedule should be active upon creation. (default: true)
  --session-metadata: record # Arbitrary metadata to include in each session created by this schedule. (default: {})
  --max-executions-to-keep: int # Maximum number of past execution records to keep. Defaults to 10. (format: int32, default: 10)
  --stall-timeout-seconds: int # Number of seconds a scheduled run may go without producing output (streamed tokens, tool calls, or other progress events) before it is considered stalled and retried. Set this above the longest silent operation the agent is expected to perform so an in-flight run is not retried mid-operation.  (format: int32, default: 3600, e.g. 1800)
]: any -> record<key: string, agent_key: string, name: string, description: string, message: list<any>, schedule: any, enabled: bool, session_metadata: record, max_executions_to_keep: int, stall_timeout_seconds: int, last_execution_at: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/schedules")
  let body = {key: $key, name: $name, description: $description, message: $message, schedule: $schedule, enabled: $enabled, session_metadata: $session_metadata, max_executions_to_keep: $max_executions_to_keep, stall_timeout_seconds: $stall_timeout_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List agent schedules
#
# GET /v2/agents/{agent_key}/schedules
# operationId: listAgentSchedules
export def "agents-schedules listAgentSchedules" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of schedules to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of schedules after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<schedules: table<key: string, agent_key: string, name: string, description: string, message: list, schedule: any, enabled: bool, session_metadata: record, max_executions_to_keep: int, stall_timeout_seconds: int, last_execution_at: string, created_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agents/($agent_key)/schedules" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent schedule
#
# GET /v2/agents/{agent_key}/schedules/{schedule_key}
# operationId: getAgentSchedule
export def "agents-schedules get" [
  agent_key: string
  schedule_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<key: string, agent_key: string, name: string, description: string, message: list<any>, schedule: any, enabled: bool, session_metadata: record, max_executions_to_keep: int, stall_timeout_seconds: int, last_execution_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/schedules/($schedule_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update agent schedule
#
# PATCH /v2/agents/{agent_key}/schedules/{schedule_key}
# operationId: updateAgentSchedule
export def "agents-schedules updateAgentSchedule" [
  agent_key: string
  schedule_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # The human-readable name of an agent schedule. (e.g. Daily Summary Report)
  --description: string # Updated description of the schedule's purpose.
  --message: list # Updated input message to send to the agent on each scheduled execution.
  --schedule: any # Configuration for when and how often the schedule should execute.
  --enabled: oneof<nothing, bool> # Updated enabled status for the schedule.
  --session-metadata: record # Updated metadata to include in each session created by this schedule.
  --max-executions-to-keep: int # Updated maximum number of past execution records to keep. (format: int32)
  --stall-timeout-seconds: int # Updated number of seconds a scheduled run may go without producing output before it is considered stalled and retried. Omit to leave the current value unchanged.  (format: int32)
]: any -> record<key: string, agent_key: string, name: string, description: string, message: list<any>, schedule: any, enabled: bool, session_metadata: record, max_executions_to_keep: int, stall_timeout_seconds: int, last_execution_at: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/schedules/($schedule_key)")
  let body = {name: $name, description: $description, message: $message, schedule: $schedule, enabled: $enabled, session_metadata: $session_metadata, max_executions_to_keep: $max_executions_to_keep, stall_timeout_seconds: $stall_timeout_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete agent schedule
#
# DELETE /v2/agents/{agent_key}/schedules/{schedule_key}
# operationId: deleteAgentSchedule
export def "agents-schedules delete" [
  agent_key: string
  schedule_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/schedules/($schedule_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List agent schedule executions
#
# GET /v2/agents/{agent_key}/schedules/{schedule_key}/executions
# operationId: listAgentScheduleExecutions
export def "agents-schedules-executions listAgentScheduleExecutions" [
  agent_key: string
  schedule_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int32, default: 10
  --page-key: string
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<executions: table<schedule_key: string, workflow_run_id: string, session_key: string, attempt: int, status: string, error_message: string, executed_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agents/($agent_key)/schedules/($schedule_key)/executions" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent identity
#
# GET /v2/agents/{agent_key}/identity
# operationId: getAgentIdentity
export def "agents-identity get" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<mode: string, client_id: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/identity")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update agent identity
#
# PATCH /v2/agents/{agent_key}/identity
# operationId: updateAgentIdentity
# --corpus_roles item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
# --agent_roles item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
export def "agents-identity updateAgentIdentity" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --mode: string@mode-completer # The role management mode of the agent's identity. - `auto`: The platform keeps roles in sync with the agent's tool configuration. When tools change, roles are automatically recomputed. - `manual`: Roles are user-managed. The platform will not modify roles when the agent is updated.  (e.g. auto)
  --api-roles: list # Customer-level roles to assign. Only applied in `manual` mode.
  --corpus-roles: list # Corpus-specific roles to assign. Only applied in `manual` mode. — item shape: {corpus_key: string, role: "owner"|"administrator"|"viewer"|"editor"}
  --agent-roles: list # Agent-specific roles to assign. Only applied in `manual` mode. — item shape: {agent_key: string, role: "agent_administrator"|"agent_viewer"|"agent_developer"|"agent_user"}
]: any -> record<mode: string, client_id: string, api_roles: list<string>, corpus_roles: table<corpus_key: string, role: string>, agent_roles: table<agent_key: string, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/identity")
  let body = {mode: $mode, api_roles: $api_roles, corpus_roles: $corpus_roles, agent_roles: $agent_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent secrets
#
# GET /v2/agents/{agent_key}/secrets
# operationId: getAgentSecrets
export def "agents-secrets get" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<secrets: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/secrets")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace agent secrets
#
# PUT /v2/agents/{agent_key}/secrets
# operationId: replaceAgentSecrets
export def "agents-secrets replaceAgentSecrets" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  secrets: record # Map of secret name to plaintext value. (e.g. {jira_api_token: ATATT3xFf...})
]: any -> record<secrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/secrets")
  let body = {secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update agent secrets
#
# PATCH /v2/agents/{agent_key}/secrets
# operationId: updateAgentSecrets
export def "agents-secrets updateAgentSecrets" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  secrets: record # Map of secret name to plaintext value (or `null` to remove). Names not in the map are not touched.  (e.g. {jira_api_token: ATATT3xFf..., old_token_to_remove: })
]: any -> record<secrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/secrets")
  let body = {secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent memory
#
# GET /v2/agents/{agent_key}/memory
# operationId: getAgentMemory
export def "agents-memory get" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<skill: record<description: string, content: string>, metadata: record<memory_version: int, memory_last_updated: string, memory_last_updated_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/memory")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update agent memory
#
# PATCH /v2/agents/{agent_key}/memory
# operationId: updateAgentMemory
export def "agents-memory updateAgentMemory" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  content: string # The full memory content to store. Replaces the previous content entirely. (e.g. - Customer prefers email contact - Time zone: PST)
  updated_by: string # Identifier of who is performing this update (e.g. `query_handler`, `manual_update`). (e.g. query_handler)
  --expected-version: int # The `memory_version` the client last read. If provided and it does not match the current version, the update is rejected with `409 Conflict`. Omit to update unconditionally.  (nullable, format: int32, e.g. 2)
]: any -> record<skill: record<description: string, content: string>, metadata: record<memory_version: int, memory_last_updated: string, memory_last_updated_by: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/memory")
  let body = {content: $content, updated_by: $updated_by, expected_version: $expected_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get agent memory history
#
# GET /v2/agents/{agent_key}/memory/history
# operationId: getAgentMemoryHistory
export def "agents-memory-history get" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<skill_name: string, versions: table<version: int, content: string, timestamp: string, updated_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/memory/history")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create agent connector
#
# POST /v2/agents/{agent_key}/connectors
# operationId: createAgentConnector
export def "agents-connectors createAgentConnector" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  name: string # The human-readable name of the connector. (e.g. Customer Support Slack Channel)
  --description: string # A detailed description of what this connector does. (e.g. Receives customer support messages from the)
  --metadata: record # Arbitrary metadata associated with the connector. (default: {}, e.g. {priority: high, department: customer_service})
  --enabled: oneof<nothing, bool> # Whether the connector should be enabled upon creation. (default: true, e.g. true)
  configuration: any # Write view of a connector's configuration. Used when creating a connector and reused when updating one. Carries the secrets and inputs the customer must supply. Server-derived display fields are not accepted here and instead appear in the read view: Slack returns `webhook_path`, and gchat returns `audience_url` and `client_email`.
]: any -> record<id: string, agent_key: string, name: string, description: string, type: string, status: string, status_message: string, metadata: record, enabled: bool, configuration: any, created_at: string, updated_at: string, last_webhook_at: string, last_webhook_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/connectors")
  let body = {name: $name, description: $description, metadata: $metadata, enabled: $enabled, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List agent connectors
#
# GET /v2/agents/{agent_key}/connectors
# operationId: listAgentConnectors
export def "agents-connectors listAgentConnectors" [
  agent_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-9 # Filter connectors by type. (e.g. slack)
  --enabled: oneof<nothing, bool> # Filter connectors by enabled status. (e.g. true)
  --limit: int # The maximum number of connectors to return in the list. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of connectors after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<connectors: table<id: string, agent_key: string, name: string, description: string, type: string, status: string, status_message: string, metadata: record, enabled: bool, configuration: any, created_at: string, updated_at: string, last_webhook_at: string, last_webhook_status: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agents/($agent_key)/connectors" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent connector
#
# GET /v2/agents/{agent_key}/connectors/{connector_id}
# operationId: getAgentConnector
export def "agents-connectors get" [
  agent_key: string
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, agent_key: string, name: string, description: string, type: string, status: string, status_message: string, metadata: record, enabled: bool, configuration: any, created_at: string, updated_at: string, last_webhook_at: string, last_webhook_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/connectors/($connector_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update agent connector
#
# PATCH /v2/agents/{agent_key}/connectors/{connector_id}
# operationId: updateAgentConnector
export def "agents-connectors updateAgentConnector" [
  agent_key: string
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # The human-readable name of the connector. (e.g. Updated Customer Support Slack Channel)
  --description: string # A detailed description of what this connector does. (e.g. Updated description for the Slack connector)
  --metadata: record # Arbitrary metadata associated with the connector. (e.g. {priority: medium, department: customer_service, last_reviewed: 2024-01-15})
  --enabled: oneof<nothing, bool> # Whether the connector is enabled. (e.g. false)
  --configuration: any # Write view of a connector's configuration. Used when creating a connector and reused when updating one. Carries the secrets and inputs the customer must supply. Server-derived display fields are not accepted here and instead appear in the read view: Slack returns `webhook_path`, and gchat returns `audience_url` and `client_email`.
]: any -> record<id: string, agent_key: string, name: string, description: string, type: string, status: string, status_message: string, metadata: record, enabled: bool, configuration: any, created_at: string, updated_at: string, last_webhook_at: string, last_webhook_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/connectors/($connector_id)")
  let body = {name: $name, description: $description, metadata: $metadata, enabled: $enabled, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete agent connector
#
# DELETE /v2/agents/{agent_key}/connectors/{connector_id}
# operationId: deleteAgentConnector
export def "agents-connectors delete" [
  agent_key: string
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agents/($agent_key)/connectors/($connector_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an alias
#
# POST /v2/agent_aliases
# operationId: createAgentAlias
export def "agent-aliases createAgentAlias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  key: string # The unique key identifying an alias. Alias keys are independent of agent keys — the same string may exist as both an alias and an agent in a customer; calls to `/v2/agent_aliases/{key}/...` target the alias and calls to `/v2/agents/{key}/...` target the agent.  (e.g. support)
  name: string
  --description: string
  policy: any # A routing policy. The `type` discriminator determines which fields apply:  * `routed` — evaluate ordered rules; the first rule whose `match` expression evaluates to true is selected. The selected rule's `targets` are then used (one agent for `single`, hashed by `partition_by` for `weighted`). A rule with omitted `match` is a catch-all that always matches; it must be the last rule, and any rule placed after it is rejected as unreachable.  Most use cases (direct, weighted/canary, conditional, conditional+canary) collapse into `routed`.
  --enabled: oneof<nothing, bool> # default: true
  --metadata: record
]: any -> record<key: string, name: string, description: string, policy: any, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/agent_aliases")
  let body = {key: $key, name: $name, description: $description, policy: $policy, enabled: $enabled, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List aliases
#
# GET /v2/agent_aliases
# operationId: listAgentAliases
export def "agent-aliases listAgentAliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max number of aliases to return. (format: int32, default: 10)
  --page-key: string # Pagination cursor.
  --filter: string # A regular expression matched against alias names and descriptions to filter results. (e.g. support.*)
  --enabled: oneof<nothing, bool> # Filter aliases by enabled status. (e.g. true)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<aliases: table<key: string, name: string, description: string, policy: any, enabled: bool, metadata: record, created_at: string, updated_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/agent_aliases" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an alias
#
# GET /v2/agent_aliases/{alias_key}
# operationId: getAgentAlias
export def "agent-aliases get" [
  alias_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<key: string, name: string, description: string, policy: any, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an alias's metadata
#
# PATCH /v2/agent_aliases/{alias_key}
# operationId: updateAgentAlias
export def "agent-aliases updateAgentAlias" [
  alias_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string
  --description: string
  --enabled: oneof<nothing, bool>
  --metadata: record
]: any -> record<key: string, name: string, description: string, policy: any, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)")
  let body = {name: $name, description: $description, enabled: $enabled, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an alias
#
# DELETE /v2/agent_aliases/{alias_key}
# operationId: deleteAgentAlias
export def "agent-aliases delete" [
  alias_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace an alias's routing policy
#
# PUT /v2/agent_aliases/{alias_key}/policy
# operationId: replaceAgentAliasPolicy
export def "agent-aliases-policy replaceAgentAliasPolicy" [
  alias_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  policy: any # A routing policy. The `type` discriminator determines which fields apply:  * `routed` — evaluate ordered rules; the first rule whose `match` expression evaluates to true is selected. The selected rule's `targets` are then used (one agent for `single`, hashed by `partition_by` for `weighted`). A rule with omitted `match` is a catch-all that always matches; it must be the last rule, and any rule placed after it is rejected as unreachable.  Most use cases (direct, weighted/canary, conditional, conditional+canary) collapse into `routed`.
]: any -> record<key: string, name: string, description: string, policy: any, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/policy")
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create session via alias
#
# POST /v2/agent_aliases/{alias_key}/sessions
# operationId: createAliasRoutedSession
# --from_session shape: {agent_key?: string, session_key: string, include_up_to_event_id?: string, compact_up_to_event_id?: string}
export def "agent-aliases-sessions createAliasRoutedSession" [
  alias_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: string # A unique key that identifies an agent session. (e.g. customer_support_chat)
  --name: string # Human-readable name for the session. (e.g. Customer Support Session)
  --description: string # A short description of the session's purpose. If omitted, one is auto-generated once the session has produced events. Pass an empty string to suppress auto-generation.  (e.g. Helping customer troubleshoot issues)
  --metadata: record # Arbitrary metadata associated with the session. (default: {}, e.g. {customer_id: 12345, priority: medium, channel: web_chat})
  --enabled: oneof<nothing, bool> # Whether the session should be enabled upon creation. (default: true, e.g. true)
  --tti-minutes: int # Time-to-idle in minutes for the session. If no events occur in the session for this duration, the session will be automatically deleted. If set to 0, the session will not expire. (format: int64, default: 0, e.g. 60)
  --secrets: record # Session-scoped secrets to store on the new session. Map of secret name to plaintext value. Encrypted at rest with the owning agent's encryption key. Referenced from tool `argument_override` via `{"$ref": "session.secrets.<name>"}`. Returned masked (`****`) on reads.  (e.g. {slack_user_token: xoxp-your-token-here})
  --from-session: record # Create a new session by forking an existing one. By default, copies all visible events and artifacts from the source session without compaction. Optionally specify exactly one of include_up_to_event_id or compact_up_to_event_id to control which events are included and whether they are compacted. These two fields are mutually exclusive. — shape: {agent_key?: string, session_key: string, include_up_to_event_id?: string, compact_up_to_event_id?: string}
]: any -> record<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record<input_tokens: record<count: int>, output_tokens: record<count: int, reasoning_tokens: int>, total_tokens: int, model_context_window: int>, effective_compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, alias_key: string, secrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions")
  let body = {key: $key, name: $name, description: $description, metadata: $metadata, enabled: $enabled, tti_minutes: $tti_minutes, secrets: $secrets, from_session: $from_session} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List sessions routed via this alias
#
# GET /v2/agent_aliases/{alias_key}/sessions
# operationId: listAliasRoutedSessions
export def "agent-aliases-sessions listAliasRoutedSessions" [
  alias_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string
  --limit: int # format: int32, default: 10
  --page-key: string
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<sessions: table<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record, effective_compaction: record, alias_key: string, secrets: record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get alias-routed session
#
# GET /v2/agent_aliases/{alias_key}/sessions/{session_key}
# operationId: getAliasRoutedSession
export def "agent-aliases-sessions get" [
  alias_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record<input_tokens: record<count: int>, output_tokens: record<count: int, reasoning_tokens: int>, total_tokens: int, model_context_window: int>, effective_compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, alias_key: string, secrets: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update alias-routed session
#
# PATCH /v2/agent_aliases/{alias_key}/sessions/{session_key}
# operationId: updateAliasRoutedSession
export def "agent-aliases-sessions updateAliasRoutedSession" [
  alias_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # Human-readable name for the session. (e.g. Updated Session Name)
  --description: string # A short description of the session's purpose. Pass an empty string to suppress auto-generation.  (e.g. Updated session description)
  --metadata: record # Arbitrary metadata associated with the session. (e.g. {customer_id: 12345, priority: high, status: escalated})
  --enabled: oneof<nothing, bool> # Whether the session is enabled. (e.g. false)
  --tti-minutes: int # Time-to-idle in minutes for the session. If no events occur in the session for this duration, the session will be automatically deleted. If set to 0, the session will not expire. (format: int64, e.g. 60)
  --secrets: record # Patch the session's secrets. Names present in the map are added or replaced; names absent from the map are left unchanged. A name mapped to `null` is removed. Values are encrypted at rest with the owning agent's encryption key and returned masked on reads.  (e.g. {slack_user_token: xoxp-rotated-token, old_token_to_remove: })
]: any -> record<key: string, agent_key: string, name: string, description: string, metadata: record, current_step_name: string, enabled: bool, status: string, tti_minutes: int, created_at: string, session_context_usage: record<input_tokens: record<count: int>, output_tokens: record<count: int, reasoning_tokens: int>, total_tokens: int, model_context_window: int>, effective_compaction: record<enabled: bool, threshold_percent: int, keep_recent_inputs: int, compaction_message: string, tool_event_policy: string>, alias_key: string, secrets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)")
  let body = {name: $name, description: $description, metadata: $metadata, enabled: $enabled, tti_minutes: $tti_minutes, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete alias-routed session
#
# DELETE /v2/agent_aliases/{alias_key}/sessions/{session_key}
# operationId: deleteAliasRoutedSession
export def "agent-aliases-sessions delete" [
  alias_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit input to alias-routed session
#
# POST /v2/agent_aliases/{alias_key}/sessions/{session_key}/events
# Discriminator (request): type = input_message, interrupt, compact, tool_output
# operationId: createAliasRoutedInput
export def "agent-aliases-sessions-events createAliasRoutedInput" [
  alias_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  type: string@type-completer-8 # default: input_message
]: any -> record<events: list<record>, session_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/events")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List events on alias-routed session
#
# GET /v2/agent_aliases/{alias_key}/sessions/{session_key}/events
# operationId: listAliasRoutedEvents
export def "agent-aliases-sessions-events listAliasRoutedEvents" [
  alias_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int32, default: 10
  --page-key: string
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<events: list<record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/events" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List outstanding client tool calls on alias-routed session
#
# GET /v2/agent_aliases/{alias_key}/sessions/{session_key}/outstanding_client_tool_calls
# operationId: listAliasRoutedOutstandingClientToolCalls
export def "agent-aliases-sessions-outstanding-client-tool-calls listAliasRoutedOutstandingClientToolCalls" [
  alias_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<client_tool_calls: table<event_id: string, tool_configuration_name: string, tool_name: string, arguments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/outstanding_client_tool_calls")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get event on alias-routed session
#
# GET /v2/agent_aliases/{alias_key}/sessions/{session_key}/events/{event_id}
# Discriminator (response): type = input_message, skill_load, artifact_upload, tool_input, tool_output, thinking, agent_output, structured_output, context_limit_exceeded, step_transition_limit_exceeded, session_interrupted, client_tool_pending, image_read, step_transition, compaction
# operationId: getAliasRoutedEvent
export def "agent-aliases-sessions-events get" [
  alias_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/events/($event_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete event on alias-routed session
#
# DELETE /v2/agent_aliases/{alias_key}/sessions/{session_key}/events/{event_id}
# operationId: deleteAliasRoutedEvent
export def "agent-aliases-sessions-events delete" [
  alias_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/events/($event_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hide event on alias-routed session
#
# POST /v2/agent_aliases/{alias_key}/sessions/{session_key}/events/{event_id}/hide
# Discriminator (response): type = input_message, skill_load, artifact_upload, tool_input, tool_output, thinking, agent_output, structured_output, context_limit_exceeded, step_transition_limit_exceeded, session_interrupted, client_tool_pending, image_read, step_transition, compaction
# operationId: hideAliasRoutedEvent
export def "agent-aliases-sessions-events-hide hideAliasRoutedEvent" [
  alias_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/events/($event_id)/hide")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unhide event on alias-routed session
#
# POST /v2/agent_aliases/{alias_key}/sessions/{session_key}/events/{event_id}/unhide
# Discriminator (response): type = input_message, skill_load, artifact_upload, tool_input, tool_output, thinking, agent_output, structured_output, context_limit_exceeded, step_transition_limit_exceeded, session_interrupted, client_tool_pending, image_read, step_transition, compaction
# operationId: unhideAliasRoutedEvent
export def "agent-aliases-sessions-events-unhide unhideAliasRoutedEvent" [
  alias_key: string
  session_key: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/events/($event_id)/unhide")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List artifacts on alias-routed session
#
# GET /v2/agent_aliases/{alias_key}/sessions/{session_key}/artifacts
# operationId: listAliasRoutedSessionArtifacts
export def "agent-aliases-sessions-artifacts listAliasRoutedSessionArtifacts" [
  alias_key: string
  session_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int32, default: 10
  --page-key: string
  --sort-by: string@sort-by-completer # default: created_at
  --order-by: string@order-by-completer # default: desc
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<artifacts: table<artifact_id: string, filename: string, mime_type: string, size_bytes: int, checksum_sha256: string, metadata: record, description: string, ttl_days: int, created_at: string, updated_at: string, data: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/artifacts" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get artifact on alias-routed session
#
# GET /v2/agent_aliases/{alias_key}/sessions/{session_key}/artifacts/{artifact_id}
# operationId: getAliasRoutedSessionArtifact
export def "agent-aliases-sessions-artifacts get" [
  alias_key: string
  session_key: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<artifact_id: string, filename: string, mime_type: string, size_bytes: int, checksum_sha256: string, metadata: record, description: string, ttl_days: int, created_at: string, updated_at: string, data: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_aliases/($alias_key)/sessions/($session_key)/artifacts/($artifact_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create pipeline
#
# POST /v2/pipelines
# operationId: createPipeline
# --transform shape: {type: "agent", agent_key?: string, verification?: any}
export def "pipelines createPipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: any # A user-provided key for the pipeline. If omitted, one is auto-generated.
  name: string # The human-readable name of the pipeline. (e.g. SharePoint Legal Docs Ingest)
  --description: string
  --body-source: any # The source system to ingest data from.
  trigger: any # Defines when the pipeline runs.
  transform: record # Defines how source data is processed. Currently only agent transforms are supported. — shape: {type: "agent", agent_key?: string, verification?: any}
  --sync-mode: string@sync-mode-completer # How the pipeline syncs data from the source. - `incremental`: Only process new or changed records since the last watermark. - `full_refresh`: Process all records from the source on each run.  (default: incremental)
  --enabled: oneof<nothing, bool> # default: true
  --metadata: record # default: {}
]: any -> record<key: string, name: string, description: string, source: any, trigger: any, transform: record<type: string>, sync_mode: string, watermark: record<value: string, updated_at: string>, status: string, status_message: string, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/pipelines")
  let body = {key: $key, name: $name, description: $description, source: $body_source, trigger: $trigger, transform: $transform, sync_mode: $sync_mode, enabled: $enabled, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List pipelines
#
# GET /v2/pipelines
# operationId: listPipelines
export def "pipelines listPipelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-type: string@source-type-completer # Filter pipelines by source type.
  --status: string@status-completer # Filter pipelines by status.
  --enabled: oneof<nothing, bool> # Filter pipelines by enabled state.
  --filter: string # A regex filter on pipeline name and description.
  --limit: int # The maximum number of pipelines to return. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of pipelines after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<pipelines: table<key: string, name: string, description: string, source: any, trigger: any, transform: record, sync_mode: string, watermark: record, status: string, status_message: string, enabled: bool, metadata: record, created_at: string, updated_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_type" $source_type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/pipelines" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pipeline
#
# GET /v2/pipelines/{pipeline_key}
# operationId: getPipeline
export def "pipelines get" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<key: string, name: string, description: string, source: any, trigger: any, transform: record<type: string>, sync_mode: string, watermark: record<value: string, updated_at: string>, status: string, status_message: string, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace pipeline
#
# PUT /v2/pipelines/{pipeline_key}
# operationId: replacePipeline
# --transform shape: {type: "agent", agent_key?: string, verification?: any}
export def "pipelines replacePipeline" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: any # A user-provided key for the pipeline. If omitted, one is auto-generated.
  name: string # The human-readable name of the pipeline. (e.g. SharePoint Legal Docs Ingest)
  --description: string
  --body-source: any # The source system to ingest data from.
  trigger: any # Defines when the pipeline runs.
  transform: record # Defines how source data is processed. Currently only agent transforms are supported. — shape: {type: "agent", agent_key?: string, verification?: any}
  --sync-mode: string@sync-mode-completer # How the pipeline syncs data from the source. - `incremental`: Only process new or changed records since the last watermark. - `full_refresh`: Process all records from the source on each run.  (default: incremental)
  --enabled: oneof<nothing, bool> # default: true
  --metadata: record # default: {}
]: any -> record<key: string, name: string, description: string, source: any, trigger: any, transform: record<type: string>, sync_mode: string, watermark: record<value: string, updated_at: string>, status: string, status_message: string, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)")
  let body = {key: $key, name: $name, description: $description, source: $body_source, trigger: $trigger, transform: $transform, sync_mode: $sync_mode, enabled: $enabled, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update pipeline
#
# PATCH /v2/pipelines/{pipeline_key}
# operationId: updatePipeline
# --transform shape: {type: "agent", agent_key?: string, verification?: any}
export def "pipelines updatePipeline" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # The human-readable name of the pipeline. (e.g. SharePoint Legal Docs Ingest)
  --description: string # nullable
  --body-source: any # Source configuration for partial updates. Only provided fields are changed; credentials are optional.
  --trigger: any # Defines when the pipeline runs.
  --transform: record # Defines how source data is processed. Currently only agent transforms are supported. — shape: {type: "agent", agent_key?: string, verification?: any}
  --sync-mode: string@sync-mode-completer # How the pipeline syncs data from the source. - `incremental`: Only process new or changed records since the last watermark. - `full_refresh`: Process all records from the source on each run.  (default: incremental)
  --enabled: oneof<nothing, bool>
  --metadata: record # nullable
]: any -> record<key: string, name: string, description: string, source: any, trigger: any, transform: record<type: string>, sync_mode: string, watermark: record<value: string, updated_at: string>, status: string, status_message: string, enabled: bool, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)")
  let body = {name: $name, description: $description, source: $body_source, trigger: $trigger, transform: $transform, sync_mode: $sync_mode, enabled: $enabled, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete pipeline
#
# DELETE /v2/pipelines/{pipeline_key}
# operationId: deletePipeline
export def "pipelines delete" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger pipeline
#
# POST /v2/pipelines/{pipeline_key}/trigger
# operationId: triggerPipeline
export def "pipelines-trigger triggerPipeline" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, pipeline_key: string, agent_key: string, status: string, trigger_type: string, records_fetched: int, records_processed: int, records_failed: int, error: string, started_at: string, completed_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/trigger")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List dead letters
#
# GET /v2/pipelines/{pipeline_key}/dead_letters
# operationId: listPipelineDeadLetterEntries
export def "pipelines-dead-letters listPipelineDeadLetterEntries" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # Filter dead letters by status.
  --last-run-id: string # Filter dead letters to those from a specific run. (e.g. run_pip_abc_manual_550e8400)
  --origin: string@origin-completer # Filter dead letters by origin.
  --filter: string # A regex filter on the source record ID. Supports partial matching.
  --limit: int # The maximum number of dead letters to return. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of dead letters after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<dead_letters: table<id: string, source_record_id: string, status: string, error_message: string, last_run_id: record, attempt_count: int, origin: string, created_at: string, updated_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "last_run_id" $last_run_id "scalar") (serialize-qp "origin" $origin "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/dead_letters" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create dead letter
#
# POST /v2/pipelines/{pipeline_key}/dead_letters
# operationId: createPipelineDeadLetterEntry
export def "pipelines-dead-letters createPipelineDeadLetterEntry" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  source_record_id: string # The identifier for the source record to add. Format depends on connector type: - S3: the object key (e.g. `legal/contracts/doc.pdf`) - SharePoint: the drive item ID - Google Drive: the file ID - Web: the canonicalized URL (e.g. `https://docs.example.com/page`)
  --error-message: string # Optional reason for manually adding this record.
]: any -> record<id: string, source_record_id: string, status: string, error_message: string, last_run_id: record, attempt_count: int, origin: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/dead_letters")
  let body = {source_record_id: $source_record_id, error_message: $error_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get dead letter
#
# GET /v2/pipelines/{pipeline_key}/dead_letters/{dead_letter_id}
# operationId: getPipelineDeadLetterEntry
export def "pipelines-dead-letters get" [
  pipeline_key: string
  dead_letter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, source_record_id: string, status: string, error_message: string, last_run_id: record, attempt_count: int, origin: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/dead_letters/($dead_letter_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete dead letter
#
# DELETE /v2/pipelines/{pipeline_key}/dead_letters/{dead_letter_id}
# operationId: deletePipelineDeadLetterEntry
export def "pipelines-dead-letters delete" [
  pipeline_key: string
  dead_letter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/dead_letters/($dead_letter_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Process dead letters
#
# POST /v2/pipelines/{pipeline_key}/dead_letters/process
# operationId: processPipelineDeadLetterEntries
export def "pipelines-dead-letters-process processPipelineDeadLetterEntries" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --source-record-ids: list # Specific source record IDs to process. If omitted, processes all matching dead letters.
  --last-run-id: any # Only process dead letters whose `last_run_id` matches this value.
  --origin: string@origin-completer # How this dead letter was created.
]: any -> record<id: string, pipeline_key: string, agent_key: string, status: string, trigger_type: string, records_fetched: int, records_processed: int, records_failed: int, error: string, started_at: string, completed_at: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/dead_letters/process")
  let body = {source_record_ids: $source_record_ids, last_run_id: $last_run_id, origin: $origin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List pipeline runs
#
# GET /v2/pipelines/{pipeline_key}/runs
# operationId: listPipelineRuns
export def "pipelines-runs listPipelineRuns" [
  pipeline_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # Filter runs by status.
  --after: string # Only return runs created after this timestamp. (format: date-time)
  --limit: int # The maximum number of runs to return. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of runs after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<runs: table<id: string, pipeline_key: string, agent_key: string, status: string, trigger_type: string, records_fetched: int, records_processed: int, records_failed: int, error: string, started_at: string, completed_at: string, created_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/runs" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get pipeline run
#
# GET /v2/pipelines/{pipeline_key}/runs/{run_id}
# operationId: getPipelineRun
export def "pipelines-runs get" [
  pipeline_key: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<id: string, pipeline_key: string, agent_key: string, status: string, trigger_type: string, records_fetched: int, records_processed: int, records_failed: int, error: string, started_at: string, completed_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/runs/($run_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel pipeline run
#
# POST /v2/pipelines/{pipeline_key}/runs/{run_id}/cancel
# operationId: cancelPipelineRun
export def "pipelines-runs-cancel cancelPipelineRun" [
  pipeline_key: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/runs/($run_id)/cancel")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pipeline run events
#
# GET /v2/pipelines/{pipeline_key}/runs/{run_id}/events
# operationId: listPipelineRunEvents
export def "pipelines-runs-events listPipelineRunEvents" [
  pipeline_key: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Filter to one or more event types. Repeat the parameter to pass multiple values.
  --source-record-id: string # Filter to events for a specific source record.
  --order: string@order-completer # Order events by timestamp. Defaults to newest-first.
  --limit: int # The maximum number of events to return. (format: int32, default: 50)
  --page-key: string # Used to retrieve the next page of events after the limit has been reached.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<events: list<record>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "source_record_id" $source_record_id "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/pipelines/($pipeline_key)/runs/($run_id)/events" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available metrics
#
# GET /v2/metrics
# operationId: listMetrics
export def "metrics listMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category: list # Restrict the returned catalog to metrics in these categories. When omitted, all categories are returned.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<metrics: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/metrics" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query a metric time series
#
# GET /v2/metrics/{metric_name}
# Discriminator (response): kind = counter, gauge, percentiles, distribution
# operationId: getMetric
export def "metrics get" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: record # Label filters keyed by label name. The set of valid label names for each metric is published in its descriptor at `/v2/metrics`.
  --start: string # Inclusive start of the query window (ISO 8601). Must be no more than 30 days before now. (format: date-time)
  --end: string # Exclusive end of the query window (ISO 8601). Must be after `start`. (format: date-time)
  --max-bins: int # Upper bound on the number of points in the response. The response may contain fewer points than requested but never more. The actual time-bin size is reported in the response as `bin_size_seconds`. Defaults to 60. (format: int32, default: 60)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "labels" $labels "deepObject") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_bins" $max_bins "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/metrics/($metric_name)" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List agent traces
#
# GET /v2/agent_analytics/traces
# operationId: listTraces
export def "agent-analytics-traces listTraces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agent-key: string # Filter traces by agent key.
  --session-key: string # Filter traces by session key.
  --status: string@status-completer-3 # Filter traces by status.
  --error-type: string@error-type-completer # Filter to traces containing a span with this exact error type.
  --operation: string@operation-completer # Filter to traces containing at least one span with this operation.
  --tool-name: string # Filter to traces containing a tool execution span with this exact tool name.
  --tool-error-type: string@tool-error-type-completer # Filter to traces containing a tool span with this exact error type.
  --started-after: string # Return only traces started after this time (ISO 8601). (format: date-time)
  --started-before: string # Return only traces started before this time (ISO 8601). (format: date-time)
  --min-duration-ms: int # Return only traces with duration at or above this threshold in milliseconds. (format: int64)
  --max-duration-ms: int # Return only traces with duration at or below this threshold in milliseconds. (format: int64)
  --limit: int # The maximum number of traces to return. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of results.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<traces: table<trace_id: string, agent_key: string, session_key: string, started_at: string, duration_ms: int, status: string, input_tokens: int, output_tokens: int>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_key" $agent_key "scalar") (serialize-qp "session_key" $session_key "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "error_type" $error_type "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "tool_name" $tool_name "scalar") (serialize-qp "tool_error_type" $tool_error_type "scalar") (serialize-qp "started_after" $started_after "scalar") (serialize-qp "started_before" $started_before "scalar") (serialize-qp "min_duration_ms" $min_duration_ms "scalar") (serialize-qp "max_duration_ms" $max_duration_ms "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/agent_analytics/traces" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get agent trace
#
# GET /v2/agent_analytics/traces/{trace_id}
# operationId: getTrace
export def "agent-analytics-traces get" [
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<trace_id: string, agent_key: string, session_key: string, started_at: string, duration_ms: int, status: string, input_tokens: int, output_tokens: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/agent_analytics/traces/($trace_id)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List spans in a trace
#
# GET /v2/agent_analytics/traces/{trace_id}/spans
# operationId: listTraceSpans
export def "agent-analytics-traces-spans listTraceSpans" [
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-content: oneof<nothing, bool> # When true, include decrypted span content such as input/output messages and tool arguments. (default: false)
  --operation: string@operation-completer # Restrict to spans with this operation.
  --parent-span-id: string # Filter spans to only direct children of this span ID.
  --exclude-subagents: oneof<nothing, bool> # When true, exclude nested sub-agent invocations and their descendants. Restricts results to the entry-point invoke_agent span and any spans that belong to the entry agent's session. (default: false)
  --limit: int # The maximum number of spans to return. (format: int32, default: 100)
  --page-key: string # Used to retrieve the next page of results.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<spans: list<any>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_content" $include_content "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "parent_span_id" $parent_span_id "scalar") (serialize-qp "exclude_subagents" $exclude_subagents "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agent_analytics/traces/($trace_id)/spans" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get span in a trace
#
# GET /v2/agent_analytics/traces/{trace_id}/spans/{span_id}
# Discriminator (response): operation = invoke_agent, chat, execute_tool, thinking, output, guardrail, step_transition, image_read, compaction
# operationId: getTraceSpan
export def "agent-analytics-traces-spans get" [
  trace_id: string
  span_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-content: oneof<nothing, bool> # When true, include decrypted span content. (default: false)
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_content" $include_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/agent_analytics/traces/($trace_id)/spans/($span_id)" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create glossary
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
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --key: string # A user-provided key that uniquely identifies a glossary. (e.g. eng-acronyms)
  name: string # Human-readable name for the glossary. (e.g. Engineering Acronyms)
  --description: string # A description of what this glossary covers. (e.g. Common engineering and infrastructure acronyms used by the platform team.)
]: any -> record<key: string, name: string, description: string, num_entries: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/glossaries")
  let body = {key: $key, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List glossaries
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
  --filter: string # A case-insensitive substring to filter glossary names and descriptions. (e.g. engineering)
  --limit: int # The maximum number of glossaries to return. (format: int32, default: 10)
  --page-key: string # Used to retrieve the next page of glossaries.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<glossaries: table<key: string, name: string, description: string, num_entries: int, created_at: string, updated_at: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/glossaries" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get glossary
#
# GET /v2/glossaries/{glossary_key}
# operationId: getGlossary
export def "glossaries get" [
  glossary_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<key: string, name: string, description: string, num_entries: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/glossaries/($glossary_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update glossary
#
# PATCH /v2/glossaries/{glossary_key}
# operationId: updateGlossary
export def "glossaries updateGlossary" [
  glossary_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  --name: string # Updated name for the glossary. (e.g. Platform Acronyms)
  --description: string # Updated description.
]: any -> record<key: string, name: string, description: string, num_entries: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/glossaries/($glossary_key)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete glossary
#
# DELETE /v2/glossaries/{glossary_key}
# operationId: deleteGlossary
export def "glossaries delete" [
  glossary_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/glossaries/($glossary_key)")
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert glossary entries
#
# POST /v2/glossaries/{glossary_key}/entries
# operationId: upsertGlossaryEntries
export def "glossaries-entries upsertGlossaryEntries" [
  glossary_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  entries: record # A map of terms to their expanded forms. Keys are terms (1–200 characters); values are expansions (1–1000 characters).  (e.g. {k8s: Kubernetes, tf: Terraform})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/glossaries/($glossary_key)/entries")
  let body = {entries: $entries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List glossary entries
#
# GET /v2/glossaries/{glossary_key}/entries
# operationId: listGlossaryEntries
export def "glossaries-entries listGlossaryEntries" [
  glossary_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The maximum number of entries to return. (format: int32, default: 100)
  --page-key: string # Used to retrieve the next page of entries.
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
]: nothing -> record<entries: table<term: string, expansion: string>, metadata: record<page_key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_key" $page_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/glossaries/($glossary_key)/entries" $qp)
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete glossary entries
#
# DELETE /v2/glossaries/{glossary_key}/entries
# operationId: deleteGlossaryEntries
export def "glossaries-entries delete" [
  glossary_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Request-Timeout: int # The API will make a best effort to complete the request in the specified seconds or time out.
  --Request-Timeout-Millis: int # The API will make a best effort to complete the request in the specified milliseconds or time out.
  terms: list # The terms to remove from the glossary.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/glossaries/($glossary_key)/entries")
  let body = {terms: $terms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Request-Timeout": $Request_Timeout, "Request-Timeout-Millis": $Request_Timeout_Millis} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
