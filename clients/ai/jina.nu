# Auto-generated client for Jina Search Foundation API v2026.06.03.1845
# Source: https://api.jina.ai/openapi.json
# Auth: --token flag or $env.JINA_SEARCH_FOUNDATION_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o JINA_SEARCH_FOUNDATION_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def model-completer [] { ["elser-v2" "jina-clip-v1" "jina-clip-v2" "jina-code-embeddings-0.5b" "jina-code-embeddings-1.5b" "jina-colbert-v1-en" "jina-colbert-v2" "jina-embeddings-v2-base-code" "jina-embeddings-v2-base-de" "jina-embeddings-v2-base-en" "jina-embeddings-v2-base-es" "jina-embeddings-v2-base-zh" "jina-embeddings-v3" "jina-embeddings-v4" "jina-embeddings-v5-omni-nano" "jina-embeddings-v5-omni-small" "jina-embeddings-v5-text-nano" "jina-embeddings-v5-text-small"] }
def model-completer-1 [] { ["jina-colbert-v1-en" "jina-colbert-v2" "jina-reranker-m0" "jina-reranker-v1-base-en" "jina-reranker-v1-tiny-en" "jina-reranker-v1-turbo-en" "jina-reranker-v2-base-multilingual" "jina-reranker-v3"] }
def model-completer-2 [] { ["jina-embeddings-v5-text-nano" "jina-embeddings-v5-text-small"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "health get" } } | get name | first)
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

