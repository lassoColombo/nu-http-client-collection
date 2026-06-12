# Auto-generated client for Mistral AI API v1.0.0
# Source: https://docs.mistral.ai/openapi.yaml
# Auth: --token flag or $env.MISTRAL_AI_API_TOKEN

const BASE_URL = "https://api.mistral.ai"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MISTRAL_AI_API_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["https://api.mistral.ai"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def stream-completer [] { ["false"] }
def handoff-execution-completer [] { ["client" "server"] }
def stream-completer-1 [] { ["true"] }
def purpose-completer [] { ["batch" "fine-tune" "ocr"] }
def order-by-completer [] { ["-created" "created"] }
def endpoint-completer [] { ["/v1/audio/transcriptions" "/v1/chat/classifications" "/v1/chat/completions" "/v1/chat/moderations" "/v1/classifications" "/v1/conversations" "/v1/embeddings" "/v1/fim/completions" "/v1/moderations" "/v1/ocr"] }
def reasoning-effort-completer [] { ["high" "none"] }
def accept-completer [] { ["application/json" "text/event-stream"] }
def output-dtype-completer [] { ["binary" "float" "int8" "ubinary" "uint8"] }
def encoding-format-completer [] { ["base64" "float"] }
def response-format-completer [] { ["flac" "mp3" "opus" "pcm" "wav"] }
def accept-completer-1 [] { ["application/json" "audio/wav"] }
def level-completer [] { ["Editor" "Viewer"] }
def share-with-type-completer [] { ["Org" "User" "Workspace"] }
def operator-completer [] { ["contains" "endswith" "eq" "excludes" "gt" "gte" "icontains" "iendswith" "includes" "inotcontains" "isnull" "istartswith" "len_eq" "lt" "lte" "matches" "neq" "notcontains" "startswith"] }
def scope-completer [] { ["*" "activity" "workflow"] }
def visibility-completer [] { ["private" "shared_global" "shared_org" "shared_workspace"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "models list" } } | get name | first)
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider: string
  --model: string
]: nothing -> record<object: string, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider" $provider "scalar") (serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Model
#
# GET /v1/models/{model_id}
# Discriminator (response): type = base, fine-tuned
# operationId: retrieve_model_v1_models__model_id__get
export def "models get" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Model
#
# DELETE /v1/models/{model_id}
# operationId: delete_model_v1_models__model_id__delete
export def "models delete" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a conversation and append entries to it.
#
# POST /v1/conversations
# operationId: agents_api_v1_conversations_start
export def "conversations start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  inputs: any
  --stream: oneof<nothing, bool> # default: false
  --store: any
  --handoff-execution: any
  --instructions: any
  --tools: any
  --completion-args: any
  --guardrails: any
  --name: any
  --description: any
  --metadata: any
  --agent-id: any
  --agent-version: any
  --model: any
]: any -> record<object: string, conversation_id: string, outputs: list<any>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int, connector_tokens: any, connectors: any>, guardrails: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/conversations")
  let body = {inputs: $inputs, stream: $stream, store: $store, handoff_execution: $handoff_execution, instructions: $instructions, tools: $tools, completion_args: $completion_args, guardrails: $guardrails, name: $name, description: $description, metadata: $metadata, agent_id: $agent_id, agent_version: $agent_version, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all created conversations.
#
# GET /v1/conversations
# operationId: agents_api_v1_conversations_list
export def "conversations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 0
  --page-size: int # default: 100
  --metadata: string
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "metadata" $metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a conversation information.
#
# GET /v1/conversations/{conversation_id}
# operationId: agents_api_v1_conversations_get
export def "conversations get" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a conversation.
#
# DELETE /v1/conversations/{conversation_id}
# operationId: agents_api_v1_conversations_delete
export def "conversations delete" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Append new entries to an existing conversation.
#
# POST /v1/conversations/{conversation_id}
# operationId: agents_api_v1_conversations_append
# --completion_args shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
export def "conversations append" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inputs: any
  --stream: oneof<nothing, bool> # default: false
  --store: oneof<nothing, bool> # Whether to store the results into our servers or not. (default: true)
  --handoff-execution: string@handoff-execution-completer # default: server
  --completion-args: record # White-listed arguments from the completion API — shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
  --tool-confirmations: any
]: any -> record<object: string, conversation_id: string, outputs: list<any>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int, connector_tokens: any, connectors: any>, guardrails: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)")
  let body = {inputs: $inputs, stream: $stream, store: $store, handoff_execution: $handoff_execution, completion_args: $completion_args, tool_confirmations: $tool_confirmations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all entries in a conversation.
#
# GET /v1/conversations/{conversation_id}/history
# operationId: agents_api_v1_conversations_history
export def "conversations-history history" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<object: string, conversation_id: string, entries: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all messages in a conversation.
#
# GET /v1/conversations/{conversation_id}/messages
# operationId: agents_api_v1_conversations_messages
export def "conversations-messages messages" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<object: string, conversation_id: string, messages: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/messages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart a conversation starting from a given entry.
#
# POST /v1/conversations/{conversation_id}/restart
# operationId: agents_api_v1_conversations_restart
# --completion_args shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
export def "conversations-restart restart" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inputs: any
  --stream: oneof<nothing, bool> # default: false
  --store: oneof<nothing, bool> # Whether to store the results into our servers or not. (default: true)
  --handoff-execution: string@handoff-execution-completer # default: server
  --completion-args: record # White-listed arguments from the completion API — shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
  --guardrails: any
  --metadata: any # Custom metadata for the conversation.
  from_entry_id: string
  --agent-version: any # Specific version of the agent to use when restarting. If not provided, uses the current version.
]: any -> record<object: string, conversation_id: string, outputs: list<any>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int, connector_tokens: any, connectors: any>, guardrails: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/restart")
  let body = {inputs: $inputs, stream: $stream, store: $store, handoff_execution: $handoff_execution, completion_args: $completion_args, guardrails: $guardrails, metadata: $metadata, from_entry_id: $from_entry_id, agent_version: $agent_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a agent that can be used within a conversation.
#
# POST /v1/agents
# operationId: agents_api_v1_agents_create
# --completion_args shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
export def "agents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --instructions: any # Instruction prompt the model will follow during the conversation.
  --tools: list # List of tools which are available to the model during the conversation.
  --completion-args: record # White-listed arguments from the completion API — shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
  --guardrails: any
  model: string
  name: string
  --description: any
  --handoffs: any
  --metadata: any
  --version-message: any
]: any -> record<instructions: any, tools: list<any>, completion_args: record<stop: any, presence_penalty: any, frequency_penalty: any, temperature: any, top_p: any, max_tokens: any, random_seed: any, prediction: any, response_format: any, tool_choice: string, reasoning_effort: any>, guardrails: any, model: string, name: string, description: any, handoffs: any, metadata: any, object: string, id: string, version: int, versions: list<int>, created_at: string, updated_at: string, deployment_chat: bool, source: string, version_message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/agents")
  let body = {instructions: $instructions, tools: $tools, completion_args: $completion_args, guardrails: $guardrails, model: $model, name: $name, description: $description, handoffs: $handoffs, metadata: $metadata, version_message: $version_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List agent entities.
#
# GET /v1/agents
# operationId: agents_api_v1_agents_list
export def "agents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (0-indexed) (default: 0)
  --page-size: int # Number of agents per page (default: 20)
  --deployment-chat: string
  --sources: string
  --name: string # Filter by agent name
  --search: string # Search agents by name or ID
  --id: string
  --metadata: string
]: nothing -> table<instructions: any, tools: list<any>, completion_args: record<stop: any, presence_penalty: any, frequency_penalty: any, temperature: any, top_p: any, max_tokens: any, random_seed: any, prediction: any, response_format: any, tool_choice: string, reasoning_effort: any>, guardrails: any, model: string, name: string, description: any, handoffs: any, metadata: any, object: string, id: string, version: int, versions: list<int>, created_at: string, updated_at: string, deployment_chat: bool, source: string, version_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "deployment_chat" $deployment_chat "scalar") (serialize-qp "sources" $sources "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "metadata" $metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/agents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an agent entity.
#
# GET /v1/agents/{agent_id}
# operationId: agents_api_v1_agents_get
export def "agents get" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-version: string
]: nothing -> record<instructions: any, tools: list<any>, completion_args: record<stop: any, presence_penalty: any, frequency_penalty: any, temperature: any, top_p: any, max_tokens: any, random_seed: any, prediction: any, response_format: any, tool_choice: string, reasoning_effort: any>, guardrails: any, model: string, name: string, description: any, handoffs: any, metadata: any, object: string, id: string, version: int, versions: list<int>, created_at: string, updated_at: string, deployment_chat: bool, source: string, version_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "agent_version" $agent_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/agents/($agent_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an agent entity.
#
# PATCH /v1/agents/{agent_id}
# operationId: agents_api_v1_agents_update
# --completion_args shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
export def "agents update" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --instructions: any # Instruction prompt the model will follow during the conversation.
  --tools: list # List of tools which are available to the model during the conversation.
  --completion-args: record # White-listed arguments from the completion API — shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
  --guardrails: any
  --model: any
  --name: any
  --description: any
  --handoffs: any
  --deployment-chat: any
  --metadata: any
  --version-message: any
]: any -> record<instructions: any, tools: list<any>, completion_args: record<stop: any, presence_penalty: any, frequency_penalty: any, temperature: any, top_p: any, max_tokens: any, random_seed: any, prediction: any, response_format: any, tool_choice: string, reasoning_effort: any>, guardrails: any, model: string, name: string, description: any, handoffs: any, metadata: any, object: string, id: string, version: int, versions: list<int>, created_at: string, updated_at: string, deployment_chat: bool, source: string, version_message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($agent_id)")
  let body = {instructions: $instructions, tools: $tools, completion_args: $completion_args, guardrails: $guardrails, model: $model, name: $name, description: $description, handoffs: $handoffs, deployment_chat: $deployment_chat, metadata: $metadata, version_message: $version_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an agent entity.
#
# DELETE /v1/agents/{agent_id}
# operationId: agents_api_v1_agents_delete
export def "agents delete" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($agent_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an agent version.
#
# PATCH /v1/agents/{agent_id}/version
# operationId: agents_api_v1_agents_update_version
export def "agents-version version" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int
]: nothing -> record<instructions: any, tools: list<any>, completion_args: record<stop: any, presence_penalty: any, frequency_penalty: any, temperature: any, top_p: any, max_tokens: any, random_seed: any, prediction: any, response_format: any, tool_choice: string, reasoning_effort: any>, guardrails: any, model: string, name: string, description: any, handoffs: any, metadata: any, object: string, id: string, version: int, versions: list<int>, created_at: string, updated_at: string, deployment_chat: bool, source: string, version_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/agents/($agent_id)/version" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all versions of an agent.
#
# GET /v1/agents/{agent_id}/versions
# operationId: agents_api_v1_agents_list_versions
export def "agents-versions versions" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (0-indexed) (default: 0)
  --page-size: int # Number of versions per page (default: 20)
]: nothing -> table<instructions: any, tools: list<any>, completion_args: record<stop: any, presence_penalty: any, frequency_penalty: any, temperature: any, top_p: any, max_tokens: any, random_seed: any, prediction: any, response_format: any, tool_choice: string, reasoning_effort: any>, guardrails: any, model: string, name: string, description: any, handoffs: any, metadata: any, object: string, id: string, version: int, versions: list<int>, created_at: string, updated_at: string, deployment_chat: bool, source: string, version_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/agents/($agent_id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a specific version of an agent.
#
# GET /v1/agents/{agent_id}/versions/{version}
# operationId: agents_api_v1_agents_get_version
export def "agents-versions version" [
  agent_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<instructions: any, tools: list<any>, completion_args: record<stop: any, presence_penalty: any, frequency_penalty: any, temperature: any, top_p: any, max_tokens: any, random_seed: any, prediction: any, response_format: any, tool_choice: string, reasoning_effort: any>, guardrails: any, model: string, name: string, description: any, handoffs: any, metadata: any, object: string, id: string, version: int, versions: list<int>, created_at: string, updated_at: string, deployment_chat: bool, source: string, version_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($agent_id)/versions/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an agent version alias.
#
# PUT /v1/agents/{agent_id}/aliases
# operationId: agents_api_v1_agents_create_or_update_alias
export def "agents-aliases alias-by-agent_id" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --version: int
]: nothing -> record<alias: string, version: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/agents/($agent_id)/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all aliases for an agent.
#
# GET /v1/agents/{agent_id}/aliases
# operationId: agents_api_v1_agents_list_version_aliases
export def "agents-aliases aliases" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alias: string, version: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/agents/($agent_id)/aliases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an agent version alias.
#
# DELETE /v1/agents/{agent_id}/aliases
# operationId: agents_api_v1_agents_delete_alias
export def "agents-aliases alias-by-agent_id-1" [
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/agents/($agent_id)/aliases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a conversation and append entries to it.
#
# POST /v1/conversations#stream
# operationId: agents_api_v1_conversations_start_stream
export def "conversationsstream stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  inputs: any
  --stream: oneof<nothing, bool> # default: true
  --store: any
  --handoff-execution: any
  --instructions: any
  --tools: any
  --completion-args: any
  --guardrails: any
  --name: any
  --description: any
  --metadata: any
  --agent-id: any
  --agent-version: any
  --model: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/conversations#stream")
  let body = {inputs: $inputs, stream: $stream, store: $store, handoff_execution: $handoff_execution, instructions: $instructions, tools: $tools, completion_args: $completion_args, guardrails: $guardrails, name: $name, description: $description, metadata: $metadata, agent_id: $agent_id, agent_version: $agent_version, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Append new entries to an existing conversation.
#
# POST /v1/conversations/{conversation_id}#stream
# operationId: agents_api_v1_conversations_append_stream
# --completion_args shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
export def "conversations stream" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inputs: any
  --stream: oneof<nothing, bool> # default: true
  --store: oneof<nothing, bool> # Whether to store the results into our servers or not. (default: true)
  --handoff-execution: string@handoff-execution-completer # default: server
  --completion-args: record # White-listed arguments from the completion API — shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
  --tool-confirmations: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)#stream")
  let body = {inputs: $inputs, stream: $stream, store: $store, handoff_execution: $handoff_execution, completion_args: $completion_args, tool_confirmations: $tool_confirmations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restart a conversation starting from a given entry.
#
# POST /v1/conversations/{conversation_id}/restart#stream
# operationId: agents_api_v1_conversations_restart_stream
# --completion_args shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
export def "conversations-restartstream stream" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inputs: any
  --stream: oneof<nothing, bool> # default: true
  --store: oneof<nothing, bool> # Whether to store the results into our servers or not. (default: true)
  --handoff-execution: string@handoff-execution-completer # default: server
  --completion-args: record # White-listed arguments from the completion API — shape: {stop?: any, presence_penalty?: any, frequency_penalty?: any, temperature?: any, top_p?: any, max_tokens?: any, random_seed?: any, prediction?: any, response_format?: any, tool_choice?: "auto"|"none"|"any"|"required", reasoning_effort?: any}
  --guardrails: any
  --metadata: any # Custom metadata for the conversation.
  from_entry_id: string
  --agent-version: any # Specific version of the agent to use when restarting. If not provided, uses the current version.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/conversations/($conversation_id)/restart#stream")
  let body = {inputs: $inputs, stream: $stream, store: $store, handoff_execution: $handoff_execution, completion_args: $completion_args, guardrails: $guardrails, metadata: $metadata, from_entry_id: $from_entry_id, agent_version: $agent_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload File
#
# POST /v1/files
# operationId: files_api_routes_upload_file
export def "files file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: any
  --visibility: any # default: workspace
  --purpose: string@purpose-completer
  file: string # The File object (not file name) to be uploaded.  To upload a file and specify a custom file name you should format your request as such:  ```bash  file=@path/to/your/file.jsonl;filename=custom_name.jsonl  ```  Otherwise, you can just keep the original file name:  ```bash  file=@path/to/your/file.jsonl  ``` (format: binary)
]: any -> record<id: string, object: string, bytes: int, created_at: int, filename: string, purpose: string, sample_type: string, num_lines: any, mimetype: any, source: string, signature: any, expires_at: any, visibility: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/files")
  let body = {expiry: $expiry, visibility: $visibility, purpose: $purpose, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List Files
#
# GET /v1/files
# operationId: files_api_routes_list_files
export def "files files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 0
  --page-size: int # default: 100
  --include-total: oneof<nothing, bool> # default: true
  --sample-type: string
  --qp-source: string
  --search: string
  --purpose: string
  --mimetypes: string
]: nothing -> record<data: table<id: string, object: string, bytes: int, created_at: int, filename: string, purpose: string, sample_type: string, num_lines: any, mimetype: any, source: string, signature: any, expires_at: any, visibility: any>, object: string, total: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "include_total" $include_total "scalar") (serialize-qp "sample_type" $sample_type "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "purpose" $purpose "scalar") (serialize-qp "mimetypes" $mimetypes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve File
#
# GET /v1/files/{file_id}
# operationId: files_api_routes_retrieve_file
export def "files file-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, object: string, bytes: int, created_at: int, filename: string, purpose: string, sample_type: string, num_lines: any, mimetype: any, source: string, signature: any, expires_at: any, visibility: any, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete File
#
# DELETE /v1/files/{file_id}
# operationId: files_api_routes_delete_file
export def "files file-by-file_id-1" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, object: string, deleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download File
#
# GET /v1/files/{file_id}/content
# operationId: files_api_routes_download_file
export def "files-content file" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/files/($file_id)/content")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Signed Url
#
# GET /v1/files/{file_id}/url
# operationId: files_api_routes_get_signed_url
export def "files-url url" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: int # Number of hours before the url becomes invalid. Defaults to 24h (default: 24)
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry" $expiry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/files/($file_id)/url" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Fine Tuning Jobs
#
# GET /v1/fine_tuning/jobs
# operationId: jobs_api_routes_fine_tuning_get_fine_tuning_jobs
export def "fine-tuning-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number of the results to be returned. (default: 0)
  --page-size: int # The number of items to return per page. (default: 100)
  --model: string # The model name used for fine-tuning to filter on. When set, the other results are not displayed.
  --created-after: string # The date/time to filter on. When set, the results for previous creation times are not displayed.
  --created-before: string
  --created-by-me: oneof<nothing, bool> # When set, only return results for jobs created by the API caller. Other results are not displayed. (default: false)
  --status: string # The current job state to filter on. When set, the other results are not displayed.
  --wandb-project: string # The Weights and Biases project to filter on. When set, the other results are not displayed.
  --wandb-name: string # The Weight and Biases run name to filter on. When set, the other results are not displayed.
  --suffix: string # The model suffix to filter on. When set, the other results are not displayed.
]: nothing -> record<data: list<any>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "created_by_me" $created_by_me "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "wandb_project" $wandb_project "scalar") (serialize-qp "wandb_name" $wandb_name "scalar") (serialize-qp "suffix" $suffix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/fine_tuning/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Fine Tuning Job
#
# POST /v1/fine_tuning/jobs
# operationId: jobs_api_routes_fine_tuning_create_fine_tuning_job
# --training_files item shape: {file_id: string, weight?: float}
export def "fine-tuning-jobs job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-dry-run: string # * If `true` the job is not spawned, instead the query returns a handful of useful metadata   for the user to perform sanity checks (see `LegacyJobMetadataOut` response). * Otherwise, the job is started and the query returns the job ID along with some of the   input parameters (see `JobOut` response).
  model: string
  --training-files: list # default: [] — item shape: {file_id: string, weight?: float}
  --validation-files: any # A list containing the IDs of uploaded files that contain validation data. If you provide these files, the data is used to generate validation metrics periodically during fine-tuning. These metrics can be viewed in `checkpoints` when getting the status of a running fine-tuning job. The same data should not be present in both train and validation files.
  --suffix: any # A string that will be added to your fine-tuning model name. For example, a suffix of "my-great-model" would produce a model name like `ft:open-mistral-7b:my-great-model:xxx...`
  --integrations: any # A list of integrations to enable for your fine-tuning job.
  --auto-start: oneof<nothing, bool> # This field will be required in a future release.
  --invalid-sample-skip-percentage: float # default: 0
  --job-type: any
  hyperparameters: any
  --repositories: any
  --classifier-targets: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dry_run" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/fine_tuning/jobs" $qp)
  let body = {model: $model, training_files: $training_files, validation_files: $validation_files, suffix: $suffix, integrations: $integrations, auto_start: $auto_start, invalid_sample_skip_percentage: $invalid_sample_skip_percentage, job_type: $job_type, hyperparameters: $hyperparameters, repositories: $repositories, classifier_targets: $classifier_targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Fine Tuning Job
#
# GET /v1/fine_tuning/jobs/{job_id}
# Discriminator (response): job_type = classifier, completion
# operationId: jobs_api_routes_fine_tuning_get_fine_tuning_job
export def "fine-tuning-jobs job-by-job_id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tuning/jobs/($job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Fine Tuning Job
#
# POST /v1/fine_tuning/jobs/{job_id}/cancel
# Discriminator (response): job_type = classifier, completion
# operationId: jobs_api_routes_fine_tuning_cancel_fine_tuning_job
export def "fine-tuning-jobs-cancel job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tuning/jobs/($job_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start Fine Tuning Job
#
# POST /v1/fine_tuning/jobs/{job_id}/start
# Discriminator (response): job_type = classifier, completion
# operationId: jobs_api_routes_fine_tuning_start_fine_tuning_job
export def "fine-tuning-jobs-start job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tuning/jobs/($job_id)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Fine Tuned Model
#
# PATCH /v1/fine_tuning/models/{model_id}
# Discriminator (response): model_type = classifier, completion
# operationId: jobs_api_routes_fine_tuning_update_fine_tuned_model
export def "fine-tuning-models model" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --description: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tuning/models/($model_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive Fine Tuned Model
#
# POST /v1/fine_tuning/models/{model_id}/archive
# operationId: jobs_api_routes_fine_tuning_archive_fine_tuned_model
export def "fine-tuning-models-archive model-by-model_id" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, object: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tuning/models/($model_id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive Fine Tuned Model
#
# DELETE /v1/fine_tuning/models/{model_id}/archive
# operationId: jobs_api_routes_fine_tuning_unarchive_fine_tuned_model
export def "fine-tuning-models-archive model-by-model_id-1" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, object: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fine_tuning/models/($model_id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Batch Jobs
#
# GET /v1/batch/jobs
# operationId: jobs_api_routes_batch_get_batch_jobs
export def "batch-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 0
  --page-size: int # default: 100
  --model: string
  --agent-id: string
  --metadata: string
  --created-after: string
  --created-by-me: oneof<nothing, bool> # default: false
  --status: string
  --order-by: string@order-by-completer # default: -created
]: nothing -> record<data: table<id: string, object: string, input_files: list, metadata: any, endpoint: string, model: any, agent_id: any, output_file: any, error_file: any, errors: list, outputs: any, status: string, created_at: int, total_requests: int, completed_requests: int, succeeded_requests: int, failed_requests: int, started_at: any, completed_at: any>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "agent_id" $agent_id "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_by_me" $created_by_me "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batch/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Batch Job
#
# POST /v1/batch/jobs
# operationId: jobs_api_routes_batch_create_batch_job
export def "batch-jobs job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --input-files: any # The list of input files to be used for batch inference, these files should be `jsonl` files, containing the input data corresponding to the bory request for the batch inference in a "body" field. An example of such file is the following: ```json {"custom_id": "0", "body": {"max_tokens": 100, "messages": [{"role": "user", "content": "What is the best French cheese?"}]}} {"custom_id": "1", "body": {"max_tokens": 100, "messages": [{"role": "user", "content": "What is the best French wine?"}]}} ```
  --requests: any
  endpoint: string@endpoint-completer
  --model: any # The model to be used for batch inference.
  --agent-id: any # In case you want to use a specific agent from the **deprecated** agents api for batch inference, you can specify the agent ID here.
  --metadata: any # The metadata of your choice to be associated with the batch inference job.
  --timeout-hours: int # The timeout in hours for the batch inference job. (default: 24)
]: any -> record<id: string, object: string, input_files: list<string>, metadata: any, endpoint: string, model: any, agent_id: any, output_file: any, error_file: any, errors: table<message: string, count: int>, outputs: any, status: string, created_at: int, total_requests: int, completed_requests: int, succeeded_requests: int, failed_requests: int, started_at: any, completed_at: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batch/jobs")
  let body = {input_files: $input_files, requests: $requests, endpoint: $endpoint, model: $model, agent_id: $agent_id, metadata: $metadata, timeout_hours: $timeout_hours} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Batch Job
#
# GET /v1/batch/jobs/{job_id}
# operationId: jobs_api_routes_batch_get_batch_job
export def "batch-jobs job-by-job_id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inline: string
]: nothing -> record<id: string, object: string, input_files: list<string>, metadata: any, endpoint: string, model: any, agent_id: any, output_file: any, error_file: any, errors: table<message: string, count: int>, outputs: any, status: string, created_at: int, total_requests: int, completed_requests: int, succeeded_requests: int, failed_requests: int, started_at: any, completed_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inline" $inline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/batch/jobs/($job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Batch Job
#
# POST /v1/batch/jobs/{job_id}/cancel
# operationId: jobs_api_routes_batch_cancel_batch_job
export def "batch-jobs-cancel job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, object: string, input_files: list<string>, metadata: any, endpoint: string, model: any, agent_id: any, output_file: any, error_file: any, errors: table<message: string, count: int>, outputs: any, status: string, created_at: int, total_requests: int, completed_requests: int, succeeded_requests: int, failed_requests: int, started_at: any, completed_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/batch/jobs/($job_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Chat Completion
#
# POST /v1/chat/completions
# operationId: chat_completion_v1_chat_completions_post
# --response_format shape: {type?: "text"|"json_object"|"json_schema", json_schema?: any}
# --prediction shape: {type?: string, content?: string}
export def "chat-completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  model: string # ID of the model to use. You can use the [List Available Models](/api/#tag/models/operation/list_models_v1_models_get) API to see all of your available models, or see our [Model overview](/models) for model descriptions.
  --temperature: any # What sampling temperature to use, we recommend between 0.0 and 0.7. Higher values like 0.7 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. The default value varies depending on the model you are targeting. Call the `/models` endpoint to retrieve the appropriate value.
  --top-p: float # Nucleus sampling, where the model considers the results of the tokens with `top_p` probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (default: 1.0)
  --max-tokens: any # The maximum number of tokens to generate in the completion. The token count of your prompt plus `max_tokens` cannot exceed the model's context length.
  --stream: oneof<nothing, bool> # Whether to stream back partial progress. If set, tokens will be sent as data-only server-side events as they become available, with the stream terminated by a data: [DONE] message. Otherwise, the server will hold the request open until the timeout or until completion, with the response containing the full result as JSON. (default: false)
  --stop: any # Stop generation if this token is detected. Or if one of these tokens is detected when providing an array
  --random-seed: any # The seed to use for random sampling. If set, different calls will generate deterministic results.
  --metadata: any
  messages: list # The prompt(s) to generate completions for, encoded as a list of dict with role and content.
  --response-format: record # Specify the format that the model must output. By default it will use `{ "type": "text" }`. Setting to `{ "type": "json_object" }` enables JSON mode, which guarantees the message the model generates is in JSON. When using JSON mode you MUST also instruct the model to produce JSON yourself with a system or a user message. Setting to `{ "type": "json_schema" }` enables JSON schema mode, which guarantees the message the model generates is in JSON and follows the schema you provide. — shape: {type?: "text"|"json_object"|"json_schema", json_schema?: any}
  --tools: any # A list of tools the model may call. Use this to provide a list of functions the model may generate JSON inputs for.
  --tool-choice: any # Controls which (if any) tool is called by the model. `none` means the model will not call any tool and instead generates a message. `auto` means the model can pick between generating a message or calling one or more tools. `any` or `required` means the model must call one or more tools. Specifying a particular tool via `{"type": "function", "function": {"name": "my_function"}}` forces the model to call that tool. (default: auto)
  --presence-penalty: float # The `presence_penalty` determines how much the model penalizes the repetition of words or phrases. A higher presence penalty encourages the model to use a wider variety of words and phrases, making the output more diverse and creative. (default: 0.0)
  --frequency-penalty: float # The `frequency_penalty` penalizes the repetition of words based on their frequency in the generated text. A higher frequency penalty discourages the model from repeating words that have already appeared frequently in the output, promoting diversity and reducing repetition. (default: 0.0)
  --n: any # Number of completions to return for each request, input tokens are only billed once.
  --prediction: record # Enable users to specify an expected completion, optimizing response times by leveraging known or predictable content. — shape: {type?: string, content?: string}
  --parallel-tool-calls: oneof<nothing, bool> # Whether to enable parallel function calling during tool use, when enabled the model can call multiple tools in parallel. (default: true)
  --prompt-mode: any # Allows toggling between the reasoning mode and no system prompt. When set to `reasoning` the system prompt for reasoning models will be used. **Deprecated for reasoning models - use `reasoning_effort` parameter instead.**
  --reasoning-effort: string@reasoning-effort-completer # Controls the reasoning effort level for reasoning models. "high" enables comprehensive reasoning traces, "none" disables reasoning effort.
  --guardrails: any # A list of guardrail configurations to apply to this request. Each guardrail specifies a moderation type, categories with thresholds to evaluate, and an action to take on violation.
  --prompt-cache-key: any # A cache key to enable prompt caching. When provided, the API will attempt to reuse previously computed tokens for requests sharing the same prefix (e.g. multi-turn conversations or requests with a similar system prompt). Cached tokens are billed at 10% of the standard input token price.
  --safe-prompt: oneof<nothing, bool> # Whether to inject a safety prompt before all conversations. (default: false)
]: any -> record<choices: table<index: int, message: record, finish_reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chat/completions")
  let body = {model: $model, temperature: $temperature, top_p: $top_p, max_tokens: $max_tokens, stream: $stream, stop: $stop, random_seed: $random_seed, metadata: $metadata, messages: $messages, response_format: $response_format, tools: $tools, tool_choice: $tool_choice, presence_penalty: $presence_penalty, frequency_penalty: $frequency_penalty, n: $n, prediction: $prediction, parallel_tool_calls: $parallel_tool_calls, prompt_mode: $prompt_mode, reasoning_effort: $reasoning_effort, guardrails: $guardrails, prompt_cache_key: $prompt_cache_key, safe_prompt: $safe_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fim Completion
#
# POST /v1/fim/completions
# operationId: fim_completion_v1_fim_completions_post
export def "fim-completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  model: string # ID of the model with FIM to use. (default: codestral-2404)
  --temperature: any # What sampling temperature to use, we recommend between 0.0 and 0.7. Higher values like 0.7 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or `top_p` but not both. The default value varies depending on the model you are targeting. Call the `/models` endpoint to retrieve the appropriate value.
  --top-p: float # Nucleus sampling, where the model considers the results of the tokens with `top_p` probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or `temperature` but not both. (default: 1.0)
  --max-tokens: any # The maximum number of tokens to generate in the completion. The token count of your prompt plus `max_tokens` cannot exceed the model's context length.
  --stream: oneof<nothing, bool> # Whether to stream back partial progress. If set, tokens will be sent as data-only server-side events as they become available, with the stream terminated by a data: [DONE] message. Otherwise, the server will hold the request open until the timeout or until completion, with the response containing the full result as JSON. (default: false)
  --stop: any # Stop generation if this token is detected. Or if one of these tokens is detected when providing an array
  --random-seed: any # The seed to use for random sampling. If set, different calls will generate deterministic results.
  --metadata: any
  prompt: string # The text/code to complete.
  --suffix: any # Optional text/code that adds more context for the model. When given a `prompt` and a `suffix` the model will fill what is between them. When `suffix` is not provided, the model will simply execute completion starting with `prompt`. (default: )
  --min-tokens: any # The minimum number of tokens to generate in the completion.
  --prompt-cache-key: any # A cache key to enable prompt caching. When provided, the API will attempt to reuse previously computed tokens for requests sharing the same prefix (e.g. multi-turn conversations or requests with a similar system prompt). Cached tokens are billed at 10% of the standard input token price.
]: any -> record<model: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fim/completions")
  let body = {model: $model, temperature: $temperature, top_p: $top_p, max_tokens: $max_tokens, stream: $stream, stop: $stop, random_seed: $random_seed, metadata: $metadata, prompt: $prompt, suffix: $suffix, min_tokens: $min_tokens, prompt_cache_key: $prompt_cache_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Agents Completion
#
# POST /v1/agents/completions
# DEPRECATED
# operationId: agents_completion_v1_agents_completions_post
# --response_format shape: {type?: "text"|"json_object"|"json_schema", json_schema?: any}
# --prediction shape: {type?: string, content?: string}
@deprecated
export def "agents-completions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-tokens: any # The maximum number of tokens to generate in the completion. The token count of your prompt plus `max_tokens` cannot exceed the model's context length.
  --stream: oneof<nothing, bool> # Whether to stream back partial progress. If set, tokens will be sent as data-only server-side events as they become available, with the stream terminated by a data: [DONE] message. Otherwise, the server will hold the request open until the timeout or until completion, with the response containing the full result as JSON. (default: false)
  --stop: any # Stop generation if this token is detected. Or if one of these tokens is detected when providing an array
  --random-seed: any # The seed to use for random sampling. If set, different calls will generate deterministic results.
  --metadata: any
  messages: list # The prompt(s) to generate completions for, encoded as a list of dict with role and content.
  --response-format: record # Specify the format that the model must output. By default it will use `{ "type": "text" }`. Setting to `{ "type": "json_object" }` enables JSON mode, which guarantees the message the model generates is in JSON. When using JSON mode you MUST also instruct the model to produce JSON yourself with a system or a user message. Setting to `{ "type": "json_schema" }` enables JSON schema mode, which guarantees the message the model generates is in JSON and follows the schema you provide. — shape: {type?: "text"|"json_object"|"json_schema", json_schema?: any}
  --tools: any
  --tool-choice: any # default: auto
  --presence-penalty: float # The `presence_penalty` determines how much the model penalizes the repetition of words or phrases. A higher presence penalty encourages the model to use a wider variety of words and phrases, making the output more diverse and creative. (default: 0.0)
  --frequency-penalty: float # The `frequency_penalty` penalizes the repetition of words based on their frequency in the generated text. A higher frequency penalty discourages the model from repeating words that have already appeared frequently in the output, promoting diversity and reducing repetition. (default: 0.0)
  --n: any # Number of completions to return for each request, input tokens are only billed once.
  --prediction: record # Enable users to specify an expected completion, optimizing response times by leveraging known or predictable content. — shape: {type?: string, content?: string}
  --parallel-tool-calls: oneof<nothing, bool> # default: true
  --prompt-mode: any # Allows toggling between the reasoning mode and no system prompt. When set to `reasoning` the system prompt for reasoning models will be used. **Deprecated for reasoning models - use `reasoning_effort` parameter instead.**
  --reasoning-effort: string@reasoning-effort-completer # Controls the reasoning effort level for reasoning models. "high" enables comprehensive reasoning traces, "none" disables reasoning effort.
  --prompt-cache-key: any # A cache key to enable prompt caching. When provided, the API will attempt to reuse previously computed tokens for requests sharing the same prefix (e.g. multi-turn conversations or requests with a similar system prompt). Cached tokens are billed at 10% of the standard input token price.
  agent_id: string # The ID of the agent to use for this completion.
]: any -> record<choices: table<index: int, message: record, finish_reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/agents/completions")
  let body = {max_tokens: $max_tokens, stream: $stream, stop: $stop, random_seed: $random_seed, metadata: $metadata, messages: $messages, response_format: $response_format, tools: $tools, tool_choice: $tool_choice, presence_penalty: $presence_penalty, frequency_penalty: $frequency_penalty, n: $n, prediction: $prediction, parallel_tool_calls: $parallel_tool_calls, prompt_mode: $prompt_mode, reasoning_effort: $reasoning_effort, prompt_cache_key: $prompt_cache_key, agent_id: $agent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Embeddings
#
# POST /v1/embeddings
# operationId: embeddings_v1_embeddings_post
export def "embeddings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string # ID of the model to use. (e.g. mistral-embed)
  --metadata: any
  input: any # Text to embed. (e.g. [Embed this sentence., As well as this one.])
  --output-dimension: any # The dimension of the output embeddings when feature available. If not provided, a default output dimension will be used.
  --output-dtype: string@output-dtype-completer
  --encoding-format: string@encoding-format-completer
]: any -> record<id: string, object: string, model: string, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int, prompt_audio_seconds: any, num_cached_tokens: any, prompt_tokens_details: any, prompt_token_details: any>, data: table<object: string, embedding: list, index: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/embeddings")
  let body = {model: $model, metadata: $metadata, input: $input, output_dimension: $output_dimension, output_dtype: $output_dtype, encoding_format: $encoding_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Moderations
#
# POST /v1/moderations
# operationId: moderations_v1_moderations_post
export def "moderations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string # ID of the model to use.
  --metadata: any
  input: any # Text to classify.
]: any -> record<id: string, model: string, results: table<categories: record, category_scores: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/moderations")
  let body = {model: $model, metadata: $metadata, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Chat Moderations
#
# POST /v1/chat/moderations
# operationId: chat_moderations_v1_chat_moderations_post
export def "chat-moderations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  input: any # Chat to classify
  model: string
]: any -> record<id: string, model: string, results: table<categories: record, category_scores: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chat/moderations")
  let body = {input: $input, model: $model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OCR
#
# POST /v1/ocr
# operationId: ocr_v1_ocr_post
export def "ocr post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: any
  --id: string
  document: any # Document to run OCR on
  --pages: any # Specific pages user wants to process in various formats: single number, range, or list of both. Starts from 0
  --include-image-base64: any # Include image URLs in response
  --image-limit: any # Max images to extract
  --image-min-size: any # Minimum height and width of image to extract
  --bbox-annotation-format: any # Structured output class for extracting useful information from each extracted bounding box / image from document. Only json_schema is valid for this field
  --document-annotation-format: any # Structured output class for extracting useful information from the entire document. Only json_schema is valid for this field
  --document-annotation-prompt: any # Optional prompt to guide the model in extracting structured output from the entire document. A document_annotation_format must be provided.
  --table-format: any
  --extract-header: oneof<nothing, bool> # default: false
  --extract-footer: oneof<nothing, bool> # default: false
  --confidence-scores-granularity: any # Granularity for confidence scores: 'word' (per-word scores) or 'page' (aggregate only). Defaults to None (no confidence scores) to keep response payload small.
]: any -> record<pages: table<index: int, markdown: string, images: list, tables: list, hyperlinks: list, header: any, footer: any, dimensions: any, confidence_scores: any>, model: string, document_annotation: any, usage_info: record<pages_processed: int, doc_size_bytes: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ocr")
  let body = {model: $model, id: $id, document: $document, pages: $pages, include_image_base64: $include_image_base64, image_limit: $image_limit, image_min_size: $image_min_size, bbox_annotation_format: $bbox_annotation_format, document_annotation_format: $document_annotation_format, document_annotation_prompt: $document_annotation_prompt, table_format: $table_format, extract_header: $extract_header, extract_footer: $extract_footer, confidence_scores_granularity: $confidence_scores_granularity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Classifications
#
# POST /v1/classifications
# operationId: classifications_v1_classifications_post
export def "classifications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string # ID of the model to use.
  --metadata: any
  input: any # Text to classify.
]: any -> record<id: string, model: string, results: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/classifications")
  let body = {model: $model, metadata: $metadata, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Chat Classifications
#
# POST /v1/chat/classifications
# operationId: chat_classifications_v1_chat_classifications_post
export def "chat-classifications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string
  input: any # Chat to classify
]: any -> record<id: string, model: string, results: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/chat/classifications")
  let body = {model: $model, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Transcription
#
# POST /v1/audio/transcriptions
# operationId: audio_api_v1_transcriptions_post
export def "audio-transcriptions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string # ID of the model to be used.
  --file: any
  --file-url: any # Url of a file to be transcribed
  --file-id: any # ID of a file uploaded to /v1/files
  --language: any # Language of the audio, e.g. 'en'. Providing the language can boost accuracy.
  --temperature: any
  --stream: oneof<nothing, bool> # default: false
  --diarize: oneof<nothing, bool> # default: false
  --context-bias: list # default: []
  --timestamp-granularities: list # Granularities of timestamps to include in the response.
]: any -> record<model: string, text: string, language: any, segments: table<type: string, text: string, start: float, end: float, score: any, speaker_id: any>, usage: record<prompt_tokens: int, completion_tokens: int, total_tokens: int, prompt_audio_seconds: any, num_cached_tokens: any, prompt_tokens_details: any, prompt_token_details: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio/transcriptions")
  let body = {model: $model, file: $file, file_url: $file_url, file_id: $file_id, language: $language, temperature: $temperature, stream: $stream, diarize: $diarize, context_bias: $context_bias, timestamp_granularities: $timestamp_granularities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create Streaming Transcription (SSE)
#
# POST /v1/audio/transcriptions#stream
# operationId: audio_api_v1_transcriptions_post_stream
export def "audio-transcriptionsstream stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  model: string
  --file: any
  --file-url: any # Url of a file to be transcribed
  --file-id: any # ID of a file uploaded to /v1/files
  --language: any # Language of the audio, e.g. 'en'. Providing the language can boost accuracy.
  --temperature: any
  --stream: oneof<nothing, bool> # default: true
  --diarize: oneof<nothing, bool> # default: false
  --context-bias: list # default: []
  --timestamp-granularities: list # Granularities of timestamps to include in the response.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio/transcriptions#stream")
  let body = {model: $model, file: $file, file_url: $file_url, file_id: $file_id, language: $language, temperature: $temperature, stream: $stream, diarize: $diarize, context_bias: $context_bias, timestamp_granularities: $timestamp_granularities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Speech
#
# POST /v1/audio/speech
# operationId: speech_v1_audio_speech_post
export def "audio-speech post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --model: any
  --stream: oneof<nothing, bool> # default: false
  --voice-id: any # The preset or custom voice to use for generating the speech.
  --ref-audio: any # The base64-encoded audio reference for zero-shot voice cloning.
  input: string # Text to generate speech from.
  --response-format: string@response-format-completer
]: any -> record<audio_data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio/speech")
  let body = {model: $model, stream: $stream, voice_id: $voice_id, ref_audio: $ref_audio, input: $input, response_format: $response_format} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all voices
#
# GET /v1/audio/voices
# operationId: list_voices_v1_audio_voices_get
export def "audio-voices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of voices to return (default: 10)
  --offset: int # Offset for pagination (default: 0)
]: nothing -> record<items: table<name: string, slug: any, languages: list, gender: any, age: any, tags: any, color: any, retention_notice: int, id: string, created_at: string, user_id: any>, total: int, page: int, page_size: int, total_pages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/audio/voices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new voice
#
# POST /v1/audio/voices
# operationId: create_voice_v1_audio_voices_post
export def "audio-voices post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --slug: any
  --languages: list # default: []
  --gender: any
  --age: any
  --tags: any
  --color: any
  --retention-notice: int # default: 30
  sample_audio: string # Base64-encoded audio file
  --sample-filename: any # Original filename for extension detection
]: any -> record<name: string, slug: any, languages: list<string>, gender: any, age: any, tags: any, color: any, retention_notice: int, id: string, created_at: string, user_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/audio/voices")
  let body = {name: $name, slug: $slug, languages: $languages, gender: $gender, age: $age, tags: $tags, color: $color, retention_notice: $retention_notice, sample_audio: $sample_audio, sample_filename: $sample_filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get voice details
#
# GET /v1/audio/voices/{voice_id}
# operationId: get_voice_v1_audio_voices__voice_id__get
export def "audio-voices get" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, slug: any, languages: list<string>, gender: any, age: any, tags: any, color: any, retention_notice: int, id: string, created_at: string, user_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audio/voices/($voice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update voice metadata
#
# PATCH /v1/audio/voices/{voice_id}
# operationId: update_voice_v1_audio_voices__voice_id__patch
export def "audio-voices patch" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --languages: any
  --gender: any
  --age: any
  --tags: any
]: any -> record<name: string, slug: any, languages: list<string>, gender: any, age: any, tags: any, color: any, retention_notice: int, id: string, created_at: string, user_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audio/voices/($voice_id)")
  let body = {name: $name, languages: $languages, gender: $gender, age: $age, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a custom voice
#
# DELETE /v1/audio/voices/{voice_id}
# operationId: delete_voice_v1_audio_voices__voice_id__delete
export def "audio-voices delete" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, slug: any, languages: list<string>, gender: any, age: any, tags: any, color: any, retention_notice: int, id: string, created_at: string, user_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audio/voices/($voice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get voice sample audio
#
# GET /v1/audio/voices/{voice_id}/sample
# operationId: get_voice_sample_audio_v1_audio_voices__voice_id__sample_get
export def "audio-voices-sample get" [
  voice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audio/voices/($voice_id)/sample")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all libraries you have access to.
#
# GET /v1/libraries
# operationId: libraries_list_v1
export def "libraries v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string, name: string, created_at: string, updated_at: string, owner_id: any, owner_type: string, total_size: int, nb_documents: int, chunk_size: any, emoji: any, description: any, generated_description: any, explicit_user_members_count: any, explicit_workspace_members_count: any, org_sharing_role: any, generated_name: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/libraries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Library.
#
# POST /v1/libraries
# operationId: libraries_create_v1
export def "libraries v1-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --description: any
  --chunk-size: any
]: any -> record<id: string, name: string, created_at: string, updated_at: string, owner_id: any, owner_type: string, total_size: int, nb_documents: int, chunk_size: any, emoji: any, description: any, generated_description: any, explicit_user_members_count: any, explicit_workspace_members_count: any, org_sharing_role: any, generated_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/libraries")
  let body = {name: $name, description: $description, chunk_size: $chunk_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Detailed information about a specific Library.
#
# GET /v1/libraries/{library_id}
# operationId: libraries_get_v1
export def "libraries v1-by-library_id" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, owner_id: any, owner_type: string, total_size: int, nb_documents: int, chunk_size: any, emoji: any, description: any, generated_description: any, explicit_user_members_count: any, explicit_workspace_members_count: any, org_sharing_role: any, generated_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a library and all of it's document.
#
# DELETE /v1/libraries/{library_id}
# operationId: libraries_delete_v1
export def "libraries v1-by-library_id-1" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, created_at: string, updated_at: string, owner_id: any, owner_type: string, total_size: int, nb_documents: int, chunk_size: any, emoji: any, description: any, generated_description: any, explicit_user_members_count: any, explicit_workspace_members_count: any, org_sharing_role: any, generated_name: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a library.
#
# PUT /v1/libraries/{library_id}
# operationId: libraries_update_v1
export def "libraries v1-by-library_id-2" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --description: any
]: any -> record<id: string, name: string, created_at: string, updated_at: string, owner_id: any, owner_type: string, total_size: int, nb_documents: int, chunk_size: any, emoji: any, description: any, generated_description: any, explicit_user_members_count: any, explicit_workspace_members_count: any, org_sharing_role: any, generated_name: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List documents in a given library.
#
# GET /v1/libraries/{library_id}/documents
# operationId: libraries_documents_list_v1
export def "libraries-documents v1-by-library_id" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --page-size: int # default: 100
  --page: int # default: 0
  --filters-attributes: string
  --sort-by: string # default: created_at
  --sort-order: string # default: desc
]: nothing -> record<pagination: record<total_items: int, total_pages: int, current_page: int, page_size: int, has_more: bool>, data: table<id: string, library_id: string, hash: any, mime_type: any, extension: any, size: any, name: string, summary: any, created_at: string, last_processed_at: any, number_of_pages: any, process_status: string, uploaded_by_id: any, uploaded_by_type: string, tokens_processing_main_content: any, tokens_processing_summary: any, url: any, attributes: any, processing_status: string, tokens_processing_total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filters_attributes" $filters_attributes "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a new document.
#
# POST /v1/libraries/{library_id}/documents
# operationId: libraries_documents_upload_v1
export def "libraries-documents v1-by-library_id-1" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The File object (not file name) to be uploaded.  To upload a file and specify a custom file name you should format your request as such:  ```bash  file=@path/to/your/file.jsonl;filename=custom_name.jsonl  ```  Otherwise, you can just keep the original file name:  ```bash  file=@path/to/your/file.jsonl  ``` (format: binary)
]: any -> record<id: string, library_id: string, hash: any, mime_type: any, extension: any, size: any, name: string, summary: any, created_at: string, last_processed_at: any, number_of_pages: any, process_status: string, uploaded_by_id: any, uploaded_by_type: string, tokens_processing_main_content: any, tokens_processing_summary: any, url: any, attributes: any, processing_status: string, tokens_processing_total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve the metadata of a specific document.
#
# GET /v1/libraries/{library_id}/documents/{document_id}
# operationId: libraries_documents_get_v1
export def "libraries-documents v1-by-library_id-document_id" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, library_id: string, hash: any, mime_type: any, extension: any, size: any, name: string, summary: any, created_at: string, last_processed_at: any, number_of_pages: any, process_status: string, uploaded_by_id: any, uploaded_by_type: string, tokens_processing_main_content: any, tokens_processing_summary: any, url: any, attributes: any, processing_status: string, tokens_processing_total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the metadata of a specific document.
#
# PUT /v1/libraries/{library_id}/documents/{document_id}
# operationId: libraries_documents_update_v1
export def "libraries-documents v1-by-library_id-document_id-1" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --attributes: any
]: any -> record<id: string, library_id: string, hash: any, mime_type: any, extension: any, size: any, name: string, summary: any, created_at: string, last_processed_at: any, number_of_pages: any, process_status: string, uploaded_by_id: any, uploaded_by_type: string, tokens_processing_main_content: any, tokens_processing_summary: any, url: any, attributes: any, processing_status: string, tokens_processing_total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)")
  let body = {name: $name, attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a document.
#
# DELETE /v1/libraries/{library_id}/documents/{document_id}
# operationId: libraries_documents_delete_v1
export def "libraries-documents v1-by-library_id-document_id-2" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the text content of a specific document.
#
# GET /v1/libraries/{library_id}/documents/{document_id}/text_content
# operationId: libraries_documents_get_text_content_v1
export def "libraries-documents-text-content v1" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)/text_content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the processing status of a specific document.
#
# GET /v1/libraries/{library_id}/documents/{document_id}/status
# operationId: libraries_documents_get_status_v1
export def "libraries-documents-status v1" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<document_id: string, process_status: string, processing_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the signed URL of a specific document.
#
# GET /v1/libraries/{library_id}/documents/{document_id}/signed-url
# operationId: libraries_documents_get_signed_url_v1
export def "libraries-documents-signed-url v1" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)/signed-url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the signed URL of text extracted from a given document.
#
# GET /v1/libraries/{library_id}/documents/{document_id}/extracted-text-signed-url
# operationId: libraries_documents_get_extracted_text_signed_url_v1
export def "libraries-documents-extracted-text-signed-url v1" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)/extracted-text-signed-url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reprocess a document.
#
# POST /v1/libraries/{library_id}/documents/{document_id}/reprocess
# operationId: libraries_documents_reprocess_v1
export def "libraries-documents-reprocess v1" [
  library_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/documents/($document_id)/reprocess")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all of the access to this library.
#
# GET /v1/libraries/{library_id}/share
# operationId: libraries_share_list_v1
export def "libraries-share v1-by-library_id" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<library_id: string, user_id: any, org_id: string, role: string, share_with_type: string, share_with_uuid: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/share")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an access level.
#
# PUT /v1/libraries/{library_id}/share
# operationId: libraries_share_create_v1
export def "libraries-share v1-by-library_id-1" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: any
  level: string@level-completer
  share_with_uuid: string # The id of the entity (user, workspace or organization) to share with (format: uuid)
  share_with_type: string@share-with-type-completer # The type of entity, used to share a library.
]: any -> record<library_id: string, user_id: any, org_id: string, role: string, share_with_type: string, share_with_uuid: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/share")
  let body = {org_id: $org_id, level: $level, share_with_uuid: $share_with_uuid, share_with_type: $share_with_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an access level.
#
# DELETE /v1/libraries/{library_id}/share
# operationId: libraries_share_delete_v1
export def "libraries-share v1-by-library_id-2" [
  library_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-id: any
  share_with_uuid: string # The id of the entity (user, workspace or organization) to share with (format: uuid)
  share_with_type: string@share-with-type-completer # The type of entity, used to share a library.
]: any -> record<library_id: string, user_id: any, org_id: string, role: string, share_with_type: string, share_with_uuid: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/libraries/($library_id)/share")
  let body = {org_id: $org_id, share_with_uuid: $share_with_uuid, share_with_type: $share_with_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Chat Completion Events
#
# POST /v1/observability/chat-completion-events/search
# operationId: get_chat_completion_events_v1_observability_chat_completion_events_search_post
# --search_params shape: {filters: any}
export def "observability-chat-completion-events-search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # default: 50
  --cursor: string
  search_params: record # shape: {filters: any}
  --extra-fields: any
]: any -> record<completion_events: record<results: list<record>, next: any, cursor: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/observability/chat-completion-events/search" $qp)
  let body = {search_params: $search_params, extra_fields: $extra_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Alternative to /search that returns only the IDs and that can return many IDs at once
#
# POST /v1/observability/chat-completion-events/search-ids
# operationId: get_chat_completion_event_ids_v1_observability_chat_completion_events_search_ids_post
# --search_params shape: {filters: any}
export def "observability-chat-completion-events-search-ids post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  search_params: record # shape: {filters: any}
  --extra-fields: any
]: any -> record<completion_event_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/observability/chat-completion-events/search-ids")
  let body = {search_params: $search_params, extra_fields: $extra_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Chat Completion Event
#
# GET /v1/observability/chat-completion-events/{event_id}
# operationId: get_chat_completion_event_v1_observability_chat_completion_events__event_id__get
export def "observability-chat-completion-events get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<event_id: string, correlation_id: string, created_at: string, extra_fields: record, nb_input_tokens: int, nb_output_tokens: int, enabled_tools: list<record>, request_messages: list<record>, response_messages: list<record>, nb_messages: int, chat_transcription_events: table<audio_url: string, model: string, response_message: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/chat-completion-events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Similar Chat Completion Events
#
# GET /v1/observability/chat-completion-events/{event_id}/similar-events
# operationId: get_similar_chat_completion_events_v1_observability_chat_completion_events__event_id__similar_events_get
export def "observability-chat-completion-events-similar-events get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completion_events: record<results: list<record>, next: any, cursor: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/chat-completion-events/($event_id)/similar-events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Chat Completion Fields
#
# GET /v1/observability/chat-completion-fields
# operationId: get_chat_completion_fields_v1_observability_chat_completion_fields_get
export def "observability-chat-completion-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<field_definitions: table<name: string, label: string, type: string, group: any, supported_operators: list>, field_groups: table<name: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/observability/chat-completion-fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Chat Completion Field Options
#
# GET /v1/observability/chat-completion-fields/{field_name}/options
# operationId: get_chat_completion_field_options_v1_observability_chat_completion_fields__field_name__options_get
export def "observability-chat-completion-fields-options get" [
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --operator: string@operator-completer # The operator to use for filtering options
]: nothing -> record<options: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "operator" $operator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/observability/chat-completion-fields/($field_name)/options" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Chat Completion Field Options Counts
#
# POST /v1/observability/chat-completion-fields/{field_name}/options-counts
# operationId: get_chat_completion_field_options_counts_v1_observability_chat_completion_fields__field_name__options_counts_post
export def "observability-chat-completion-fields-options-counts post" [
  field_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-params: any
]: any -> record<counts: table<value: string, count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/chat-completion-fields/($field_name)/options-counts")
  let body = {filter_params: $filter_params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Judge on an event based on the given options
#
# POST /v1/observability/chat-completion-events/{event_id}/live-judging
# operationId: judge_chat_completion_event_v1_observability_chat_completion_events__event_id__live_judging_post
# --judge_definition shape: {name: string, description: string, model_name: string, output: any, instructions: string, tools: list}
export def "observability-chat-completion-events-live-judging post" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  judge_definition: record # shape: {name: string, description: string, model_name: string, output: any, instructions: string, tools: list}
]: any -> record<analysis: string, answer: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/chat-completion-events/($event_id)/live-judging")
  let body = {judge_definition: $judge_definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new judge
#
# POST /v1/observability/judges
# operationId: create_judge_v1_observability_judges_post
export def "observability-judges post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  model_name: string
  output: any
  instructions: string
  tools: list
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, owner_id: string, workspace_id: string, name: string, description: string, model_name: string, output: any, instructions: string, tools: list<string>, up_revision: any, down_revision: any, base_revision: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/observability/judges")
  let body = {name: $name, description: $description, model_name: $model_name, output: $output, instructions: $instructions, tools: $tools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get judges with optional filtering and search
#
# GET /v1/observability/judges
# operationId: get_judges_v1_observability_judges_get
export def "observability-judges list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type-filter: string # Filter by judge output types
  --model-filter: string # Filter by model names
  --page-size: int # default: 50
  --page: int # default: 1
  --q: string
]: nothing -> record<judges: record<results: list<record>, count: int, next: any, previous: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type_filter" $type_filter "scalar") (serialize-qp "model_filter" $model_filter "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/observability/judges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get judge by id
#
# GET /v1/observability/judges/{judge_id}
# operationId: get_judge_by_id_v1_observability_judges__judge_id__get
export def "observability-judges get" [
  judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, created_at: string, updated_at: string, deleted_at: any, owner_id: string, workspace_id: string, name: string, description: string, model_name: string, output: any, instructions: string, tools: list<string>, up_revision: any, down_revision: any, base_revision: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/judges/($judge_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a judge
#
# DELETE /v1/observability/judges/{judge_id}
# operationId: delete_judge_v1_observability_judges__judge_id__delete
export def "observability-judges delete" [
  judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/judges/($judge_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a judge
#
# PUT /v1/observability/judges/{judge_id}
# operationId: update_judge_v1_observability_judges__judge_id__put
export def "observability-judges put" [
  judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
  model_name: string
  output: any
  instructions: string
  tools: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/judges/($judge_id)")
  let body = {name: $name, description: $description, model_name: $model_name, output: $output, instructions: $instructions, tools: $tools} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run a saved judge on a conversation
#
# POST /v1/observability/judges/{judge_id}/live-judging
# operationId: judge_conversation_v1_observability_judges__judge_id__live_judging_post
export def "observability-judges-live-judging post" [
  judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messages: list
  --properties: any
]: any -> record<analysis: string, answer: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/judges/($judge_id)/live-judging")
  let body = {messages: $messages, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create and start a new campaign
#
# POST /v1/observability/campaigns
# operationId: create_campaign_v1_observability_campaigns_post
# --search_params shape: {filters: any}
export def "observability-campaigns post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  search_params: record # shape: {filters: any}
  judge_id: string # format: uuid
  name: string
  description: string
  max_nb_events: int
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, name: string, owner_id: string, workspace_id: string, description: string, max_nb_events: int, search_params: record<filters: any>, judge: record<id: string, created_at: string, updated_at: string, deleted_at: any, owner_id: string, workspace_id: string, name: string, description: string, model_name: string, output: any, instructions: string, tools: list<string>, up_revision: any, down_revision: any, base_revision: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/observability/campaigns")
  let body = {search_params: $search_params, judge_id: $judge_id, name: $name, description: $description, max_nb_events: $max_nb_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all campaigns
#
# GET /v1/observability/campaigns
# operationId: get_campaigns_v1_observability_campaigns_get
export def "observability-campaigns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # default: 50
  --page: int # default: 1
  --q: string
]: nothing -> record<campaigns: record<results: list<record>, count: int, next: any, previous: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/observability/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get campaign by id
#
# GET /v1/observability/campaigns/{campaign_id}
# operationId: get_campaign_by_id_v1_observability_campaigns__campaign_id__get
export def "observability-campaigns get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, created_at: string, updated_at: string, deleted_at: any, name: string, owner_id: string, workspace_id: string, description: string, max_nb_events: int, search_params: record<filters: any>, judge: record<id: string, created_at: string, updated_at: string, deleted_at: any, owner_id: string, workspace_id: string, name: string, description: string, model_name: string, output: any, instructions: string, tools: list<string>, up_revision: any, down_revision: any, base_revision: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/campaigns/($campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a campaign
#
# DELETE /v1/observability/campaigns/{campaign_id}
# operationId: delete_campaign_v1_observability_campaigns__campaign_id__delete
export def "observability-campaigns delete" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/campaigns/($campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get campaign status by campaign id
#
# GET /v1/observability/campaigns/{campaign_id}/status
# operationId: get_campaign_status_by_id_v1_observability_campaigns__campaign_id__status_get
export def "observability-campaigns-status get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/campaigns/($campaign_id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get event ids that were selected by the given campaign
#
# GET /v1/observability/campaigns/{campaign_id}/selected-events
# operationId: get_campaign_selected_events_v1_observability_campaigns__campaign_id__selected_events_get
export def "observability-campaigns-selected-events get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # default: 50
  --page: int # default: 1
]: nothing -> record<completion_events: record<results: list<record>, count: int, next: any, previous: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/observability/campaigns/($campaign_id)/selected-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new empty dataset
#
# POST /v1/observability/datasets
# operationId: create_dataset_v1_observability_datasets_post
export def "observability-datasets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  description: string
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, name: string, description: string, owner_id: string, workspace_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/observability/datasets")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List existing datasets
#
# GET /v1/observability/datasets
# operationId: get_datasets_v1_observability_datasets_get
export def "observability-datasets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # default: 50
  --page: int # default: 1
  --q: string
]: nothing -> record<datasets: record<results: list<record>, count: int, next: any, previous: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/observability/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dataset by id
#
# GET /v1/observability/datasets/{dataset_id}
# operationId: get_dataset_by_id_v1_observability_datasets__dataset_id__get
export def "observability-datasets get" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, created_at: string, updated_at: string, deleted_at: any, name: string, description: string, owner_id: string, workspace_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a dataset
#
# DELETE /v1/observability/datasets/{dataset_id}
# operationId: delete_dataset_v1_observability_datasets__dataset_id__delete
export def "observability-datasets delete" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch dataset
#
# PATCH /v1/observability/datasets/{dataset_id}
# operationId: update_dataset_v1_observability_datasets__dataset_id__patch
export def "observability-datasets patch" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --description: any
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, name: string, description: string, owner_id: string, workspace_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List existing records in the dataset
#
# GET /v1/observability/datasets/{dataset_id}/records
# operationId: get_dataset_records_v1_observability_datasets__dataset_id__records_get
export def "observability-datasets-records get" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # default: 50
  --page: int # default: 1
]: nothing -> record<records: record<results: list<record>, count: int, next: any, previous: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a conversation to the dataset
#
# POST /v1/observability/datasets/{dataset_id}/records
# operationId: create_dataset_record_v1_observability_datasets__dataset_id__records_post
# --payload shape: {messages: list}
export def "observability-datasets-records post" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payload: record # shape: {messages: list}
  properties: record
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, dataset_id: string, payload: record<messages: list<record>>, properties: record, source: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/records")
  let body = {payload: $payload, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Populate the dataset with a campaign
#
# POST /v1/observability/datasets/{dataset_id}/imports/from-campaign
# operationId: post_dataset_records_from_campaign_v1_observability_datasets__dataset_id__imports_from_campaign_post
export def "observability-datasets-imports-from-campaign post" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  campaign_id: string # format: uuid
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, creator_id: string, dataset_id: string, workspace_id: string, status: string, progress: any, message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/imports/from-campaign")
  let body = {campaign_id: $campaign_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Populate the dataset with samples from the explorer
#
# POST /v1/observability/datasets/{dataset_id}/imports/from-explorer
# operationId: post_dataset_records_from_explorer_v1_observability_datasets__dataset_id__imports_from_explorer_post
export def "observability-datasets-imports-from-explorer post" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  completion_event_ids: list
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, creator_id: string, dataset_id: string, workspace_id: string, status: string, progress: any, message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/imports/from-explorer")
  let body = {completion_event_ids: $completion_event_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Populate the dataset with samples from an uploaded file
#
# POST /v1/observability/datasets/{dataset_id}/imports/from-file
# operationId: post_dataset_records_from_file_v1_observability_datasets__dataset_id__imports_from_file_post
export def "observability-datasets-imports-from-file post" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file_id: string
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, creator_id: string, dataset_id: string, workspace_id: string, status: string, progress: any, message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/imports/from-file")
  let body = {file_id: $file_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Populate the dataset with samples from the playground
#
# POST /v1/observability/datasets/{dataset_id}/imports/from-playground
# operationId: post_dataset_records_from_playground_v1_observability_datasets__dataset_id__imports_from_playground_post
export def "observability-datasets-imports-from-playground post" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  conversation_ids: list
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, creator_id: string, dataset_id: string, workspace_id: string, status: string, progress: any, message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/imports/from-playground")
  let body = {conversation_ids: $conversation_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Populate the dataset with samples from another dataset
#
# POST /v1/observability/datasets/{dataset_id}/imports/from-dataset
# operationId: post_dataset_records_from_dataset_v1_observability_datasets__dataset_id__imports_from_dataset_post
export def "observability-datasets-imports-from-dataset post" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset_record_ids: list
]: any -> record<id: string, created_at: string, updated_at: string, deleted_at: any, creator_id: string, dataset_id: string, workspace_id: string, status: string, progress: any, message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/imports/from-dataset")
  let body = {dataset_record_ids: $dataset_record_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export to the Files API and retrieve presigned URL to download the resulting JSONL file
#
# GET /v1/observability/datasets/{dataset_id}/exports/to-jsonl
# operationId: export_dataset_to_jsonl_v1_observability_datasets__dataset_id__exports_to_jsonl_get
export def "observability-datasets-exports-to-jsonl get" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<file_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/exports/to-jsonl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status of a dataset import task
#
# GET /v1/observability/datasets/{dataset_id}/tasks/{task_id}
# operationId: get_dataset_import_task_v1_observability_datasets__dataset_id__tasks__task_id__get
export def "observability-datasets-tasks get" [
  dataset_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, created_at: string, updated_at: string, deleted_at: any, creator_id: string, dataset_id: string, workspace_id: string, status: string, progress: any, message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List import tasks for the given dataset
#
# GET /v1/observability/datasets/{dataset_id}/tasks
# operationId: get_dataset_import_tasks_v1_observability_datasets__dataset_id__tasks_get
export def "observability-datasets-tasks list" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # default: 50
  --page: int # default: 1
]: nothing -> record<tasks: record<results: list<record>, count: int, next: any, previous: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/observability/datasets/($dataset_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of a given conversation from a dataset
#
# GET /v1/observability/dataset-records/{dataset_record_id}
# operationId: get_dataset_record_v1_observability_dataset_records__dataset_record_id__get
export def "observability-dataset-records get" [
  dataset_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, created_at: string, updated_at: string, deleted_at: any, dataset_id: string, payload: record<messages: list<record>>, properties: record, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/dataset-records/($dataset_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a record from a dataset
#
# DELETE /v1/observability/dataset-records/{dataset_record_id}
# operationId: delete_dataset_record_v1_observability_dataset_records__dataset_record_id__delete
export def "observability-dataset-records delete" [
  dataset_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/dataset-records/($dataset_record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete multiple records from datasets
#
# POST /v1/observability/dataset-records/bulk-delete
# operationId: delete_dataset_records_v1_observability_dataset_records_bulk_delete_post
export def "observability-dataset-records-bulk-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataset_record_ids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/observability/dataset-records/bulk-delete")
  let body = {dataset_record_ids: $dataset_record_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Judge on a dataset record based on the given options
#
# POST /v1/observability/dataset-records/{dataset_record_id}/live-judging
# operationId: judge_dataset_record_v1_observability_dataset_records__dataset_record_id__live_judging_post
# --judge_definition shape: {name: string, description: string, model_name: string, output: any, instructions: string, tools: list}
export def "observability-dataset-records-live-judging post" [
  dataset_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  judge_definition: record # shape: {name: string, description: string, model_name: string, output: any, instructions: string, tools: list}
]: any -> record<analysis: string, answer: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/dataset-records/($dataset_record_id)/live-judging")
  let body = {judge_definition: $judge_definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a dataset record conversation payload
#
# PUT /v1/observability/dataset-records/{dataset_record_id}/payload
# operationId: update_dataset_record_payload_v1_observability_dataset_records__dataset_record_id__payload_put
# --payload shape: {messages: list}
export def "observability-dataset-records-payload put" [
  dataset_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payload: record # shape: {messages: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/dataset-records/($dataset_record_id)/payload")
  let body = {payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update conversation properties
#
# PUT /v1/observability/dataset-records/{dataset_record_id}/properties
# operationId: update_dataset_record_properties_v1_observability_dataset_records__dataset_record_id__properties_put
export def "observability-dataset-records-properties put" [
  dataset_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  properties: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/observability/dataset-records/($dataset_record_id)/properties")
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Workflow Execution
#
# GET /v1/workflows/executions/{execution_id}
# operationId: get_workflow_execution_v1_workflows_executions__execution_id__get
export def "workflows-executions get" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflow_name: string, execution_id: string, parent_execution_id: any, root_execution_id: string, status: any, start_time: string, end_time: any, total_duration_ms: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Workflow Execution History
#
# GET /v1/workflows/executions/{execution_id}/history
# operationId: get_workflow_execution_history_v1_workflows_executions__execution_id__history_get
export def "workflows-executions-history get" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --decode-payloads: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "decode_payloads" $decode_payloads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Signal Workflow Execution
#
# POST /v1/workflows/executions/{execution_id}/signals
# operationId: signal_workflow_execution_v1_workflows_executions__execution_id__signals_post
export def "workflows-executions-signals post" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the signal to send
  --input: any # Input data for the signal, matching its schema
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/signals")
  let body = {name: $name, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query Workflow Execution
#
# POST /v1/workflows/executions/{execution_id}/queries
# operationId: query_workflow_execution_v1_workflows_executions__execution_id__queries_post
export def "workflows-executions-queries post" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the query to request
  --input: any # Input data for the query, matching its schema
]: any -> record<query_name: string, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/queries")
  let body = {name: $name, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Terminate Workflow Execution
#
# POST /v1/workflows/executions/{execution_id}/terminate
# operationId: terminate_workflow_execution_v1_workflows_executions__execution_id__terminate_post
export def "workflows-executions-terminate post-by-execution_id" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/terminate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch Terminate Workflow Executions
#
# POST /v1/workflows/executions/terminate
# operationId: batch_terminate_workflow_executions_v1_workflows_executions_terminate_post
export def "workflows-executions-terminate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  execution_ids: list # List of execution IDs to process
]: any -> record<results: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workflows/executions/terminate")
  let body = {execution_ids: $execution_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel Workflow Execution
#
# POST /v1/workflows/executions/{execution_id}/cancel
# operationId: cancel_workflow_execution_v1_workflows_executions__execution_id__cancel_post
export def "workflows-executions-cancel post-by-execution_id" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch Cancel Workflow Executions
#
# POST /v1/workflows/executions/cancel
# operationId: batch_cancel_workflow_executions_v1_workflows_executions_cancel_post
export def "workflows-executions-cancel post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  execution_ids: list # List of execution IDs to process
]: any -> record<results: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workflows/executions/cancel")
  let body = {execution_ids: $execution_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset Workflow
#
# POST /v1/workflows/executions/{execution_id}/reset
# operationId: reset_workflow_v1_workflows_executions__execution_id__reset_post
export def "workflows-executions-reset post" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event_id: int # The event ID to reset the workflow execution to
  --reason: any # Reason for resetting the workflow execution
  --exclude-signals: oneof<nothing, bool> # Whether to exclude signals that happened after the reset point (default: false)
  --exclude-updates: oneof<nothing, bool> # Whether to exclude updates that happened after the reset point (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/reset")
  let body = {event_id: $event_id, reason: $reason, exclude_signals: $exclude_signals, exclude_updates: $exclude_updates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Workflow Execution
#
# POST /v1/workflows/executions/{execution_id}/updates
# operationId: update_workflow_execution_v1_workflows_executions__execution_id__updates_post
export def "workflows-executions-updates post" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the update to request
  --input: any # Input data for the update, matching its schema
]: any -> record<update_name: string, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/updates")
  let body = {name: $name, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Workflow Execution Trace Otel
#
# GET /v1/workflows/executions/{execution_id}/trace/otel
# operationId: get_workflow_execution_trace_otel
export def "workflows-executions-trace-otel otel" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflow_name: string, execution_id: string, parent_execution_id: any, root_execution_id: string, status: any, start_time: string, end_time: any, total_duration_ms: any, result: any, data_source: string, otel_trace_id: any, otel_trace_data: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/trace/otel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Workflow Execution Trace Summary
#
# GET /v1/workflows/executions/{execution_id}/trace/summary
# operationId: get_workflow_execution_trace_summary
export def "workflows-executions-trace-summary summary" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflow_name: string, execution_id: string, parent_execution_id: any, root_execution_id: string, status: any, start_time: string, end_time: any, total_duration_ms: any, result: any, span_tree: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/trace/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Workflow Execution Trace Events
#
# GET /v1/workflows/executions/{execution_id}/trace/events
# operationId: get_workflow_execution_trace_events
export def "workflows-executions-trace-events events" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --merge-same-id-events: oneof<nothing, bool> # default: false
  --include-internal-events: oneof<nothing, bool> # default: false
]: nothing -> record<workflow_name: string, execution_id: string, parent_execution_id: any, root_execution_id: string, status: any, start_time: string, end_time: any, total_duration_ms: any, result: any, events: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge_same_id_events" $merge_same_id_events "scalar") (serialize-qp "include_internal_events" $include_internal_events "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/trace/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stream
#
# GET /v1/workflows/executions/{execution_id}/stream
# operationId: stream_v1_workflows_executions__execution_id__stream_get
export def "workflows-executions-stream get" [
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-source: string
  --last-event-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event_source" $event_source "scalar") (serialize-qp "last_event_id" $last_event_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workflows/executions/($execution_id)/stream" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Workflow Metrics
#
# GET /v1/workflows/{workflow_name}/metrics
# operationId: get_workflow_metrics_v1_workflows__workflow_name__metrics_get
export def "workflows-metrics get" [
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # Filter workflows started after this time (ISO 8601)
  --end-time: string # Filter workflows started before this time (ISO 8601)
]: nothing -> record<execution_count: record<value: any>, success_count: record<value: any>, error_count: record<value: any>, average_latency_ms: record<value: any>, latency_over_time: record<value: list<list>>, retry_rate: record<value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workflows/($workflow_name)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Runs
#
# GET /v1/workflows/runs
# operationId: list_runs_v1_workflows_runs_get
export def "workflows-runs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-identifier: string # Filter by workflow name or id
  --search: string # Search by workflow name, display name or id
  --status: string # Filter by workflow status
  --page-size: int # Number of items per page (default: 50)
  --next-page-token: string # Token for the next page of results
]: nothing -> record<executions: table<workflow_name: string, execution_id: string, parent_execution_id: any, root_execution_id: string, status: any, start_time: string, end_time: any, total_duration_ms: any>, next_page_token: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_identifier" $workflow_identifier "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "next_page_token" $next_page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workflows/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Run
#
# GET /v1/workflows/runs/{run_id}
# operationId: get_run_v1_workflows_runs__run_id__get
export def "workflows-runs get" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflow_name: string, execution_id: string, parent_execution_id: any, root_execution_id: string, status: any, start_time: string, end_time: any, total_duration_ms: any, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/runs/($run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Run History
#
# GET /v1/workflows/runs/{run_id}/history
# operationId: get_run_history_v1_workflows_runs__run_id__history_get
export def "workflows-runs-history get" [
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --decode-payloads: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "decode_payloads" $decode_payloads "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workflows/runs/($run_id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Schedules
#
# GET /v1/workflows/schedules
# operationId: get_schedules_v1_workflows_schedules_get
export def "workflows-schedules get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedules: table<input: any, calendars: list, intervals: list, cron_expressions: list, skip: list, start_at: any, end_at: any, jitter: any, time_zone_name: any, policy: record, schedule_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workflows/schedules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedule Workflow
#
# POST /v1/workflows/schedules
# operationId: schedule_workflow_v1_workflows_schedules_post
# --schedule shape: {input: any, calendars?: list, intervals?: list, cron_expressions?: list, skip?: list, start_at?: any, end_at?: any, jitter?: any, time_zone_name?: any, policy?: record, schedule_id?: any}
@deprecated --flag workflow-task-queue
export def "workflows-schedules post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  schedule: record # Specification of the times scheduled actions may occur.  The times are the union of :py:attr:`calendars`, :py:attr:`intervals`, and :py:attr:`cron_expressions` excluding anything in :py:attr:`skip`.  Used for input where schedule_id is optional (can be provided or auto-generated). — shape: {input: any, calendars?: list, intervals?: list, cron_expressions?: list, skip?: list, start_at?: any, end_at?: any, jitter?: any, time_zone_name?: any, policy?: record, schedule_id?: any}
  --workflow-registration-id: any # The ID of the workflow registration to schedule
  --workflow-version-id: any # Deprecated: use workflow_registration_id
  --workflow-identifier: any # The name or ID of the workflow to schedule
  --workflow-task-queue: any # Deprecated. Use deployment_name instead. (DEPRECATED)
  --schedule-id: any # Allows you to specify a custom schedule ID. If not provided, a random ID will be generated.
  --deployment-name: any # Name of the deployment to route this schedule to
]: any -> record<schedule_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workflows/schedules")
  let body = {schedule: $schedule, workflow_registration_id: $workflow_registration_id, workflow_version_id: $workflow_version_id, workflow_identifier: $workflow_identifier, workflow_task_queue: $workflow_task_queue, schedule_id: $schedule_id, deployment_name: $deployment_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unschedule Workflow
#
# DELETE /v1/workflows/schedules/{schedule_id}
# operationId: unschedule_workflow_v1_workflows_schedules__schedule_id__delete
export def "workflows-schedules delete" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/schedules/($schedule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Worker Info
#
# GET /v1/workflows/workers/whoami
# operationId: get_worker_info_v1_workflows_workers_whoami_get
export def "workflows-workers-whoami get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<scheduler_url: string, namespace: string, tls: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/workflows/workers/whoami")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Stream Events
#
# GET /v1/workflows/events/stream
# operationId: get_stream_events_v1_workflows_events_stream_get
export def "workflows-events-stream get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # default: *
  --activity-name: string # default: *
  --activity-id: string # default: *
  --workflow-name: string # default: *
  --workflow-exec-id: string # default: *
  --root-workflow-exec-id: string # default: *
  --parent-workflow-exec-id: string # default: *
  --stream: string # default: *
  --start-seq: int # default: 0
  --metadata-filters: string
  --workflow-event-types: string
  --last-event-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "activity_name" $activity_name "scalar") (serialize-qp "activity_id" $activity_id "scalar") (serialize-qp "workflow_name" $workflow_name "scalar") (serialize-qp "workflow_exec_id" $workflow_exec_id "scalar") (serialize-qp "root_workflow_exec_id" $root_workflow_exec_id "scalar") (serialize-qp "parent_workflow_exec_id" $parent_workflow_exec_id "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "start_seq" $start_seq "scalar") (serialize-qp "metadata_filters" $metadata_filters "scalar") (serialize-qp "workflow_event_types" $workflow_event_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workflows/events/stream" $qp)
  let extra_headers = {"last-event-id": $last_event_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Workflow Events
#
# GET /v1/workflows/events/list
# operationId: get_workflow_events_v1_workflows_events_list_get
export def "workflows-events-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --root-workflow-exec-id: string # Execution ID of the root workflow that initiated this execution chain.
  --workflow-exec-id: string # Execution ID of the workflow that emitted this event.
  --workflow-run-id: string # Run ID of the workflow that emitted this event.
  --limit: int # Maximum number of events to return. (default: 100)
  --cursor: string # Cursor for pagination.
]: nothing -> record<events: list<any>, next_cursor: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "root_workflow_exec_id" $root_workflow_exec_id "scalar") (serialize-qp "workflow_exec_id" $workflow_exec_id "scalar") (serialize-qp "workflow_run_id" $workflow_run_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workflows/events/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Deployments
#
# GET /v1/workflows/deployments
# operationId: list_deployments_v1_workflows_deployments_get
export def "workflows-deployments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-only: oneof<nothing, bool> # default: true
  --workflow-name: string
]: nothing -> record<deployments: table<id: string, name: string, is_active: bool, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active_only" $active_only "scalar") (serialize-qp "workflow_name" $workflow_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workflows/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Deployment
#
# GET /v1/workflows/deployments/{name}
# operationId: get_deployment_v1_workflows_deployments__name__get
export def "workflows-deployments get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, is_active: bool, created_at: string, updated_at: string, workers: table<name: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/deployments/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Workflow Registrations
#
# GET /v1/workflows/registrations
# operationId: get_workflow_registrations_v1_workflows_registrations_get
export def "workflows-registrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-id: string # The workflow ID to filter by
  --task-queue: string # The task queue to filter by
  --active-only: oneof<nothing, bool> # Whether to only return active workflows versions (default: false)
  --include-shared: oneof<nothing, bool> # Whether to include shared workflow versions (default: true)
  --workflow-search: string # The workflow name to filter by
  --archived: string # Filter by archived state. False=exclude archived, True=only archived, None=include all
  --with-workflow: oneof<nothing, bool> # Whether to include the workflow definition (default: false)
  --available-in-chat-assistant: string # Whether to only return workflows compatible with chat assistant
  --limit: int # The maximum number of workflows versions to return (default: 50)
  --cursor: string # The cursor for pagination
]: nothing -> record<workflow_registrations: table<id: string, task_queue: string, definition: record, workflow_id: string, workflow: any, compatible_with_chat_assistant: bool>, next_cursor: any, workflow_versions: table<id: string, task_queue: string, definition: record, workflow_id: string, workflow: any, compatible_with_chat_assistant: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_id" $workflow_id "scalar") (serialize-qp "task_queue" $task_queue "scalar") (serialize-qp "active_only" $active_only "scalar") (serialize-qp "include_shared" $include_shared "scalar") (serialize-qp "workflow_search" $workflow_search "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "with_workflow" $with_workflow "scalar") (serialize-qp "available_in_chat_assistant" $available_in_chat_assistant "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workflows/registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute Workflow
#
# POST /v1/workflows/{workflow_identifier}/execute
# operationId: execute_workflow_v1_workflows__workflow_identifier__execute_post
@deprecated --flag task-queue
export def "workflows-execute post" [
  workflow_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --execution-id: any # Allows you to specify a custom execution ID. If not provided, a random ID will be generated.
  --input: any # The input to the workflow. This should be a dictionary that matches the workflow's input schema.
  --encoded-input: any # Encoded input to the workflow, used when payload encoding is enabled.
  --wait-for-result: oneof<nothing, bool> # If true, wait for the workflow to complete and return the result directly. (default: false)
  --timeout-seconds: any # Maximum time to wait for completion when wait_for_result is true.
  --custom-tracing-attributes: any
  --task-queue: any # Deprecated. Use deployment_name instead. (DEPRECATED)
  --deployment-name: any # Name of the deployment to route this execution to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/($workflow_identifier)/execute")
  let body = {execution_id: $execution_id, input: $input, encoded_input: $encoded_input, wait_for_result: $wait_for_result, timeout_seconds: $timeout_seconds, custom_tracing_attributes: $custom_tracing_attributes, task_queue: $task_queue, deployment_name: $deployment_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute Workflow Registration
#
# POST /v1/workflows/registrations/{workflow_registration_id}/execute
# DEPRECATED
# operationId: execute_workflow_registration_v1_workflows_registrations__workflow_registration_id__execute_post
@deprecated
@deprecated --flag task-queue
export def "workflows-registrations-execute post" [
  workflow_registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --execution-id: any # Allows you to specify a custom execution ID. If not provided, a random ID will be generated.
  --input: any # The input to the workflow. This should be a dictionary that matches the workflow's input schema.
  --encoded-input: any # Encoded input to the workflow, used when payload encoding is enabled.
  --wait-for-result: oneof<nothing, bool> # If true, wait for the workflow to complete and return the result directly. (default: false)
  --timeout-seconds: any # Maximum time to wait for completion when wait_for_result is true.
  --custom-tracing-attributes: any
  --task-queue: any # Deprecated. Use deployment_name instead. (DEPRECATED)
  --deployment-name: any # Name of the deployment to route this execution to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/registrations/($workflow_registration_id)/execute")
  let body = {execution_id: $execution_id, input: $input, encoded_input: $encoded_input, wait_for_result: $wait_for_result, timeout_seconds: $timeout_seconds, custom_tracing_attributes: $custom_tracing_attributes, task_queue: $task_queue, deployment_name: $deployment_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Workflow
#
# GET /v1/workflows/{workflow_identifier}
# operationId: get_workflow_v1_workflows__workflow_identifier__get
export def "workflows get" [
  workflow_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflow: record<id: string, name: string, display_name: string, type: string, description: any, customer_id: string, workspace_id: string, shared_namespace: any, available_in_chat_assistant: bool, is_technical: bool, archived: bool, active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/($workflow_identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Workflow
#
# PUT /v1/workflows/{workflow_identifier}
# operationId: update_workflow_v1_workflows__workflow_identifier__put
export def "workflows put" [
  workflow_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-name: any # New display name value
  --description: any # New description value
  --available-in-chat-assistant: any # Whether to make the workflow available in the chat assistant
]: any -> record<workflow: record<id: string, name: string, display_name: string, type: string, description: any, customer_id: string, workspace_id: string, shared_namespace: any, available_in_chat_assistant: bool, is_technical: bool, archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/($workflow_identifier)")
  let body = {display_name: $display_name, description: $description, available_in_chat_assistant: $available_in_chat_assistant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Workflow Registration
#
# GET /v1/workflows/registrations/{workflow_registration_id}
# operationId: get_workflow_registration_v1_workflows_registrations__workflow_registration_id__get
export def "workflows-registrations get" [
  workflow_registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-workflow: oneof<nothing, bool> # Whether to include the workflow definition (default: false)
  --include-shared: oneof<nothing, bool> # Whether to include shared workflow versions (default: true)
]: nothing -> record<workflow_registration: record<id: string, task_queue: string, definition: record<input_schema: record, output_schema: any, signals: list, queries: list, updates: list, enforce_determinism: bool, execution_timeout: float>, workflow_id: string, workflow: any, compatible_with_chat_assistant: bool, active: bool>, workflow_version: record<id: string, task_queue: string, definition: record<input_schema: record, output_schema: any, signals: list, queries: list, updates: list, enforce_determinism: bool, execution_timeout: float>, workflow_id: string, workflow: any, compatible_with_chat_assistant: bool, active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_workflow" $with_workflow "scalar") (serialize-qp "include_shared" $include_shared "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/workflows/registrations/($workflow_registration_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive Workflow
#
# PUT /v1/workflows/{workflow_identifier}/archive
# operationId: archive_workflow_v1_workflows__workflow_identifier__archive_put
export def "workflows-archive put" [
  workflow_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflow: record<id: string, name: string, display_name: string, type: string, description: any, customer_id: string, workspace_id: string, shared_namespace: any, available_in_chat_assistant: bool, is_technical: bool, archived: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/($workflow_identifier)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive Workflow
#
# PUT /v1/workflows/{workflow_identifier}/unarchive
# operationId: unarchive_workflow_v1_workflows__workflow_identifier__unarchive_put
export def "workflows-unarchive put" [
  workflow_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workflow: record<id: string, name: string, display_name: string, type: string, description: any, customer_id: string, workspace_id: string, shared_namespace: any, available_in_chat_assistant: bool, is_technical: bool, archived: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/($workflow_identifier)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new connector.
#
# POST /v1/connectors
# operationId: connector_create_v1
export def "connectors v1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the connector. Should be 64 char length maximum, alphanumeric, only underscores/dashes.
  description: string # The description of the connector.
  --icon-url: any # The optional url of the icon you want to associate to the connector.
  --visibility: string@visibility-completer
  server: string # The url of the MCP server. (format: uri)
  --headers: any # Optional organization-level headers to be sent with the request to the mcp server.
  --auth-data: any # Optional additional authentication data for the connector.
  --system-prompt: any # Optional system prompt for the connector.
]: any -> record<id: string, name: string, description: string, created_at: string, modified_at: string, server: any, auth_type: any, tools: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connectors")
  let body = {name: $name, description: $description, icon_url: $icon_url, visibility: $visibility, server: $server, headers: $headers, auth_data: $auth_data, system_prompt: $system_prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all connectors.
#
# GET /v1/connectors
# operationId: connector_list_v1
export def "connectors v1-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query-filters: record
  --cursor: string
  --page-size: int # default: 100
]: nothing -> record<items: table<id: string, name: string, description: string, created_at: string, modified_at: string, server: any, auth_type: any, tools: any>, pagination: record<next_cursor: any, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query_filters" $query_filters "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the auth URL for a connector.
#
# GET /v1/connectors/{connector_id_or_name}/auth_url
# operationId: connector_get_auth_url_v1
export def "connectors-auth-url v1" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-return-url: string
  --credentials-name: string
]: nothing -> record<auth_url: string, ttl: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_return_url" $app_return_url "scalar") (serialize-qp "credentials_name" $credentials_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/auth_url" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call Connector Tool
#
# POST /v1/connectors/{connector_id_or_name}/tools/{tool_name}/call
# operationId: connector_call_tool_v1
export def "connectors-tools-call v1" [
  tool_name: string
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --credentials-name: string
  --arguments: record
]: any -> record<content: list<any>, metadata: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "credentials_name" $credentials_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/tools/($tool_name)/call" $qp)
  let body = {arguments: $arguments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List tools for a connector.
#
# GET /v1/connectors/{connector_id_or_name}/tools
# operationId: connector_list_tools_v1
export def "connectors-tools v1" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --page-size: int # default: 100
  --refresh: oneof<nothing, bool> # default: false
  --pretty: oneof<nothing, bool> # Return a simplified payload with only name, description, annotations, and a compact inputSchema. (default: false)
  --credentials-name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "refresh" $refresh "scalar") (serialize-qp "pretty" $pretty "scalar") (serialize-qp "credentials_name" $credentials_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/tools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get authentication methods for a connector.
#
# GET /v1/connectors/{connector_id_or_name}/authentication_methods
# operationId: connector_get_authentication_methods_v1
export def "connectors-authentication-methods v1" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<method_type: string, headers: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/authentication_methods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organization credentials for a connector.
#
# GET /v1/connectors/{connector_id_or_name}/organization/credentials
# operationId: connector_list_organization_credentials_v1
export def "connectors-organization-credentials v1-by-connector_id_or_name" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-type: string
  --fetch-default: oneof<nothing, bool> # default: false
]: nothing -> record<credentials: table<name: string, authentication_type: string, is_default: bool>, connector_preset_credentials_for_auth: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auth_type" $auth_type "scalar") (serialize-qp "fetch_default" $fetch_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/organization/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update organization credentials for a connector.
#
# POST /v1/connectors/{connector_id_or_name}/organization/credentials
# operationId: connector_create_or_update_organization_credentials_v1
export def "connectors-organization-credentials v1-by-connector_id_or_name-1" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the credentials. Use this name to access or modify your credentials.
  --is-default: any # Controls whether this credential is the default for its auth method. On creation: if no credential exists yet for this auth method, the credential is automatically set as default when is_default is true or omitted; setting is_default to false is rejected because a default must exist. If other credentials already exist, setting is_default to true promotes this credential (demoting the previous default); false or omitted creates it as non-default. On update: true promotes this credential, false is rejected if it is currently the default (promote another credential first), omitted leaves the default status unchanged.
  --credentials: any # The credential data (headers, bearer_token).
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/organization/credentials")
  let body = {name: $name, is_default: $is_default, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List workspace credentials for a connector.
#
# GET /v1/connectors/{connector_id_or_name}/workspace/credentials
# operationId: connector_list_workspace_credentials_v1
export def "connectors-workspace-credentials v1-by-connector_id_or_name" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-type: string
  --fetch-default: oneof<nothing, bool> # default: false
]: nothing -> record<credentials: table<name: string, authentication_type: string, is_default: bool>, connector_preset_credentials_for_auth: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auth_type" $auth_type "scalar") (serialize-qp "fetch_default" $fetch_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/workspace/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update workspace credentials for a connector.
#
# POST /v1/connectors/{connector_id_or_name}/workspace/credentials
# operationId: connector_create_or_update_workspace_credentials_v1
export def "connectors-workspace-credentials v1-by-connector_id_or_name-1" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the credentials. Use this name to access or modify your credentials.
  --is-default: any # Controls whether this credential is the default for its auth method. On creation: if no credential exists yet for this auth method, the credential is automatically set as default when is_default is true or omitted; setting is_default to false is rejected because a default must exist. If other credentials already exist, setting is_default to true promotes this credential (demoting the previous default); false or omitted creates it as non-default. On update: true promotes this credential, false is rejected if it is currently the default (promote another credential first), omitted leaves the default status unchanged.
  --credentials: any # The credential data (headers, bearer_token).
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/workspace/credentials")
  let body = {name: $name, is_default: $is_default, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List user credentials for a connector.
#
# GET /v1/connectors/{connector_id_or_name}/user/credentials
# operationId: connector_list_user_credentials_v1
export def "connectors-user-credentials v1-by-connector_id_or_name" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-type: string
  --fetch-default: oneof<nothing, bool> # default: false
]: nothing -> record<credentials: table<name: string, authentication_type: string, is_default: bool>, connector_preset_credentials_for_auth: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "auth_type" $auth_type "scalar") (serialize-qp "fetch_default" $fetch_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/user/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update user credentials for a connector.
#
# POST /v1/connectors/{connector_id_or_name}/user/credentials
# operationId: connector_create_or_update_user_credentials_v1
export def "connectors-user-credentials v1-by-connector_id_or_name-1" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the credentials. Use this name to access or modify your credentials.
  --is-default: any # Controls whether this credential is the default for its auth method. On creation: if no credential exists yet for this auth method, the credential is automatically set as default when is_default is true or omitted; setting is_default to false is rejected because a default must exist. If other credentials already exist, setting is_default to true promotes this credential (demoting the previous default); false or omitted creates it as non-default. On update: true promotes this credential, false is rejected if it is currently the default (promote another credential first), omitted leaves the default status unchanged.
  --credentials: any # The credential data (headers, bearer_token).
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/user/credentials")
  let body = {name: $name, is_default: $is_default, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete organization credentials for a connector.
#
# DELETE /v1/connectors/{connector_id_or_name}/organization/credentials/{credentials_name}
# operationId: connector_delete_organization_credentials_v1
export def "connectors-organization-credentials v1-by-credentials_name-connector_id_or_name" [
  credentials_name: string
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/organization/credentials/($credentials_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete workspace credentials for a connector.
#
# DELETE /v1/connectors/{connector_id_or_name}/workspace/credentials/{credentials_name}
# operationId: connector_delete_workspace_credentials_v1
export def "connectors-workspace-credentials v1-by-credentials_name-connector_id_or_name" [
  credentials_name: string
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/workspace/credentials/($credentials_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user credentials for a connector.
#
# DELETE /v1/connectors/{connector_id_or_name}/user/credentials/{credentials_name}
# operationId: connector_delete_user_credentials_v1
export def "connectors-user-credentials v1-by-credentials_name-connector_id_or_name" [
  credentials_name: string
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)/user/credentials/($credentials_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a connector.
#
# GET /v1/connectors/{connector_id_or_name}#idOrName
# operationId: connector_get_v1
export def "connectors v1-by-connector_id_or_name" [
  connector_id_or_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fetch-customer-data: oneof<nothing, bool> # Fetch the customer data associated with the connector (e.g. customer secrets / config). (default: false)
  --fetch-connection-secrets: oneof<nothing, bool> # Fetch the general connection secrets associated with the connector. (default: false)
]: nothing -> record<id: string, name: string, description: string, created_at: string, modified_at: string, server: any, auth_type: any, tools: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fetch_customer_data" $fetch_customer_data "scalar") (serialize-qp "fetch_connection_secrets" $fetch_connection_secrets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/connectors/($connector_id_or_name)#idOrName" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a connector.
#
# PATCH /v1/connectors/{connector_id}#id
# operationId: connector_update_v1
export def "connectors v1-by-connector_id" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any # The name of the connector.
  --description: any # The description of the connector.
  --icon-url: any # The optional url of the icon you want to associate to the connector.
  --system-prompt: any # Optional system prompt for the connector.
  --connection-config: any # Optional new connection config.
  --connection-secrets: any # Optional new connection secrets
  --server: any # New server url for your mcp connector.
  --headers: any # New headers for your mcp connector.
  --auth-data: any # New authentication data for your mcp connector.
]: any -> record<id: string, name: string, description: string, created_at: string, modified_at: string, server: any, auth_type: any, tools: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id)#id")
  let body = {name: $name, description: $description, icon_url: $icon_url, system_prompt: $system_prompt, connection_config: $connection_config, connection_secrets: $connection_secrets, server: $server, headers: $headers, auth_data: $auth_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a connector.
#
# DELETE /v1/connectors/{connector_id}#id
# operationId: connector_delete_v1
export def "connectors v1-by-connector_id-1" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connectors/($connector_id)#id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
