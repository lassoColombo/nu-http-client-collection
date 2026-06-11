# Auto-generated client for Replicate HTTP API v1.0.0-a1
# Source: https://api.replicate.com/openapi.json
# Auth: --token flag or $env.REPLICATE_HTTP_API_TOKEN

const BASE_URL = "https://api.replicate.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REPLICATE_HTTP_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.replicate.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-by-completer [] { ["latest_version_created_at" "model_created_at"] }
def sort-direction-completer [] { ["asc" "desc"] }
def visibility-completer [] { ["private" "public"] }
def source-completer [] { ["web"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account accountget" } } | get name | first)
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

# Get the authenticated account
#
# GET /account
# operationId: account.get
export def "account accountget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<avatar_url: string, github_url: string, name: string, type: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List collections of models
#
# GET /collections
# operationId: collections.list
export def "collections collectionslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<next: string, previous: string, results: table<description: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a collection of models
#
# GET /collections/{collection_slug}
# operationId: collections.get
export def "collections collectionsget" [
  collection_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, full_description: string, models: table<cover_image_url: string, default_example: record, description: string, github_url: string, is_official: bool, latest_version: record, license_url: string, name: string, owner: string, paper_url: string, run_count: int, url: string, visibility: string>, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collection_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List deployments
#
# GET /deployments
# operationId: deployments.list
export def "deployments deploymentslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<next: string, previous: string, results: table<current_release: record, name: string, owner: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a deployment
#
# POST /deployments
# operationId: deployments.create
export def "deployments deploymentscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hardware: string # The SKU for the hardware used to run the model. Possible values can be retrieved from the `hardware.list` endpoint.
  max_instances: int # The maximum number of instances for scaling.
  min_instances: int # The minimum number of instances for scaling.
  model: string # The full name of the model that you want to deploy e.g. stability-ai/sdxl.
  name: string # The name of the deployment.
  version: string # The 64-character string ID of the model version that you want to deploy.
]: any -> record<current_release: record<configuration: record<hardware: string, max_instances: int, min_instances: int>, created_at: string, created_by: record<avatar_url: string, github_url: string, name: string, type: string, username: string>, model: string, number: int, version: string>, name: string, owner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deployments")
  let body = {hardware: $hardware, max_instances: $max_instances, min_instances: $min_instances, model: $model, name: $name, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a deployment
#
# DELETE /deployments/{deployment_owner}/{deployment_name}
# operationId: deployments.delete
export def "deployments deploymentsdelete" [
  deployment_owner: string
  deployment_name: string
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
  let full_url = (build-url $base $"/deployments/($deployment_owner)/($deployment_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a deployment
#
# GET /deployments/{deployment_owner}/{deployment_name}
# operationId: deployments.get
export def "deployments deploymentsget" [
  deployment_owner: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<current_release: record<configuration: record<hardware: string, max_instances: int, min_instances: int>, created_at: string, created_by: record<avatar_url: string, github_url: string, name: string, type: string, username: string>, model: string, number: int, version: string>, name: string, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_owner)/($deployment_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a deployment
#
# PATCH /deployments/{deployment_owner}/{deployment_name}
# operationId: deployments.update
export def "deployments deploymentsupdate" [
  deployment_owner: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hardware: string # The SKU for the hardware used to run the model. Possible values can be retrieved from the `hardware.list` endpoint.
  --max-instances: int # The maximum number of instances for scaling.
  --min-instances: int # The minimum number of instances for scaling.
  --version: string # The ID of the model version that you want to deploy
]: any -> record<current_release: record<configuration: record<hardware: string, max_instances: int, min_instances: int>, created_at: string, created_by: record<avatar_url: string, github_url: string, name: string, type: string, username: string>, model: string, number: int, version: string>, name: string, owner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_owner)/($deployment_name)")
  let body = {hardware: $hardware, max_instances: $max_instances, min_instances: $min_instances, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a prediction using a deployment
#
# POST /deployments/{deployment_owner}/{deployment_name}/predictions
# operationId: deployments.predictions.create
export def "deployments-predictions deploymentspredictionscreate" [
  deployment_owner: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Prefer: string # Leave the request open and wait for the model to finish generating output. Set to `wait=n` where n is a number of seconds between 1 and 60.  See [sync mode](https://replicate.com/docs/topics/predictions/create-a-prediction#sync-mode) for more information.  (e.g. wait=5)
  --Cancel-After: string # The maximum time the prediction can run before it is automatically canceled. The lifetime is measured from when the prediction is created.  The duration can be specified as string with an optional unit suffix: - `s` for seconds (e.g., `30s`, `90s`) - `m` for minutes (e.g., `5m`, `15m`) - `h` for hours (e.g., `1h`, `2h30m`) - defaults to seconds if no unit suffix is provided (e.g. `30` is the same as `30s`)  You can combine units for more precision (e.g., `1h30m45s`).  The minimum allowed duration is 5 seconds.  (e.g. 5m)
  input: record # The model's input as a JSON object. The input schema depends on what model you are running. To see the available inputs, click the "API" tab on the model you are running or [get the model version](#models.versions.get) and look at its `openapi_schema` property. For example, [stability-ai/sdxl](https://replicate.com/stability-ai/sdxl) takes `prompt` as an input.  Files should be passed as HTTP URLs or data URLs.  Use an HTTP URL when:  - you have a large file > 256kb - you want to be able to use the file multiple times - you want your prediction metadata to be associable with your input files  Use a data URL when:  - you have a small file <= 256kb - you don't want to upload and host the file somewhere - you don't need to use the file again (Replicate will not store it)  (e.g. {prompt: Tell me a joke, system_prompt: You are a helpful assistant})
  --stream: string@bool-completer # **This field is deprecated.**  Request a URL to receive streaming output using [server-sent events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events).  This field is no longer needed as the returned prediction will always have a `stream` entry in its `urls` property if the model supports streaming.
  --webhook: string # An HTTPS URL for receiving a webhook when the prediction has new output. The webhook will be a POST request where the request body is the same as the response body of the [get prediction](#predictions.get) operation. If there are network problems, we will retry the webhook a few times, so make sure it can be safely called more than once. Replicate will not follow redirects when sending webhook requests to your service, so be sure to specify a URL that will resolve without redirecting.  (e.g. https://example.com/my-webhook-handler)
  --webhook-events-filter: list # By default, we will send requests to your webhook URL whenever there are new outputs or the prediction has finished. You can change which events trigger webhook requests by specifying `webhook_events_filter` in the prediction request:  - `start`: immediately on prediction start - `output`: each time a prediction generates an output (note that predictions can generate multiple outputs) - `logs`: each time log output is generated by a prediction - `completed`: when the prediction reaches a terminal state (succeeded/canceled/failed)  For example, if you only wanted requests to be sent at the start and end of the prediction, you would provide:  ```json {   "input": {     "text": "Alice"   },   "webhook": "https://example.com/my-webhook",   "webhook_events_filter": ["start", "completed"] } ```  Requests for event types `output` and `logs` will be sent at most once every 500ms. If you request `start` and `completed` webhooks, then they'll always be sent regardless of throttling.  (e.g. [start, completed])
]: any -> record<completed_at: string, created_at: string, data_removed: bool, deadline: string, deployment: string, error: string, id: string, input: record, logs: string, metrics: record<total_time: float>, model: string, output: any, source: string, started_at: string, status: string, urls: record<cancel: string, get: string, stream: string, web: string>, version: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/deployments/($deployment_owner)/($deployment_name)/predictions")
  let body = {input: $input, stream: $stream, webhook: $webhook, webhook_events_filter: $webhook_events_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Prefer": $Prefer, "Cancel-After": $Cancel_After} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List files
#
# GET /files
# operationId: files.list
export def "files fileslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<next: string, previous: string, results: table<checksums: record, content_type: string, created_at: string, expires_at: string, id: string, metadata: record, size: int, urls: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a file
#
# POST /files
# operationId: files.create
export def "files filescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The file content (format: binary)
  --filename: string # The filename
  --metadata: record # User-provided metadata associated with the file (default: {})
  --type: string # The content / MIME type for the file (default: application/octet-stream)
]: any -> record<checksums: record<sha256: string>, content_type: string, created_at: string, expires_at: string, id: string, metadata: record, size: int, urls: record<get: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let body = {content: $content, filename: $filename, metadata: $metadata, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete a file
#
# DELETE /files/{file_id}
# operationId: files.delete
export def "files filesdelete" [
  file_id: string
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
  let full_url = (build-url $base $"/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a file
#
# GET /files/{file_id}
# operationId: files.get
export def "files filesget" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<checksums: record<sha256: string>, content_type: string, created_at: string, expires_at: string, id: string, metadata: record, size: int, urls: record<get: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a file
#
# GET /files/{file_id}/download
# operationId: files.download
export def "files-download filesdownload" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The username of the user or organization that uploaded the file
  --expiry: int # A Unix timestamp with expiration date of this download URL (format: int64)
  --signature: string # A base64-encoded HMAC-SHA256 checksum of the string '{owner} {id} {expiry}' generated with the Files API signing secret
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "expiry" $expiry "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/($file_id)/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available hardware for models
#
# GET /hardware
# operationId: hardware.list
export def "hardware hardwarelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hardware")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List public models
#
# GET /models
# operationId: models.list
export def "models modelslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string@sort-by-completer # Field to sort models by. Defaults to `latest_version_created_at`.  (default: latest_version_created_at)
  --sort-direction: string@sort-direction-completer # Sort direction. Defaults to `desc` (descending, newest first).  (default: desc)
]: nothing -> record<next: string, previous: string, results: table<cover_image_url: string, default_example: record, description: string, github_url: string, is_official: bool, latest_version: record, license_url: string, name: string, owner: string, paper_url: string, run_count: int, url: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_direction" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a model
#
# POST /models
# operationId: models.create
export def "models modelscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cover-image-url: string # A URL for the model's cover image. This should be an image file.
  --description: string # A description of the model. (e.g. Detect hot dogs in images)
  --github-url: string # A URL for the model's source code on GitHub. (e.g. https://github.com/alice/hot-dog-detector)
  hardware: string # The SKU for the hardware used to run the model. Possible values can be retrieved from the `hardware.list` endpoint. (e.g. cpu)
  --license-url: string # A URL for the model's license.
  name: string # The name of the model. This must be unique among all models owned by the user or organization. (e.g. hot-dog-detector)
  owner: string # The name of the user or organization that will own the model. This must be the same as the user or organization that is making the API request. In other words, the API token used in the request must belong to this user or organization. (e.g. alice)
  --paper-url: string # A URL for the model's paper. (e.g. https://arxiv.org/abs/2504.17639)
  visibility: string@visibility-completer # Whether the model should be public or private. A public model can be viewed and run by anyone, whereas a private model can be viewed and run only by the user or organization members that own the model. (e.g. public)
]: any -> record<cover_image_url: string, default_example: record, description: string, github_url: string, is_official: bool, latest_version: record, license_url: string, name: string, owner: string, paper_url: string, run_count: int, url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models")
  let body = {cover_image_url: $cover_image_url, description: $description, github_url: $github_url, hardware: $hardware, license_url: $license_url, name: $name, owner: $owner, paper_url: $paper_url, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a model
#
# DELETE /models/{model_owner}/{model_name}
# operationId: models.delete
export def "models modelsdelete" [
  model_owner: string
  model_name: string
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
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a model
#
# GET /models/{model_owner}/{model_name}
# operationId: models.get
export def "models modelsget" [
  model_owner: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cover_image_url: string, default_example: record, description: string, github_url: string, is_official: bool, latest_version: record, license_url: string, name: string, owner: string, paper_url: string, run_count: int, url: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update metadata for a model
#
# PATCH /models/{model_owner}/{model_name}
# operationId: models.update
export def "models modelsupdate" [
  model_owner: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # A description of the model. (e.g. Detect hot dogs in images)
  --github-url: string # A URL for the model's source code on GitHub. (e.g. https://github.com/alice/hot-dog-detector)
  --license-url: string # A URL for the model's license.
  --paper-url: string # A URL for the model's paper. (e.g. https://arxiv.org/abs/2504.17639)
  --readme: string # The README content of the model. (e.g. # Updated README  New content here)
  --weights-url: string # A URL for the model's weights. (e.g. https://huggingface.co/alice/hot-dog-detector)
]: any -> record<cover_image_url: string, default_example: record, description: string, github_url: string, is_official: bool, latest_version: record, license_url: string, name: string, owner: string, paper_url: string, run_count: int, url: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)")
  let body = {description: $description, github_url: $github_url, license_url: $license_url, paper_url: $paper_url, readme: $readme, weights_url: $weights_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List examples for a model
#
# GET /models/{model_owner}/{model_name}/examples
# operationId: models.examples.list
export def "models-examples modelsexampleslist" [
  model_owner: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<next: string, previous: string, results: table<completed_at: string, created_at: string, data_removed: bool, deadline: string, deployment: string, error: string, id: string, input: record, logs: string, metrics: record, model: string, output: any, source: string, started_at: string, status: string, urls: record, version: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)/examples")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a prediction using an official model
#
# POST /models/{model_owner}/{model_name}/predictions
# operationId: models.predictions.create
export def "models-predictions modelspredictionscreate" [
  model_owner: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Prefer: string # Leave the request open and wait for the model to finish generating output. Set to `wait=n` where n is a number of seconds between 1 and 60.  See [sync mode](https://replicate.com/docs/topics/predictions/create-a-prediction#sync-mode) for more information.  (e.g. wait=5)
  --Cancel-After: string # The maximum time the prediction can run before it is automatically canceled. The lifetime is measured from when the prediction is created.  The duration can be specified as string with an optional unit suffix: - `s` for seconds (e.g., `30s`, `90s`) - `m` for minutes (e.g., `5m`, `15m`) - `h` for hours (e.g., `1h`, `2h30m`) - defaults to seconds if no unit suffix is provided (e.g. `30` is the same as `30s`)  You can combine units for more precision (e.g., `1h30m45s`).  The minimum allowed duration is 5 seconds.  (e.g. 5m)
  input: record # The model's input as a JSON object. The input schema depends on what model you are running. To see the available inputs, click the "API" tab on the model you are running or [get the model version](#models.versions.get) and look at its `openapi_schema` property. For example, [stability-ai/sdxl](https://replicate.com/stability-ai/sdxl) takes `prompt` as an input.  Files should be passed as HTTP URLs or data URLs.  Use an HTTP URL when:  - you have a large file > 256kb - you want to be able to use the file multiple times - you want your prediction metadata to be associable with your input files  Use a data URL when:  - you have a small file <= 256kb - you don't want to upload and host the file somewhere - you don't need to use the file again (Replicate will not store it)  (e.g. {prompt: Tell me a joke, system_prompt: You are a helpful assistant})
  --stream: string@bool-completer # **This field is deprecated.**  Request a URL to receive streaming output using [server-sent events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events).  This field is no longer needed as the returned prediction will always have a `stream` entry in its `urls` property if the model supports streaming.
  --webhook: string # An HTTPS URL for receiving a webhook when the prediction has new output. The webhook will be a POST request where the request body is the same as the response body of the [get prediction](#predictions.get) operation. If there are network problems, we will retry the webhook a few times, so make sure it can be safely called more than once. Replicate will not follow redirects when sending webhook requests to your service, so be sure to specify a URL that will resolve without redirecting.  (e.g. https://example.com/my-webhook-handler)
  --webhook-events-filter: list # By default, we will send requests to your webhook URL whenever there are new outputs or the prediction has finished. You can change which events trigger webhook requests by specifying `webhook_events_filter` in the prediction request:  - `start`: immediately on prediction start - `output`: each time a prediction generates an output (note that predictions can generate multiple outputs) - `logs`: each time log output is generated by a prediction - `completed`: when the prediction reaches a terminal state (succeeded/canceled/failed)  For example, if you only wanted requests to be sent at the start and end of the prediction, you would provide:  ```json {   "input": {     "text": "Alice"   },   "webhook": "https://example.com/my-webhook",   "webhook_events_filter": ["start", "completed"] } ```  Requests for event types `output` and `logs` will be sent at most once every 500ms. If you request `start` and `completed` webhooks, then they'll always be sent regardless of throttling.  (e.g. [start, completed])
]: any -> record<completed_at: string, created_at: string, data_removed: bool, deadline: string, deployment: string, error: string, id: string, input: record, logs: string, metrics: record<total_time: float>, model: string, output: any, source: string, started_at: string, status: string, urls: record<cancel: string, get: string, stream: string, web: string>, version: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)/predictions")
  let body = {input: $input, stream: $stream, webhook: $webhook, webhook_events_filter: $webhook_events_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Prefer": $Prefer, "Cancel-After": $Cancel_After} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a model's README
#
# GET /models/{model_owner}/{model_name}/readme
# operationId: models.readme.get
export def "models-readme modelsreadmeget" [
  model_owner: string
  model_name: string
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
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)/readme")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List model versions
#
# GET /models/{model_owner}/{model_name}/versions
# operationId: models.versions.list
export def "models-versions modelsversionslist" [
  model_owner: string
  model_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<next: string, previous: string, results: table<cog_version: string, created_at: string, id: string, openapi_schema: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a model version
#
# DELETE /models/{model_owner}/{model_name}/versions/{version_id}
# operationId: models.versions.delete
export def "models-versions modelsversionsdelete" [
  model_owner: string
  model_name: string
  version_id: string
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
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a model version
#
# GET /models/{model_owner}/{model_name}/versions/{version_id}
# operationId: models.versions.get
export def "models-versions modelsversionsget" [
  model_owner: string
  model_name: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cog_version: string, created_at: string, id: string, openapi_schema: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a training
#
# POST /models/{model_owner}/{model_name}/versions/{version_id}/trainings
# operationId: trainings.create
export def "models-versions-trainings trainingscreate" [
  model_owner: string
  model_name: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destination: string # A string representing the desired model to push to in the format `{destination_model_owner}/{destination_model_name}`. This should be an existing model owned by the user or organization making the API request. If the destination is invalid, the server will return an appropriate 4XX response.
  input: record # An object containing inputs to the Cog model's `train()` function.
  --webhook: string # An HTTPS URL for receiving a webhook when the training completes. The webhook will be a POST request where the request body is the same as the response body of the [get training](#trainings.get) operation. If there are network problems, we will retry the webhook a few times, so make sure it can be safely called more than once. Replicate will not follow redirects when sending webhook requests to your service, so be sure to specify a URL that will resolve without redirecting.
  --webhook-events-filter: list # By default, we will send requests to your webhook URL whenever there are new outputs or the training has finished. You can change which events trigger webhook requests by specifying `webhook_events_filter` in the training request:  - `start`: immediately on training start - `output`: each time a training generates an output (note that trainings can generate multiple outputs) - `logs`: each time log output is generated by a training - `completed`: when the training reaches a terminal state (succeeded/canceled/failed)  For example, if you only wanted requests to be sent at the start and end of the training, you would provide:  ```json {   "destination": "my-organization/my-model",   "input": {     "text": "Alice"   },   "webhook": "https://example.com/my-webhook",   "webhook_events_filter": ["start", "completed"] } ```  Requests for event types `output` and `logs` will be sent at most once every 500ms. If you request `start` and `completed` webhooks, then they'll always be sent regardless of throttling.
]: any -> record<completed_at: string, created_at: string, error: string, id: string, input: record, logs: string, metrics: record<predict_time: float, total_time: float>, model: string, output: record<version: string, weights: string>, source: string, started_at: string, status: string, urls: record<cancel: string, get: string>, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/models/($model_owner)/($model_name)/versions/($version_id)/trainings")
  let body = {destination: $destination, input: $input, webhook: $webhook, webhook_events_filter: $webhook_events_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List predictions
#
# GET /predictions
# operationId: predictions.list
export def "predictions predictionslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-after: string # Include only predictions created at or after this date-time, in ISO 8601 format. (format: date-time, e.g. 2025-01-01T00:00:00Z)
  --created-before: string # Include only predictions created before this date-time, in ISO 8601 format. (format: date-time, e.g. 2025-02-01T00:00:00Z)
  --qp-source: string@source-completer # Filter predictions by how they were created. Currently only `web` is supported.  If no value is set, the API returns predictions from both API and web sources.  When filtering by `source=web`, results are limited to predictions created in the last 14 days.
]: nothing -> record<next: string, previous: string, results: table<completed_at: string, created_at: string, data_removed: bool, deadline: string, deployment: string, error: string, id: string, input: record, logs: string, metrics: record, model: string, output: any, source: string, started_at: string, status: string, urls: record, version: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/predictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a prediction
#
# POST /predictions
# operationId: predictions.create
export def "predictions predictionscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Prefer: string # Leave the request open and wait for the model to finish generating output. Set to `wait=n` where n is a number of seconds between 1 and 60.  See [sync mode](https://replicate.com/docs/topics/predictions/create-a-prediction#sync-mode) for more information.  (e.g. wait=5)
  --Cancel-After: string # The maximum time the prediction can run before it is automatically canceled. The lifetime is measured from when the prediction is created.  The duration can be specified as string with an optional unit suffix: - `s` for seconds (e.g., `30s`, `90s`) - `m` for minutes (e.g., `5m`, `15m`) - `h` for hours (e.g., `1h`, `2h30m`) - defaults to seconds if no unit suffix is provided (e.g. `30` is the same as `30s`)  You can combine units for more precision (e.g., `1h30m45s`).  The minimum allowed duration is 5 seconds.  (e.g. 5m)
  input: record # The model's input as a JSON object. The input schema depends on what model you are running. To see the available inputs, click the "API" tab on the model you are running or [get the model version](#models.versions.get) and look at its `openapi_schema` property. For example, [stability-ai/sdxl](https://replicate.com/stability-ai/sdxl) takes `prompt` as an input.  Files should be passed as HTTP URLs or data URLs.  Use an HTTP URL when:  - you have a large file > 256kb - you want to be able to use the file multiple times - you want your prediction metadata to be associable with your input files  Use a data URL when:  - you have a small file <= 256kb - you don't want to upload and host the file somewhere - you don't need to use the file again (Replicate will not store it)  (e.g. {text: Alice})
  --stream: string@bool-completer # **This field is deprecated.**  Request a URL to receive streaming output using [server-sent events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events).  This field is no longer needed as the returned prediction will always have a `stream` entry in its `urls` property if the model supports streaming.
  version: string # The identifier for the model or model version that you want to run. This can be specified in a few different formats:  - `{owner_name}/{model_name}` - Use this format for [official models](https://replicate.com/docs/topics/models/official-models). For example, `black-forest-labs/flux-schnell`. For all other models, the specific version is required. - `{owner_name}/{model_name}:{version_id}` - The owner and model name, plus the full 64-character version ID. For example, `replicate/hello-world:9dcd6d78e7c6560c340d916fe32e9f24aabfa331e5cce95fe31f77fb03121426`. - `{version_id}` - Just the 64-character version ID. For example, `9dcd6d78e7c6560c340d916fe32e9f24aabfa331e5cce95fe31f77fb03121426`  (e.g. replicate/hello-world:9dcd6d78e7c6560c340d916fe32e9f24aabfa331e5cce95fe31f77fb03121426)
  --webhook: string # An HTTPS URL for receiving a webhook when the prediction has new output. The webhook will be a POST request where the request body is the same as the response body of the [get prediction](#predictions.get) operation. If there are network problems, we will retry the webhook a few times, so make sure it can be safely called more than once. Replicate will not follow redirects when sending webhook requests to your service, so be sure to specify a URL that will resolve without redirecting.  (e.g. https://example.com/my-webhook-handler)
  --webhook-events-filter: list # By default, we will send requests to your webhook URL whenever there are new outputs or the prediction has finished. You can change which events trigger webhook requests by specifying `webhook_events_filter` in the prediction request:  - `start`: immediately on prediction start - `output`: each time a prediction generates an output (note that predictions can generate multiple outputs) - `logs`: each time log output is generated by a prediction - `completed`: when the prediction reaches a terminal state (succeeded/canceled/failed)  For example, if you only wanted requests to be sent at the start and end of the prediction, you would provide:  ```json {   "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",   "input": {     "text": "Alice"   },   "webhook": "https://example.com/my-webhook",   "webhook_events_filter": ["start", "completed"] } ```  Requests for event types `output` and `logs` will be sent at most once every 500ms. If you request `start` and `completed` webhooks, then they'll always be sent regardless of throttling.  (e.g. [start, completed])
]: any -> record<completed_at: string, created_at: string, data_removed: bool, deadline: string, deployment: string, error: string, id: string, input: record, logs: string, metrics: record<total_time: float>, model: string, output: any, source: string, started_at: string, status: string, urls: record<cancel: string, get: string, stream: string, web: string>, version: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/predictions")
  let body = {input: $input, stream: $stream, version: $version, webhook: $webhook, webhook_events_filter: $webhook_events_filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Prefer": $Prefer, "Cancel-After": $Cancel_After} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a prediction
#
# GET /predictions/{prediction_id}
# operationId: predictions.get
export def "predictions predictionsget" [
  prediction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<completed_at: string, created_at: string, data_removed: bool, deadline: string, deployment: string, error: string, id: string, input: record, logs: string, metrics: record<total_time: float>, model: string, output: any, source: string, started_at: string, status: string, urls: record<cancel: string, get: string, stream: string, web: string>, version: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/predictions/($prediction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a prediction
#
# POST /predictions/{prediction_id}/cancel
# operationId: predictions.cancel
export def "predictions-cancel predictionscancel" [
  prediction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<completed_at: string, created_at: string, data_removed: bool, deadline: string, deployment: string, error: string, id: string, input: record, logs: string, metrics: record<total_time: float>, model: string, output: any, source: string, started_at: string, status: string, urls: record<cancel: string, get: string, stream: string, web: string>, version: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/predictions/($prediction_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search models, collections, and docs (beta)
#
# GET /search
# operationId: search
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query string (e.g. nano banana)
  --limit: int # Maximum number of model results to return (1-50, defaults to 20) (default: 20, e.g. 10)
]: nothing -> record<collections: table<description: string, models: list, name: string, slug: string>, models: table<metadata: record, model: record>, pages: table<href: string, name: string>, query: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List trainings
#
# GET /trainings
# operationId: trainings.list
export def "trainings trainingslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<next: string, previous: string, results: table<completed_at: string, created_at: string, error: string, id: string, input: record, logs: string, metrics: record, model: string, output: record, source: string, started_at: string, status: string, urls: record, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trainings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a training
#
# GET /trainings/{training_id}
# operationId: trainings.get
export def "trainings trainingsget" [
  training_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<completed_at: string, created_at: string, error: string, id: string, input: record, logs: string, metrics: record<predict_time: float, total_time: float>, model: string, output: record<version: string, weights: string>, source: string, started_at: string, status: string, urls: record<cancel: string, get: string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trainings/($training_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a training
#
# POST /trainings/{training_id}/cancel
# operationId: trainings.cancel
export def "trainings-cancel trainingscancel" [
  training_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<completed_at: string, created_at: string, error: string, id: string, input: record, logs: string, metrics: record<predict_time: float, total_time: float>, model: string, output: record<version: string, weights: string>, source: string, started_at: string, status: string, urls: record<cancel: string, get: string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/trainings/($training_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the signing secret for the default webhook
#
# GET /webhooks/default/secret
# operationId: webhooks.default.secret.get
export def "webhooks-default-secret webhooksdefaultsecretget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/default/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