# Health
#
# GET /health
# operationId: health_health_get
export def "health get" [
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
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ready
#
# GET /ready
# operationId: ready_ready_get
export def "ready get" [
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
  let full_url = (build-url $base "/ready")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Live
#
# GET /live
# operationId: live_live_get
export def "live get" [
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
  let full_url = (build-url $base "/live")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Embeddings
#
# POST /v1/embeddings
# Discriminator (request): model = jina-embeddings-v2-base-en, jina-embeddings-v2-base-zh, jina-embeddings-v2-base-de, jina-embeddings-v2-base-es, jina-embeddings-v2-base-code, jina-embeddings-v3, jina-embeddings-v5-text-nano, jina-embeddings-v5-text-small, jina-embeddings-v5-omni-small, jina-embeddings-v5-omni-nano, jina-embeddings-v4, jina-code-embeddings-0.5b, jina-code-embeddings-1.5b, jina-clip-v1, jina-clip-v2, jina-colbert-v1-en, jina-colbert-v2, elser-v2
# operationId: embeddings_v1_embeddings_post
export def "embeddings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --embedding-type: any # Output encoding format: `float`, `base64`, `binary`, `ubinary`, or a list of these.
  --normalized: any # If true (default), embeddings are L2-normalized to unit length. (default: true)
  --truncate: any # If true, truncates input exceeding the model's max token limit instead of returning an error. (default: false)
  model: string@model-completer # The embedding model to use.
  --input: any # Text to embed: a string, `TextDoc`, or a list of items.
  --task: any # Task optimization: `retrieval.query` for queries, `retrieval.passage` for documents, `text-matching` for similarity, `classification`, or `separation` for clustering.
  --late-chunking: any # If true, concatenates all inputs and processes as one sequence before splitting. Useful for context across chunks.
  --dimensions: any # Number of dimensions for the output embedding. Range: 1-1024.
  --return-multivector: any # If true, returns one embedding per token. Cannot be used with `dimensions`. (default: false)
  --return-tokenized-input: any # If true, returns tokens alongside multi-vector embeddings. Requires `return_multivector=true`. (default: false)
  --input-type: any # Role of the input: `query` for search queries, `document` for passages. (default: document)
]: any -> record<model: string, object: string, usage: any, data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embeddings")
  let body = {embedding_type: $embedding_type, normalized: $normalized, truncate: $truncate, model: $model, input: $input, task: $task, late_chunking: $late_chunking, dimensions: $dimensions, return_multivector: $return_multivector, return_tokenized_input: $return_tokenized_input, input_type: $input_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rerank
#
# POST /v1/rerank
# Discriminator (request): model = jina-reranker-v2-base-multilingual, jina-reranker-v1-tiny-en, jina-reranker-v1-turbo-en, jina-reranker-v1-base-en, jina-colbert-v1-en, jina-colbert-v2, jina-reranker-m0, jina-reranker-v3
# operationId: rerank_v1_rerank_post
export def "rerank post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # The search query to rank documents against.
  --top-n: any # Number of top results to return. If not set, returns all documents.
  --return-documents: any # If true (default), includes document content in each result. (default: true)
  --truncation: any # If true, truncates documents exceeding the model's max token limit.
  model: string@model-completer-1 # The reranking model to use.
  --documents: list # Documents to rank: strings or `TextDoc` objects.
  --max-doc-length: int # Maximum tokens per document. Range: 1-8192. Default: 2048. (default: 2048)
  --return-embeddings: any # If true, returns the document embedding alongside the relevance score.
]: any -> record<model: string, object: string, usage: record<total_tokens: int>, results: table<index: int, relevance_score: float, document: any, embedding: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rerank")
  let body = {query: $body_query, top_n: $top_n, return_documents: $return_documents, truncation: $truncation, model: $model, documents: $documents, max_doc_length: $max_doc_length, return_embeddings: $return_embeddings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Classify
#
# POST /v1/classify
# operationId: classify_v1_classify_post
export def "classify post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --classifier-id: string # ID of the trained classifier to use.
  --input: any # Text to classify: a string, `TextDoc`, or list of up to 512 items.
]: any -> record<data: table<object: string, index: int, prediction: any, score: any, predictions: any>, usage: record<total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/classify")
  let body = {classifier_id: $classifier_id, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Train
#
# POST /v1/train
# operationId: train_v1_train_post
export def "train post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --classifier-id: string # ID of the classifier to use for few-shot classification.
  --input: any # Input(s) for updating training. Accepts a `TextTrainingItem`, `ImageTrainingItem`, or a list of them. For batch update, provide a list with up to 512 items.
  --num-iters: int # Number of iterations for the training process. (default: 10)
]: any -> record<classifier_id: string, num_samples: int, usage: record<total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/train")
  let body = {classifier_id: $classifier_id, input: $input, num_iters: $num_iters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Classifiers
#
# GET /v1/classifiers
# operationId: list_classifiers_v1_classifiers_post
export def "classifiers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<classifier_id: string, user_id: string, model: string, labels: list<string>, access: string, updated_number: int, used_number: int, created_at: string, updated_at: string, used_at: any, is_active: bool, is_latest: bool, metadata_: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/classifiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Classifiers
#
# POST /v1/classifiers
# operationId: list_classifiers_v1_classifiers_post
export def "classifiers post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<classifier_id: string, user_id: string, model: string, labels: list<string>, access: string, updated_number: int, used_number: int, created_at: string, updated_at: string, used_at: any, is_active: bool, is_latest: bool, metadata_: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/classifiers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Classifier
#
# DELETE /v1/classifiers/{classifier_id}
# operationId: delete_classifier_v1_classifiers__classifier_id__delete
export def "classifiers delete" [
  classifier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/classifiers/($classifier_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Models
#
# GET /v1/models
# operationId: list_models_v1_models_get
export def "models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, hugging_face_id: string, name: string, created: int, input_modalities: list, output_modalities: list, quantization: string, context_length: int, max_output_length: int, pricing: record, supported_sampling_parameters: list, supported_features: list, description: string, datacenters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Model
#
# GET /v1/models/{model_id}
# operationId: get_model_v1_models__model_id__get
export def "models get" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, hugging_face_id: string, name: string, created: int, input_modalities: list<string>, output_modalities: list<string>, quantization: string, context_length: int, max_output_length: int, pricing: record<prompt: string, completion: string, image: string, request: string, input_cache_read: string, input_cache_write: string>, supported_sampling_parameters: list<string>, supported_features: list<string>, description: string, datacenters: table<country_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Chat Completions (Experimental)
#
# POST /v1/chat/completions
# operationId: chat_completions_v1_chat_completions_post
export def "chat-completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chat/completions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a batch embedding job
#
# POST /v1/batch/embeddings
# operationId: create_batch_job_v1_batch_embeddings_post
export def "batch-embeddings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  model: string@model-completer-2 # The embedding model to use for batch processing.
  --input-url: any # URL to input JSONL file (GCS, S3, or HTTP). Either input_url or input must be provided.
  --input: any # Inline JSONL lines for small batches. Either input_url or input must be provided.
  --task: any # Task optimization: retrieval, text-matching, clustering, or classification. (default: text-matching)
  --dimensions: any # Number of dimensions for output embeddings (1-1024).
  --normalized: any # If true (default), embeddings are L2-normalized to unit length. (default: true)
  --webhook-url: any # URL to POST notification when job completes.
]: any -> record<batch_id: string, status: string, model: string, created_at: string, completed_at: any, expires_at: any, output_url: any, error_file_url: any, error: any, stats: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batch/embeddings")
  let body = {model: $model, input_url: $input_url, input: $input, task: $task, dimensions: $dimensions, normalized: $normalized, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get batch job status
#
# GET /v1/batch/{batch_id}
# operationId: get_batch_status_v1_batch__batch_id__get
export def "batch get" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<batch_id: string, status: string, model: string, created_at: string, completed_at: any, expires_at: any, output_url: any, error_file_url: any, error: any, stats: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batch/($batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a batch job
#
# DELETE /v1/batch/{batch_id}
# operationId: cancel_batch_job_v1_batch__batch_id__delete
export def "batch delete" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<batch_id: string, status: string, model: string, created_at: string, completed_at: any, expires_at: any, output_url: any, error_file_url: any, error: any, stats: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batch/($batch_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List batch jobs
#
# GET /v1/batches
# operationId: list_batch_jobs_v1_batches_get
export def "batches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 20
]: nothing -> table<batch_id: string, status: string, model: string, created_at: string, completed_at: any, expires_at: any, output_url: any, error_file_url: any, error: any, stats: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download batch job output
#
# GET /v1/batch/{batch_id}/output
# operationId: download_batch_output_v1_batch__batch_id__output_get
export def "batch-output get" [
  batch_id: string
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
  let full_url = (build-url $base $"/v1/batch/($batch_id)/output")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download batch job error file
#
# GET /v1/batch/{batch_id}/errors
# operationId: download_batch_errors_v1_batch__batch_id__errors_get
export def "batch-errors get" [
  batch_id: string
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
  let full_url = (build-url $base $"/v1/batch/($batch_id)/errors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
