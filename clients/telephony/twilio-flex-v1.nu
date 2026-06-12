# Auto-generated client for Twilio - Flex v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_flex_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_FLEX_TOKEN

const BASE_URL = "https://flex-api.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_FLEX_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://flex-api.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def ChannelType-completer [] { ["custom" "facebook" "line" "sms" "web" "whatsapp"] }
def IntegrationType-completer [] { ["external" "studio" "task"] }
def Type-completer [] { ["agent" "customer" "external" "supervisor" "unknown"] }
def Status-completer [] { ["closed" "wrapup"] }
def ChatStatus-completer [] { ["inactive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "channels ListChannel" } } | get name | first)
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
export def "channels ListChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Channels
#
# operationId: CreateChannel
export def "channels CreateChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ChatFriendlyName: string # The chat channel's friendly name.
  --ChatUniqueName: string # The chat channel's unique name.
  ChatUserFriendlyName: string # The chat participant's friendly name.
  FlexFlowSid: string # The SID of the Flex Flow.
  Identity: string # The `identity` value that uniquely identifies the new resource's chat User.
  --LongLived: oneof<nothing, bool> # Whether to create the channel as long-lived.
  --PreEngagementData: string # The pre-engagement data.
  --Target: string # The Target Contact Identity, for example the phone number of an SMS.
  --TaskAttributes: string # The Task attributes to be added for the TaskRouter Task.
  --TaskSid: string # The SID of the TaskRouter Task. Only valid when integration type is `task`. `null` for integration types `studio` & `external`
]: any -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Channels")
  let body = {ChatFriendlyName: $ChatFriendlyName, ChatUniqueName: $ChatUniqueName, ChatUserFriendlyName: $ChatUserFriendlyName, FlexFlowSid: $FlexFlowSid, Identity: $Identity, LongLived: $LongLived, PreEngagementData: $PreEngagementData, Target: $Target, TaskAttributes: $TaskAttributes, TaskSid: $TaskSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Channels/{Sid}
#
# operationId: DeleteChannel
export def "channels DeleteChannel" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Channels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Channels/{Sid}
#
# operationId: FetchChannel
export def "channels FetchChannel" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, task_sid: string, url: string, user_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Channels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Configuration
#
# operationId: FetchConfiguration
export def "configuration FetchConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UiVersion: string # The Pinned UI version of the Configuration resource to fetch.
]: nothing -> record<account_sid: string, attributes: any, call_recording_enabled: bool, call_recording_webhook_url: string, channel_configs: list<any>, chat_service_instance_sid: string, crm_attributes: any, crm_callback_url: string, crm_enabled: bool, crm_fallback_url: string, crm_type: string, date_created: string, date_updated: string, debugger_integration: any, flex_insights_drilldown: bool, flex_insights_hr: any, flex_service_instance_sid: string, flex_ui_status_report: any, flex_url: string, integrations: list<any>, markdown: any, messaging_service_instance_sid: string, notifications: any, outbound_call_flows: any, plugin_service_attributes: any, plugin_service_enabled: bool, public_attributes: any, queue_stats_configuration: any, runtime_domain: string, serverless_service_sids: list<string>, service_version: string, status: string, taskrouter_offline_activity_sid: string, taskrouter_skills: list<any>, taskrouter_target_taskqueue_sid: string, taskrouter_target_workflow_sid: string, taskrouter_taskqueues: list<any>, taskrouter_worker_attributes: any, taskrouter_worker_channels: any, taskrouter_workspace_sid: string, ui_attributes: any, ui_dependencies: any, ui_language: string, ui_version: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "UiVersion" $UiVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Configuration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/FlexFlows
#
# operationId: ListFlexFlow
export def "flex-flows ListFlexFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # The `friendly_name` of the Flex Flow resources to read.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<flex_flows: table<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/FlexFlows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/FlexFlows
#
# operationId: CreateFlexFlow
export def "flex-flows CreateFlexFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ChannelType: string@ChannelType-completer
  ChatServiceSid: string # The SID of the chat service.
  --ContactIdentity: string # The channel contact's Identity.
  --Enabled: oneof<nothing, bool> # Whether the new Flex Flow is enabled.
  FriendlyName: string # A descriptive string that you create to describe the Flex Flow resource.
  --IntegrationChannel: string # The Task Channel SID (TCXXXX) or unique name (e.g., `sms`) to use for the Task that will be created. Applicable and required when `integrationType` is `task`. The default value is `default`.
  --IntegrationCreationOnMessage: oneof<nothing, bool> # In the context of outbound messaging, defines whether to create a Task immediately (and therefore reserve the conversation to current agent), or delay Task creation until the customer sends the first response. Set to false to create immediately, true to delay Task creation. This setting is only applicable for outbound messaging.
  --IntegrationFlowSid: string # The SID of the Studio Flow. Required when `integrationType` is `studio`.
  --IntegrationPriority: int # The Task priority of a new Task. The default priority is 0. Optional when `integrationType` is `task`, not applicable otherwise.
  --IntegrationRetryCount: int # The number of times to retry the Studio Flow or webhook in case of failure. Takes integer values from 0 to 3 with the default being 3. Optional when `integrationType` is `studio` or `external`, not applicable otherwise.
  --IntegrationTimeout: int # The Task timeout in seconds for a new Task. Default is 86,400 seconds (24 hours). Optional when `integrationType` is `task`, not applicable otherwise.
  --IntegrationUrl: string # The URL of the external webhook. Required when `integrationType` is `external`. (format: uri)
  --IntegrationWorkflowSid: string # The Workflow SID for a new Task. Required when `integrationType` is `task`.
  --IntegrationWorkspaceSid: string # The Workspace SID for a new Task. Required when `integrationType` is `task`.
  --IntegrationType: string@IntegrationType-completer
  --JanitorEnabled: oneof<nothing, bool> # When enabled, the Messaging Channel Janitor will remove active Proxy sessions if the associated Task is deleted outside of the Flex UI. Defaults to `false`.
  --LongLived: oneof<nothing, bool> # When enabled, Flex will keep the chat channel active so that it may be used for subsequent interactions with a contact identity. Defaults to `false`.
]: any -> record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/FlexFlows")
  let body = {ChannelType: $ChannelType, ChatServiceSid: $ChatServiceSid, ContactIdentity: $ContactIdentity, Enabled: $Enabled, FriendlyName: $FriendlyName, Integration.Channel: $IntegrationChannel, Integration.CreationOnMessage: $IntegrationCreationOnMessage, Integration.FlowSid: $IntegrationFlowSid, Integration.Priority: $IntegrationPriority, Integration.RetryCount: $IntegrationRetryCount, Integration.Timeout: $IntegrationTimeout, Integration.Url: $IntegrationUrl, Integration.WorkflowSid: $IntegrationWorkflowSid, Integration.WorkspaceSid: $IntegrationWorkspaceSid, IntegrationType: $IntegrationType, JanitorEnabled: $JanitorEnabled, LongLived: $LongLived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/FlexFlows/{Sid}
#
# operationId: DeleteFlexFlow
export def "flex-flows DeleteFlexFlow" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/FlexFlows/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/FlexFlows/{Sid}
#
# operationId: FetchFlexFlow
export def "flex-flows FetchFlexFlow" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/FlexFlows/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/FlexFlows/{Sid}
#
# operationId: UpdateFlexFlow
export def "flex-flows UpdateFlexFlow" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ChannelType: string@ChannelType-completer
  --ChatServiceSid: string # The SID of the chat service.
  --ContactIdentity: string # The channel contact's Identity.
  --Enabled: oneof<nothing, bool> # Whether the new Flex Flow is enabled.
  --FriendlyName: string # A descriptive string that you create to describe the Flex Flow resource.
  --IntegrationChannel: string # The Task Channel SID (TCXXXX) or unique name (e.g., `sms`) to use for the Task that will be created. Applicable and required when `integrationType` is `task`. The default value is `default`.
  --IntegrationCreationOnMessage: oneof<nothing, bool> # In the context of outbound messaging, defines whether to create a Task immediately (and therefore reserve the conversation to current agent), or delay Task creation until the customer sends the first response. Set to false to create immediately, true to delay Task creation. This setting is only applicable for outbound messaging.
  --IntegrationFlowSid: string # The SID of the Studio Flow. Required when `integrationType` is `studio`.
  --IntegrationPriority: int # The Task priority of a new Task. The default priority is 0. Optional when `integrationType` is `task`, not applicable otherwise.
  --IntegrationRetryCount: int # The number of times to retry the Studio Flow or webhook in case of failure. Takes integer values from 0 to 3 with the default being 3. Optional when `integrationType` is `studio` or `external`, not applicable otherwise.
  --IntegrationTimeout: int # The Task timeout in seconds for a new Task. Default is 86,400 seconds (24 hours). Optional when `integrationType` is `task`, not applicable otherwise.
  --IntegrationUrl: string # The URL of the external webhook. Required when `integrationType` is `external`. (format: uri)
  --IntegrationWorkflowSid: string # The Workflow SID for a new Task. Required when `integrationType` is `task`.
  --IntegrationWorkspaceSid: string # The Workspace SID for a new Task. Required when `integrationType` is `task`.
  --IntegrationType: string@IntegrationType-completer
  --JanitorEnabled: oneof<nothing, bool> # When enabled, the Messaging Channel Janitor will remove active Proxy sessions if the associated Task is deleted outside of the Flex UI. Defaults to `false`.
  --LongLived: oneof<nothing, bool> # When enabled, Flex will keep the chat channel active so that it may be used for subsequent interactions with a contact identity. Defaults to `false`.
]: any -> record<account_sid: string, channel_type: string, chat_service_sid: string, contact_identity: string, date_created: string, date_updated: string, enabled: bool, friendly_name: string, integration: any, integration_type: string, janitor_enabled: bool, long_lived: bool, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/FlexFlows/($Sid)")
  let body = {ChannelType: $ChannelType, ChatServiceSid: $ChatServiceSid, ContactIdentity: $ContactIdentity, Enabled: $Enabled, FriendlyName: $FriendlyName, Integration.Channel: $IntegrationChannel, Integration.CreationOnMessage: $IntegrationCreationOnMessage, Integration.FlowSid: $IntegrationFlowSid, Integration.Priority: $IntegrationPriority, Integration.RetryCount: $IntegrationRetryCount, Integration.Timeout: $IntegrationTimeout, Integration.Url: $IntegrationUrl, Integration.WorkflowSid: $IntegrationWorkflowSid, Integration.WorkspaceSid: $IntegrationWorkspaceSid, IntegrationType: $IntegrationType, JanitorEnabled: $JanitorEnabled, LongLived: $LongLived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# To get conversation with segment id
#
# GET /v1/Insights/Conversations
# operationId: ListInsightsConversations
export def "insights-conversations ListInsightsConversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SegmentId: string # Unique Id of the segment for which conversation details needs to be fetched
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --Token: string # The Token HTTP request header
]: nothing -> record<conversations: table<account_id: string, conversation_id: string, segment_count: int, segments: list>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "SegmentId" $SegmentId "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/Conversations" $qp)
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get assessments done for a conversation by logged in user
#
# GET /v1/Insights/QM/Assessments
# operationId: ListInsightsAssessments
export def "insights-qm-assessments ListInsightsAssessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SegmentId: string # The id of the segment.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --Token: string # The Token HTTP request header
]: nothing -> record<assessments: table<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "SegmentId" $SegmentId "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Assessments" $qp)
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add assessments against conversation to dynamo db. Used in assessments screen by user. Users can select the questionnaire and pick up answers for each and every question.
#
# POST /v1/Insights/QM/Assessments
# operationId: CreateInsightsAssessments
export def "insights-qm-assessments CreateInsightsAssessments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  AgentId: string # The id of the Agent
  AnswerId: string # The id of the answer selected by user
  AnswerText: string # The answer text selected by user
  CategoryId: string # The id of the category 
  CategoryName: string # The name of the category
  MetricId: string # The question Id selected for assessment
  MetricName: string # The question name of the assessment
  Offset: float # The offset of the conversation.
  QuestionnaireId: string # Questionnaire Id of the associated question
  SegmentId: string # Segment Id of the conversation
  UserEmail: string # Email of the user assessing conversation
  UserName: string # Name of the user assessing conversation
]: any -> record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Assessments")
  let body = {AgentId: $AgentId, AnswerId: $AnswerId, AnswerText: $AnswerText, CategoryId: $CategoryId, CategoryName: $CategoryName, MetricId: $MetricId, MetricName: $MetricName, Offset: $Offset, QuestionnaireId: $QuestionnaireId, SegmentId: $SegmentId, UserEmail: $UserEmail, UserName: $UserName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# To create a comment assessment for a conversation
#
# GET /v1/Insights/QM/Assessments/Comments
# operationId: ListInsightsAssessmentsComment
export def "insights-qm-assessments-comments ListInsightsAssessmentsComment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SegmentId: string # The id of the segment.
  --AgentId: string # The id of the agent.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --Token: string # The Token HTTP request header
]: nothing -> record<comments: table<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "SegmentId" $SegmentId "scalar") (serialize-qp "AgentId" $AgentId "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Assessments/Comments" $qp)
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To create a comment assessment for a conversation
#
# POST /v1/Insights/QM/Assessments/Comments
# operationId: CreateInsightsAssessmentsComment
export def "insights-qm-assessments-comments CreateInsightsAssessmentsComment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  AgentId: string # The id of the agent.
  CategoryId: string # The ID of the category
  CategoryName: string # The name of the category
  Comment: string # The Assessment comment.
  Offset: float # The offset
  SegmentId: string # The id of the segment.
  UserEmail: string # The email id of the user.
  UserName: string # The name of the user.
]: any -> record<account_sid: string, agent_id: string, assessment_id: string, comment: any, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Assessments/Comments")
  let body = {AgentId: $AgentId, CategoryId: $CategoryId, CategoryName: $CategoryName, Comment: $Comment, Offset: $Offset, SegmentId: $SegmentId, UserEmail: $UserEmail, UserName: $UserName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update a specific Assessment assessed earlier
#
# POST /v1/Insights/QM/Assessments/{AssessmentId}
# operationId: UpdateInsightsAssessments
export def "insights-qm-assessments UpdateInsightsAssessments" [
  AssessmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  AnswerId: string # The id of the answer selected by user
  AnswerText: string # The answer text selected by user
  Offset: float # The offset of the conversation
]: any -> record<account_sid: string, agent_id: string, answer_id: string, answer_text: string, assessment: any, assessment_id: string, offset: float, report: bool, segment_id: string, timestamp: float, url: string, user_email: string, user_name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Assessments/($AssessmentId)")
  let body = {AnswerId: $AnswerId, AnswerText: $AnswerText, Offset: $Offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# To get all the categories
#
# GET /v1/Insights/QM/Categories
# operationId: ListInsightsQuestionnairesCategory
export def "insights-qm-categories ListInsightsQuestionnairesCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --Token: string # The Token HTTP request header
]: nothing -> record<categories: table<account_sid: string, category_id: string, name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Categories" $qp)
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To create a category for Questions
#
# POST /v1/Insights/QM/Categories
# operationId: CreateInsightsQuestionnairesCategory
export def "insights-qm-categories CreateInsightsQuestionnairesCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  Name: string # The name of this category.
]: any -> record<account_sid: string, category_id: string, name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Categories")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Insights/QM/Categories/{CategoryId}
#
# operationId: DeleteInsightsQuestionnairesCategory
export def "insights-qm-categories DeleteInsightsQuestionnairesCategory" [
  CategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Categories/($CategoryId)")
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To update the category for Questions
#
# POST /v1/Insights/QM/Categories/{CategoryId}
# operationId: UpdateInsightsQuestionnairesCategory
export def "insights-qm-categories UpdateInsightsQuestionnairesCategory" [
  CategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  Name: string # The name of this category.
]: any -> record<account_sid: string, category_id: string, name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Categories/($CategoryId)")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# To get all questionnaires with questions
#
# GET /v1/Insights/QM/Questionnaires
# operationId: ListInsightsQuestionnaires
export def "insights-qm-questionnaires ListInsightsQuestionnaires" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IncludeInactive: oneof<nothing, bool> # Flag indicating whether to include inactive questionnaires or not
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --Token: string # The Token HTTP request header
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questionnaires: table<account_sid: string, active: bool, description: string, id: string, name: string, questions: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "IncludeInactive" $IncludeInactive "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Questionnaires" $qp)
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To create a Questionnaire
#
# POST /v1/Insights/QM/Questionnaires
# operationId: CreateInsightsQuestionnaires
export def "insights-qm-questionnaires CreateInsightsQuestionnaires" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  --Active: oneof<nothing, bool> # The flag to enable or disable questionnaire
  --Description: string # The description of this questionnaire
  Name: string # The name of this questionnaire
  --QuestionIds: list # The list of questions ids under a questionnaire
]: any -> record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Questionnaires")
  let body = {Active: $Active, Description: $Description, Name: $Name, QuestionIds: $QuestionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# To delete the questionnaire
#
# DELETE /v1/Insights/QM/Questionnaires/{Id}
# operationId: DeleteInsightsQuestionnaires
export def "insights-qm-questionnaires DeleteInsightsQuestionnaires" [
  Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Questionnaires/($Id)")
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To get the Questionnaire Detail
#
# GET /v1/Insights/QM/Questionnaires/{Id}
# operationId: FetchInsightsQuestionnaires
export def "insights-qm-questionnaires FetchInsightsQuestionnaires" [
  Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
]: nothing -> record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Questionnaires/($Id)")
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To update the questionnaire
#
# POST /v1/Insights/QM/Questionnaires/{Id}
# operationId: UpdateInsightsQuestionnaires
export def "insights-qm-questionnaires UpdateInsightsQuestionnaires" [
  Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  --Active: oneof<nothing, bool> # The flag to enable or disable questionnaire
  --Description: string # The description of this questionnaire
  --Name: string # The name of this questionnaire
  --QuestionIds: list # The list of questions ids under a questionnaire
]: any -> record<account_sid: string, active: bool, description: string, id: string, name: string, questions: list<any>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Questionnaires/($Id)")
  let body = {Active: $Active, Description: $Description, Name: $Name, QuestionIds: $QuestionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# To get all the question for the given categories
#
# GET /v1/Insights/QM/Questions
# operationId: ListInsightsQuestionnairesQuestion
export def "insights-qm-questions ListInsightsQuestionnairesQuestion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CategoryId: list # The list of category IDs
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --Token: string # The Token HTTP request header
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, questions: table<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "CategoryId" $CategoryId "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/QM/Questions" $qp)
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To create a question for a Category
#
# POST /v1/Insights/QM/Questions
# operationId: CreateInsightsQuestionnairesQuestion
export def "insights-qm-questions CreateInsightsQuestionnairesQuestion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  --AllowNa: oneof<nothing, bool> # The flag to enable for disable NA for answer.
  AnswerSetId: string # The answer_set for the question.
  CategoryId: string # The ID of the category
  --Description: string # The description for the question.
  Question: string # The question.
]: any -> record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Questions")
  let body = {AllowNa: $AllowNa, AnswerSetId: $AnswerSetId, CategoryId: $CategoryId, Description: $Description, Question: $Question} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Insights/QM/Questions/{QuestionId}
#
# operationId: DeleteInsightsQuestionnairesQuestion
export def "insights-qm-questions DeleteInsightsQuestionnairesQuestion" [
  QuestionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Questions/($QuestionId)")
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To update the question
#
# POST /v1/Insights/QM/Questions/{QuestionId}
# operationId: UpdateInsightsQuestionnairesQuestion
export def "insights-qm-questions UpdateInsightsQuestionnairesQuestion" [
  QuestionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
  --AllowNa: oneof<nothing, bool> # The flag to enable for disable NA for answer.
  --AnswerSetId: string # The answer_set for the question.
  --CategoryId: string # The ID of the category
  --Description: string # The description for the question.
  --Question: string # The question.
]: any -> record<account_sid: string, allow_na: bool, answer_set: any, answer_set_id: string, category: any, description: string, question: string, question_id: string, url: string, usage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/QM/Questions/($QuestionId)")
  let body = {AllowNa: $AllowNa, AnswerSetId: $AnswerSetId, CategoryId: $CategoryId, Description: $Description, Question: $Question} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# To get the Answer Set Settings for an Account
#
# GET /v1/Insights/QM/Settings/AnswerSets
# operationId: FetchInsightsSettingsAnswersets
export def "insights-qm-settings-answer-sets FetchInsightsSettingsAnswersets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
]: nothing -> record<account_sid: string, answer_set_categories: any, answer_sets: any, not_applicable: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Settings/AnswerSets")
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To get the Comment Settings for an Account
#
# GET /v1/Insights/QM/Settings/CommentTags
# operationId: FetchInsightsSettingsComment
export def "insights-qm-settings-comment-tags FetchInsightsSettingsComment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
]: nothing -> record<account_sid: string, comments: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/QM/Settings/CommentTags")
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To get segments for given reservation Ids
#
# GET /v1/Insights/Segments
# operationId: ListInsightsSegments
export def "insights-segments ListInsightsSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ReservationId: list # The list of reservation Ids
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --Token: string # The Token HTTP request header
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, segments: table<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "ReservationId" $ReservationId "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Insights/Segments" $qp)
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To get the Segments of an Account
#
# GET /v1/Insights/Segments/{SegmentId}
# operationId: FetchInsightsSegments
export def "insights-segments FetchInsightsSegments" [
  SegmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Token: string # The Token HTTP request header
]: nothing -> record<account_id: string, agent_id: string, agent_link: string, agent_name: string, agent_phone: string, agent_team_name: string, agent_team_name_in_hierarchy: string, assessment_percentage: any, assessment_type: any, customer_link: string, customer_name: string, customer_phone: string, date: string, external_contact: string, external_id: string, external_segment_link: string, external_segment_link_id: string, media: any, queue: string, segment_id: string, segment_recording_offset: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Insights/Segments/($SegmentId)")
  let extra_headers = {"Token": $Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To obtain session details for fetching reports and dashboards
#
# POST /v1/Insights/Session
# operationId: CreateInsightsSession
export def "insights-session CreateInsightsSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The Authorization HTTP request header
]: nothing -> record<base_url: string, session_expiry: string, session_id: string, url: string, workspace_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/Session")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This is used by Flex UI and Quality Management to fetch the Flex Insights roles for the user
#
# GET /v1/Insights/UserRoles
# operationId: FetchInsightsUserRoles
export def "insights-user-roles FetchInsightsUserRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The Authorization HTTP request header
]: nothing -> record<roles: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Insights/UserRoles")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Interaction.
#
# POST /v1/Interactions
# operationId: CreateInteraction
export def "interactions CreateInteraction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Channel: any # The Interaction's channel.
  Routing: any # The Interaction's routing logic.
]: any -> record<channel: any, links: record, routing: any, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/Interactions")
  let body = {Channel: $Channel, Routing: $Routing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all Channels for an Interaction.
#
# GET /v1/Interactions/{InteractionSid}/Channels
# operationId: ListInteractionChannel
export def "interactions-channels ListInteractionChannel" [
  InteractionSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<channels: table<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Invites for a Channel.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites
# operationId: ListInteractionChannelInvite
export def "interactions-channels-invites ListInteractionChannelInvite" [
  InteractionSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<invites: table<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels/($ChannelSid)/Invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite an Agent or a TaskQueue to a Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Invites
# operationId: CreateInteractionChannelInvite
export def "interactions-channels-invites CreateInteractionChannelInvite" [
  InteractionSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Routing: any # The Interaction's routing logic.
]: any -> record<channel_sid: string, interaction_sid: string, routing: any, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels/($ChannelSid)/Invites")
  let body = {Routing: $Routing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all Participants for a Channel.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants
# operationId: ListInteractionChannelParticipant
export def "interactions-channels-participants ListInteractionChannelParticipant" [
  InteractionSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels/($ChannelSid)/Participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Participant to a Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants
# operationId: CreateInteractionChannelParticipant
export def "interactions-channels-participants CreateInteractionChannelParticipant" [
  InteractionSid: string
  ChannelSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  MediaProperties: any # JSON representing the Media Properties for the new Participant.
  Type: string@Type-completer
]: any -> record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels/($ChannelSid)/Participants")
  let body = {MediaProperties: $MediaProperties, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update an existing Channel Participant.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{ChannelSid}/Participants/{Sid}
# operationId: UpdateInteractionChannelParticipant
export def "interactions-channels-participants UpdateInteractionChannelParticipant" [
  InteractionSid: string
  ChannelSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Status: string@Status-completer
]: any -> record<channel_sid: string, interaction_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels/($ChannelSid)/Participants/($Sid)")
  let body = {Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch a Channel for an Interaction.
#
# GET /v1/Interactions/{InteractionSid}/Channels/{Sid}
# operationId: FetchInteractionChannel
export def "interactions-channels FetchInteractionChannel" [
  InteractionSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing Interaction Channel.
#
# POST /v1/Interactions/{InteractionSid}/Channels/{Sid}
# operationId: UpdateInteractionChannel
export def "interactions-channels UpdateInteractionChannel" [
  InteractionSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Routing: any # Optional. The state of associated tasks. If not specified, all tasks will be set to `wrapping`.
  Status: string@Status-completer
]: any -> record<error_code: int, error_message: string, interaction_sid: string, links: record, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Interactions/($InteractionSid)/Channels/($Sid)")
  let body = {Routing: $Routing, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Interactions/{Sid}
#
# operationId: FetchInteraction
export def "interactions FetchInteraction" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channel: any, links: record, routing: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/Interactions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/WebChannels
#
# operationId: ListWebChannel
export def "web-channels ListWebChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<flex_chat_channels: table<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/WebChannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/WebChannels
#
# operationId: CreateWebChannel
export def "web-channels CreateWebChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ChatFriendlyName: string # The chat channel's friendly name.
  --ChatUniqueName: string # The chat channel's unique name.
  CustomerFriendlyName: string # The chat participant's friendly name.
  FlexFlowSid: string # The SID of the Flex Flow.
  Identity: string # The chat identity.
  --PreEngagementData: string # The pre-engagement data.
]: any -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base "/v1/WebChannels")
  let body = {ChatFriendlyName: $ChatFriendlyName, ChatUniqueName: $ChatUniqueName, CustomerFriendlyName: $CustomerFriendlyName, FlexFlowSid: $FlexFlowSid, Identity: $Identity, PreEngagementData: $PreEngagementData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/WebChannels/{Sid}
#
# operationId: DeleteWebChannel
export def "web-channels DeleteWebChannel" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/WebChannels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/WebChannels/{Sid}
#
# operationId: FetchWebChannel
export def "web-channels FetchWebChannel" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/WebChannels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/WebChannels/{Sid}
#
# operationId: UpdateWebChannel
export def "web-channels UpdateWebChannel" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ChatStatus: string@ChatStatus-completer
  --PostEngagementData: string # The post-engagement data.
]: any -> record<account_sid: string, date_created: string, date_updated: string, flex_flow_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://flex-api.twilio.com")
  let full_url = (build-url $base $"/v1/WebChannels/($Sid)")
  let body = {ChatStatus: $ChatStatus, PostEngagementData: $PostEngagementData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
