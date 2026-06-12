# Auto-generated client for Pinecone Inference API v2026-04
# Source: https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/inference_2026-04.oas.yaml
# Auth: --token flag or $env.PINECONE_INFERENCE_API_TOKEN

const BASE_URL = "https://api.pinecone.io"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PINECONE_INFERENCE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.pinecone.io"] }
def auth-scheme-completer [] { ["api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "embed embed" } } | get name | first)
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

# Generate vectors
#
# POST /embed
# operationId: embed
# --inputs item shape: {text?: string}
export def "embed embed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  model: string # The [model](https://docs.pinecone.io/guides/index-data/create-an-index#embedding-models) to use for embedding generation. (e.g. multilingual-e5-large)
  --parameters: record # Additional model-specific parameters. Refer to the [model guide](https://docs.pinecone.io/guides/index-data/create-an-index#embedding-models) for available model parameters. (e.g. {input_type: passage, truncate: END})
  inputs: list # List of inputs to generate embeddings for. — item shape: {text?: string}
]: any -> record<model: string, vector_type: string, data: list<record>, usage: record<total_tokens: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/embed")
  let body = {model: $model, parameters: $parameters, inputs: $inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rerank results
#
# POST /rerank
# operationId: rerank
export def "rerank rerank" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
  model: string # The [model](https://docs.pinecone.io/guides/search/rerank-results#reranking-models) to use for reranking. (e.g. bge-reranker-v2-m3)
  --body-query: string # The query to rerank documents against. (e.g. What is the capital of France?)
  --top-n: int # The number of results to return sorted by relevance. Defaults to the number of inputs. (e.g. 5)
  --return-documents: oneof<nothing, bool> # Whether to return the documents in the response. (default: true, e.g. true)
  --rank-fields: list # The field(s) to consider for reranking. If not provided, the default is `["text"]`.  The number of fields supported is [model-specific](https://docs.pinecone.io/guides/search/rerank-results#reranking-models).  (default: [text])
  documents: list # The documents to rerank.
  --parameters: record # Additional model-specific parameters. Refer to the [model guide](https://docs.pinecone.io/guides/search/rerank-results#reranking-models) for available model parameters. (e.g. {truncate: END})
]: any -> record<model: string, data: table<index: int, score: float, document: record>, usage: record<rerank_units: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rerank")
  let body = {model: $model, query: $body_query, top_n: $top_n, return_documents: $return_documents, rank_fields: $rank_fields, documents: $documents, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List available models
#
# GET /models
# operationId: list_models
export def "models models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Filter models by type ('embed' or 'rerank'). (e.g. embed)
  --vector-type: string # Filter embedding models by vector type ('dense' or 'sparse'). Only relevant when `type=embed`. (e.g. sparse)
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<models: table<model: string, short_description: string, type: string, vector_type: string, default_dimension: int, modality: string, max_sequence_length: int, max_batch_size: int, provider_name: string, supported_dimensions: list, supported_metrics: list, supported_parameters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "vector_type" $vector_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/models" $qp)
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Describe a model
#
# GET /models/{model_name}
# operationId: get_model
export def "models model" [
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pinecone-Api-Version: string # Required date-based version header
]: nothing -> record<model: string, short_description: string, type: string, vector_type: string, default_dimension: int, modality: string, max_sequence_length: int, max_batch_size: int, provider_name: string, supported_dimensions: list<int>, supported_metrics: list<string>, supported_parameters: table<parameter: string, type: string, value_type: string, required: bool, allowed_values: list, min: float, max: float, default: any>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_name)")
  let extra_headers = {"X-Pinecone-Api-Version": $X_Pinecone_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
