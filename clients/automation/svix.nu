# Auto-generated client for Svix API v1.84.0
# Source: https://api.svix.com/api/v1/openapi.json
# Auth: --token flag or $env.SVIX_API_TOKEN

const BASE_URL = "https://api.eu.svix.com"
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

def base-url-completer [] { ["https://api.eu.svix.com" "https://api.us.svix.com" "https://api.ca.svix.com" "https://api.au.svix.com" "https://api.in.svix.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["ascending" "descending"] }
def status-completer [] { ["0" "1" "2" "3" "4"] }
def status-code-class-completer [] { ["0" "100" "200" "300" "400" "500"] }
def statusCodeClass-completer [] { ["0" "100" "200" "300" "400" "500"] }
def status-completer-1 [] { ["failed" "finished" "running"] }
def task-completer [] { ["application.purge_content" "application.stats" "endpoint.bulk-replay" "endpoint.recover" "endpoint.replay" "event-type.aggregate" "message.broadcast" "sdk.generate"] }
def product-type-completer [] { ["Dispatch" "Stream"] }
def kind-completer [] { ["AgenticCommerceProtocol" "CloseCRM" "Custom" "CustomerIO" "Discord" "Hubspot" "Inngest" "Loops" "Otel" "Resend" "Salesforce" "Segment" "Sendgrid" "Slack" "Teams" "TriggerDev" "Windmill" "Zapier"] }
def productType-completer [] { ["Dispatch" "Stream"] }
def status-completer-2 [] { ["disabled" "enabled"] }
def type-completer [] { ["amazonS3" "azureBlobStorage" "bigQuery" "clickhouse" "eventBridge" "googleCloudPubSub" "googleCloudStorage" "http" "otelTracing" "poller" "rabbitMq" "redshift" "snowflake" "sns" "sqs"] }
def type-completer-1 [] { ["adobe-sign" "airwallex" "beehiiv" "brex" "checkbook" "clerk" "cron" "docusign" "easypost" "generic-webhook" "github" "guesty" "hubspot" "incident-io" "lithic" "meta" "nash" "open-ai" "orum-io" "panda-doc" "pleo" "port-io" "psi-fi" "render" "replicate" "resend" "rutter" "safebase" "sardine" "segment" "shopify" "slack" "stripe" "stych" "svix" "tailscale" "telnyx" "vapi" "veriff" "vgs" "zoom"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app v1applicationlist" } } | get name | first)
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
# GET /api/v1/app
# operationId: v1.application.list
export def "app v1applicationlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exclude-apps-with-no-endpoints: oneof<nothing, bool> # Exclude applications that have no endpoints. Default is false. (default: false)
  --exclude-apps-with-disabled-endpoints: oneof<nothing, bool> # Exclude applications that have only disabled endpoints. Default is false. (default: false)
  --exclude-apps-with-svix-play-endpoints: oneof<nothing, bool> # Exclude applications that only have Svix Play endpoints. Default is false. (default: false)
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. app_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, throttleRate: int, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exclude_apps_with_no_endpoints" $exclude_apps_with_no_endpoints "scalar") (serialize-qp "exclude_apps_with_disabled_endpoints" $exclude_apps_with_disabled_endpoints "scalar") (serialize-qp "exclude_apps_with_svix_play_endpoints" $exclude_apps_with_svix_play_endpoints "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/app" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Application
#
# POST /api/v1/app
# operationId: v1.application.create
@deprecated --flag rateLimit
export def "app v1applicationcreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --get-if-exists: oneof<nothing, bool> # Get an existing application, or create a new one if doesn't exist. It's two separate functions in the libs. (default: false)
  --idempotency-key: string # The request's idempotency key
  --metadata: record # default: {}
  name: string # Application name for human consumption. (e.g. My first application)
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --throttleRate: int # Maximum messages per second to send to this application.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # Optional unique identifier for the application. (nullable, e.g. unique-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, throttleRate: int, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "get_if_exists" $get_if_exists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/app" $qp)
  let body = {metadata: $metadata, name: $name, rateLimit: $rateLimit, throttleRate: $throttleRate, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Application
#
# GET /api/v1/app/{app_id}
# operationId: v1.application.get
export def "app v1applicationget" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, throttleRate: int, uid: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Application
#
# PUT /api/v1/app/{app_id}
# operationId: v1.application.update
@deprecated --flag rateLimit
export def "app v1applicationupdate" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # default: {}
  name: string # Application name for human consumption. (e.g. My first application)
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --throttleRate: int # Maximum messages per second to send to this application.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # Optional unique identifier for the application. (nullable, e.g. unique-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, throttleRate: int, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)")
  let body = {metadata: $metadata, name: $name, rateLimit: $rateLimit, throttleRate: $throttleRate, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Application
#
# DELETE /api/v1/app/{app_id}
# operationId: v1.application.delete
export def "app v1applicationdelete" [
  app_id: string
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
  let full_url = (build-url $base $"/api/v1/app/($app_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Application
#
# PATCH /api/v1/app/{app_id}
# operationId: v1.application.patch
@deprecated --flag rateLimit
export def "app v1applicationpatch" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record
  --name: string
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --throttleRate: int # Maximum messages per second to send to this application.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # The Application's UID. (nullable, e.g. unique-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, throttleRate: int, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)")
  let body = {metadata: $metadata, name: $name, rateLimit: $rateLimit, throttleRate: $throttleRate, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Attempts By Endpoint
#
# GET /api/v1/app/{app_id}/attempt/endpoint/{endpoint_id}
# operationId: v1.message-attempt.list-by-endpoint
export def "app-attempt-endpoint v1message-attemptlist-by-endpoint" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --status: int@status-completer # Filter response based on the status of the attempt: Success (0), Pending (1), Failed (2), Sending (3), or Canceled (4)
  --status-code-class: int@status-code-class-completer # Filter response based on the HTTP status code
  --channel: string # Filter response based on the channel (nullable, e.g. project_1337)
  --tag: string # Filter response based on the tag (nullable, e.g. project_1337)
  --before: string # Only include items created before a certain date (nullable, format: date-time)
  --after: string # Only include items created after a certain date (nullable, format: date-time)
  --with-content: oneof<nothing, bool> # When `true` attempt content is included in the response (default: true)
  --with-msg: oneof<nothing, bool> # When `true`, the message information is included in the response  Note that message payloads are never included in the response, regardless of this flag. (default: false)
  --expanded-statuses: oneof<nothing, bool> # When `true`, return the Canceled (4) status in attempts.  If `false`, canceled attempts are returned as Success (0) for backwards compatibility. (default: false)
  --event-types: list # Filter response based on the event type (nullable)
]: nothing -> record<data: table<endpointId: string, id: string, msg: record, msgId: string, response: string, responseDurationMs: int, responseStatusCode: int, status: int, statusText: string, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status_code_class" $status_code_class "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "with_content" $with_content "scalar") (serialize-qp "with_msg" $with_msg "scalar") (serialize-qp "expanded_statuses" $expanded_statuses "scalar") (serialize-qp "event_types" $event_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/attempt/endpoint/($endpoint_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Attempts By Msg
#
# GET /api/v1/app/{app_id}/attempt/msg/{msg_id}
# operationId: v1.message-attempt.list-by-msg
export def "app-attempt-msg v1message-attemptlist-by-msg" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --status: int@status-completer # Filter response based on the status of the attempt: Success (0), Pending (1), Failed (2), Sending (3), or Canceled (4)
  --status-code-class: int@status-code-class-completer # Filter response based on the HTTP status code
  --channel: string # Filter response based on the channel (nullable, e.g. project_1337)
  --tag: string # Filter response based on the tag (nullable, e.g. project_1337)
  --endpoint-id: string # Filter the attempts based on the attempted endpoint (nullable, e.g. unique-identifier)
  --before: string # Only include items created before a certain date (nullable, format: date-time)
  --after: string # Only include items created after a certain date (nullable, format: date-time)
  --with-content: oneof<nothing, bool> # When `true` attempt content is included in the response (default: true)
  --expanded-statuses: oneof<nothing, bool> # When `true`, return the Canceled (4) status in attempts.  If `false`, canceled attempts are returned as Success (0) for backwards compatibility. (default: false)
  --event-types: list # Filter response based on the event type (nullable)
]: nothing -> record<data: table<endpointId: string, id: string, msg: record, msgId: string, response: string, responseDurationMs: int, responseStatusCode: int, status: int, statusText: string, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status_code_class" $status_code_class "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "endpoint_id" $endpoint_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "with_content" $with_content "scalar") (serialize-qp "expanded_statuses" $expanded_statuses "scalar") (serialize-qp "event_types" $event_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/attempt/msg/($msg_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Endpoints
#
# GET /api/v1/app/{app_id}/endpoint
# operationId: v1.endpoint.list
export def "app-endpoint v1endpointlist" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string, version: int>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Endpoint
#
# POST /api/v1/app/{app_id}/endpoint
# operationId: v1.endpoint.create
@deprecated --flag rateLimit
export def "app-endpoint v1endpointcreate" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --channels: list # List of message channels this endpoint listens to (omit for all). (nullable, e.g. [project_123, group_2])
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filterTypes: list # nullable, e.g. [user.signup, user.deleted]
  --headers: record # nullable, e.g. {X-Example: 123, X-Foobar: Bar}
  --metadata: record # default: {}
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --secret: string # The endpoint's verification secret.  Format: `base64` encoded random bytes optionally prefixed with `whsec_`. It is recommended to not set this and let the server generate the secret. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
  --throttleRate: int # Maximum messages per second to send to this endpoint.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # Optional unique identifier for the endpoint. (nullable, e.g. unique-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
]: any -> record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint")
  let body = {channels: $channels, description: $description, disabled: $disabled, filterTypes: $filterTypes, headers: $headers, metadata: $metadata, rateLimit: $rateLimit, secret: $secret, throttleRate: $throttleRate, uid: $uid, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Endpoint
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}
# operationId: v1.endpoint.get
export def "app-endpoint v1endpointget" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Endpoint
#
# PUT /api/v1/app/{app_id}/endpoint/{endpoint_id}
# operationId: v1.endpoint.update
@deprecated --flag rateLimit
export def "app-endpoint v1endpointupdate" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channels: list # List of message channels this endpoint listens to (omit for all). (nullable, e.g. [project_123, group_2])
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filterTypes: list # nullable, e.g. [user.signup, user.deleted]
  --metadata: record # default: {}
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --throttleRate: int # Maximum messages per second to send to this endpoint.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # Optional unique identifier for the endpoint. (nullable, e.g. unique-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
]: any -> record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)")
  let body = {channels: $channels, description: $description, disabled: $disabled, filterTypes: $filterTypes, metadata: $metadata, rateLimit: $rateLimit, throttleRate: $throttleRate, uid: $uid, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Endpoint
#
# DELETE /api/v1/app/{app_id}/endpoint/{endpoint_id}
# operationId: v1.endpoint.delete
export def "app-endpoint v1endpointdelete" [
  app_id: string
  endpoint_id: string
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
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Endpoint
#
# PATCH /api/v1/app/{app_id}/endpoint/{endpoint_id}
# operationId: v1.endpoint.patch
@deprecated --flag rateLimit
export def "app-endpoint v1endpointpatch" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channels: list # nullable
  --description: string
  --disabled: oneof<nothing, bool>
  --filterTypes: list # nullable
  --metadata: record
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --body-url: string # format: uri
  --throttleRate: int # Maximum messages per second to send to this endpoint.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # The Endpoint's UID. (nullable, e.g. unique-identifier)
]: any -> record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)")
  let body = {channels: $channels, description: $description, disabled: $disabled, filterTypes: $filterTypes, metadata: $metadata, rateLimit: $rateLimit, url: $body_url, throttleRate: $throttleRate, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Replay Messages
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/bulk-replay
# operationId: v1.endpoint.bulk-replay
export def "app-endpoint-bulk-replay v1endpointbulk-replay" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --channel: string # nullable, e.g. project_1337
  --eventTypes: list # nullable
  since: string # format: date-time
  --status: int@status-completer # The sending status of the message:  - Success = 0 - Pending = 1 - Fail = 2 - Sending = 3 - Canceled = 4
  --statusCodeClass: int@statusCodeClass-completer # The different classes of HTTP status codes:  - CodeNone = 0 - Code1xx = 100 - Code2xx = 200 - Code3xx = 300 - Code4xx = 400 - Code5xx = 500
  --tag: string # nullable, e.g. project_1337
  --until: string # nullable, format: date-time
]: any -> record<id: string, status: string, task: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/bulk-replay")
  let body = {channel: $channel, eventTypes: $eventTypes, since: $since, status: $status, statusCodeClass: $statusCodeClass, tag: $tag, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Endpoint Headers
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers
# operationId: v1.endpoint.get-headers
export def "app-endpoint-headers v1endpointget-headers" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<headers: record, sensitive: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/headers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Endpoint Headers
#
# PUT /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers
# operationId: v1.endpoint.update-headers
export def "app-endpoint-headers v1endpointupdate-headers" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/headers")
  let body = {headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch Endpoint Headers
#
# PATCH /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers
# operationId: v1.endpoint.patch-headers
export def "app-endpoint-headers v1endpointpatch-headers" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteHeaders: list # A list of headers be be removed (default: [])
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/headers")
  let body = {deleteHeaders: $deleteHeaders, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Attempted Messages
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/msg
# operationId: v1.message-attempt.list-attempted-messages
export def "app-endpoint-msg v1message-attemptlist-attempted-messages" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. msg_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --channel: string # Filter response based on the channel (nullable, e.g. project_1337)
  --tag: string # Filter response based on the message tags (nullable, e.g. project_1337)
  --status: int@status-completer # Filter response based on the status of the attempt: Success (0), Pending (1), Failed (2), Sending (3), or Canceled (4)
  --before: string # Only include items created before a certain date (nullable, format: date-time)
  --after: string # Only include items created after a certain date (nullable, format: date-time)
  --with-content: oneof<nothing, bool> # When `true` message payloads are included in the response (default: true)
  --expanded-statuses: oneof<nothing, bool> # When `true`, return the Canceled (4) status in attempts.  If `false`, canceled attempts are returned as Success (0) for backwards compatibility. (default: false)
  --event-types: list # Filter response based on the event type (nullable)
]: nothing -> record<data: table<channels: list, deliverAt: string, eventId: string, eventType: string, id: string, nextAttempt: string, payload: record, status: int, statusText: string, tags: list, timestamp: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "with_content" $with_content "scalar") (serialize-qp "expanded_statuses" $expanded_statuses "scalar") (serialize-qp "event_types" $event_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/msg" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover Failed Webhooks
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/recover
# operationId: v1.endpoint.recover
export def "app-endpoint-recover v1endpointrecover" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  since: string # format: date-time
  --until: string # nullable, format: date-time
]: any -> record<id: string, status: string, task: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/recover")
  let body = {since: $since, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replay Missing Webhooks
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/replay-missing
# operationId: v1.endpoint.replay-missing
export def "app-endpoint-replay-missing v1endpointreplay-missing" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  since: string # format: date-time
  --until: string # nullable, format: date-time
]: any -> record<id: string, status: string, task: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/replay-missing")
  let body = {since: $since, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Endpoint Secret
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/secret
# operationId: v1.endpoint.get-secret
export def "app-endpoint-secret v1endpointget-secret" [
  app_id: string
  endpoint_id: string
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
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Endpoint Secret
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/secret/rotate
# operationId: v1.endpoint.rotate-secret
export def "app-endpoint-secret-rotate v1endpointrotate-secret" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --key: string # The endpoint's verification secret.  Format: `base64` encoded random bytes optionally prefixed with `whsec_`. It is recommended to not set this and let the server generate the secret. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/secret/rotate")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send Event Type Example Message
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/send-example
# operationId: v1.endpoint.send-example
export def "app-endpoint-send-example v1endpointsend-example" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  eventType: string # The event type's name (e.g. user.signup)
  --exampleIndex: int # If the event type schema contains an array of examples, chooses which one to send.  Defaults to the first example. Ignored if the schema doesn't contain an array of examples. (format: uint, default: 0)
]: any -> record<channels: list<string>, deliverAt: string, eventId: string, eventType: string, id: string, payload: record, tags: list<string>, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/send-example")
  let body = {eventType: $eventType, exampleIndex: $exampleIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Endpoint Stats
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/stats
# operationId: v1.endpoint.get-stats
export def "app-endpoint-stats v1endpointget-stats" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Filter the range to data starting from this date. (nullable, format: date-time)
  --until: string # Filter the range to data ending by this date. (nullable, format: date-time)
]: nothing -> record<canceled: int, fail: int, pending: int, sending: int, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Endpoint Transformation
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation
# operationId: v1.endpoint.transformation-get
export def "app-endpoint-transformation v1endpointtransformation-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, enabled: bool, updatedAt: string, variables: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/transformation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Endpoint Transformation
#
# PATCH /api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation
# operationId: v1.endpoint.patch-transformation
export def "app-endpoint-transformation v1endpointpatch-transformation" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # nullable, e.g. function handler(webhook) { /* ... */ }
  --enabled: oneof<nothing, bool>
  --body-variables: record # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/endpoint/($endpoint_id)/transformation")
  let body = {code: $code, enabled: $enabled, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Integrations
#
# GET /api/v1/app/{app_id}/integration
# operationId: v1.integration.list
export def "app-integration v1integrationlist" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. integ_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<createdAt: string, featureFlags: list, id: string, name: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Integration
#
# POST /api/v1/app/{app_id}/integration
# operationId: v1.integration.create
export def "app-integration v1integrationcreate" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --featureFlags: list # The set of feature flags the integration will have access to. (e.g. [])
  name: string # e.g. Example Integration
]: any -> record<createdAt: string, featureFlags: list<string>, id: string, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration")
  let body = {featureFlags: $featureFlags, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Integration
#
# GET /api/v1/app/{app_id}/integration/{integ_id}
# operationId: v1.integration.get
export def "app-integration v1integrationget" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, featureFlags: list<string>, id: string, name: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Integration
#
# PUT /api/v1/app/{app_id}/integration/{integ_id}
# operationId: v1.integration.update
export def "app-integration v1integrationupdate" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --featureFlags: list # The set of feature flags the integration will have access to. (e.g. [])
  name: string # e.g. Example Integration
]: any -> record<createdAt: string, featureFlags: list<string>, id: string, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)")
  let body = {featureFlags: $featureFlags, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Integration
#
# DELETE /api/v1/app/{app_id}/integration/{integ_id}
# operationId: v1.integration.delete
export def "app-integration v1integrationdelete" [
  app_id: string
  integ_id: string
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
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Integration Key
#
# GET /api/v1/app/{app_id}/integration/{integ_id}/key
# DEPRECATED
# operationId: v1.integration.get-key
@deprecated
export def "app-integration-key v1integrationget-key" [
  app_id: string
  integ_id: string
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
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)/key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Integration Key
#
# POST /api/v1/app/{app_id}/integration/{integ_id}/key/rotate
# operationId: v1.integration.rotate-key
export def "app-integration-key-rotate v1integrationrotate-key" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/integration/($integ_id)/key/rotate")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Messages
#
# GET /api/v1/app/{app_id}/msg
# operationId: v1.message.list
export def "app-msg v1messagelist" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. msg_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --channel: string # Filter response based on the channel. (nullable, e.g. project_1337)
  --before: string # Only include items created before a certain date. (nullable, format: date-time)
  --after: string # Only include items created after a certain date. (nullable, format: date-time)
  --with-content: oneof<nothing, bool> # When `true` message payloads are included in the response. (default: true)
  --tag: string # Filter messages matching the provided tag. (nullable, e.g. project_1337)
  --event-types: list # Filter response based on the event type (nullable)
]: nothing -> record<data: table<channels: list, deliverAt: string, eventId: string, eventType: string, id: string, payload: record, tags: list, timestamp: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "with_content" $with_content "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "event_types" $event_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Message
#
# POST /api/v1/app/{app_id}/msg
# operationId: v1.message.create
# --application shape: {metadata?: record, name: string, rateLimit?: int, throttleRate?: int, uid?: string}
export def "app-msg v1messagecreate" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-content: oneof<nothing, bool> # When `true`, message payloads are included in the response. (default: true)
  --idempotency-key: string # The request's idempotency key
  --application: record # shape: {metadata?: record, name: string, rateLimit?: int, throttleRate?: int, uid?: string}
  --channels: list # List of free-form identifiers that endpoints can filter by (nullable, e.g. [project_123, group_2])
  --deliverAt: string # The date and time at which the message will be delivered.  Note that this time is best-effort-only. Must be at least one minute and no more than 24 hours in the future. (nullable, format: date-time)
  --eventId: string # Optional unique identifier for the message (nullable, e.g. unique-identifier)
  eventType: string # The event type's name (e.g. user.signup)
  payload: record # JSON payload to send as the request body of the webhook.  We also support sending non-JSON payloads. Please contact us for more information. (e.g. {email: test@example.com, type: user.created, username: test_user})
  --payloadRetentionHours: int # Optional number of hours to retain the message payload. Note that this is mutually exclusive with `payloadRetentionPeriod`. (nullable, format: int64)
  --payloadRetentionPeriod: int # Optional number of days to retain the message payload. Defaults to 90. Note that this is mutually exclusive with `payloadRetentionHours`. (nullable, format: int64, default: 90, e.g. 90)
  --tags: list # List of free-form tags that can be filtered by when listing messages (nullable, e.g. [my_tag, other])
  --transformationsParams: record # Extra parameters to pass to Transformations (for future use) (nullable)
]: any -> record<channels: list<string>, deliverAt: string, eventId: string, eventType: string, id: string, payload: record, tags: list<string>, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_content" $with_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg" $qp)
  let body = {application: $application, channels: $channels, deliverAt: $deliverAt, eventId: $eventId, eventType: $eventType, payload: $payload, payloadRetentionHours: $payloadRetentionHours, payloadRetentionPeriod: $payloadRetentionPeriod, tags: $tags, transformationsParams: $transformationsParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Expunge all message contents
#
# POST /api/v1/app/{app_id}/msg/expunge-all-contents
# operationId: v1.message.expunge-all-contents
export def "app-msg-expunge-all-contents v1messageexpunge-all-contents" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<id: string, status: string, task: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/expunge-all-contents")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Message Precheck
#
# POST /api/v1/app/{app_id}/msg/precheck/active
# operationId: v1.message.precheck
export def "app-msg-precheck-active v1messageprecheck" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --channels: list # nullable, e.g. [project_123, group_2]
  eventType: string # The event type's name (e.g. user.signup)
]: any -> record<active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/precheck/active")
  let body = {channels: $channels, eventType: $eventType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Message
#
# GET /api/v1/app/{app_id}/msg/{msg_id}
# operationId: v1.message.get
export def "app-msg v1messageget" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-content: oneof<nothing, bool> # When `true` message payloads are included in the response. (default: true)
]: nothing -> record<channels: list<string>, deliverAt: string, eventId: string, eventType: string, id: string, payload: record, tags: list<string>, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_content" $with_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Attempt
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}
# operationId: v1.message-attempt.get
export def "app-msg-attempt v1message-attemptget" [
  app_id: string
  msg_id: string
  attempt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expanded-statuses: oneof<nothing, bool> # When `true`, return the Canceled (4) status in attempts.  If `false`, canceled attempts are returned as Success (0) for backwards compatibility. (default: false)
]: nothing -> record<endpointId: string, id: string, msg: record<channels: list<string>, deliverAt: string, eventId: string, eventType: string, id: string, payload: record, tags: list<string>, timestamp: string>, msgId: string, response: string, responseDurationMs: int, responseStatusCode: int, status: int, statusText: string, timestamp: string, triggerType: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expanded_statuses" $expanded_statuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/attempt/($attempt_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete attempt response body
#
# DELETE /api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}/content
# operationId: v1.message-attempt.expunge-content
export def "app-msg-attempt-content v1message-attemptexpunge-content" [
  app_id: string
  msg_id: string
  attempt_id: string
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
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/attempt/($attempt_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete message payload
#
# DELETE /api/v1/app/{app_id}/msg/{msg_id}/content
# operationId: v1.message.expunge-content
export def "app-msg-content v1messageexpunge-content" [
  app_id: string
  msg_id: string
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
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Attempted Destinations
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/endpoint
# operationId: v1.message-attempt.list-attempted-destinations
export def "app-msg-endpoint v1message-attemptlist-attempted-destinations" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2)
]: nothing -> record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, nextAttempt: string, rateLimit: int, status: int, statusText: string, throttleRate: int, uid: string, updatedAt: string, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/endpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend Webhook
#
# POST /api/v1/app/{app_id}/msg/{msg_id}/endpoint/{endpoint_id}/resend
# operationId: v1.message-attempt.resend
export def "app-msg-endpoint-resend v1message-attemptresend" [
  app_id: string
  msg_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/msg/($msg_id)/endpoint/($endpoint_id)/resend")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Poller Poll
#
# GET /api/v1/app/{app_id}/poller/{sink_id}
# operationId: v1.message.poller.poll
export def "app-poller v1messagepollerpoll" [
  app_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable)
  --event-type: string # Filters messages sent with this event type (optional). (nullable, e.g. user.signup)
  --channel: string # Filters messages sent with this channel (optional). (nullable, e.g. project_1337)
  --after: string # nullable, format: date-time
]: nothing -> record<data: table<channels: list, deliverAt: string, eventId: string, eventType: string, headers: record, id: string, payload: record, tags: list, timestamp: string>, done: bool, iterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/poller/($sink_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Poller Consumer Poll
#
# GET /api/v1/app/{app_id}/poller/{sink_id}/consumer/{consumer_id}
# operationId: v1.message.poller.consumer-poll
export def "app-poller-consumer v1messagepollerconsumer-poll" [
  app_id: string
  sink_id: string
  consumer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable)
]: nothing -> record<data: table<channels: list, deliverAt: string, eventId: string, eventType: string, headers: record, id: string, payload: record, tags: list, timestamp: string>, done: bool, iterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/app/($app_id)/poller/($sink_id)/consumer/($consumer_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Poller Consumer Seek
#
# POST /api/v1/app/{app_id}/poller/{sink_id}/consumer/{consumer_id}/seek
# operationId: v1.message.poller.consumer-seek
export def "app-poller-consumer-seek v1messagepollerconsumer-seek" [
  app_id: string
  sink_id: string
  consumer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  after: string # format: date-time, e.g. 2025-04-21T11:20:34Z
]: any -> record<iterator: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/app/($app_id)/poller/($sink_id)/consumer/($consumer_id)/seek")
  let body = {after: $after} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Consumer App Portal Access
#
# POST /api/v1/auth/app-portal-access/{app_id}
# operationId: v1.authentication.app-portal-access
# --application shape: {metadata?: record, name: string, rateLimit?: int, throttleRate?: int, uid?: string}
@deprecated --flag readOnly
export def "auth-app-portal-access v1authenticationapp-portal-access" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --application: record # shape: {metadata?: record, name: string, rateLimit?: int, throttleRate?: int, uid?: string}
  --capabilities: list # Custom capabilities attached to the token, You can combine as many capabilities as necessary.  The `ViewBase` capability is always required  - `ViewBase`: Basic read only permissions, does not allow the user to see the endpoint secret.  - `ViewEndpointSecret`: Allows user to view the endpoint secret.  - `ManageEndpointSecret`: Allows user to rotate and view the endpoint secret.  - `ManageTransformations`: Allows user to modify the endpoint transformations.  - `CreateAttempts`: Allows user to replay missing messages and send example messages.  - `ManageEndpoint`: Allows user to read/modify any field or configuration of an endpoint (including secrets)  By default, the token will get all capabilities if the capabilities are not explicitly specified. (nullable, e.g. [ViewBase, ViewEndpointSecret])
  --expiry: int # How long the token will be valid for, in seconds.  Valid values are between 1 hour and 7 days. The default is 7 days. (nullable, format: uint64, default: 604800)
  --featureFlags: list # The set of feature flags the created token will have access to. (e.g. [])
  --readOnly: oneof<nothing, bool> # Whether the app portal should be in read-only mode. (DEPRECATED, nullable)
  --sessionId: string # An optional session ID to attach to the token.  When expiring tokens with "Expire All", you can include the session ID to only expire tokens that were created with that session ID. (nullable, e.g. user_1FB8)
]: any -> record<token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/app-portal-access/($app_id)")
  let body = {application: $application, capabilities: $capabilities, expiry: $expiry, featureFlags: $featureFlags, readOnly: $readOnly, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Expire All
#
# POST /api/v1/auth/app/{app_id}/expire-all
# operationId: v1.authentication.expire-all
export def "auth-app-expire-all v1authenticationexpire-all" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --expiry: int # How many seconds until the old key is expired. (nullable, format: int64, e.g. 60)
  --sessionIds: list # An optional list of session ids.  If any session ids are specified, only Application tokens created with that session id will be expired.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/app/($app_id)/expire-all")
  let body = {expiry: $expiry, sessionIds: $sessionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Logout
#
# POST /api/v1/auth/logout
# operationId: v1.authentication.logout
export def "auth-logout v1authenticationlogout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/logout")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stream Logout
#
# POST /api/v1/auth/stream-logout
# operationId: v1.authentication.stream-logout
export def "auth-stream-logout v1authenticationstream-logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/stream-logout")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Stream Portal Access
#
# POST /api/v1/auth/stream-portal-access/{stream_id}
# operationId: v1.authentication.stream-portal-access
export def "auth-stream-portal-access v1authenticationstream-portal-access" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --expiry: int # How long the token will be valid for, in seconds.  Valid values are between 1 hour and 7 days. The default is 7 days. (nullable, format: uint64, default: 604800)
  --featureFlags: list # The set of feature flags the created token will have access to. (e.g. [])
  --sessionId: string # An optional session ID to attach to the token.  When expiring tokens with "Expire All", you can include the session ID to only expire tokens that were created with that session ID. (nullable, e.g. user_1FB8)
]: any -> record<token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/stream-portal-access/($stream_id)")
  let body = {expiry: $expiry, featureFlags: $featureFlags, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stream Expire All
#
# POST /api/v1/auth/stream/{stream_id}/expire-all
# operationId: v1.authentication.stream-expire-all
export def "auth-stream-expire-all v1authenticationstream-expire-all" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --expiry: int # How many seconds until the old key is expired. (nullable, format: int64, e.g. 60)
  --sessionIds: list # An optional list of session ids.  If any session ids are specified, only Stream tokens created with that session id will be expired.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/stream/($stream_id)/expire-all")
  let body = {expiry: $expiry, sessionIds: $sessionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Poller Token
#
# GET /api/v1/auth/stream/{stream_id}/sink/{sink_id}/poller/token
# operationId: v1.authentication.get-stream-poller-token
export def "auth-stream-sink-poller-token v1authenticationget-stream-poller-token" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, expiresAt: string, id: string, name: string, scopes: list<string>, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/stream/($stream_id)/sink/($sink_id)/poller/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Poller Token
#
# POST /api/v1/auth/stream/{stream_id}/sink/{sink_id}/poller/token/rotate
# operationId: v1.authentication.rotate-stream-poller-token
export def "auth-stream-sink-poller-token-rotate v1authenticationrotate-stream-poller-token" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --expiry: int # How long the token will be valid for, in seconds. Can be up to 31,536,000 seconds (1 year). (nullable, format: int64)
  --oldTokenExpiry: int # Updates the previous token's expiration, in seconds.  If set to 0, the old token will immediately be revoked. Must be between 0 and 86,400 seconds (1 day).  Defaults to 300 seconds (5 minutes). (format: int64, default: 300)
]: any -> record<createdAt: string, expiresAt: string, id: string, name: string, scopes: list<string>, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/stream/($stream_id)/sink/($sink_id)/poller/token/rotate")
  let body = {expiry: $expiry, oldTokenExpiry: $oldTokenExpiry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Background Tasks
#
# GET /api/v1/background-task
# operationId: v1.background-task.list
export def "background-task v1background-tasklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # Filter the response based on the status.
  --task: string@task-completer # Filter the response based on the type.
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. qtask_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<data: record, id: string, status: string, task: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "task" $task "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/background-task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Background Task
#
# GET /api/v1/background-task/{task_id}
# operationId: v1.background-task.get
export def "background-task v1background-taskget" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record, id: string, status: string, task: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/background-task/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Connectors
#
# GET /api/v1/connector
# operationId: v1.connector.list
export def "connector v1connectorlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. trtmpl_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --order: string@order-completer # The sorting order of the returned items
  --product-type: string@product-type-completer
]: nothing -> record<data: table<allowedEventTypes: list, createdAt: string, description: string, featureFlags: list, id: string, instructions: string, kind: string, logo: string, name: string, orgId: string, productType: string, transformation: string, transformationUpdatedAt: string, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "product_type" $product_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/connector" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Connector
#
# POST /api/v1/connector
# operationId: v1.connector.create
export def "connector v1connectorcreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --allowedEventTypes: list # nullable, e.g. [user.signup, user.deleted]
  --description: string # default: , e.g. Example connector description
  --featureFlags: list # nullable
  --instructions: string # default: , e.g. Markdown-formatted instructions
  --kind: string@kind-completer
  --logo: string # nullable, format: uri, e.g. https://example.com/logo.png
  name: string # e.g. My first connector
  --productType: string@productType-completer
  transformation: string # e.g. function handler(webhook) { /* ... */ }
  --uid: string # The Connector's UID. (nullable, e.g. unique-identifier)
]: any -> record<allowedEventTypes: list<string>, createdAt: string, description: string, featureFlags: list<string>, id: string, instructions: string, kind: string, logo: string, name: string, orgId: string, productType: string, transformation: string, transformationUpdatedAt: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/connector")
  let body = {allowedEventTypes: $allowedEventTypes, description: $description, featureFlags: $featureFlags, instructions: $instructions, kind: $kind, logo: $logo, name: $name, productType: $productType, transformation: $transformation, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Connector
#
# GET /api/v1/connector/{connector_id}
# operationId: v1.connector.get
export def "connector v1connectorget" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allowedEventTypes: list<string>, createdAt: string, description: string, featureFlags: list<string>, id: string, instructions: string, kind: string, logo: string, name: string, orgId: string, productType: string, transformation: string, transformationUpdatedAt: string, uid: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/connector/($connector_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Connector
#
# PUT /api/v1/connector/{connector_id}
# operationId: v1.connector.update
export def "connector v1connectorupdate" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowedEventTypes: list # nullable, e.g. [user.signup, user.deleted]
  --description: string # default: , e.g. Example connector description
  --featureFlags: list # nullable, e.g. [cool-new-feature]
  --instructions: string # default: , e.g. Markdown-formatted instructions
  --kind: string@kind-completer
  --logo: string # nullable, format: uri, e.g. https://example.com/logo.png
  --name: string # default: , e.g. My first connector
  transformation: string # e.g. function handler(webhook) { /* ... */ }
]: any -> record<allowedEventTypes: list<string>, createdAt: string, description: string, featureFlags: list<string>, id: string, instructions: string, kind: string, logo: string, name: string, orgId: string, productType: string, transformation: string, transformationUpdatedAt: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/connector/($connector_id)")
  let body = {allowedEventTypes: $allowedEventTypes, description: $description, featureFlags: $featureFlags, instructions: $instructions, kind: $kind, logo: $logo, name: $name, transformation: $transformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Connector
#
# DELETE /api/v1/connector/{connector_id}
# operationId: v1.connector.delete
export def "connector v1connectordelete" [
  connector_id: string
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
  let full_url = (build-url $base $"/api/v1/connector/($connector_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Connector
#
# PATCH /api/v1/connector/{connector_id}
# operationId: v1.connector.patch
export def "connector v1connectorpatch" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowedEventTypes: list # nullable, e.g. [user.signup, user.deleted]
  --description: string
  --featureFlags: list # nullable, e.g. [cool-new-feature]
  --instructions: string
  --kind: string@kind-completer
  --logo: string # nullable, format: uri
  --name: string
  --transformation: string
]: any -> record<allowedEventTypes: list<string>, createdAt: string, description: string, featureFlags: list<string>, id: string, instructions: string, kind: string, logo: string, name: string, orgId: string, productType: string, transformation: string, transformationUpdatedAt: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/connector/($connector_id)")
  let body = {allowedEventTypes: $allowedEventTypes, description: $description, featureFlags: $featureFlags, instructions: $instructions, kind: $kind, logo: $logo, name: $name, transformation: $transformation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export Environment Configuration
#
# POST /api/v1/environment/export
# operationId: v1.environment.export
export def "environment-export v1environmentexport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<connectors: table<allowedEventTypes: list, createdAt: string, description: string, featureFlags: list, id: string, instructions: string, kind: string, logo: string, name: string, orgId: string, productType: string, transformation: string, transformationUpdatedAt: string, uid: string, updatedAt: string>, createdAt: string, eventTypes: table<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlag: string, featureFlags: list, groupName: string, name: string, schemas: record, updatedAt: string>, settings: record, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/environment/export")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import Environment Configuration
#
# POST /api/v1/environment/import
# operationId: v1.environment.import
# --connectors item shape: {allowedEventTypes?: list, description?: string, featureFlags?: list, instructions?: string, kind?: "Custom"|"AgenticCommerceProtocol"|"CloseCRM"|"CustomerIO"|"Discord"|"Hubspot"|"Inngest"|"Loops"|"Otel"|"Resend"|"Salesforce"|"Segment"|"Sendgrid"|"Slack"|"Teams"|"TriggerDev"|"Windmill"|"Zapier", logo?: string, name: string, productType?: "Dispatch"|"Stream", transformation: string, uid?: string}
# --eventTypes item shape: {archived?: bool, deprecated?: bool, description: string, featureFlag?: string, featureFlags?: list, groupName?: string, name: string, schemas?: record}
export def "environment-import v1environmentimport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --connectors: list # nullable — item shape: {allowedEventTypes?: list, description?: string, featureFlags?: list, instructions?: string, kind?: "Custom"|"AgenticCommerceProtocol"|"CloseCRM"|"CustomerIO"|"Discord"|"Hubspot"|"Inngest"|"Loops"|"Otel"|"Resend"|"Salesforce"|"Segment"|"Sendgrid"|"Slack"|"Teams"|"TriggerDev"|"Windmill"|"Zapier", logo?: string, name: string, productType?: "Dispatch"|"Stream", transformation: string, uid?: string}
  --eventTypes: list # nullable — item shape: {archived?: bool, deprecated?: bool, description: string, featureFlag?: string, featureFlags?: list, groupName?: string, name: string, schemas?: record}
  --settings: record # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/environment/import")
  let body = {connectors: $connectors, eventTypes: $eventTypes, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Event Types
#
# GET /api/v1/event-type
# operationId: v1.event-type.list
export def "event-type v1event-typelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. user.signup)
  --order: string@order-completer # The sorting order of the returned items
  --include-archived: oneof<nothing, bool> # When `true` archived (deleted but not expunged) items are included in the response. (default: false)
  --with-content: oneof<nothing, bool> # When `true` the full item (including the schema) is included in the response. (default: false)
]: nothing -> record<data: table<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlag: string, featureFlags: list, groupName: string, name: string, schemas: record, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "include_archived" $include_archived "scalar") (serialize-qp "with_content" $with_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/event-type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Event Type
#
# POST /api/v1/event-type
# operationId: v1.event-type.create
@deprecated --flag featureFlag
export def "event-type v1event-typecreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --archived: oneof<nothing, bool> # default: false, e.g. false
  --deprecated: oneof<nothing, bool> # default: false
  description: string # e.g. A user has signed up
  --featureFlag: string # Deprecated, use `featureFlags` instead. (DEPRECATED, nullable)
  --featureFlags: list # nullable, e.g. [cool-new-feature]
  --groupName: string # The event type group's name (nullable, e.g. user)
  name: string # The event type's name (e.g. user.signup)
  --schemas: record # The schema for the event type for a specific version as a JSON schema. (nullable, e.g. {1: {description: An invoice was paid by a user, properties: {invoiceId: {description: The invoice id, type: string}, userId: {description: The user id, type: string}}, required: [invoiceId, userId], title: Invoice Paid Event, type: object}})
]: any -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlag: string, featureFlags: list<string>, groupName: string, name: string, schemas: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/event-type")
  let body = {archived: $archived, deprecated: $deprecated, description: $description, featureFlag: $featureFlag, featureFlags: $featureFlags, groupName: $groupName, name: $name, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Event Type Import From Openapi
#
# POST /api/v1/event-type/import/openapi
# operationId: v1.event-type.import-openapi
export def "event-type-import-openapi v1event-typeimport-openapi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --dryRun: oneof<nothing, bool> # If `true`, return the event types that would be modified without actually modifying them. (default: false)
  --replaceAll: oneof<nothing, bool> # If `true`, all existing event types that are not in the spec will be archived. (default: false)
  --spec: record # A pre-parsed JSON spec. (nullable, e.g. {info: {title: Webhook Example, version: 1.0.0}, openapi: 3.1.0, webhooks: {pet.new: {post: {requestBody: {content: {application/json: {schema: {properties: {id: {format: int64, type: integer}, name: {type: string}, tag: {type: string}}, required: [id, name]}}}, description: Information about a new pet in the system}, responses: {200: {description: Return a 200 status to indicate that the data was received successfully}}}}}})
  --specRaw: string # A string, parsed by the server as YAML or JSON. (nullable, e.g.  # Both YAML and JSON are supported openapi: 3.1.0 info:   title: Webhook Example   version: 1.0.0 # Since OAS 3.1.0 the paths element isn't necessary. Now a valid OpenAPI Document can describe only paths, webhooks, or even only reusable components webhooks:   # Each webhook needs a name   "pet.new":     # This is a Path Item Object, the only difference is that the request is initiated by the API provider     post:       requestBody:         description: Information about a new pet in the system         content:           application/json:             schema:               $ref: "#/components/schemas/Pet"       responses:         "200":           description: Return a 200 status to indicate that the data was received successfully  components:   schemas:     Pet:       required:         - id         - name       properties:         id:           type: integer           format: int64         name:           type: string         tag:           type: string )
]: any -> record<data: record<modified: list<string>, to_modify: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/event-type/import/openapi")
  let body = {dryRun: $dryRun, replaceAll: $replaceAll, spec: $spec, specRaw: $specRaw} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Event Type
#
# GET /api/v1/event-type/{event_type_name}
# operationId: v1.event-type.get
export def "event-type v1event-typeget" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlag: string, featureFlags: list<string>, groupName: string, name: string, schemas: record, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-type/($event_type_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Event Type
#
# PUT /api/v1/event-type/{event_type_name}
# operationId: v1.event-type.update
@deprecated --flag featureFlag
export def "event-type v1event-typeupdate" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # default: false, e.g. false
  --deprecated: oneof<nothing, bool> # default: false
  description: string # e.g. A user has signed up
  --featureFlag: string # Deprecated, use `featureFlags` instead. (DEPRECATED, nullable)
  --featureFlags: list # nullable, e.g. [cool-new-feature]
  --groupName: string # The event type group's name (nullable, e.g. user)
  --schemas: record # The schema for the event type for a specific version as a JSON schema. (nullable, e.g. {1: {description: An invoice was paid by a user, properties: {invoiceId: {description: The invoice id, type: string}, userId: {description: The user id, type: string}}, required: [invoiceId, userId], title: Invoice Paid Event, type: object}})
]: any -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlag: string, featureFlags: list<string>, groupName: string, name: string, schemas: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-type/($event_type_name)")
  let body = {archived: $archived, deprecated: $deprecated, description: $description, featureFlag: $featureFlag, featureFlags: $featureFlags, groupName: $groupName, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Event Type
#
# DELETE /api/v1/event-type/{event_type_name}
# operationId: v1.event-type.delete
export def "event-type v1event-typedelete" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expunge: oneof<nothing, bool> # By default event types are archived when "deleted". Passing this to `true` deletes them entirely. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expunge" $expunge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/event-type/($event_type_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Event Type
#
# PATCH /api/v1/event-type/{event_type_name}
# operationId: v1.event-type.patch
@deprecated --flag featureFlag
export def "event-type v1event-typepatch" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool>
  --deprecated: oneof<nothing, bool>
  --description: string
  --featureFlag: string # Deprecated, use `featureFlags` instead. (DEPRECATED, nullable)
  --featureFlags: list # nullable, e.g. [cool-new-feature]
  --groupName: string # The event type group's name (nullable, e.g. user)
  --schemas: record # nullable, e.g. {description: An invoice was paid by a user, properties: {invoiceId: {description: The invoice id, type: string}, userId: {description: The user id, type: string}}, required: [invoiceId, userId], title: Invoice Paid Event, type: object}
]: any -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlag: string, featureFlags: list<string>, groupName: string, name: string, schemas: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-type/($event_type_name)")
  let body = {archived: $archived, deprecated: $deprecated, description: $description, featureFlag: $featureFlag, featureFlags: $featureFlags, groupName: $groupName, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Health
#
# GET /api/v1/health
# operationId: v1.health.get
export def "health v1healthget" [
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
  let full_url = (build-url $base "/api/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Operational Webhook Endpoints
#
# GET /api/v1/operational-webhook/endpoint
# operationId: v1.operational-webhook.endpoint.list
export def "operational-webhook-endpoint v1operational-webhookendpointlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/operational-webhook/endpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Operational Webhook Endpoint
#
# POST /api/v1/operational-webhook/endpoint
# operationId: v1.operational-webhook.endpoint.create
@deprecated --flag rateLimit
export def "operational-webhook-endpoint v1operational-webhookendpointcreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filterTypes: list # nullable, e.g. [message.attempt.failing]
  --metadata: record # default: {}
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --secret: string # The endpoint's verification secret.  Format: `base64` encoded random bytes optionally prefixed with `whsec_`. It is recommended to not set this and let the server generate the secret. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
  --throttleRate: int # Maximum messages per second to send to this endpoint.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # Optional unique identifier for the endpoint. (nullable, e.g. unique-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
]: any -> record<createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/operational-webhook/endpoint")
  let body = {description: $description, disabled: $disabled, filterTypes: $filterTypes, metadata: $metadata, rateLimit: $rateLimit, secret: $secret, throttleRate: $throttleRate, uid: $uid, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Operational Webhook Endpoint
#
# GET /api/v1/operational-webhook/endpoint/{endpoint_id}
# operationId: v1.operational-webhook.endpoint.get
export def "operational-webhook-endpoint v1operational-webhookendpointget" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/operational-webhook/endpoint/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Operational Webhook Endpoint
#
# PUT /api/v1/operational-webhook/endpoint/{endpoint_id}
# operationId: v1.operational-webhook.endpoint.update
@deprecated --flag rateLimit
export def "operational-webhook-endpoint v1operational-webhookendpointupdate" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filterTypes: list # nullable, e.g. [message.attempt.failing]
  --metadata: record # default: {}
  --rateLimit: int # Deprecated, use `throttleRate` instead. (DEPRECATED, nullable, format: uint16)
  --throttleRate: int # Maximum messages per second to send to this endpoint.  Outgoing messages will be throttled to this rate. (nullable, format: uint16)
  --uid: string # Optional unique identifier for the endpoint. (nullable, e.g. unique-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
]: any -> record<createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, throttleRate: int, uid: string, updatedAt: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/operational-webhook/endpoint/($endpoint_id)")
  let body = {description: $description, disabled: $disabled, filterTypes: $filterTypes, metadata: $metadata, rateLimit: $rateLimit, throttleRate: $throttleRate, uid: $uid, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Operational Webhook Endpoint
#
# DELETE /api/v1/operational-webhook/endpoint/{endpoint_id}
# operationId: v1.operational-webhook.endpoint.delete
export def "operational-webhook-endpoint v1operational-webhookendpointdelete" [
  endpoint_id: string
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
  let full_url = (build-url $base $"/api/v1/operational-webhook/endpoint/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Operational Webhook Endpoint Headers
#
# GET /api/v1/operational-webhook/endpoint/{endpoint_id}/headers
# operationId: v1.operational-webhook.endpoint.get-headers
export def "operational-webhook-endpoint-headers v1operational-webhookendpointget-headers" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<headers: record, sensitive: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/operational-webhook/endpoint/($endpoint_id)/headers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Operational Webhook Endpoint Headers
#
# PUT /api/v1/operational-webhook/endpoint/{endpoint_id}/headers
# operationId: v1.operational-webhook.endpoint.update-headers
export def "operational-webhook-endpoint-headers v1operational-webhookendpointupdate-headers" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/operational-webhook/endpoint/($endpoint_id)/headers")
  let body = {headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Operational Webhook Endpoint Secret
#
# GET /api/v1/operational-webhook/endpoint/{endpoint_id}/secret
# operationId: v1.operational-webhook.endpoint.get-secret
export def "operational-webhook-endpoint-secret v1operational-webhookendpointget-secret" [
  endpoint_id: string
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
  let full_url = (build-url $base $"/api/v1/operational-webhook/endpoint/($endpoint_id)/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Operational Webhook Endpoint Secret
#
# POST /api/v1/operational-webhook/endpoint/{endpoint_id}/secret/rotate
# operationId: v1.operational-webhook.endpoint.rotate-secret
export def "operational-webhook-endpoint-secret-rotate v1operational-webhookendpointrotate-secret" [
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --key: string # The endpoint's verification secret.  Format: `base64` encoded random bytes optionally prefixed with `whsec_`. It is recommended to not set this and let the server generate the secret. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/operational-webhook/endpoint/($endpoint_id)/secret/rotate")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Aggregate App Stats
#
# POST /api/v1/stats/usage/app
# operationId: v1.statistics.aggregate-app-stats
export def "stats-usage-app v1statisticsaggregate-app-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --appIds: list # Specific app IDs or UIDs to aggregate stats for.  Note that if none of the given IDs or UIDs are resolved, a 422 response will be given. (nullable)
  since: string # format: date-time
  until: string # format: date-time
]: any -> record<id: string, status: string, task: string, unresolvedAppIds: list<string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/stats/usage/app")
  let body = {appIds: $appIds, since: $since, until: $until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Aggregate Event Types
#
# PUT /api/v1/stats/usage/event-types
# operationId: v1.statistics.aggregate-event-types
export def "stats-usage-event-types v1statisticsaggregate-event-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, task: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/stats/usage/event-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Streams
#
# GET /api/v1/stream
# operationId: v1.streaming.stream.list
export def "stream v1streamingstreamlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. strm_2yZwUhtgs5Ai8T9yRQJXA)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<createdAt: string, id: string, metadata: record, name: string, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Stream
#
# POST /api/v1/stream
# operationId: v1.streaming.stream.create
export def "stream v1streamingstreamcreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --metadata: record # default: {}
  name: string # The stream's name.
  --uid: string # An optional unique identifier for the stream. (nullable, e.g. unique-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/stream")
  let body = {metadata: $metadata, name: $name, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Stream Event Types
#
# GET /api/v1/stream/event-type
# operationId: v1.streaming.event-type.list
export def "stream-event-type v1streamingevent-typelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. user.signup)
  --order: string@order-completer # The sorting order of the returned items
  --include-archived: oneof<nothing, bool> # Include archived (deleted but not expunged) items in the response. (default: false)
]: nothing -> record<data: table<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlags: list, name: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "include_archived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stream/event-type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Stream Event Type
#
# POST /api/v1/stream/event-type
# operationId: v1.streaming.event-type.create
export def "stream-event-type v1streamingevent-typecreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --archived: oneof<nothing, bool> # default: false
  --deprecated: oneof<nothing, bool> # default: false
  --description: string # nullable
  --featureFlags: list # nullable, e.g. [cool-new-feature]
  name: string # The event type's name (e.g. user.signup)
]: any -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlags: list<string>, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/stream/event-type")
  let body = {archived: $archived, deprecated: $deprecated, description: $description, featureFlags: $featureFlags, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Stream Event Type
#
# GET /api/v1/stream/event-type/{name}
# operationId: v1.streaming.event-type.get
export def "stream-event-type v1streamingevent-typeget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlags: list<string>, name: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/event-type/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Stream Event Type
#
# PUT /api/v1/stream/event-type/{name}
# operationId: v1.streaming.event-type.update
export def "stream-event-type v1streamingevent-typeupdate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool> # default: false
  --deprecated: oneof<nothing, bool> # default: false
  --description: string # nullable
  --featureFlags: list # nullable, e.g. [cool-new-feature]
  --body-name: string # The event type's name (e.g. user.signup)
]: any -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlags: list<string>, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/event-type/($name)")
  let body = {archived: $archived, deprecated: $deprecated, description: $description, featureFlags: $featureFlags, name: $body_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Stream Event Type
#
# DELETE /api/v1/stream/event-type/{name}
# operationId: v1.streaming.event-type.delete
export def "stream-event-type v1streamingevent-typedelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expunge: oneof<nothing, bool> # By default, event types are archived when "deleted". With this flag, they are deleted entirely. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expunge" $expunge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/event-type/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Stream Event Type
#
# PATCH /api/v1/stream/event-type/{name}
# operationId: v1.streaming.event-type.patch
export def "stream-event-type v1streamingevent-typepatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: oneof<nothing, bool>
  --deprecated: oneof<nothing, bool>
  --description: string # nullable
  --featureFlags: list # nullable, e.g. [cool-new-feature]
]: any -> record<archived: bool, createdAt: string, deprecated: bool, description: string, featureFlags: list<string>, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/event-type/($name)")
  let body = {archived: $archived, deprecated: $deprecated, description: $description, featureFlags: $featureFlags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Stream
#
# GET /api/v1/stream/{stream_id}
# operationId: v1.streaming.stream.get
export def "stream v1streamingstreamget" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, id: string, metadata: record, name: string, uid: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Stream
#
# PUT /api/v1/stream/{stream_id}
# operationId: v1.streaming.stream.update
export def "stream v1streamingstreamupdate" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # default: {}
  name: string # The stream's name.
  --uid: string # An optional unique identifier for the stream. (nullable, e.g. unique-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)")
  let body = {metadata: $metadata, name: $name, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Stream
#
# DELETE /api/v1/stream/{stream_id}
# operationId: v1.streaming.stream.delete
export def "stream v1streamingstreamdelete" [
  stream_id: string
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
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Stream
#
# PATCH /api/v1/stream/{stream_id}
# operationId: v1.streaming.stream.patch
export def "stream v1streamingstreampatch" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The Stream's description.
  --metadata: record
  --uid: string # An optional unique identifier for the stream. (nullable, e.g. unique-identifier)
]: any -> record<createdAt: string, id: string, metadata: record, name: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)")
  let body = {description: $description, metadata: $metadata, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Events
#
# POST /api/v1/stream/{stream_id}/events
# operationId: v1.streaming.events.create
# --events item shape: {eventType: string, payload: string}
# --stream shape: {metadata?: record, name: string, uid?: string}
export def "stream-events v1streamingeventscreate" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  events: list # e.g. [{eventType: user.signup, payload: {"email":"test@example.com","username":"test_user"}}] — item shape: {eventType: string, payload: string}
  --stream: record # shape: {metadata?: record, name: string, uid?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/events")
  let body = {events: $events, stream: $stream} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Sinks
#
# GET /api/v1/stream/{stream_id}/sink
# operationId: v1.streaming.sink.list
export def "stream-sink v1streamingsinklist" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. sink_2yZwUhtgs5Ai8T9yRQJXA)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<batchSize: int, createdAt: string, currentIterator: string, eventTypes: list, failureReason: string, id: string, maxWaitSecs: int, metadata: record, nextRetryAt: string, status: string, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Sink
#
# POST /api/v1/stream/{stream_id}/sink
# Discriminator (request): type = amazonS3, azureBlobStorage, bigQuery, clickhouse, eventBridge, googleCloudPubSub, googleCloudStorage, http, otelTracing, poller, rabbitMq, redshift, snowflake, sns, sqs
# operationId: v1.streaming.sink.create
# --config shape: {accessKey: string, account: string, container: string}
export def "stream-sink v1streamingsinkcreate" [
  stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --batchSize: int # How many events will be batched in a request to the Sink. (format: uint16, default: 100, e.g. 100)
  --eventTypes: list # A list of event types that filter which events are dispatched to the Sink. An empty list (or null) will not filter out any events. (default: [])
  --maxWaitSecs: int # How long to wait before a batch of events is sent, if the `batchSize` is not reached.  For example, with a `batchSize` of 100 and `maxWaitSecs` of 10, we will send a request after 10 seconds or 100 events, whichever comes first.  Note that we will never send an empty batch of events to the Sink. (format: uint16, default: 0)
  --metadata: record # default: {}
  --status: string@status-completer-2
  --uid: string # An optional unique identifier for the sink. (nullable, e.g. unique-identifier)
  type: string@type-completer
  --config: record # shape: {accessKey: string, account: string, container: string}
]: any -> record<batchSize: int, createdAt: string, currentIterator: string, eventTypes: list<string>, failureReason: string, id: string, maxWaitSecs: int, metadata: record, nextRetryAt: string, status: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink")
  let body = {batchSize: $batchSize, eventTypes: $eventTypes, maxWaitSecs: $maxWaitSecs, metadata: $metadata, status: $status, uid: $uid, type: $type, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Sink
#
# GET /api/v1/stream/{stream_id}/sink/{sink_id}
# Discriminator (response): type = amazonS3, azureBlobStorage, bigQuery, clickhouse, eventBridge, googleCloudPubSub, googleCloudStorage, http, otelTracing, poller, rabbitMq, redshift, snowflake, sns, sqs
# operationId: v1.streaming.sink.get
export def "stream-sink v1streamingsinkget" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<batchSize: int, createdAt: string, currentIterator: string, eventTypes: list<string>, failureReason: string, id: string, maxWaitSecs: int, metadata: record, nextRetryAt: string, status: string, uid: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Sink
#
# PUT /api/v1/stream/{stream_id}/sink/{sink_id}
# Discriminator (request): type = amazonS3, azureBlobStorage, bigQuery, clickhouse, eventBridge, googleCloudPubSub, googleCloudStorage, http, otelTracing, poller, rabbitMq, redshift, snowflake, sns, sqs
# operationId: v1.streaming.sink.update
# --config shape: {accessKey: string, account: string, container: string}
export def "stream-sink v1streamingsinkupdate" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --batchSize: int # How many events will be batched in a request to the Sink. (format: uint16, default: 100, e.g. 100)
  --eventTypes: list # A list of event types that filter which events are dispatched to the Sink. An empty list (or null) will not filter out any events. (default: [])
  --maxWaitSecs: int # How long to wait before a batch of events is sent, if the `batchSize` is not reached.  For example, with a `batchSize` of 100 and `maxWaitSecs` of 10, we will send a request after 10 seconds or 100 events, whichever comes first.  Note that we will never send an empty batch of events to the Sink. (format: uint16, default: 0)
  --metadata: record # default: {}
  --status: string@status-completer-2
  --uid: string # An optional unique identifier for the sink. (nullable, e.g. unique-identifier)
  type: string@type-completer
  --config: record # shape: {accessKey: string, account: string, container: string}
]: any -> record<batchSize: int, createdAt: string, currentIterator: string, eventTypes: list<string>, failureReason: string, id: string, maxWaitSecs: int, metadata: record, nextRetryAt: string, status: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)")
  let body = {batchSize: $batchSize, eventTypes: $eventTypes, maxWaitSecs: $maxWaitSecs, metadata: $metadata, status: $status, uid: $uid, type: $type, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Sink
#
# DELETE /api/v1/stream/{stream_id}/sink/{sink_id}
# operationId: v1.streaming.sink.delete
export def "stream-sink v1streamingsinkdelete" [
  stream_id: string
  sink_id: string
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
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Sink
#
# PATCH /api/v1/stream/{stream_id}/sink/{sink_id}
# Discriminator (request): type = amazonS3, azureBlobStorage, bigQuery, clickhouse, eventBridge, googleCloudPubSub, googleCloudStorage, http, otelTracing, poller, rabbitMq, redshift, snowflake, sns, sqs
# operationId: v1.streaming.sink.patch
# --config shape: {accessKey?: string, account?: string, container?: string}
export def "stream-sink v1streamingsinkpatch" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --batchSize: int # nullable, format: uint16, e.g. 100
  --eventTypes: list
  --maxWaitSecs: int # nullable, format: uint16
  --metadata: record
  --status: string@status-completer-2
  --uid: string # The StreamSink's UID. (nullable, e.g. unique-identifier)
  type: string@type-completer
  --config: record # shape: {accessKey?: string, account?: string, container?: string}
]: any -> record<batchSize: int, createdAt: string, currentIterator: string, eventTypes: list<string>, failureReason: string, id: string, maxWaitSecs: int, metadata: record, nextRetryAt: string, status: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)")
  let body = {batchSize: $batchSize, eventTypes: $eventTypes, maxWaitSecs: $maxWaitSecs, metadata: $metadata, status: $status, uid: $uid, type: $type, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Poller Sink Stream Events
#
# GET /api/v1/stream/{stream_id}/sink/{sink_id}/events
# operationId: v1.streaming.events.get
export def "stream-sink-events v1streamingeventsget" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable)
  --after: string # nullable, format: date-time
]: nothing -> record<data: table<eventType: string, payload: string, timestamp: string>, done: bool, iterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sink Headers
#
# GET /api/v1/stream/{stream_id}/sink/{sink_id}/headers
# operationId: v1.streaming.sink-headers-get
export def "stream-sink-headers v1streamingsink-headers-get" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<headers: record, sensitive: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)/headers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Sink Headers
#
# PATCH /api/v1/stream/{stream_id}/sink/{sink_id}/headers
# operationId: v1.streaming.sink-headers-patch
export def "stream-sink-headers v1streamingsink-headers-patch" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> record<headers: record, sensitive: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)/headers")
  let body = {headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Sink Secret
#
# GET /api/v1/stream/{stream_id}/sink/{sink_id}/secret
# operationId: v1.streaming.sink.get-secret
export def "stream-sink-secret v1streamingsinkget-secret" [
  stream_id: string
  sink_id: string
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
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Sink Secret
#
# POST /api/v1/stream/{stream_id}/sink/{sink_id}/secret/rotate
# operationId: v1.streaming.sink.rotate-secret
export def "stream-sink-secret-rotate v1streamingsinkrotate-secret" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --key: string # The endpoint's verification secret.  Format: `base64` encoded random bytes optionally prefixed with `whsec_`. It is recommended to not set this and let the server generate the secret. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)/secret/rotate")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Sink Transformation
#
# GET /api/v1/stream/{stream_id}/sink/{sink_id}/transformation
# operationId: v1.streaming.sink-transformation-get
export def "stream-sink-transformation v1streamingsink-transformation-get" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)/transformation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Sink Transformation
#
# PATCH /api/v1/stream/{stream_id}/sink/{sink_id}/transformation
# operationId: v1.streaming.sink.transformation-partial-update
export def "stream-sink-transformation v1streamingsinktransformation-partial-update" [
  stream_id: string
  sink_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/stream/($stream_id)/sink/($sink_id)/transformation")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Ingest Sources
#
# GET /ingest/api/v1/source
# operationId: v1.ingest.source.list
export def "ingest-source v1ingestsourcelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. src_2yZwUhtgs5Ai8T9yRQJXA)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<createdAt: string, id: string, ingestUrl: string, metadata: record, name: string, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ingest/api/v1/source" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ingest Source
#
# POST /ingest/api/v1/source
# Discriminator (request): type = adobe-sign, airwallex, beehiiv, brex, checkbook, clerk, cron, docusign, easypost, generic-webhook, github, guesty, hubspot, incident-io, lithic, meta, nash, open-ai, orum-io, panda-doc, pleo, port-io, psi-fi, render, replicate, resend, rutter, safebase, sardine, segment, shopify, slack, stripe, stych, svix, tailscale, telnyx, vapi, veriff, vgs, zoom
# operationId: v1.ingest.source.create
# --config shape: {contentType?: string, payload: string, schedule: string}
export def "ingest-source v1ingestsourcecreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --metadata: record # default: {}
  name: string
  --uid: string # The Source's UID. (nullable, e.g. unique-identifier)
  type: string@type-completer-1
  --config: record # shape: {contentType?: string, payload: string, schedule: string}
]: any -> record<createdAt: string, id: string, ingestUrl: string, metadata: record, name: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ingest/api/v1/source")
  let body = {metadata: $metadata, name: $name, uid: $uid, type: $type, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Ingest Source
#
# GET /ingest/api/v1/source/{source_id}
# Discriminator (response): type = adobe-sign, airwallex, beehiiv, brex, checkbook, clerk, cron, docusign, easypost, generic-webhook, github, guesty, hubspot, incident-io, lithic, meta, nash, open-ai, orum-io, panda-doc, pleo, port-io, psi-fi, render, replicate, resend, rutter, safebase, sardine, segment, shopify, slack, stripe, stych, svix, tailscale, telnyx, vapi, veriff, vgs, zoom
# operationId: v1.ingest.source.get
export def "ingest-source v1ingestsourceget" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, id: string, ingestUrl: string, metadata: record, name: string, uid: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Source
#
# PUT /ingest/api/v1/source/{source_id}
# Discriminator (request): type = adobe-sign, airwallex, beehiiv, brex, checkbook, clerk, cron, docusign, easypost, generic-webhook, github, guesty, hubspot, incident-io, lithic, meta, nash, open-ai, orum-io, panda-doc, pleo, port-io, psi-fi, render, replicate, resend, rutter, safebase, sardine, segment, shopify, slack, stripe, stych, svix, tailscale, telnyx, vapi, veriff, vgs, zoom
# operationId: v1.ingest.source.update
# --config shape: {contentType?: string, payload: string, schedule: string}
export def "ingest-source v1ingestsourceupdate" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # default: {}
  name: string
  --uid: string # The Source's UID. (nullable, e.g. unique-identifier)
  type: string@type-completer-1
  --config: record # shape: {contentType?: string, payload: string, schedule: string}
]: any -> record<createdAt: string, id: string, ingestUrl: string, metadata: record, name: string, uid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)")
  let body = {metadata: $metadata, name: $name, uid: $uid, type: $type, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ingest Source
#
# DELETE /ingest/api/v1/source/{source_id}
# operationId: v1.ingest.source.delete
export def "ingest-source v1ingestsourcedelete" [
  source_id: string
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
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ingest Source Consumer Portal
#
# POST /ingest/api/v1/source/{source_id}/dashboard
# operationId: v1.ingest.dashboard
export def "ingest-source-dashboard v1ingestdashboard" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --expiry: int # How long the token will be valid for, in seconds.  Valid values are between 1 hour and 7 days. The default is 7 days. (nullable, format: uint64)
  --readOnly: oneof<nothing, bool> # Whether the app portal should be in read-only mode. (nullable)
]: any -> record<token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/dashboard")
  let body = {expiry: $expiry, readOnly: $readOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Ingest Endpoints
#
# GET /ingest/api/v1/source/{source_id}/endpoint
# operationId: v1.ingest.endpoint.list
export def "ingest-source-endpoint v1ingestendpointlist" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of returned items (format: uint64)
  --iterator: string # The iterator returned from a prior invocation (nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2)
  --order: string@order-completer # The sorting order of the returned items
]: nothing -> record<data: table<createdAt: string, description: string, disabled: bool, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string>, done: bool, iterator: string, prevIterator: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "iterator" $iterator "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ingest Endpoint
#
# POST /ingest/api/v1/source/{source_id}/endpoint
# operationId: v1.ingest.endpoint.create
export def "ingest-source-endpoint v1ingestendpointcreate" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --metadata: record # default: {}
  --rateLimit: int # nullable, format: uint16
  --secret: string # The endpoint's verification secret.  Format: `base64` encoded random bytes optionally prefixed with `whsec_`. It is recommended to not set this and let the server generate the secret. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
  --uid: string # Optional unique identifier for the endpoint. (nullable, e.g. unique-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
]: any -> record<createdAt: string, description: string, disabled: bool, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint")
  let body = {description: $description, disabled: $disabled, metadata: $metadata, rateLimit: $rateLimit, secret: $secret, uid: $uid, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Ingest Endpoint
#
# GET /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}
# operationId: v1.ingest.endpoint.get
export def "ingest-source-endpoint v1ingestendpointget" [
  source_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<createdAt: string, description: string, disabled: bool, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ingest Endpoint
#
# PUT /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}
# operationId: v1.ingest.endpoint.update
export def "ingest-source-endpoint v1ingestendpointupdate" [
  source_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # default: , e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --metadata: record # default: {}
  --rateLimit: int # nullable, format: uint16
  --uid: string # Optional unique identifier for the endpoint. (nullable, e.g. unique-identifier)
  --body-url: string # format: uri, e.g. https://example.com/webhook/
]: any -> record<createdAt: string, description: string, disabled: bool, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)")
  let body = {description: $description, disabled: $disabled, metadata: $metadata, rateLimit: $rateLimit, uid: $uid, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ingest Endpoint
#
# DELETE /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}
# operationId: v1.ingest.endpoint.delete
export def "ingest-source-endpoint v1ingestendpointdelete" [
  source_id: string
  endpoint_id: string
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
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Ingest Endpoint Headers
#
# GET /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}/headers
# operationId: v1.ingest.endpoint.get-headers
export def "ingest-source-endpoint-headers v1ingestendpointget-headers" [
  source_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<headers: record, sensitive: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)/headers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ingest Endpoint Headers
#
# PUT /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}/headers
# operationId: v1.ingest.endpoint.update-headers
export def "ingest-source-endpoint-headers v1ingestendpointupdate-headers" [
  source_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)/headers")
  let body = {headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Ingest Endpoint Secret
#
# GET /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}/secret
# operationId: v1.ingest.endpoint.get-secret
export def "ingest-source-endpoint-secret v1ingestendpointget-secret" [
  source_id: string
  endpoint_id: string
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
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate Ingest Endpoint Secret
#
# POST /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}/secret/rotate
# operationId: v1.ingest.endpoint.rotate-secret
export def "ingest-source-endpoint-secret-rotate v1ingestendpointrotate-secret" [
  source_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
  --key: string # The endpoint's verification secret.  Format: `base64` encoded random bytes optionally prefixed with `whsec_`. It is recommended to not set this and let the server generate the secret. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)/secret/rotate")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Ingest Endpoint Transformation
#
# GET /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}/transformation
# operationId: v1.ingest.endpoint.get-transformation
export def "ingest-source-endpoint-transformation v1ingestendpointget-transformation" [
  source_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)/transformation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Ingest Endpoint Transformation
#
# PATCH /ingest/api/v1/source/{source_id}/endpoint/{endpoint_id}/transformation
# operationId: v1.ingest.endpoint.set-transformation
export def "ingest-source-endpoint-transformation v1ingestendpointset-transformation" [
  source_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # nullable
  --enabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/endpoint/($endpoint_id)/transformation")
  let body = {code: $code, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate Ingest Token
#
# POST /ingest/api/v1/source/{source_id}/token/rotate
# operationId: v1.ingest.source.rotate-token
export def "ingest-source-token-rotate v1ingestsourcerotate-token" [
  source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # The request's idempotency key
]: nothing -> record<ingestUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ingest/api/v1/source/($source_id)/token/rotate")
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
