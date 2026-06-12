# Auto-generated client for REST API v1.0.0
# Source: https://developers.deepgram.com/reference/openapi.json
# Auth: --token flag or $env.REST_API_TOKEN

const BASE_URL = "https://agent.deepgram.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://agent.deepgram.com" "https://api.deepgram.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def callback-method-completer [] { ["POST" "PUT"] }
def custom-topic-mode-completer [] { ["extended" "strict"] }
def custom-intent-mode-completer [] { ["extended" "strict"] }
def diarize-model-completer [] { ["latest" "v1" "v2"] }
def encoding-completer [] { ["amr-nb" "amr-wb" "flac" "g729" "linear16" "mulaw" "opus" "speex"] }
def model-completer [] { ["aura-2-alvaro-es" "aura-2-amalthea-en" "aura-2-andromeda-en" "aura-2-apollo-en" "aura-2-aquila-es" "aura-2-arcas-en" "aura-2-aries-en" "aura-2-asteria-en" "aura-2-athena-en" "aura-2-atlas-en" "aura-2-aurora-en" "aura-2-callista-en" "aura-2-carina-es" "aura-2-celeste-es" "aura-2-cora-en" "aura-2-cordelia-en" "aura-2-delia-en" "aura-2-diana-es" "aura-2-draco-en" "aura-2-electra-en" "aura-2-estrella-es" "aura-2-harmonia-en" "aura-2-helena-en" "aura-2-hera-en" "aura-2-hermes-en" "aura-2-hyperion-en" "aura-2-iris-en" "aura-2-janus-en" "aura-2-javier-es" "aura-2-juno-en" "aura-2-jupiter-en" "aura-2-luna-en" "aura-2-mars-en" "aura-2-minerva-en" "aura-2-neptune-en" "aura-2-nestor-es" "aura-2-odysseus-en" "aura-2-ophelia-en" "aura-2-orion-en" "aura-2-orpheus-en" "aura-2-pandora-en" "aura-2-phoebe-en" "aura-2-pluto-en" "aura-2-saturn-en" "aura-2-selena-es" "aura-2-selene-en" "aura-2-sirio-es" "aura-2-thalia-en" "aura-2-theia-en" "aura-2-vesta-en" "aura-2-zeus-en" "aura-angus-en" "aura-arcas-en" "aura-asteria-en" "aura-athena-en" "aura-helios-en" "aura-hera-en" "aura-luna-en" "aura-orion-en" "aura-orpheus-en" "aura-perseus-en" "aura-stella-en" "aura-zeus-en"] }
def status-completer [] { ["active" "expired"] }
def deployment-completer [] { ["beta" "hosted" "self-hosted"] }
def endpoint-completer [] { ["agent" "listen" "read" "speak"] }
def method-completer [] { ["async" "streaming" "sync"] }
def status-completer-1 [] { ["failed" "succeeded"] }
def grouping-completer [] { ["accessor" "deployment" "endpoint" "feature_set" "method" "models" "tags"] }
def provider-completer [] { ["quay"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "agent-settings-think-models list" } } | get name | first)
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

