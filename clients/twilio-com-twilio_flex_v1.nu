# Auto-generated client for Twilio - Flex v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_flex_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_FLEX_TOKEN

const BASE_URL = "https://flex-api.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TWILIO_FLEX_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://flex-api.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def channel-type-completer [] { ["custom" "facebook" "line" "sms" "web" "whatsapp"] }
def integration-type-completer [] { ["external" "studio" "task"] }
def type-completer [] { ["agent" "customer" "external" "supervisor" "unknown"] }
def status-completer [] { ["closed" "wrapup"] }
def chat-status-completer [] { ["inactive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "channels list" } } | get name | first)
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

# GET /v1/Channels
#
# operationId: ListChannel
export def "channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Channels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Channels
#
# operationId: CreateChannel
export def "channels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_friendly_name: string # The chat channel's friendly name.
  --chat-unique-name: string # The chat channel's unique name.
  chat_user_friendly_name: string # The chat participant's friendly name.
  flex_flow_sid: string # The SID of the Flex Flow.
  identity: string # The `identity` value that uniquely identifies the new resource's chat User.
  --long-lived: oneof<nothing, bool> # Whether to create the channel as long-lived.
  --pre-engagement-data: string # The pre-engagement data.
  --target: string # The Target Contact Identity, for example the phone number of an SMS.
  --task-attributes: string # The Task attributes to be added for the TaskRouter Task.
  --task-sid: string # The SID of the TaskRouter Task. Only valid when integration type is `task`. `null` for integration types `studio` & `external`
]: any -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Channels" $auth.query)
  let req_body = {"ChatFriendlyName": $chat_friendly_name, "ChatUniqueName": $chat_unique_name, "ChatUserFriendlyName": $chat_user_friendly_name, "FlexFlowSid": $flex_flow_sid, "Identity": $identity, "LongLived": $long_lived, "PreEngagementData": $pre_engagement_data, "Target": $target, "TaskAttributes": $task_attributes, "TaskSid": $task_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Channels/{Sid}
#
# operationId: DeleteChannel
export def "channels delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Channels/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/Channels/{Sid}
#
# operationId: FetchChannel
export def "channels get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Channels/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /v1/Configuration
#
# operationId: FetchConfiguration
export def "configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ui-version: string # The Pinned UI version of the Configuration resource to fetch.
]: nothing -> record<account_sid: string, attributes: any, call_recording_enabled: bool, call_recording_webhook_url: string, channel_configs: list<any>, chat_service_instance_sid: string, crm_attributes: any, crm_callback_url: string, crm_enabled: bool, crm_fallback_url: string, crm_type: string, date_created: string, date_updated: string, debugger_integration: any, flex_insights_drilldown: bool, flex_insights_hr: any, flex_service_instance_sid: string, flex_ui_status_report: any, flex_url: string, integrations: list<any>, markdown: any, messaging_service_instance_sid: string, notifications: any, outbound_call_flows: any, plugin_service_attributes: any, plugin_service_enabled: bool, public_attributes: any, queue_stats_configuration: any, runtime_domain: string, serverless_service_sids: list<string>, service_version: string, status: string, taskrouter_offline_activity_sid: string, taskrouter_skills: list<any>, taskrouter_target_taskqueue_sid: string, taskrouter_target_workflow_sid: string, taskrouter_taskqueues: list<any>, taskrouter_worker_attributes: any, taskrouter_worker_channels: any, taskrouter_workspace_sid: string, ui_attributes: any, ui_dependencies: any, ui_language: string, ui_version: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "UiVersion" $ui_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Configuration" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UiVersion": $ui_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /v1/FlexFlows
#
# operationId: ListFlexFlow
export def "flex-flows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Flex Flow resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<flex_flows: table<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/FlexFlows" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FriendlyName": $friendly_name, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/FlexFlows
#
# operationId: CreateFlexFlow
export def "flex-flows create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_type: string@channel-type-completer
  chat_service_sid: string # The SID of the chat service.
  --contact-identity: string # The channel contact's Identity.
  --enabled: oneof<nothing, bool> # Whether the new Flex Flow is enabled.
  friendly_name: string # A descriptive string that you create to describe the Flex Flow resource.
  --integration-channel: string # The Task Channel SID (TCXXXX) or unique name (e.g., `sms`) to use for the Task that will be created. Applicable and required when `integrationType` is `task`. The default value is `default`.
  --integration-creation-on-message: oneof<nothing, bool> # In the context of outbound messaging, defines whether to create a Task immediately (and therefore reserve the conversation to current agent), or delay Task creation until the customer sends the first response. Set to false to create immediately, true to delay Task creation. This setting is only applicable for outbound messaging.
  --integration-flow-sid: string # The SID of the Studio Flow. Required when `integrationType` is `studio`.
  --integration-priority: int # The Task priority of a new Task. The default priority is 0. Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-retry-count: int # The number of times to retry the Studio Flow or webhook in case of failure. Takes integer values from 0 to 3 with the default being 3. Optional when `integrationType` is `studio` or `external`, not applicable otherwise.
  --integration-timeout: int # The Task timeout in seconds for a new Task. Default is 86,400 seconds (24 hours). Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-url: string # The URL of the external webhook. Required when `integrationType` is `external`. (format: uri)
  --integration-workflow-sid: string # The Workflow SID for a new Task. Required when `integrationType` is `task`.
  --integration-workspace-sid: string # The Workspace SID for a new Task. Required when `integrationType` is `task`.
  --integration-type: string@integration-type-completer
  --janitor-enabled: oneof<nothing, bool> # When enabled, the Messaging Channel Janitor will remove active Proxy sessions if the associated Task is deleted outside of the Flex UI. Defaults to `false`.
  --long-lived: oneof<nothing, bool> # When enabled, Flex will keep the chat channel active so that it may be used for subsequent interactions with a contact identity. Defaults to `false`.
]: any -> record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/FlexFlows" $auth.query)
  let req_body = {"ChannelType": $channel_type, "ChatServiceSid": $chat_service_sid, "ContactIdentity": $contact_identity, "Enabled": $enabled, "FriendlyName": $friendly_name, "Integration.Channel": $integration_channel, "Integration.CreationOnMessage": $integration_creation_on_message, "Integration.FlowSid": $integration_flow_sid, "Integration.Priority": $integration_priority, "Integration.RetryCount": $integration_retry_count, "Integration.Timeout": $integration_timeout, "Integration.Url": $integration_url, "Integration.WorkflowSid": $integration_workflow_sid, "Integration.WorkspaceSid": $integration_workspace_sid, "IntegrationType": $integration_type, "JanitorEnabled": $janitor_enabled, "LongLived": $long_lived} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/FlexFlows/{Sid}
