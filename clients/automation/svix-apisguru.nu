# Auto-generated client for Svix API v1.4
# Source: https://api.apis.guru/v2/specs/svix.com/1.4/openapi.json
# Auth: --token flag or $env.SVIX_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SVIX_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["0" "1" "2" "3"] }
def status-code-class-completer [] { ["0" "100" "200" "300" "400" "500"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app list" } } | get name | first)
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

# List Applications
#
# GET /api/v1/app/
# operationId: list_applications_api_v1_app__get
export def "app list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. app_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --order: string # default: descending
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/app/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Application
#
# POST /api/v1/app/
# operationId: create_application_api_v1_app__post
export def "app post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --get-if-exists: oneof<nothing, bool> # Get an existing application, or create a new one if doesn't exist. It's two separate functions in the libs. (default: false)
  --idempotency-key: string # The request's idempotency key
  --metadata: record # nullable
  name: string # e.g. My first application
  --rateLimit: int # nullable, e.g. 1000
  --uid: string # Optional unique identifier for the application (nullable, e.g. unique-app-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "get_if_exists" $get_if_exists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/app/" $qp)
  let body = {metadata: $metadata, name: $name, rateLimit: $rateLimit, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Application
#
# DELETE /api/v1/app/{app_id}/
# operationId: delete_application_api_v1_app__app_id___delete
export def "app delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Application
#
# GET /api/v1/app/{app_id}/
# operationId: get_application_api_v1_app__app_id___get
export def "app get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Application
#
# PUT /api/v1/app/{app_id}/
# operationId: update_application_api_v1_app__app_id___put
export def "app put" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --metadata: record # nullable
  name: string # e.g. My first application
  --rateLimit: int # nullable, e.g. 1000
  --uid: string # Optional unique identifier for the application (nullable, e.g. unique-app-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/")
  let body = {metadata: $metadata, name: $name, rateLimit: $rateLimit, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Attempts By Endpoint
#
# GET /api/v1/app/{app_id}/attempt/endpoint/{endpoint_id}/
# operationId: list_attempts_by_endpoint_api_v1_app__app_id__attempt_endpoint__endpoint_id___get
export def "app-attempt-endpoint get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --status: int@status-completer
  --status-code-class: int@status-code-class-completer
  --event-types: list # nullable
  --channel: string # nullable, e.g. project_1337
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status_code_class" $status_code_class "scalar") (serialize-qp "event_types" $event_types "multi") (serialize-qp "channel" $channel "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/attempt/endpoint/($endpoint_id)/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Attempts By Msg
#
# GET /api/v1/app/{app_id}/attempt/msg/{msg_id}/
# operationId: list_attempts_by_msg_api_v1_app__app_id__attempt_msg__msg_id___get
export def "app-attempt-msg get" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-id: string # nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --status: int@status-completer
  --status-code-class: int@status-code-class-completer
  --event-types: list # nullable
  --channel: string # nullable, e.g. project_1337
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "endpoint_id" $endpoint_id "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status_code_class" $status_code_class "scalar") (serialize-qp "event_types" $event_types "multi") (serialize-qp "channel" $channel "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/attempt/msg/($msg_id)/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Endpoints
#
# GET /api/v1/app/{app_id}/endpoint/
# operationId: list_endpoints_api_v1_app__app_id__endpoint__get
export def "app-endpoint list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --order: string # default: descending
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Endpoint
#
# POST /api/v1/app/{app_id}/endpoint/
# operationId: create_endpoint_api_v1_app__app_id__endpoint__post
export def "app-endpoint post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --channels: list # List of message channels this endpoint listens to (omit for all) (nullable, e.g. [project_123, group_2])
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filterTypes: list # nullable, e.g. [user.signup, user.deleted]
  --metadata: record # nullable
  --rateLimit: int # nullable, e.g. 1000
  --secret: string # The endpoint's verification secret. If `null` is passed, a secret is automatically generated. Format: `base64` encoded random bytes optionally prefixed with `whsec_`. Recommended size: 24. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
  --uid: string # Optional unique identifier for the endpoint (nullable, e.g. unique-endpoint-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
  version: int # e.g. 1
]: any -> record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/")
  let body = {channels: $channels, description: $description, disabled: $disabled, filterTypes: $filterTypes, metadata: $metadata, rateLimit: $rateLimit, secret: $secret, uid: $uid, url: $body_url, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Endpoint
#
# DELETE /api/v1/app/{app_id}/endpoint/{endpoint_id}/
# operationId: delete_endpoint_api_v1_app__app_id__endpoint__endpoint_id___delete
export def "app-endpoint delete" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Endpoint
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/
# operationId: get_endpoint_api_v1_app__app_id__endpoint__endpoint_id___get
export def "app-endpoint get" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Endpoint
#
# PUT /api/v1/app/{app_id}/endpoint/{endpoint_id}/
# operationId: update_endpoint_api_v1_app__app_id__endpoint__endpoint_id___put
export def "app-endpoint put" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --channels: list # List of message channels this endpoint listens to (omit for all) (nullable, e.g. [project_123, group_2])
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filterTypes: list # nullable, e.g. [user.signup, user.deleted]
  --metadata: record # nullable
  --rateLimit: int # nullable, e.g. 1000
  --uid: string # Optional unique identifier for the endpoint (nullable, e.g. unique-endpoint-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
  version: int # e.g. 1
]: any -> record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/")
  let body = {channels: $channels, description: $description, disabled: $disabled, filterTypes: $filterTypes, metadata: $metadata, rateLimit: $rateLimit, uid: $uid, url: $body_url, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Endpoint Headers
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/
# operationId: get_endpoint_headers_api_v1_app__app_id__endpoint__endpoint_id__headers__get
export def "app-endpoint-headers get" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<headers: record, sensitive: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/headers/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch Endpoint Headers
#
# PATCH /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/
# operationId: patch_endpoint_headers_api_v1_app__app_id__endpoint__endpoint_id__headers__patch
export def "app-endpoint-headers patch" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/headers/")
  let body = {headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Endpoint Headers
#
# PUT /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/
# operationId: update_endpoint_headers_api_v1_app__app_id__endpoint__endpoint_id__headers__put
export def "app-endpoint-headers put" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/headers/")
  let body = {headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Attempted Messages
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/msg/
# operationId: list_attempted_messages_api_v1_app__app_id__endpoint__endpoint_id__msg__get
export def "app-endpoint-msg get" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. msg_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --channel: string # nullable, e.g. project_1337
  --status: int@status-completer
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<channels: list, eventId: string, eventType: string, id: string, nextAttempt: string, payload: record, status: int, timestamp: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/msg/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recover Failed Webhooks
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/recover/
# operationId: recover_failed_webhooks_api_v1_app__app_id__endpoint__endpoint_id__recover__post
export def "app-endpoint-recover post" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  since: string # format: date-time
  --until: string # nullable, format: date-time
]: any -> record<id: string, status: string, task: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/recover/")
  let body = {since: $since, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replay Missing Webhooks
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/replay-missing/
# operationId: replay_missing_webhooks_api_v1_app__app_id__endpoint__endpoint_id__replay_missing__post
export def "app-endpoint-replay-missing post" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  since: string # format: date-time
  --until: string # nullable, format: date-time
]: any -> record<id: string, status: string, task: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/replay-missing/")
  let body = {since: $since, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Endpoint Secret
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/secret/
# operationId: get_endpoint_secret_api_v1_app__app_id__endpoint__endpoint_id__secret__get
export def "app-endpoint-secret get" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/secret/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotate Endpoint Secret
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/secret/rotate/
# operationId: rotate_endpoint_secret_api_v1_app__app_id__endpoint__endpoint_id__secret_rotate__post
export def "app-endpoint-secret-rotate post" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --key: string # The endpoint's verification secret. If `null` is passed, a secret is automatically generated. Format: `base64` encoded random bytes optionally prefixed with `whsec_`. Recommended size: 24. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/secret/rotate/")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Endpoint Stats
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/stats/
# operationId: get_endpoint_stats_api_v1_app__app_id__endpoint__endpoint_id__stats__get
export def "app-endpoint-stats get" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # nullable, format: date-time
  --until: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<fail: int, pending: int, sending: int, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/stats/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Endpoint Transformation
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation/
# operationId: get_endpoint_transformation_api_v1_app__app_id__endpoint__endpoint_id__transformation__get
export def "app-endpoint-transformation get" [
  endpoint_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<code: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/transformation/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Endpoint Transformation
#
# PATCH /api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation/
# operationId: set_endpoint_transformation_api_v1_app__app_id__endpoint__endpoint_id__transformation__patch
export def "app-endpoint-transformation patch" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --code: string # nullable
  --enabled: oneof<nothing, bool> # default: false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/transformation/")
  let body = {code: $code, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Integrations
#
# GET /api/v1/app/{app_id}/integration/
# operationId: list_integrations_api_v1_app__app_id__integration__get
export def "app-integration list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. integ_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<createdAt: string, id: string, name: string, updatedAt: string>, done: bool, iterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Integration
#
# POST /api/v1/app/{app_id}/integration/
# operationId: create_integration_api_v1_app__app_id__integration__post
export def "app-integration post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  name: string # e.g. Example Integration
]: any -> record<createdAt: string, id: string, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Integration
#
# DELETE /api/v1/app/{app_id}/integration/{integ_id}/
# operationId: delete_integration_api_v1_app__app_id__integration__integ_id___delete
export def "app-integration delete" [
  integ_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Integration
#
# GET /api/v1/app/{app_id}/integration/{integ_id}/
# operationId: get_integration_api_v1_app__app_id__integration__integ_id___get
export def "app-integration get" [
  integ_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<createdAt: string, id: string, name: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Integration
#
# PUT /api/v1/app/{app_id}/integration/{integ_id}/
# operationId: update_integration_api_v1_app__app_id__integration__integ_id___put
export def "app-integration put" [
  integ_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  name: string # e.g. Example Integration
]: any -> record<createdAt: string, id: string, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Integration Key
#
# GET /api/v1/app/{app_id}/integration/{integ_id}/key/
# operationId: get_integration_key_api_v1_app__app_id__integration__integ_id__key__get
export def "app-integration-key get" [
  integ_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)/key/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rotate Integration Key
#
# POST /api/v1/app/{app_id}/integration/{integ_id}/key/rotate/
# operationId: rotate_integration_key_api_v1_app__app_id__integration__integ_id__key_rotate__post
export def "app-integration-key-rotate post" [
  integ_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)/key/rotate/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Messages
#
# GET /api/v1/app/{app_id}/msg/
# operationId: list_messages_api_v1_app__app_id__msg__get
export def "app-msg list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. msg_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --event-types: list # nullable
  --channel: string # nullable, e.g. project_1337
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<channels: list, eventId: string, eventType: string, id: string, payload: record, timestamp: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "event_types" $event_types "multi") (serialize-qp "channel" $channel "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Message
#
# POST /api/v1/app/{app_id}/msg/
# operationId: create_message_api_v1_app__app_id__msg__post
# --application shape: {metadata?: record, name: string, rateLimit?: int, uid?: string}
export def "app-msg post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-content: oneof<nothing, bool> # default: true
  --idempotency-key: string # The request's idempotency key
  --application: record # shape: {metadata?: record, name: string, rateLimit?: int, uid?: string}
  --channels: list # List of free-form identifiers that endpoints can filter by (nullable, e.g. [project_123, group_2])
  --eventId: string # Optional unique identifier for the message (nullable, e.g. evt_pNZKtWg8Azow)
  eventType: string # e.g. user.signup
  payload: record # e.g. {email: test@example.com, username: test_user}
  --payloadRetentionPeriod: int # The retention period for the payload (in days). (default: 90, e.g. 90)
]: any -> record<channels: list<string>, eventId: string, eventType: string, id: string, payload: record, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_content" $with_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/" $qp)
  let body = {application: $application, channels: $channels, eventId: $eventId, eventType: $eventType, payload: $payload, payloadRetentionPeriod: $payloadRetentionPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Message
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/
# operationId: get_message_api_v1_app__app_id__msg__msg_id___get
export def "app-msg get" [
  msg_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<channels: list<string>, eventId: string, eventType: string, id: string, payload: record, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Attempts
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/attempt/
# DEPRECATED
# operationId: list_attempts_api_v1_app__app_id__msg__msg_id__attempt__get
@deprecated
export def "app-msg-attempt list" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --endpoint-id: string # nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --event-types: list # nullable
  --channel: string # nullable, e.g. project_1337
  --status: int@status-completer
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "endpoint_id" $endpoint_id "scalar") (serialize-qp "event_types" $event_types "multi") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/attempt/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Attempt
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}/
# operationId: get_attempt_api_v1_app__app_id__msg__msg_id__attempt__attempt_id___get
export def "app-msg-attempt get" [
  attempt_id: string
  msg_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/attempt/($attempt_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete attempt response body
#
# DELETE /api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}/content/
# operationId: expunge_attempt_content_api_v1_app__app_id__msg__msg_id__attempt__attempt_id__content__delete
export def "app-msg-attempt-content delete" [
  attempt_id: string
  msg_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/attempt/($attempt_id)/content/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete message payload
#
# DELETE /api/v1/app/{app_id}/msg/{msg_id}/content/
# operationId: expunge_message_payload_api_v1_app__app_id__msg__msg_id__content__delete
export def "app-msg-content delete" [
  msg_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/content/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Attempted Destinations
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/endpoint/
# operationId: list_attempted_destinations_api_v1_app__app_id__msg__msg_id__endpoint__get
export def "app-msg-endpoint get" [
  msg_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. msgep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, nextAttempt: string, rateLimit: int, status: int, uid: string, url: string, version: int>, done: bool, iterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/endpoint/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Attempts For Endpoint
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/endpoint/{endpoint_id}/attempt/
# DEPRECATED
# operationId: list_attempts_for_endpoint_api_v1_app__app_id__msg__msg_id__endpoint__endpoint_id__attempt__get
@deprecated
export def "app-msg-endpoint-attempt get" [
  msg_id: string
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --event-types: list # nullable
  --channel: string # nullable, e.g. project_1337
  --status: int@status-completer
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "event_types" $event_types "multi") (serialize-qp "channel" $channel "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/endpoint/($endpoint_id)/attempt/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend Webhook
#
# POST /api/v1/app/{app_id}/msg/{msg_id}/endpoint/{endpoint_id}/resend/
# operationId: resend_webhook_api_v1_app__app_id__msg__msg_id__endpoint__endpoint_id__resend__post
export def "app-msg-endpoint-resend post" [
  endpoint_id: string
  msg_id: string
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/endpoint/($endpoint_id)/resend/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Consumer App Portal Access
#
# POST /api/v1/auth/app-portal-access/{app_id}/
# operationId: get_app_portal_access_api_v1_auth_app_portal_access__app_id___post
export def "auth-app-portal-access post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --featureFlags: list # default: [], e.g. []
]: any -> record<token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/app-portal-access/($app_id)/")
  let body = {featureFlags: $featureFlags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Expire All
#
# POST /api/v1/auth/app/{app_id}/expire-all/
# operationId: expire_all_api_v1_auth_app__app_id__expire_all__post
export def "auth-app-expire-all post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --expiry: int # How many seconds until the old key is expired. (nullable, e.g. 60)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/app/($app_id)/expire-all/")
  let body = {expiry: $expiry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Dashboard Access
#
# POST /api/v1/auth/dashboard-access/{app_id}/
# DEPRECATED
# operationId: get_dashboard_access_api_v1_auth_dashboard_access__app_id___post
@deprecated
export def "auth-dashboard-access post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<token: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/dashboard-access/($app_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logout
#
# POST /api/v1/auth/logout/
# operationId: logout_api_v1_auth_logout__post
export def "auth-logout post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/logout/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Background Tasks
#
# GET /api/v1/background-task/
# operationId: list_background_tasks_api_v1_background_task__get
export def "background-task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. qtask_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --order: string # default: descending
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<data: record, id: string, status: string, task: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/background-task/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Background Task
#
# GET /api/v1/background-task/{task_id}/
# operationId: get_background_task_api_v1_background_task__task_id___get
export def "background-task get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: record, id: string, status: string, task: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/background-task/($task_id)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Event Types
#
# GET /api/v1/event-type/
# operationId: list_event_types_api_v1_event_type__get
export def "event-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. user.signup
  --limit: int # default: 50
  --with-content: oneof<nothing, bool> # default: false
  --include-archived: oneof<nothing, bool> # default: false
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<data: table<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "iterator" $iterator "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_content" $with_content "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/event-type/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Event Type
#
# POST /api/v1/event-type/
# operationId: create_event_type_api_v1_event_type__post
export def "event-type post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --archived: oneof<nothing, bool> # default: false, e.g. false
  description: string # e.g. A user has signed up
  --featureFlag: string # nullable, e.g. cool-new-feature
  name: string # e.g. user.signup
  --schemas: record # The schema for the event type for a specific version as a JSON schema. (nullable, e.g. {1: {description: An invoice was paid by a user, properties: {invoiceId: {description: The invoice id, type: string}, userId: {description: The user id, type: string}}, required: [invoiceId, userId], title: Invoice Paid Event, type: object}})
]: any -> record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/event-type/")
  let body = {archived: $archived, description: $description, featureFlag: $featureFlag, name: $name, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archive Event Type
#
# DELETE /api/v1/event-type/{event_type_name}/
# operationId: delete_event_type_api_v1_event_type__event_type_name___delete
export def "event-type delete" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expunge: oneof<nothing, bool> # default: false
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expunge" $expunge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/event-type/($event_type_name)/" $qp)
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Event Type
#
# GET /api/v1/event-type/{event_type_name}/
# operationId: get_event_type_api_v1_event_type__event_type_name___get
export def "event-type get" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-type/($event_type_name)/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Event Type
#
# PUT /api/v1/event-type/{event_type_name}/
# operationId: update_event_type_api_v1_event_type__event_type_name___put
export def "event-type put" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
  --archived: oneof<nothing, bool> # default: false, e.g. false
  description: string # e.g. A user has signed up
  --featureFlag: string # nullable, e.g. cool-new-feature
  --schemas: record # The schema for the event type for a specific version as a JSON schema. (nullable, e.g. {1: {description: An invoice was paid by a user, properties: {invoiceId: {description: The invoice id, type: string}, userId: {description: The user id, type: string}}, required: [invoiceId, userId], title: Invoice Paid Event, type: object}})
]: any -> record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-type/($event_type_name)/")
  let body = {archived: $archived, description: $description, featureFlag: $featureFlag, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Health
#
# GET /api/v1/health/
# operationId: health_api_v1_health__get
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/health/")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