# List Agent Think Models
#
# GET /v1/agent/settings/think/models
# operationId: list
export def "agent-settings-think-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<models: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/agent/settings/think/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Agent Configuration
#
# POST /v1/projects/{project_id}/agents
# operationId: create
export def "projects-agents create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  config: string # A valid JSON string representing the agent block of a Settings message
  --metadata: record # A map of arbitrary key-value pairs for labeling or organizing the agent configuration
  --api-version: int # API version. Defaults to 1 (default: 1)
]: any -> record<agent_id: string, config: record, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agents")
  let body = {config: $config, metadata: $metadata, api_version: $api_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Agent Configurations
#
# GET /v1/projects/{project_id}/agents
# operationId: list
export def "projects-agents list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<agents: table<agent_id: string, config: record, metadata: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agents")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Agent Configuration
#
# GET /v1/projects/{project_id}/agents/{agent_id}
# operationId: get
export def "projects-agents get" [
  project_id: string
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<agent_id: string, config: record, metadata: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agents/($agent_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Agent Metadata
#
# PUT /v1/projects/{project_id}/agents/{agent_id}
# operationId: update
export def "projects-agents update" [
  project_id: string
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  metadata: record # A map of string key-value pairs to associate with this agent configuration
]: any -> record<agent_id: string, config: record, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agents/($agent_id)")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Agent Configuration
#
# DELETE /v1/projects/{project_id}/agents/{agent_id}
# operationId: delete
export def "projects-agents delete" [
  project_id: string
  agent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agents/($agent_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Agent Variable
#
# POST /v1/projects/{project_id}/agent-variables
# operationId: create
export def "projects-agent-variables create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  key: string # The variable name, following the DG_<VARIABLE_NAME> format
  value: any # The value to substitute. Can be any valid JSON type (string, number, boolean, object, or array)
  --api-version: int # API version. Defaults to 1 (default: 1)
]: any -> record<variable_id: string, key: string, value: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agent-variables")
  let body = {key: $key, value: $value, api_version: $api_version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Agent Variables
#
# GET /v1/projects/{project_id}/agent-variables
# operationId: list
export def "projects-agent-variables list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<variables: table<variable_id: string, key: string, value: any, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agent-variables")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Agent Variable
#
# GET /v1/projects/{project_id}/agent-variables/{variable_id}
# operationId: get
export def "projects-agent-variables get" [
  project_id: string
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<variable_id: string, key: string, value: any, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agent-variables/($variable_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Agent Variable
#
# PATCH /v1/projects/{project_id}/agent-variables/{variable_id}
# operationId: update
export def "projects-agent-variables update" [
  project_id: string
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  value: any # The new value to substitute
]: any -> record<variable_id: string, key: string, value: any, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agent-variables/($variable_id)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Agent Variable
#
# DELETE /v1/projects/{project_id}/agent-variables/{variable_id}
# operationId: delete
export def "projects-agent-variables delete" [
  project_id: string
  variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/agent-variables/($variable_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transcribe and analyze pre-recorded audio and video
#
# POST /v1/listen
# operationId: transcribe
export def "listen transcribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # URL to which we'll make the callback request
  --callback-method: string@callback-method-completer # HTTP method by which the callback request will be made (default: POST)
  --extra: string # Arbitrary key-value pairs that are attached to the API response for usage in downstream processing
  --sentiment: oneof<nothing, bool> # Recognizes the sentiment throughout a transcript or text (default: false)
  --summarize: string # Summarize content. For Listen API, supports string version option. For Read API, accepts boolean only.
  --tag: string # Label your requests for the purpose of identification during usage reporting
  --topics: oneof<nothing, bool> # Detect topics throughout a transcript or text (default: false)
  --custom-topic: string # Custom topics you want the model to detect within your input audio or text if present Submit up to `100`.
  --custom-topic-mode: string@custom-topic-mode-completer # Sets how the model will interpret strings submitted to the `custom_topic` param. When `strict`, the model will only return topics submitted using the `custom_topic` param. When `extended`, the model will return its own detected topics in addition to those submitted using the `custom_topic` param (default: extended)
  --intents: oneof<nothing, bool> # Recognizes speaker intent throughout a transcript or text (default: false)
  --custom-intent: string # Custom intents you want the model to detect within your input audio if present
  --custom-intent-mode: string@custom-intent-mode-completer # Sets how the model will interpret intents submitted to the `custom_intent` param. When `strict`, the model will only return intents submitted using the `custom_intent` param. When `extended`, the model will return its own detected intents in the `custom_intent` param. (default: extended)
  --detect-entities: oneof<nothing, bool> # Identifies and extracts key entities from content in submitted audio (default: false)
  --detect-language: string # Identifies the dominant language spoken in submitted audio
  --diarize: oneof<nothing, bool> # Deprecated: use `diarize_model` instead. Recognize speaker changes. Each word in the transcript will be assigned a speaker number starting at 0. (default: false)
  --diarize-model: string@diarize-model-completer # Select and enable a specific diarization model version. Specifying this parameter enables diarization and selects the model — you do not need to also set the deprecated `diarize=true` parameter. For batch, supported values are `latest` (currently v2), `v1`, and `v2`. For streaming, supported values are `latest` (currently v1) and `v1`; `v2` returns a validation error on streaming requests.
  --dictation: oneof<nothing, bool> # Dictation mode for controlling formatting with dictated speech (default: false)
  --encoding: string@encoding-completer # Specify the expected encoding of your submitted audio
  --filler-words: oneof<nothing, bool> # Filler Words can help transcribe interruptions in your audio, like "uh" and "um" (default: false)
  --keyterm: list # Key term prompting can boost or suppress specialized terminology and brands. Only compatible with Nova-3
  --keywords: string # Keywords can boost or suppress specialized terminology and brands
  --language: string # The [BCP-47 language tag](https://tools.ietf.org/html/bcp47) that hints at the primary spoken language. Depending on the Model and API endpoint you choose only certain languages are available (default: en)
  --measurements: oneof<nothing, bool> # Spoken measurements will be converted to their corresponding abbreviations (default: false)
  --model: string # AI model used to process submitted audio
  --multichannel: oneof<nothing, bool> # Transcribe each audio channel independently (default: false)
  --numerals: oneof<nothing, bool> # Numerals converts numbers from written format to numerical format (default: false)
  --paragraphs: oneof<nothing, bool> # Splits audio into paragraphs to improve transcript readability (default: false)
  --profanity-filter: oneof<nothing, bool> # Profanity Filter looks for recognized profanity and converts it to the nearest recognized non-profane word or removes it from the transcript completely (default: false)
  --punctuate: oneof<nothing, bool> # Add punctuation and capitalization to the transcript (default: false)
  --redact: string # Redaction removes sensitive information from your transcripts
  --replace: string # Search for terms or phrases in submitted audio and replaces them
  --search: string # Search for terms or phrases in submitted audio
  --smart-format: oneof<nothing, bool> # Apply formatting to transcript output. When set to true, additional formatting will be applied to transcripts to improve readability (default: false)
  --utterances: oneof<nothing, bool> # Segments speech into meaningful semantic units (default: false)
  --utt-split: float # Seconds to wait before detecting a pause between words in submitted audio (format: double, default: 0.8)
  --version: string # Version of an AI model to use
  --mip-opt-out: oneof<nothing, bool> # Opts out requests from the Deepgram Model Improvement Program. Refer to our Docs for pricing impacts before setting this to true. https://dpgr.am/deepgram-mip (default: false)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  --body-url: string # format: uri
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "callback_method" $callback_method "scalar") (serialize-qp "extra" $extra "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "topics" $topics "scalar") (serialize-qp "custom_topic" $custom_topic "scalar") (serialize-qp "custom_topic_mode" $custom_topic_mode "scalar") (serialize-qp "intents" $intents "scalar") (serialize-qp "custom_intent" $custom_intent "scalar") (serialize-qp "custom_intent_mode" $custom_intent_mode "scalar") (serialize-qp "detect_entities" $detect_entities "scalar") (serialize-qp "detect_language" $detect_language "scalar") (serialize-qp "diarize" $diarize "scalar") (serialize-qp "diarize_model" $diarize_model "scalar") (serialize-qp "dictation" $dictation "scalar") (serialize-qp "encoding" $encoding "scalar") (serialize-qp "filler_words" $filler_words "scalar") (serialize-qp "keyterm" $keyterm "multi") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "measurements" $measurements "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "multichannel" $multichannel "scalar") (serialize-qp "numerals" $numerals "scalar") (serialize-qp "paragraphs" $paragraphs "scalar") (serialize-qp "profanity_filter" $profanity_filter "scalar") (serialize-qp "punctuate" $punctuate "scalar") (serialize-qp "redact" $redact "scalar") (serialize-qp "replace" $replace "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "smart_format" $smart_format "scalar") (serialize-qp "utterances" $utterances "scalar") (serialize-qp "utt_split" $utt_split "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "mip_opt_out" $mip_opt_out "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/listen" $qp)
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Text to Speech transformation
#
# POST /v1/speak
# operationId: generate
export def "speak generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # URL to which we'll make the callback request
  --callback-method: string@callback-method-completer # HTTP method by which the callback request will be made (default: POST)
  --mip-opt-out: oneof<nothing, bool> # Opts out requests from the Deepgram Model Improvement Program. Refer to our Docs for pricing impacts before setting this to true. https://dpgr.am/deepgram-mip (default: false)
  --tag: string # Label your requests for the purpose of identification during usage reporting
  --bit-rate: string # The bitrate of the audio in bits per second. Choose from predefined ranges or specific values based on the encoding type.
  --container: string # Container specifies the file format wrapper for the output audio. The available options depend on the encoding type.
  --encoding: string # Encoding allows you to specify the expected encoding of your audio output
  --model: string@model-completer # AI model used to process submitted text (default: aura-asteria-en)
  --sample-rate: string # Sample Rate specifies the sample rate for the output audio. Based on the encoding, different sample rates are supported. For some encodings, the sample rate is not configurable
  --speed: float # Speaking rate multiplier that adjusts the pace of generated speech while preserving natural prosody and voice quality. Not yet supported in all languages. (format: double, default: 1)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  text: string # The text content to be converted to speech
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "callback_method" $callback_method "scalar") (serialize-qp "mip_opt_out" $mip_opt_out "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "bit_rate" $bit_rate "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "encoding" $encoding "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "sample_rate" $sample_rate "scalar") (serialize-qp "speed" $speed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/speak" $qp)
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Analyze text content
#
# POST /v1/read
# operationId: analyze
export def "read analyze" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # URL to which we'll make the callback request
  --callback-method: string@callback-method-completer # HTTP method by which the callback request will be made (default: POST)
  --sentiment: oneof<nothing, bool> # Recognizes the sentiment throughout a transcript or text (default: false)
  --summarize: string # Summarize content. For Listen API, supports string version option. For Read API, accepts boolean only.
  --tag: string # Label your requests for the purpose of identification during usage reporting
  --topics: oneof<nothing, bool> # Detect topics throughout a transcript or text (default: false)
  --custom-topic: string # Custom topics you want the model to detect within your input audio or text if present Submit up to `100`.
  --custom-topic-mode: string@custom-topic-mode-completer # Sets how the model will interpret strings submitted to the `custom_topic` param. When `strict`, the model will only return topics submitted using the `custom_topic` param. When `extended`, the model will return its own detected topics in addition to those submitted using the `custom_topic` param (default: extended)
  --intents: oneof<nothing, bool> # Recognizes speaker intent throughout a transcript or text (default: false)
  --custom-intent: string # Custom intents you want the model to detect within your input audio if present
  --custom-intent-mode: string@custom-intent-mode-completer # Sets how the model will interpret intents submitted to the `custom_intent` param. When `strict`, the model will only return intents submitted using the `custom_intent` param. When `extended`, the model will return its own detected intents in the `custom_intent` param. (default: extended)
  --language: string # The [BCP-47 language tag](https://tools.ietf.org/html/bcp47) that hints at the primary spoken language. Depending on the Model and API endpoint you choose only certain languages are available (default: en)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  --body-url: string # A URL pointing to the text source (format: uri)
  --text: string # The plain text to analyze
]: any -> record<metadata: record<metadata: record<request_id: string, created: string, language: string, summary_info: record, sentiment_info: record, topics_info: record, intents_info: record>>, results: record<summary: record<results: record>, topics: record<results: record>, intents: record<results: record>, sentiments: record<segments: list, average: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "callback_method" $callback_method "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "topics" $topics "scalar") (serialize-qp "custom_topic" $custom_topic "scalar") (serialize-qp "custom_topic_mode" $custom_topic_mode "scalar") (serialize-qp "intents" $intents "scalar") (serialize-qp "custom_intent" $custom_intent "scalar") (serialize-qp "custom_intent_mode" $custom_intent_mode "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/read" $qp)
  let body = {url: $body_url, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Projects
#
# GET /v1/projects
# operationId: list
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<projects: table<project_id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/projects")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Project
#
# GET /v1/projects/{project_id}
# operationId: get
export def "projects get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Number of results to return per page. Default 10. Range [1,1000] (format: double, default: 10)
  --page: float # Navigate and return the results to retrieve specific portions of information of the response (format: double)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<project_id: string, mip_opt_out: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Project
#
# PATCH /v1/projects/{project_id}
# operationId: update
export def "projects update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  --name: string # The name of the project
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Project
#
# DELETE /v1/projects/{project_id}
# operationId: delete
export def "projects delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Leave a Project
#
# DELETE /v1/projects/{project_id}/leave
# operationId: leave
export def "projects-leave leave" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/leave")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Models
#
# GET /v1/projects/{project_id}/models
# operationId: list
export def "projects-models list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outdated: oneof<nothing, bool> # returns non-latest versions of models
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<stt: table<name: string, canonical_name: string, architecture: string, languages: list, version: string, uuid: string, batch: bool, streaming: bool, formatted_output: bool>, tts: table<name: string, canonical_name: string, architecture: string, languages: list, version: string, uuid: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_outdated" $include_outdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/models" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Project Model
#
# GET /v1/projects/{project_id}/models/{model_id}
# operationId: get
export def "projects-models get" [
  project_id: string
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/models/($model_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outdated: oneof<nothing, bool> # returns non-latest versions of models
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<stt: table<name: string, canonical_name: string, architecture: string, languages: list, version: string, uuid: string, batch: bool, streaming: bool, formatted_output: bool>, tts: table<name: string, canonical_name: string, architecture: string, languages: list, version: string, uuid: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_outdated" $include_outdated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/models" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Model
#
# GET /v1/models/{model_id}
# operationId: get
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
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/models/($model_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Keys
#
# GET /v1/projects/{project_id}/keys
# operationId: list
export def "projects-keys list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Only return keys with a specific status
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<api_keys: table<member: record, api_key: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/keys" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Project Key
#
# POST /v1/projects/{project_id}/keys
# operationId: create
export def "projects-keys create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  --body: record
]: any -> record<api_key_id: string, key: string, comment: string, scopes: list<string>, tags: list<string>, expiration_date: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/keys")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Project Key
#
# GET /v1/projects/{project_id}/keys/{key_id}
# operationId: get
export def "projects-keys get" [
  project_id: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<item: record<member: record<member_id: string, email: string, first_name: string, last_name: string, api_key: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/keys/($key_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Project Key
#
# DELETE /v1/projects/{project_id}/keys/{key_id}
# operationId: delete
export def "projects-keys delete" [
  project_id: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/keys/($key_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Members
#
# GET /v1/projects/{project_id}/members
# operationId: list
export def "projects-members list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<members: table<member_id: string, scopes: list, email: string, first_name: string, last_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/members")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Project Member
#
# DELETE /v1/projects/{project_id}/members/{member_id}
# operationId: delete
export def "projects-members delete" [
  project_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/members/($member_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Member Scopes
#
# GET /v1/projects/{project_id}/members/{member_id}/scopes
# operationId: list
export def "projects-members-scopes list" [
  project_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<scopes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/members/($member_id)/scopes")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Project Member Scopes
#
# PUT /v1/projects/{project_id}/members/{member_id}/scopes
# operationId: update
export def "projects-members-scopes update" [
  project_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  scope: string # A scope to update
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/members/($member_id)/scopes")
  let body = {scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Project Invites
#
# GET /v1/projects/{project_id}/invites
# operationId: list
export def "projects-invites list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<invites: table<email: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/invites")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Project Invite
#
# POST /v1/projects/{project_id}/invites
# operationId: create
export def "projects-invites create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  email: string # The email address of the invitee
  scope: string # The scope of the invitee
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/invites")
  let body = {email: $email, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Project Invite
#
# DELETE /v1/projects/{project_id}/invites/{email}
# operationId: delete
export def "projects-invites delete" [
  project_id: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/invites/($email)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Requests
#
# GET /v1/projects/{project_id}/requests
# operationId: list
export def "projects-requests list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date of the requested date range. Formats accepted are YYYY-MM-DD, YYYY-MM-DDTHH:MM:SS, or YYYY-MM-DDTHH:MM:SS+HH:MM (format: date-time)
  --end: string # End date of the requested date range. Formats accepted are YYYY-MM-DD, YYYY-MM-DDTHH:MM:SS, or YYYY-MM-DDTHH:MM:SS+HH:MM (format: date-time)
  --limit: float # Number of results to return per page. Default 10. Range [1,1000] (format: double, default: 10)
  --page: float # Navigate and return the results to retrieve specific portions of information of the response (format: double)
  --accessor: string # Filter for requests where a specific accessor was used
  --request-id: string # Filter for a specific request id
  --deployment: string@deployment-completer # Filter for requests where a specific deployment was used
  --endpoint: string@endpoint-completer # Filter for requests where a specific endpoint was used
  --method: string@method-completer # Filter for requests where a specific method was used
  --status: string@status-completer-1 # Filter for requests that succeeded (status code < 300) or failed (status code >=400)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<page: float, limit: float, requests: table<request_id: string, project_uuid: string, created: string, path: string, api_key_id: string, response: record, code: float, deployment: string, callback: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "accessor" $accessor "scalar") (serialize-qp "request_id" $request_id "scalar") (serialize-qp "deployment" $deployment "scalar") (serialize-qp "endpoint" $endpoint "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/requests" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Project Request
#
# GET /v1/projects/{project_id}/requests/{request_id}
# operationId: get
export def "projects-requests get" [
  project_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<request: record<request_id: string, project_uuid: string, created: string, path: string, api_key_id: string, response: record, code: float, deployment: string, callback: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/requests/($request_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Usage
#
# GET /v1/projects/{project_id}/usage
# operationId: get
export def "projects-usage get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --end: string # End date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --accessor: string # Filter for requests where a specific accessor was used
  --alternatives: oneof<nothing, bool> # Filter for requests where alternatives were used
  --callback-method: oneof<nothing, bool> # Filter for requests where callback method was used
  --callback: oneof<nothing, bool> # Filter for requests where callback was used
  --channels: oneof<nothing, bool> # Filter for requests where channels were used
  --custom-intent-mode: oneof<nothing, bool> # Filter for requests where custom intent mode was used
  --custom-intent: oneof<nothing, bool> # Filter for requests where custom intent was used
  --custom-topic-mode: oneof<nothing, bool> # Filter for requests where custom topic mode was used
  --custom-topic: oneof<nothing, bool> # Filter for requests where custom topic was used
  --deployment: string@deployment-completer # Filter for requests where a specific deployment was used
  --detect-entities: oneof<nothing, bool> # Filter for requests where detect entities was used
  --detect-language: oneof<nothing, bool> # Filter for requests where detect language was used
  --diarize: oneof<nothing, bool> # Filter for requests where diarize was used
  --dictation: oneof<nothing, bool> # Filter for requests where dictation was used
  --encoding: oneof<nothing, bool> # Filter for requests where encoding was used
  --endpoint: string@endpoint-completer # Filter for requests where a specific endpoint was used
  --extra: oneof<nothing, bool> # Filter for requests where extra was used
  --filler-words: oneof<nothing, bool> # Filter for requests where filler words was used
  --intents: oneof<nothing, bool> # Filter for requests where intents was used
  --keyterm: oneof<nothing, bool> # Filter for requests where keyterm was used
  --keywords: oneof<nothing, bool> # Filter for requests where keywords was used
  --language: oneof<nothing, bool> # Filter for requests where language was used
  --measurements: oneof<nothing, bool> # Filter for requests where measurements were used
  --method: string@method-completer # Filter for requests where a specific method was used
  --model: string # Filter for requests where a specific model uuid was used
  --multichannel: oneof<nothing, bool> # Filter for requests where multichannel was used
  --numerals: oneof<nothing, bool> # Filter for requests where numerals were used
  --paragraphs: oneof<nothing, bool> # Filter for requests where paragraphs were used
  --profanity-filter: oneof<nothing, bool> # Filter for requests where profanity filter was used
  --punctuate: oneof<nothing, bool> # Filter for requests where punctuate was used
  --redact: oneof<nothing, bool> # Filter for requests where redact was used
  --replace: oneof<nothing, bool> # Filter for requests where replace was used
  --sample-rate: oneof<nothing, bool> # Filter for requests where sample rate was used
  --search: oneof<nothing, bool> # Filter for requests where search was used
  --sentiment: oneof<nothing, bool> # Filter for requests where sentiment was used
  --smart-format: oneof<nothing, bool> # Filter for requests where smart format was used
  --summarize: oneof<nothing, bool> # Filter for requests where summarize was used
  --tag: string # Filter for requests where a specific tag was used
  --topics: oneof<nothing, bool> # Filter for requests where topics was used
  --utt-split: oneof<nothing, bool> # Filter for requests where utt split was used
  --utterances: oneof<nothing, bool> # Filter for requests where utterances was used
  --version: oneof<nothing, bool> # Filter for requests where version was used
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<start: string, end: string, resolution: record<units: string, amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "accessor" $accessor "scalar") (serialize-qp "alternatives" $alternatives "scalar") (serialize-qp "callback_method" $callback_method "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "channels" $channels "scalar") (serialize-qp "custom_intent_mode" $custom_intent_mode "scalar") (serialize-qp "custom_intent" $custom_intent "scalar") (serialize-qp "custom_topic_mode" $custom_topic_mode "scalar") (serialize-qp "custom_topic" $custom_topic "scalar") (serialize-qp "deployment" $deployment "scalar") (serialize-qp "detect_entities" $detect_entities "scalar") (serialize-qp "detect_language" $detect_language "scalar") (serialize-qp "diarize" $diarize "scalar") (serialize-qp "dictation" $dictation "scalar") (serialize-qp "encoding" $encoding "scalar") (serialize-qp "endpoint" $endpoint "scalar") (serialize-qp "extra" $extra "scalar") (serialize-qp "filler_words" $filler_words "scalar") (serialize-qp "intents" $intents "scalar") (serialize-qp "keyterm" $keyterm "scalar") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "measurements" $measurements "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "multichannel" $multichannel "scalar") (serialize-qp "numerals" $numerals "scalar") (serialize-qp "paragraphs" $paragraphs "scalar") (serialize-qp "profanity_filter" $profanity_filter "scalar") (serialize-qp "punctuate" $punctuate "scalar") (serialize-qp "redact" $redact "scalar") (serialize-qp "replace" $replace "scalar") (serialize-qp "sample_rate" $sample_rate "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "smart_format" $smart_format "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "topics" $topics "scalar") (serialize-qp "utt_split" $utt_split "scalar") (serialize-qp "utterances" $utterances "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/usage" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Usage Fields
#
# GET /v1/projects/{project_id}/usage/fields
# operationId: list
export def "projects-usage-fields list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --end: string # End date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<tags: list<string>, models: table<name: string, language: string, version: string, model_id: string>, processing_methods: list<string>, features: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/usage/fields" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Usage Breakdown
#
# GET /v1/projects/{project_id}/usage/breakdown
# operationId: get
export def "projects-usage-breakdown get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --end: string # End date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --grouping: string@grouping-completer # Common usage grouping parameters
  --accessor: string # Filter for requests where a specific accessor was used
  --alternatives: oneof<nothing, bool> # Filter for requests where alternatives were used
  --callback-method: oneof<nothing, bool> # Filter for requests where callback method was used
  --callback: oneof<nothing, bool> # Filter for requests where callback was used
  --channels: oneof<nothing, bool> # Filter for requests where channels were used
  --custom-intent-mode: oneof<nothing, bool> # Filter for requests where custom intent mode was used
  --custom-intent: oneof<nothing, bool> # Filter for requests where custom intent was used
  --custom-topic-mode: oneof<nothing, bool> # Filter for requests where custom topic mode was used
  --custom-topic: oneof<nothing, bool> # Filter for requests where custom topic was used
  --deployment: string@deployment-completer # Filter for requests where a specific deployment was used
  --detect-entities: oneof<nothing, bool> # Filter for requests where detect entities was used
  --detect-language: oneof<nothing, bool> # Filter for requests where detect language was used
  --diarize: oneof<nothing, bool> # Filter for requests where diarize was used
  --dictation: oneof<nothing, bool> # Filter for requests where dictation was used
  --encoding: oneof<nothing, bool> # Filter for requests where encoding was used
  --endpoint: string@endpoint-completer # Filter for requests where a specific endpoint was used
  --extra: oneof<nothing, bool> # Filter for requests where extra was used
  --filler-words: oneof<nothing, bool> # Filter for requests where filler words was used
  --intents: oneof<nothing, bool> # Filter for requests where intents was used
  --keyterm: oneof<nothing, bool> # Filter for requests where keyterm was used
  --keywords: oneof<nothing, bool> # Filter for requests where keywords was used
  --language: oneof<nothing, bool> # Filter for requests where language was used
  --measurements: oneof<nothing, bool> # Filter for requests where measurements were used
  --method: string@method-completer # Filter for requests where a specific method was used
  --model: string # Filter for requests where a specific model uuid was used
  --multichannel: oneof<nothing, bool> # Filter for requests where multichannel was used
  --numerals: oneof<nothing, bool> # Filter for requests where numerals were used
  --paragraphs: oneof<nothing, bool> # Filter for requests where paragraphs were used
  --profanity-filter: oneof<nothing, bool> # Filter for requests where profanity filter was used
  --punctuate: oneof<nothing, bool> # Filter for requests where punctuate was used
  --redact: oneof<nothing, bool> # Filter for requests where redact was used
  --replace: oneof<nothing, bool> # Filter for requests where replace was used
  --sample-rate: oneof<nothing, bool> # Filter for requests where sample rate was used
  --search: oneof<nothing, bool> # Filter for requests where search was used
  --sentiment: oneof<nothing, bool> # Filter for requests where sentiment was used
  --smart-format: oneof<nothing, bool> # Filter for requests where smart format was used
  --summarize: oneof<nothing, bool> # Filter for requests where summarize was used
  --tag: string # Filter for requests where a specific tag was used
  --topics: oneof<nothing, bool> # Filter for requests where topics was used
  --utt-split: oneof<nothing, bool> # Filter for requests where utt split was used
  --utterances: oneof<nothing, bool> # Filter for requests where utterances was used
  --version: oneof<nothing, bool> # Filter for requests where version was used
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<start: string, end: string, resolution: record<units: string, amount: float>, results: table<hours: float, total_hours: float, agent_hours: float, tokens_in: float, tokens_out: float, tts_characters: float, requests: float, grouping: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "grouping" $grouping "scalar") (serialize-qp "accessor" $accessor "scalar") (serialize-qp "alternatives" $alternatives "scalar") (serialize-qp "callback_method" $callback_method "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "channels" $channels "scalar") (serialize-qp "custom_intent_mode" $custom_intent_mode "scalar") (serialize-qp "custom_intent" $custom_intent "scalar") (serialize-qp "custom_topic_mode" $custom_topic_mode "scalar") (serialize-qp "custom_topic" $custom_topic "scalar") (serialize-qp "deployment" $deployment "scalar") (serialize-qp "detect_entities" $detect_entities "scalar") (serialize-qp "detect_language" $detect_language "scalar") (serialize-qp "diarize" $diarize "scalar") (serialize-qp "dictation" $dictation "scalar") (serialize-qp "encoding" $encoding "scalar") (serialize-qp "endpoint" $endpoint "scalar") (serialize-qp "extra" $extra "scalar") (serialize-qp "filler_words" $filler_words "scalar") (serialize-qp "intents" $intents "scalar") (serialize-qp "keyterm" $keyterm "scalar") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "measurements" $measurements "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "multichannel" $multichannel "scalar") (serialize-qp "numerals" $numerals "scalar") (serialize-qp "paragraphs" $paragraphs "scalar") (serialize-qp "profanity_filter" $profanity_filter "scalar") (serialize-qp "punctuate" $punctuate "scalar") (serialize-qp "redact" $redact "scalar") (serialize-qp "replace" $replace "scalar") (serialize-qp "sample_rate" $sample_rate "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "smart_format" $smart_format "scalar") (serialize-qp "summarize" $summarize "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "topics" $topics "scalar") (serialize-qp "utt_split" $utt_split "scalar") (serialize-qp "utterances" $utterances "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/usage/breakdown" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Balances
#
# GET /v1/projects/{project_id}/balances
# operationId: list
export def "projects-balances list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<balances: table<balance_id: string, amount: float, units: string, purchase_order_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/balances")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Project Balance
#
# GET /v1/projects/{project_id}/balances/{balance_id}
# operationId: get
export def "projects-balances get" [
  project_id: string
  balance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<balance_id: string, amount: float, units: string, purchase_order_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/balances/($balance_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project Billing Breakdown
#
# GET /v1/projects/{project_id}/billing/breakdown
# operationId: list
export def "projects-billing-breakdown list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --end: string # End date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --accessor: string # Filter for requests where a specific accessor was used
  --deployment: string@deployment-completer # Filter for requests where a specific deployment was used
  --tag: string # Filter for requests where a specific tag was used
  --line-item: string # Filter requests by line item (e.g. streaming::nova-3)
  --grouping: list # Group billing breakdown by one or more dimensions (accessor, deployment, line_item, tags)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<start: string, end: string, resolution: record<units: string, amount: float>, results: table<dollars: float, grouping: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "accessor" $accessor "scalar") (serialize-qp "deployment" $deployment "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "line_item" $line_item "scalar") (serialize-qp "grouping" $grouping "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/billing/breakdown" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Billing Fields
#
# GET /v1/projects/{project_id}/billing/fields
# operationId: list
export def "projects-billing-fields list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Start date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --end: string # End date of the requested date range. Format accepted is YYYY-MM-DD (format: date)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<accessors: list<string>, deployments: list<string>, tags: list<string>, line_items: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/billing/fields" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Purchases
#
# GET /v1/projects/{project_id}/purchases
# operationId: list
export def "projects-purchases list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Number of results to return per page. Default 10. Range [1,1000] (format: double, default: 10)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<orders: table<order_id: string, expiration: string, created: string, amount: float, units: string, order_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/purchases" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Project Self-Hosted Distribution Credentials
#
# GET /v1/projects/{project_id}/self-hosted/distribution/credentials
# operationId: list
export def "projects-self-hosted-distribution-credentials list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<distribution_credentials: table<member: record, distribution_credentials: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/self-hosted/distribution/credentials")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Project Self-Hosted Distribution Credential
#
# POST /v1/projects/{project_id}/self-hosted/distribution/credentials
# operationId: create
export def "projects-self-hosted-distribution-credentials create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scopes: list # List of permission scopes for the credentials (default: [self-hosted:products])
  --provider: string@provider-completer # The provider of the distribution service (default: quay)
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  --comment: string # Optional comment about the credentials
]: any -> record<member: record<member_id: string, email: string>, distribution_credentials: record<distribution_credentials_id: string, provider: string, comment: string, scopes: list<string>, created: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopes" $scopes "multi") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($project_id)/self-hosted/distribution/credentials" $qp)
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Project Self-Hosted Distribution Credential
#
# GET /v1/projects/{project_id}/self-hosted/distribution/credentials/{distribution_credentials_id}
# operationId: get
export def "projects-self-hosted-distribution-credentials get" [
  project_id: string
  distribution_credentials_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<member: record<member_id: string, email: string>, distribution_credentials: record<distribution_credentials_id: string, provider: string, comment: string, scopes: list<string>, created: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/self-hosted/distribution/credentials/($distribution_credentials_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Project Self-Hosted Distribution Credential
#
# DELETE /v1/projects/{project_id}/self-hosted/distribution/credentials/{distribution_credentials_id}
# operationId: delete
export def "projects-self-hosted-distribution-credentials delete" [
  project_id: string
  distribution_credentials_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
]: nothing -> record<member: record<member_id: string, email: string>, distribution_credentials: record<distribution_credentials_id: string, provider: string, comment: string, scopes: list<string>, created: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($project_id)/self-hosted/distribution/credentials/($distribution_credentials_id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Token-based Authentication
#
# POST /v1/auth/grant
# operationId: grant
export def "auth-grant grant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Use `Authorization: Token <API_KEY>` Example: `Authorization: Token 12345abcdef`
  --ttl-seconds: float # Time to live in seconds for the token. Defaults to 30 seconds. (format: double)
]: any -> record<access_token: string, expires_in: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/auth/grant")
  let body = {ttl_seconds: $ttl_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