#
# operationId: DeleteFlexFlow
export def "flex-flows delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/FlexFlows/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/FlexFlows/{Sid}
#
# operationId: FetchFlexFlow
export def "flex-flows get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/FlexFlows/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/FlexFlows/{Sid}
#
# operationId: UpdateFlexFlow
export def "flex-flows update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-type: string@channel-type-completer
  --chat-service-sid: string # The SID of the chat service.
  --contact-identity: string # The channel contact's Identity.
  --enabled: oneof<nothing, bool> # Whether the new Flex Flow is enabled.
  --friendly-name: string # A descriptive string that you create to describe the Flex Flow resource.
  --integration-channel: string # The Task Channel SID (TCXXXX) or unique name (e.g., `sms`) to use for the Task that will be created. Applicable and required when `integrationType` is `task`. The default value is `default`.
  --integration-creation-on-message: oneof<nothing, bool> # In the context of outbound messaging, defines whether to create a Task immediately (and therefore reserve the conversation to current agent), or delay Task creation until the customer sends the first response. Set to false to create immediately, true to delay Task creation. This setting is only applicable for outbound messaging.
  --integration-flow-sid: string # The SID of the Studio Flow. Required when `integrationType` is `studio`.
  --integration-priority: int # The Task priority of a new Task. The default priority is 0. Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-retry-count: int # The number of times to retry the Studio Flow or webhook in case of failure. Takes integer values from 0 to 3 with the default being 3. Optional when `integrationType` is `studio` or `external`, not applicable otherwise.
  --integration-timeout: int # The Task timeout in seconds for a new Task. Default is 86,400 seconds (24 hours). Optional when `integrationType` is `task`, not applicable otherwise.
  --integration-url: string # The URL of the external webhook. Required when `integrationType` is `external`. (format: uri)
  --integration-workflow-sid: string # The Workflow SID for a new Task. Required when `integrationType` is `task`.
  --integration-workspace-sid: string # The Workspace SID for a new Task. Required when `integrationType` is `task`.
  --integration-type: string@integration-type-completer
  --janitor-enabled: oneof<nothing, bool> # When enabled, the Messaging Channel Janitor will remove active Proxy sessions if the associated Task is deleted outside of the Flex UI. Defaults to `false`.
  --long-lived: oneof<nothing, bool> # When enabled, Flex will keep the chat channel active so that it may be used for subsequent interactions with a contact identity. Defaults to `false`.
]: any -> record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/FlexFlows/{sid}") $auth.query)
  let req_body = {"ChannelType": $channel_type, "ChatServiceSid": $chat_service_sid, "ContactIdentity": $contact_identity, "Enabled": $enabled, "FriendlyName": $friendly_name, "Integration.Channel": $integration_channel, "Integration.CreationOnMessage": $integration_creation_on_message, "Integration.FlowSid": $integration_flow_sid, "Integration.Priority": $integration_priority, "Integration.RetryCount": $integration_retry_count, "Integration.Timeout": $integration_timeout, "Integration.Url": $integration_url, "Integration.WorkflowSid": $integration_workflow_sid, "Integration.WorkspaceSid": $integration_workspace_sid, "IntegrationType": $integration_type, "JanitorEnabled": $janitor_enabled, "LongLived": $long_lived} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# To get conversation with segment id
