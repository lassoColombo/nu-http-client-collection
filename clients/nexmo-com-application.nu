# Auto-generated client for Nexmo Application API v1.0.2
# Source: https://api.apis.guru/v2/specs/nexmo.com/application/1.0.2/openapi.json
# Auth: --token flag or $env.NEXMO_APPLICATION_API_TOKEN

const BASE_URL = "https://api.nexmo.com/v1/applications"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEXMO_APPLICATION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.nexmo.com/v1/applications"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["messages" "voice"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api retrieveApplications" } } | get name | first)
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

# Retrieve all Applications
#
# GET /
# operationId: retrieveApplications
export def "api retrieveApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # You can find your API key in your [account overview](https://dashboard.nexmo.com/account-overview)
  --api-secret: string # You can find your API secret in your [account overview](https://dashboard.nexmo.com/account-overview)
  --page-size: int # Set the number of items returned on each call to this endpoint. The default is 10 records. (default: 10, e.g. 10)
  --page-index: int # Set the offset from the first page. The default value is `0`. (default: 0, e.g. 0)
]: nothing -> record<_embedded: any, _links: record<href: string>, count: any, page_index: any, page_size: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "api_secret" $api_secret "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_index" $page_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Application
#
# POST /
# operationId: createApplication
export def "api createApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --answer-method: string # The HTTP method used to make the request to `answer_url`. The default value is `GET`. (e.g. GET)
  --answer-url: string # The URL where your webhook delivers the Nexmo Call Control Object that governs this call. As soon as your user answers a call Nexmo makes a request to `answer_url`. Required for inbound calls only. (e.g. https://example.com/webhooks/answer)
  api_key: string # You can find your API key in your [account overview](https://dashboard.nexmo.com/account-overview) (e.g. ap1k3y)
  api_secret: string # You can find your API secret in your [account overview](https://dashboard.nexmo.com/account-overview) (e.g. 230e6cf0709417176df1b4fc1e083adc)
  --event-method: string # The HTTP method used to send event information to `event_url`. The default value is `POST`. For `voice` type applications only. (e.g. POST)
  --event-url: string # Nexmo sends event information asynchronously to this URL when status changes for `voice` applications. Always required for `voice` applications. (e.g. https://example.com/webhooks/event)
  --inbound-method: string # The HTTP method used to send event information to `inbound_url`. The default value is `POST`. For `messages` type applications only. (e.g. POST)
  --inbound-url: string # Nexmo sends a request to this URL when an inbound message is received. Required for `messages` type applications only. (e.g. https://example.com/webhooks/inbound)
  name: string # The name of your application. (e.g. My Application)
  --status-method: string # The HTTP method used to send event information to `status_url`. The default value is `POST`. For `messages` type applications only. (e.g. POST)
  --status-url: string # Nexmo sends event information asynchronously to this URL when status changes. Required for `messages` type applications only. (e.g. https://example.com/webhooks/status)
  type: string@type-completer # The Nexmo product or products that you access with this application. Currently `voice` and `messages` application types are supported. (e.g. voice)
]: any -> record<_links: record<href: string>, id: any, keys: record<public_key: string, private_key: string>, messages: record<webhooks: list<record>>, name: any, voice: record<webhooks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let body = {answer_method: $answer_method, answer_url: $answer_url, api_key: $api_key, api_secret: $api_secret, event_method: $event_method, event_url: $event_url, inbound_method: $inbound_method, inbound_url: $inbound_url, name: $name, status_method: $status_method, status_url: $status_url, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Destroy Application
#
# DELETE /{app_id}
# operationId: deleteApplication
export def "api delete" [
  app_id: string
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
  let full_url = (build-url $base $"/($app_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Application
#
# GET /{app_id}
# operationId: retrieveApplication
export def "api retrieveApplication" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # You can find your API key in your [account overview](https://dashboard.nexmo.com/account-overview)
  --api-secret: string # You can find your API secret in your [account overview](https://dashboard.nexmo.com/account-overview)
]: nothing -> record<_links: record<href: string>, id: any, keys: record<public_key: string>, messages: record<webhooks: list<record>>, name: any, voice: record<webhooks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "api_secret" $api_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($app_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Application
#
# PUT /{app_id}
# operationId: updateApplication
export def "api updateApplication" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --answer-method: string # The HTTP method used to make the request to `answer_url`. The default value is `GET`. (default: GET, e.g. GET)
  --answer-url: string # The URL where your webhook delivers the Nexmo Call Control Object that governs this call. As soon as your user answers a call Nexmo makes a request to `answer_url`. (format: url, e.g. https://example.com/webhooks/answer)
  api_key: string # You can find your API key in your [account overview](https://dashboard.nexmo.com/account-overview) (e.g. ap1k3y)
  api_secret: string # You can find your API secret in your [account overview](https://dashboard.nexmo.com/account-overview) (e.g. 230e6cf0709417176df1b4fc1e083adc)
  --event-method: string # The HTTP method used to send event information to `event_url`. The default value is POST. (default: POST, e.g. POST)
  --event-url: string # Nexmo sends event information asynchronously to this URL when status changes. (format: url, e.g. https://example.com/webhooks/event)
  name: string # The name of your application. (e.g. UpdatedApplication)
  type: string@type-completer # The Nexmo product or products that you access with this application. Currently `voice` and `messages` application types are supported. You  can't change the type of application. (e.g. voice)
]: any -> record<_links: record<href: string>, id: any, keys: record<public_key: string>, messages: record<webhooks: list<record>>, name: any, voice: record<webhooks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($app_id)")
  let body = {answer_method: $answer_method, answer_url: $answer_url, api_key: $api_key, api_secret: $api_secret, event_method: $event_method, event_url: $event_url, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