#
# GET /v1/Insights/Conversations
# operationId: ListInsightsConversations
export def "insights-conversations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # Unique Id of the segment for which conversation details needs to be fetched
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<conversations: table<account_id: string, conversation_id: string, segment_count: int, segments: list>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "SegmentId" $segment_id "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/Conversations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SegmentId": $segment_id, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get assessments done for a conversation by logged in user
#
# GET /v1/Insights/QM/Assessments
# operationId: ListInsightsAssessments
export def "insights-qm-assessments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # The id of the segment.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<assessments: table<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "SegmentId" $segment_id "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Assessments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SegmentId": $segment_id, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add assessments against conversation to dynamo db. Used in assessments screen by user. Users can select the questionnaire and pick up answers for each and every question.
#
# POST /v1/Insights/QM/Assessments
# operationId: CreateInsightsAssessments
export def "insights-qm-assessments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  agent_id: string # The id of the Agent
  answer_id: string # The id of the answer selected by user
  answer_text: string # The answer text selected by user
  category_id: string # The id of the category
  category_name: string # The name of the category
  metric_id: string # The question Id selected for assessment
  metric_name: string # The question name of the assessment
  offset: float # The offset of the conversation.
  questionnaire_id: string # Questionnaire Id of the associated question
  segment_id: string # Segment Id of the conversation
  user_email: string # Email of the user assessing conversation
  user_name: string # Name of the user assessing conversation
]: any -> record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Assessments" $auth.query)
  let req_body = {"AgentId": $agent_id, "AnswerId": $answer_id, "AnswerText": $answer_text, "CategoryId": $category_id, "CategoryName": $category_name, "MetricId": $metric_id, "MetricName": $metric_name, "Offset": $offset, "QuestionnaireId": $questionnaire_id, "SegmentId": $segment_id, "UserEmail": $user_email, "UserName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# To create a comment assessment for a conversation
#
# GET /v1/Insights/QM/Assessments/Comments
# operationId: ListInsightsAssessmentsComment
export def "insights-qm-assessments-comments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --segment-id: string # The id of the segment.
  --agent-id: string # The id of the agent.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<comments: table<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "SegmentId" $segment_id "scalar") (serialize-qp "AgentId" $agent_id "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Assessments/Comments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SegmentId": $segment_id, "AgentId": $agent_id, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To create a comment assessment for a conversation
#
# POST /v1/Insights/QM/Assessments/Comments
# operationId: CreateInsightsAssessmentsComment
export def "insights-qm-assessments-comments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  agent_id: string # The id of the agent.
  category_id: string # The ID of the category
  category_name: string # The name of the category
  comment: string # The Assessment comment.
  offset: float # The offset
  segment_id: string # The id of the segment.
  user_email: string # The email id of the user.
  user_name: string # The name of the user.
]: any -> record<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Assessments/Comments" $auth.query)
  let req_body = {"AgentId": $agent_id, "CategoryId": $category_id, "CategoryName": $category_name, "Comment": $comment, "Offset": $offset, "SegmentId": $segment_id, "UserEmail": $user_email, "UserName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Update a specific Assessment assessed earlier
#
# POST /v1/Insights/QM/Assessments/{AssessmentId}
# operationId: UpdateInsightsAssessments
export def "insights-qm-assessments update" [
  assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  answer_id: string # The id of the answer selected by user
  answer_text: string # The answer text selected by user
  offset: float # The offset of the conversation
]: any -> record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($assessment_id | is-empty) { error make --unspanned { msg: "path parameter 'AssessmentId' must be non-empty" } }
  let full_url = (build-url $base ({assessment_id: (encode-path-segment $assessment_id)} | format pattern "/v1/Insights/QM/Assessments/{assessment_id}") $auth.query)
  let req_body = {"AnswerId": $answer_id, "AnswerText": $answer_text, "Offset": $offset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# To get all the categories
#
# GET /v1/Insights/QM/Categories
# operationId: ListInsightsQuestionnairesCategory
export def "insights-qm-categories list-questionnaires-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<categories: table<account_sid: string, category_id: string, name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Categories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To create a category for Questions
#
# POST /v1/Insights/QM/Categories
# operationId: CreateInsightsQuestionnairesCategory
export def "insights-qm-categories create-questionnaires-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  name: string # The name of this category.
]: any -> record<account_sid: string, category_id: string, name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Categories" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Insights/QM/Categories/{CategoryId}
#
# operationId: DeleteInsightsQuestionnairesCategory
export def "insights-qm-categories delete-questionnaires-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'CategoryId' must be non-empty" } }
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/v1/Insights/QM/Categories/{category_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# To update the category for Questions
#
# POST /v1/Insights/QM/Categories/{CategoryId}
# operationId: UpdateInsightsQuestionnairesCategory
export def "insights-qm-categories update-questionnaires-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  name: string # The name of this category.
]: any -> record<account_sid: string, category_id: string, name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'CategoryId' must be non-empty" } }
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/v1/Insights/QM/Categories/{category_id}") $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# To get all questionnaires with questions
#
# GET /v1/Insights/QM/Questionnaires
# operationId: ListInsightsQuestionnaires
export def "insights-qm-questionnaires list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-inactive: oneof<nothing, bool> # Flag indicating whether to include inactive questionnaires or not
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questionnaires: table<account_sid: string, active: bool, description: string, id: string, name: string, questions: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "IncludeInactive" $include_inactive "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Questionnaires" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"IncludeInactive": $include_inactive, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To create a Questionnaire
#
# POST /v1/Insights/QM/Questionnaires
# operationId: CreateInsightsQuestionnaires
export def "insights-qm-questionnaires create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  --active: oneof<nothing, bool> # The flag to enable or disable questionnaire
  --description: string # The description of this questionnaire
  name: string # The name of this questionnaire
  --question-ids: list<string> # The list of questions ids under a questionnaire
]: any -> record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Questionnaires" $auth.query)
  let req_body = {"Active": $active, "Description": $description, "Name": $name, "QuestionIds": $question_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# To delete the questionnaire
#
# DELETE /v1/Insights/QM/Questionnaires/{Id}
# operationId: DeleteInsightsQuestionnaires
export def "insights-qm-questionnaires delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/Insights/QM/Questionnaires/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# To get the Questionnaire Detail
#
# GET /v1/Insights/QM/Questionnaires/{Id}
# operationId: FetchInsightsQuestionnaires
export def "insights-qm-questionnaires get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/Insights/QM/Questionnaires/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To update the questionnaire
#
# POST /v1/Insights/QM/Questionnaires/{Id}
# operationId: UpdateInsightsQuestionnaires
export def "insights-qm-questionnaires update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  --active: oneof<nothing, bool> # The flag to enable or disable questionnaire
  --description: string # The description of this questionnaire
  --name: string # The name of this questionnaire
  --question-ids: list<string> # The list of questions ids under a questionnaire
]: any -> record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/Insights/QM/Questionnaires/{id}") $auth.query)
  let req_body = {"Active": $active, "Description": $description, "Name": $name, "QuestionIds": $question_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# To get all the question for the given categories
#
# GET /v1/Insights/QM/Questions
# operationId: ListInsightsQuestionnairesQuestion
export def "insights-qm-questions list-questionnaires" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: list<string> # The list of category IDs
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questions: table<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "CategoryId" $category_id "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Questions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"CategoryId": $category_id, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To create a question for a Category
#
# POST /v1/Insights/QM/Questions
# operationId: CreateInsightsQuestionnairesQuestion
export def "insights-qm-questions create-questionnaires" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  --allow-na: oneof<nothing, bool> # The flag to enable for disable NA for answer.
  answer_set_id: string # The answer_set for the question.
  category_id: string # The ID of the category
  --description: string # The description for the question.
  question: string # The question.
]: any -> record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Questions" $auth.query)
  let req_body = {"AllowNa": $allow_na, "AnswerSetId": $answer_set_id, "CategoryId": $category_id, "Description": $description, "Question": $question} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/Insights/QM/Questions/{QuestionId}
#
# operationId: DeleteInsightsQuestionnairesQuestion
export def "insights-qm-questions delete-questionnaires" [
  question_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($question_id | is-empty) { error make --unspanned { msg: "path parameter 'QuestionId' must be non-empty" } }
  let full_url = (build-url $base ({question_id: (encode-path-segment $question_id)} | format pattern "/v1/Insights/QM/Questions/{question_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# To update the question
#
# POST /v1/Insights/QM/Questions/{QuestionId}
# operationId: UpdateInsightsQuestionnairesQuestion
export def "insights-qm-questions update-questionnaires" [
  question_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
  --allow-na: oneof<nothing, bool> # The flag to enable for disable NA for answer.
  --answer-set-id: string # The answer_set for the question.
  --category-id: string # The ID of the category
  --description: string # The description for the question.
  --question: string # The question.
]: any -> record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($question_id | is-empty) { error make --unspanned { msg: "path parameter 'QuestionId' must be non-empty" } }
  let full_url = (build-url $base ({question_id: (encode-path-segment $question_id)} | format pattern "/v1/Insights/QM/Questions/{question_id}") $auth.query)
  let req_body = {"AllowNa": $allow_na, "AnswerSetId": $answer_set_id, "CategoryId": $category_id, "Description": $description, "Question": $question} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# To get the Answer Set Settings for an Account
#
# GET /v1/Insights/QM/Settings/AnswerSets
# operationId: FetchInsightsSettingsAnswersets
export def "insights-qm-settings-answer-sets get-answersets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<account_sid: string, answer_set_categories: any, answer_sets: any, not_applicable: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Settings/AnswerSets" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To get the Comment Settings for an Account
#
# GET /v1/Insights/QM/Settings/CommentTags
# operationId: FetchInsightsSettingsComment
export def "insights-qm-settings-comment-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<account_sid: string, comments: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Settings/CommentTags" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To get segments for given reservation Ids
#
# GET /v1/Insights/Segments
# operationId: ListInsightsSegments
export def "insights-segments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation-id: list<string> # The list of reservation Ids
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, segments: table<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "ReservationId" $reservation_id "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/Segments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ReservationId": $reservation_id, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To get the Segments of an Account
#
# GET /v1/Insights/Segments/{SegmentId}
# operationId: FetchInsightsSegments
export def "insights-segments get" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # The Token HTTP request header
]: nothing -> record<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($segment_id | is-empty) { error make --unspanned { msg: "path parameter 'SegmentId' must be non-empty" } }
  let full_url = (build-url $base ({segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/Insights/Segments/{segment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Token": $hdr_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# To obtain session details for fetching reports and dashboards
#
# POST /v1/Insights/Session
# operationId: CreateInsightsSession
export def "insights-session create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The Authorization HTTP request header
]: nothing -> record<base_url: string, session_expiry: string, session_id: string, url: string, workspace_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/Session" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# This is used by Flex UI and Quality Management to fetch the Flex Insights roles for the user
#
# GET /v1/Insights/UserRoles
# operationId: FetchInsightsUserRoles
export def "insights-user-roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The Authorization HTTP request header
]: nothing -> record<roles: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/UserRoles" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new Interaction.
#
# POST /v1/Interactions
# operationId: CreateInteraction
export def "interactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel: any # The Interaction's channel.
  routing: any # The Interaction's routing logic.
]: any -> record<channel: any, links: record, routing: any, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Interactions" $auth.query)
  let req_body = {"Channel": $channel, "Routing": $routing} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# List all Channels for an Interaction.
#
# GET /v1/Interactions/{InteractionSid}/Channels
# operationId: ListInteractionChannel
export def "interactions-channels list" [
  interaction_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all Invites for a Channel.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites
# operationId: ListInteractionChannelInvite
export def "interactions-channels-invites list" [
  interaction_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<invites: table<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels/{channel_sid}/Invites") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Invite an Agent or a TaskQueue to a Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites
# operationId: CreateInteractionChannelInvite
export def "interactions-channels-invites create" [
  interaction_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  routing: any # The Interaction's routing logic.
]: any -> record<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels/{channel_sid}/Invites") $auth.query)
  let req_body = {"Routing": $routing} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# List all Participants for a Channel.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants
# operationId: ListInteractionChannelParticipant
export def "interactions-channels-participants list" [
  interaction_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels/{channel_sid}/Participants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Participant to a Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants
# operationId: CreateInteractionChannelParticipant
export def "interactions-channels-participants create" [
  interaction_sid: string
  channel_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  media_properties: any # JSON representing the Media Properties for the new Participant.
  type: string@type-completer
]: any -> record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid), channel_sid: (encode-path-segment $channel_sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels/{channel_sid}/Participants") $auth.query)
  let req_body = {"MediaProperties": $media_properties, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Update an existing Channel Participant.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants/{Sid}
# operationId: UpdateInteractionChannelParticipant
export def "interactions-channels-participants update" [
  interaction_sid: string
  channel_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer
]: any -> record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  if ($channel_sid | is-empty) { error make --unspanned { msg: "path parameter 'ChannelSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid), channel_sid: (encode-path-segment $channel_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels/{channel_sid}/Participants/{sid}") $auth.query)
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Fetch a Channel for an Interaction.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{Sid}
# operationId: FetchInteractionChannel
export def "interactions-channels get" [
  interaction_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an existing Interaction Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{Sid}
# operationId: UpdateInteractionChannel
export def "interactions-channels update" [
  interaction_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --routing: any # Optional. The state of associated tasks. If not specified, all tasks will be set to `wrapping`.
  status: string@status-completer
]: any -> record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($interaction_sid | is-empty) { error make --unspanned { msg: "path parameter 'InteractionSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({interaction_sid: (encode-path-segment $interaction_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Interactions/{interaction_sid}/Channels/{sid}") $auth.query)
  let req_body = {"Routing": $routing, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# GET /v1/Interactions/{Sid}
#
# operationId: FetchInteraction
export def "interactions get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channel: any, links: record, routing: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Interactions/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /v1/WebChannels
#
# operationId: ListWebChannel
export def "web-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/WebChannels" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/WebChannels
#
# operationId: CreateWebChannel
export def "web-channels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_friendly_name: string # The chat channel's friendly name.
  --chat-unique-name: string # The chat channel's unique name.
  customer_friendly_name: string # The chat participant's friendly name.
  flex_flow_sid: string # The SID of the Flex Flow.
  identity: string # The chat identity.
  --pre-engagement-data: string # The pre-engagement data.
]: any -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/WebChannels" $auth.query)
  let req_body = {"ChatFriendlyName": $chat_friendly_name, "ChatUniqueName": $chat_unique_name, "CustomerFriendlyName": $customer_friendly_name, "FlexFlowSid": $flex_flow_sid, "Identity": $identity, "PreEngagementData": $pre_engagement_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# DELETE /v1/WebChannels/{Sid}
#
# operationId: DeleteWebChannel
export def "web-channels delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/WebChannels/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/WebChannels/{Sid}
#
# operationId: FetchWebChannel
export def "web-channels get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/WebChannels/{sid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/WebChannels/{Sid}
#
# operationId: UpdateWebChannel
export def "web-channels update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-status: string@chat-status-completer
  --post-engagement-data: string # The post-engagement data.
]: any -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/WebChannels/{sid}") $auth.query)
  let req_body = {"ChatStatus": $chat_status, "PostEngagementData": $post_engagement_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}
