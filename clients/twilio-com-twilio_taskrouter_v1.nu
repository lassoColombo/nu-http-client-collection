# Auto-generated client for Twilio - Taskrouter v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_taskrouter_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_TASKROUTER_TOKEN

const BASE_URL = "https://taskrouter.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_TASKROUTER_TOKEN | default "" }
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

def base-url-completer [] { ["https://taskrouter.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def PrioritizeQueueOrder-completer [] { ["FIFO" "LIFO"] }
def TaskOrder-completer [] { ["FIFO" "LIFO"] }
def AssignmentStatus-completer [] { ["assigned" "canceled" "completed" "pending" "reserved" "wrapping"] }
def ReservationStatus-completer [] { ["accepted" "canceled" "completed" "pending" "rejected" "rescinded" "timeout" "wrapping"] }
def ConferenceRecordingStatusCallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def ConferenceStatusCallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def RecordingStatusCallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def StatusCallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def SupervisorMode-completer [] { ["barge" "monitor" "whisper"] }
def WaitMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "workspaces ListWorkspace" } } | get name | first)
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

# GET /v1/Workspaces
#
# operationId: ListWorkspace
export def "workspaces ListWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # The `friendly_name` of the Workspace resources to read. For example `Customer Support` or `2014 Election Campaign`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workspaces: table<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces
#
# operationId: CreateWorkspace
export def "workspaces CreateWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EventCallbackUrl: string # The URL we should call when an event occurs. If provided, the Workspace will publish events to this URL, for example, to collect data for reporting. See [Workspace Events](https://www.twilio.com/docs/taskrouter/api/event) for more information. This parameter supports Twilio's [Webhooks (HTTP callbacks) Connection Overrides](https://www.twilio.com/docs/usage/webhooks/webhooks-connection-overrides). (format: uri)
  --EventsFilter: string # The list of Workspace events for which to call event_callback_url. For example, if `EventsFilter=task.created, task.canceled, worker.activity.update`, then TaskRouter will call event_callback_url only when a task is created, canceled, or a Worker activity is updated.
  FriendlyName: string # A descriptive string that you create to describe the Workspace resource. It can be up to 64 characters long. For example: `Customer Support` or `2014 Election Campaign`.
  --MultiTaskEnabled: oneof<nothing, bool> # Whether to enable multi-tasking. Can be: `true` to enable multi-tasking, or `false` to disable it. However, all workspaces should be created as multi-tasking. The default is `true`. Multi-tasking allows Workers to handle multiple Tasks simultaneously. When enabled (`true`), each Worker can receive parallel reservations up to the per-channel maximums defined in the Workers section. In single-tasking mode (legacy mode), each Worker will only receive a new reservation when the previous task is completed. Learn more at [Multitasking](https://www.twilio.com/docs/taskrouter/multitasking).
  --PrioritizeQueueOrder: string@PrioritizeQueueOrder-completer
  --Template: string # An available template name. Can be: `NONE` or `FIFO` and the default is `NONE`. Pre-configures the Workspace with the Workflow and Activities specified in the template. `NONE` will create a Workspace with only a set of default activities. `FIFO` will configure TaskRouter with a set of default activities and a single TaskQueue for first-in, first-out distribution, which can be useful when you are getting started with TaskRouter.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base "/v1/Workspaces")
  let body = {EventCallbackUrl: $EventCallbackUrl, EventsFilter: $EventsFilter, FriendlyName: $FriendlyName, MultiTaskEnabled: $MultiTaskEnabled, PrioritizeQueueOrder: $PrioritizeQueueOrder, Template: $Template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Workspaces/{Sid}
#
# operationId: DeleteWorkspace
export def "workspaces DeleteWorkspace" [
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{Sid}
#
# operationId: FetchWorkspace
export def "workspaces FetchWorkspace" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{Sid}
#
# operationId: UpdateWorkspace
export def "workspaces UpdateWorkspace" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DefaultActivitySid: string # The SID of the Activity that will be used when new Workers are created in the Workspace.
  --EventCallbackUrl: string # The URL we should call when an event occurs. See [Workspace Events](https://www.twilio.com/docs/taskrouter/api/event) for more information. This parameter supports Twilio's [Webhooks (HTTP callbacks) Connection Overrides](https://www.twilio.com/docs/usage/webhooks/webhooks-connection-overrides). (format: uri)
  --EventsFilter: string # The list of Workspace events for which to call event_callback_url. For example if `EventsFilter=task.created,task.canceled,worker.activity.update`, then TaskRouter will call event_callback_url only when a task is created, canceled, or a Worker activity is updated.
  --FriendlyName: string # A descriptive string that you create to describe the Workspace resource. For example: `Sales Call Center` or `Customer Support Team`.
  --MultiTaskEnabled: oneof<nothing, bool> # Whether to enable multi-tasking. Can be: `true` to enable multi-tasking, or `false` to disable it. However, all workspaces should be maintained as multi-tasking. There is no default when omitting this parameter. A multi-tasking Workspace can't be updated to single-tasking unless it is not a Flex Project and another (legacy) single-tasking Workspace exists. Multi-tasking allows Workers to handle multiple Tasks simultaneously. In multi-tasking mode, each Worker can receive parallel reservations up to the per-channel maximums defined in the Workers section. In single-tasking mode (legacy mode), each Worker will only receive a new reservation when the previous task is completed. Learn more at [Multitasking](https://www.twilio.com/docs/taskrouter/multitasking).
  --PrioritizeQueueOrder: string@PrioritizeQueueOrder-completer
  --TimeoutActivitySid: string # The SID of the Activity that will be assigned to a Worker when a Task reservation times out without a response.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($Sid)")
  let body = {DefaultActivitySid: $DefaultActivitySid, EventCallbackUrl: $EventCallbackUrl, EventsFilter: $EventsFilter, FriendlyName: $FriendlyName, MultiTaskEnabled: $MultiTaskEnabled, PrioritizeQueueOrder: $PrioritizeQueueOrder, TimeoutActivitySid: $TimeoutActivitySid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Activities
#
# operationId: ListActivity
export def "workspaces-activities ListActivity" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # The `friendly_name` of the Activity resources to read.
  --Available: string # Whether return only Activity resources that are available or unavailable. A value of `true` returns only available activities. Values of '1' or `yes` also indicate `true`. All other values represent `false` and return activities that are unavailable.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<activities: table<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "Available" $Available "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Activities
#
# operationId: CreateActivity
export def "workspaces-activities CreateActivity" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Available: oneof<nothing, bool> # Whether the Worker should be eligible to receive a Task when it occupies the Activity. A value of `true`, `1`, or `yes` specifies the Activity is available. All other values specify that it is not. The value cannot be changed after the Activity is created.
  FriendlyName: string # A descriptive string that you create to describe the Activity resource. It can be up to 64 characters long. These names are used to calculate and expose statistics about Workers, and provide visibility into the state of each Worker. Examples of friendly names include: `on-call`, `break`, and `email`.
]: any -> record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Activities")
  let body = {Available: $Available, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# operationId: DeleteActivity
export def "workspaces-activities DeleteActivity" [
  WorkspaceSid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Activities/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# operationId: FetchActivity
export def "workspaces-activities FetchActivity" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Activities/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# operationId: UpdateActivity
export def "workspaces-activities UpdateActivity" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # A descriptive string that you create to describe the Activity resource. It can be up to 64 characters long. These names are used to calculate and expose statistics about Workers, and provide visibility into the state of each Worker. Examples of friendly names include: `on-call`, `break`, and `email`.
]: any -> record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Activities/($Sid)")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/CumulativeStatistics
#
# operationId: FetchWorkspaceCumulativeStatistics
export def "workspaces-cumulative-statistics FetchWorkspaceCumulativeStatistics" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --TaskChannel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --SplitByWaitTime: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA. TaskRouter will calculate statistics on up to 10,000 Tasks for any given threshold.
]: nothing -> record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_created: int, tasks_deleted: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "SplitByWaitTime" $SplitByWaitTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/CumulativeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Events
#
# operationId: ListEvent
export def "workspaces-events ListEvent" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # Only include Events that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --EventType: string # The type of Events to read. Returns only Events of the type specified.
  --Minutes: int # The period of events to read in minutes. Returns only Events that occurred since this many minutes in the past. The default is `15` minutes. Task Attributes for Events occuring more 43,200 minutes ago will be redacted.
  --ReservationSid: string # The SID of the Reservation with the Events to read. Returns only Events that pertain to the specified Reservation.
  --StartDate: string # Only include Events from on or after this date and time, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. Task Attributes for Events older than 30 days will be redacted. (format: date-time)
  --TaskQueueSid: string # The SID of the TaskQueue with the Events to read. Returns only the Events that pertain to the specified TaskQueue.
  --TaskSid: string # The SID of the Task with the Events to read. Returns only the Events that pertain to the specified Task.
  --WorkerSid: string # The SID of the Worker with the Events to read. Returns only the Events that pertain to the specified Worker.
  --WorkflowSid: string # The SID of the Workflow with the Events to read. Returns only the Events that pertain to the specified Workflow.
  --TaskChannel: string # The TaskChannel with the Events to read. Returns only the Events that pertain to the specified TaskChannel.
  --Sid: string # The SID of the Event resource to read.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<events: table<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "EventType" $EventType "scalar") (serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "ReservationSid" $ReservationSid "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "TaskQueueSid" $TaskQueueSid "scalar") (serialize-qp "TaskSid" $TaskSid "scalar") (serialize-qp "WorkerSid" $WorkerSid "scalar") (serialize-qp "WorkflowSid" $WorkflowSid "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "Sid" $Sid "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Events/{Sid}
#
# operationId: FetchEvent
export def "workspaces-events FetchEvent" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Events/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/RealTimeStatistics
#
# operationId: FetchWorkspaceRealTimeStatistics
export def "workspaces-real-time-statistics FetchWorkspaceRealTimeStatistics" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --TaskChannel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_statistics: list<any>, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, total_workers: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "TaskChannel" $TaskChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/RealTimeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Statistics
#
# operationId: FetchWorkspaceStatistics
export def "workspaces-statistics FetchWorkspaceStatistics" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --EndDate: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --TaskChannel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --SplitByWaitTime: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "SplitByWaitTime" $SplitByWaitTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskChannels
#
# operationId: ListTaskChannel
export def "workspaces-task-channels ListTaskChannel" [
  WorkspaceSid: string
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
]: nothing -> record<channels: table<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskChannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskChannels
#
# operationId: CreateTaskChannel
export def "workspaces-task-channels CreateTaskChannel" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ChannelOptimizedRouting: oneof<nothing, bool> # Whether the Task Channel should prioritize Workers that have been idle. If `true`, Workers that have been idle the longest are prioritized.
  FriendlyName: string # A descriptive string that you create to describe the Task Channel. It can be up to 64 characters long.
  UniqueName: string # An application-defined string that uniquely identifies the Task Channel, such as `voice` or `sms`.
]: any -> record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskChannels")
  let body = {ChannelOptimizedRouting: $ChannelOptimizedRouting, FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# operationId: DeleteTaskChannel
export def "workspaces-task-channels DeleteTaskChannel" [
  WorkspaceSid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskChannels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# operationId: FetchTaskChannel
export def "workspaces-task-channels FetchTaskChannel" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskChannels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# operationId: UpdateTaskChannel
export def "workspaces-task-channels UpdateTaskChannel" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ChannelOptimizedRouting: oneof<nothing, bool> # Whether the TaskChannel should prioritize Workers that have been idle. If `true`, Workers that have been idle the longest are prioritized.
  --FriendlyName: string # A descriptive string that you create to describe the Task Channel. It can be up to 64 characters long.
]: any -> record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskChannels/($Sid)")
  let body = {ChannelOptimizedRouting: $ChannelOptimizedRouting, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues
#
# operationId: ListTaskQueue
export def "workspaces-task-queues ListTaskQueue" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # The `friendly_name` of the TaskQueue resources to read.
  --EvaluateWorkerAttributes: string # The attributes of the Workers to read. Returns the TaskQueues with Workers that match the attributes specified in this parameter.
  --WorkerSid: string # The SID of the Worker with the TaskQueue resources to read.
  --Ordering: string # Sorting parameter for TaskQueues
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues: table<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "EvaluateWorkerAttributes" $EvaluateWorkerAttributes "scalar") (serialize-qp "WorkerSid" $WorkerSid "scalar") (serialize-qp "Ordering" $Ordering "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskQueues
#
# operationId: CreateTaskQueue
export def "workspaces-task-queues CreateTaskQueue" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AssignmentActivitySid: string # The SID of the Activity to assign Workers when a task is assigned to them.
  FriendlyName: string # A descriptive string that you create to describe the TaskQueue. For example `Support-Tier 1`, `Sales`, or `Escalation`.
  --MaxReservedWorkers: int # The maximum number of Workers to reserve for the assignment of a Task in the queue. Can be an integer between 1 and 50, inclusive and defaults to 1.
  --ReservationActivitySid: string # The SID of the Activity to assign Workers when a task is reserved for them.
  --TargetWorkers: string # A string that describes the Worker selection criteria for any Tasks that enter the TaskQueue. For example, `'"language" == "spanish"'`. The default value is `1==1`. If this value is empty, Tasks will wait in the TaskQueue until they are deleted or moved to another TaskQueue. For more information about Worker selection, see [Describing Worker selection criteria](https://www.twilio.com/docs/taskrouter/api/taskqueues#target-workers).
  --TaskOrder: string@TaskOrder-completer
]: any -> record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues")
  let body = {AssignmentActivitySid: $AssignmentActivitySid, FriendlyName: $FriendlyName, MaxReservedWorkers: $MaxReservedWorkers, ReservationActivitySid: $ReservationActivitySid, TargetWorkers: $TargetWorkers, TaskOrder: $TaskOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/Statistics
#
# operationId: ListTaskQueuesStatistics
export def "workspaces-task-queues-statistics ListTaskQueuesStatistics" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --FriendlyName: string # The `friendly_name` of the TaskQueue statistics to read.
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --TaskChannel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --SplitByWaitTime: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues_statistics: table<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "SplitByWaitTime" $SplitByWaitTime "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues/Statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# operationId: DeleteTaskQueue
export def "workspaces-task-queues DeleteTaskQueue" [
  WorkspaceSid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# operationId: FetchTaskQueue
export def "workspaces-task-queues FetchTaskQueue" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# operationId: UpdateTaskQueue
export def "workspaces-task-queues UpdateTaskQueue" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AssignmentActivitySid: string # The SID of the Activity to assign Workers when a task is assigned for them.
  --FriendlyName: string # A descriptive string that you create to describe the TaskQueue. For example `Support-Tier 1`, `Sales`, or `Escalation`.
  --MaxReservedWorkers: int # The maximum number of Workers to create reservations for the assignment of a task while in the queue. Maximum of 50.
  --ReservationActivitySid: string # The SID of the Activity to assign Workers when a task is reserved for them.
  --TargetWorkers: string # A string describing the Worker selection criteria for any Tasks that enter the TaskQueue. For example '"language" == "spanish"' If no TargetWorkers parameter is provided, Tasks will wait in the queue until they are either deleted or moved to another queue. Additional examples on how to describing Worker selection criteria below.
  --TaskOrder: string@TaskOrder-completer
]: any -> record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues/($Sid)")
  let body = {AssignmentActivitySid: $AssignmentActivitySid, FriendlyName: $FriendlyName, MaxReservedWorkers: $MaxReservedWorkers, ReservationActivitySid: $ReservationActivitySid, TargetWorkers: $TargetWorkers, TaskOrder: $TaskOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/CumulativeStatistics
#
# operationId: FetchTaskQueueCumulativeStatistics
export def "workspaces-task-queues-cumulative-statistics FetchTaskQueueCumulativeStatistics" [
  WorkspaceSid: string
  TaskQueueSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --TaskChannel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --SplitByWaitTime: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. TaskRouter will calculate statistics on up to 10,000 Tasks/Reservations for any given threshold.
]: nothing -> record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, task_queue_sid: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, url: string, wait_duration_in_queue_until_accepted: any, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "SplitByWaitTime" $SplitByWaitTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues/($TaskQueueSid)/CumulativeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/RealTimeStatistics
#
# operationId: FetchTaskQueueRealTimeStatistics
export def "workspaces-task-queues-real-time-statistics FetchTaskQueueRealTimeStatistics" [
  WorkspaceSid: string
  TaskQueueSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --TaskChannel: string # The TaskChannel for which to fetch statistics. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_statistics: list<any>, longest_relative_task_age_in_queue: int, longest_relative_task_sid_in_queue: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, task_queue_sid: string, tasks_by_priority: any, tasks_by_status: any, total_available_workers: int, total_eligible_workers: int, total_tasks: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "TaskChannel" $TaskChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues/($TaskQueueSid)/RealTimeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/Statistics
#
# operationId: FetchTaskQueueStatistics
export def "workspaces-task-queues-statistics FetchTaskQueueStatistics" [
  WorkspaceSid: string
  TaskQueueSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --TaskChannel: string # Only calculate real-time and cumulative statistics for the specified TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --SplitByWaitTime: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "SplitByWaitTime" $SplitByWaitTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/TaskQueues/($TaskQueueSid)/Statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks
#
# operationId: ListTask
export def "workspaces-tasks ListTask" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Priority: int # The priority value of the Tasks to read. Returns the list of all Tasks in the Workspace with the specified priority.
  --AssignmentStatus: list # The `assignment_status` of the Tasks you want to read. Can be: `pending`, `reserved`, `assigned`, `canceled`, `wrapping`, or `completed`. Returns all Tasks in the Workspace with the specified `assignment_status`.
  --WorkflowSid: string # The SID of the Workflow with the Tasks to read. Returns the Tasks controlled by the Workflow identified by this SID.
  --WorkflowName: string # The friendly name of the Workflow with the Tasks to read. Returns the Tasks controlled by the Workflow identified by this friendly name.
  --TaskQueueSid: string # The SID of the TaskQueue with the Tasks to read. Returns the Tasks waiting in the TaskQueue identified by this SID.
  --TaskQueueName: string # The `friendly_name` of the TaskQueue with the Tasks to read. Returns the Tasks waiting in the TaskQueue identified by this friendly name.
  --EvaluateTaskAttributes: string # The attributes of the Tasks to read. Returns the Tasks that match the attributes specified in this parameter.
  --Ordering: string # How to order the returned Task resources. y default, Tasks are sorted by ascending DateCreated. This value is specified as: `Attribute:Order`, where `Attribute` can be either `Priority` or `DateCreated` and `Order` can be either `asc` or `desc`. For example, `Priority:desc` returns Tasks ordered in descending order of their Priority. Multiple sort orders can be specified in a comma-separated list such as `Priority:desc,DateCreated:asc`, which returns the Tasks in descending Priority order and ascending DateCreated Order.
  --HasAddons: oneof<nothing, bool> # Whether to read Tasks with addons. If `true`, returns only Tasks with addons. If `false`, returns only Tasks without addons.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "Priority" $Priority "scalar") (serialize-qp "AssignmentStatus" $AssignmentStatus "multi") (serialize-qp "WorkflowSid" $WorkflowSid "scalar") (serialize-qp "WorkflowName" $WorkflowName "scalar") (serialize-qp "TaskQueueSid" $TaskQueueSid "scalar") (serialize-qp "TaskQueueName" $TaskQueueName "scalar") (serialize-qp "EvaluateTaskAttributes" $EvaluateTaskAttributes "scalar") (serialize-qp "Ordering" $Ordering "scalar") (serialize-qp "HasAddons" $HasAddons "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks
#
# operationId: CreateTask
export def "workspaces-tasks CreateTask" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: string # A URL-encoded JSON string with the attributes of the new task. This value is passed to the Workflow's `assignment_callback_url` when the Task is assigned to a Worker. For example: `{ "task_type": "call", "twilio_call_sid": "CAxxx", "customer_ticket_number": "12345" }`.
  --Priority: int # The priority to assign the new task and override the default. When supplied, the new Task will have this priority unless it matches a Workflow Target with a Priority set. When not supplied, the new Task will have the priority of the matching Workflow Target. Value can be 0 to 2^31^ (2,147,483,647).
  --TaskChannel: string # When MultiTasking is enabled, specify the TaskChannel by passing either its `unique_name` or `sid`. Default value is `default`.
  --Timeout: int # The amount of time in seconds the new task can live before being assigned. Can be up to a maximum of 2 weeks (1,209,600 seconds). The default value is 24 hours (86,400 seconds). On timeout, the `task.canceled` event will fire with description `Task TTL Exceeded`.
  --WorkflowSid: string # The SID of the Workflow that you would like to handle routing for the new Task. If there is only one Workflow defined for the Workspace that you are posting the new task to, this parameter is optional.
]: any -> record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks")
  let body = {Attributes: $Attributes, Priority: $Priority, TaskChannel: $TaskChannel, Timeout: $Timeout, WorkflowSid: $WorkflowSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# operationId: DeleteTask
export def "workspaces-tasks DeleteTask" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # If provided, deletes this Task if (and only if) the [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) header of the Task matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks/($Sid)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# operationId: FetchTask
export def "workspaces-tasks FetchTask" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# operationId: UpdateTask
export def "workspaces-tasks UpdateTask" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # If provided, applies this mutation if (and only if) the [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) header of the Task matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
  --AssignmentStatus: string@AssignmentStatus-completer
  --Attributes: string # The JSON string that describes the custom attributes of the task.
  --Priority: int # The Task's new priority value. When supplied, the Task takes on the specified priority unless it matches a Workflow Target with a Priority set. Value can be 0 to 2^31^ (2,147,483,647).
  --Reason: string # The reason that the Task was canceled or completed. This parameter is required only if the Task is canceled or completed. Setting this value queues the task for deletion and logs the reason.
  --TaskChannel: string # When MultiTasking is enabled, specify the TaskChannel with the task to update. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: any -> record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks/($Sid)")
  let body = {AssignmentStatus: $AssignmentStatus, Attributes: $Attributes, Priority: $Priority, Reason: $Reason, TaskChannel: $TaskChannel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations
#
# operationId: ListTaskReservation
export def "workspaces-tasks-reservations ListTaskReservation" [
  WorkspaceSid: string
  TaskSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ReservationStatus: string@ReservationStatus-completer # Returns the list of reservations for a task with a specified ReservationStatus.  Can be: `pending`, `accepted`, `rejected`, or `timeout`.
  --WorkerSid: string # The SID of the reserved Worker resource to read.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "ReservationStatus" $ReservationStatus "scalar") (serialize-qp "WorkerSid" $WorkerSid "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks/($TaskSid)/Reservations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}
#
# operationId: FetchTaskReservation
export def "workspaces-tasks-reservations FetchTaskReservation" [
  WorkspaceSid: string
  TaskSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks/($TaskSid)/Reservations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}
#
# operationId: UpdateTaskReservation
export def "workspaces-tasks-reservations UpdateTaskReservation" [
  WorkspaceSid: string
  TaskSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
  --Beep: string # Whether to play a notification beep when the participant joins or when to play a beep. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --BeepOnCustomerEntrance: oneof<nothing, bool> # Whether to play a notification beep when the customer joins.
  --CallAccept: oneof<nothing, bool> # Whether to accept a reservation when executing a Call instruction.
  --CallFrom: string # The Caller ID of the outbound call when executing a Call instruction.
  --CallRecord: string # Whether to record both legs of a call when executing a Call instruction or which leg to record.
  --CallStatusCallbackUrl: string # The URL to call  for the completed call event when executing a Call instruction. (format: uri)
  --CallTimeout: int # Timeout for call when executing a Call instruction.
  --CallTo: string # The Contact URI of the worker when executing a Call instruction.  Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --CallUrl: string # TwiML URI executed on answering the worker's leg as a result of the Call instruction. (format: uri)
  --ConferenceRecord: string # Whether to record the conference the participant is joining or when to record the conference. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --ConferenceRecordingStatusCallback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --ConferenceRecordingStatusCallbackMethod: string@ConferenceRecordingStatusCallbackMethod-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --ConferenceStatusCallback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --ConferenceStatusCallbackEvent: list # The conference status events that we will send to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `speaker`.
  --ConferenceStatusCallbackMethod: string@ConferenceStatusCallbackMethod-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --ConferenceTrim: string # How to trim the leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --DequeueFrom: string # The Caller ID of the call to the worker when executing a Dequeue instruction.
  --DequeuePostWorkActivitySid: string # The SID of the Activity resource to start after executing a Dequeue instruction.
  --DequeueRecord: string # Whether to record both legs of a call when executing a Dequeue instruction or which leg to record.
  --DequeueStatusCallbackEvent: list # The Call progress events sent via webhooks as a result of a Dequeue instruction.
  --DequeueStatusCallbackUrl: string # The Callback URL for completed call event when executing a Dequeue instruction. (format: uri)
  --DequeueTimeout: int # Timeout for call when executing a Dequeue instruction.
  --DequeueTo: string # The Contact URI of the worker when executing a Dequeue instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --EarlyMedia: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. The default is `true`.
  --EndConferenceOnCustomerExit: oneof<nothing, bool> # Whether to end the conference when the customer leaves.
  --EndConferenceOnExit: oneof<nothing, bool> # Whether to end the conference when the agent leaves.
  --From: string # The Caller ID of the call to the worker when executing a Conference instruction.
  --Instruction: string # The assignment instruction for reservation.
  --MaxParticipants: int # The maximum number of participants in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --Muted: oneof<nothing, bool> # Whether the agent is muted in the conference. The default is `false`.
  --PostWorkActivitySid: string # The new worker activity SID after executing a Conference instruction.
  --Record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. The default is `false`.
  --RecordingChannels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --RecordingStatusCallback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --RecordingStatusCallbackMethod: string@RecordingStatusCallbackMethod-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --RedirectAccept: oneof<nothing, bool> # Whether the reservation should be accepted when executing a Redirect instruction.
  --RedirectCallSid: string # The Call SID of the call parked in the queue when executing a Redirect instruction.
  --RedirectUrl: string # TwiML URI to redirect the call to when executing the Redirect instruction. (format: uri)
  --Region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --ReservationStatus: string@ReservationStatus-completer
  --SipAuthPassword: string # The SIP password for authentication.
  --SipAuthUsername: string # The SIP username used for authentication.
  --StartConferenceOnEnter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. The default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackEvent: list # The call progress events that we will send to `status_callback`. Can be: `initiated`, `ringing`, `answered`, or `completed`.
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --Supervisor: string # The Supervisor SID/URI when executing the Supervise instruction.
  --SupervisorMode: string@SupervisorMode-completer
  --Timeout: int # Timeout for call when executing a Conference instruction.
  --To: string # The Contact URI of the worker when executing a Conference instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --WaitMethod: string@WaitMethod-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --WaitUrl: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
  --WorkerActivitySid: string # The new worker activity SID if rejecting a reservation.
]: any -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Tasks/($TaskSid)/Reservations/($Sid)")
  let body = {Beep: $Beep, BeepOnCustomerEntrance: $BeepOnCustomerEntrance, CallAccept: $CallAccept, CallFrom: $CallFrom, CallRecord: $CallRecord, CallStatusCallbackUrl: $CallStatusCallbackUrl, CallTimeout: $CallTimeout, CallTo: $CallTo, CallUrl: $CallUrl, ConferenceRecord: $ConferenceRecord, ConferenceRecordingStatusCallback: $ConferenceRecordingStatusCallback, ConferenceRecordingStatusCallbackMethod: $ConferenceRecordingStatusCallbackMethod, ConferenceStatusCallback: $ConferenceStatusCallback, ConferenceStatusCallbackEvent: $ConferenceStatusCallbackEvent, ConferenceStatusCallbackMethod: $ConferenceStatusCallbackMethod, ConferenceTrim: $ConferenceTrim, DequeueFrom: $DequeueFrom, DequeuePostWorkActivitySid: $DequeuePostWorkActivitySid, DequeueRecord: $DequeueRecord, DequeueStatusCallbackEvent: $DequeueStatusCallbackEvent, DequeueStatusCallbackUrl: $DequeueStatusCallbackUrl, DequeueTimeout: $DequeueTimeout, DequeueTo: $DequeueTo, EarlyMedia: $EarlyMedia, EndConferenceOnCustomerExit: $EndConferenceOnCustomerExit, EndConferenceOnExit: $EndConferenceOnExit, From: $From, Instruction: $Instruction, MaxParticipants: $MaxParticipants, Muted: $Muted, PostWorkActivitySid: $PostWorkActivitySid, Record: $Record, RecordingChannels: $RecordingChannels, RecordingStatusCallback: $RecordingStatusCallback, RecordingStatusCallbackMethod: $RecordingStatusCallbackMethod, RedirectAccept: $RedirectAccept, RedirectCallSid: $RedirectCallSid, RedirectUrl: $RedirectUrl, Region: $Region, ReservationStatus: $ReservationStatus, SipAuthPassword: $SipAuthPassword, SipAuthUsername: $SipAuthUsername, StartConferenceOnEnter: $StartConferenceOnEnter, StatusCallback: $StatusCallback, StatusCallbackEvent: $StatusCallbackEvent, StatusCallbackMethod: $StatusCallbackMethod, Supervisor: $Supervisor, SupervisorMode: $SupervisorMode, Timeout: $Timeout, To: $To, WaitMethod: $WaitMethod, WaitUrl: $WaitUrl, WorkerActivitySid: $WorkerActivitySid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers
#
# operationId: ListWorker
export def "workspaces-workers ListWorker" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ActivityName: string # The `activity_name` of the Worker resources to read.
  --ActivitySid: string # The `activity_sid` of the Worker resources to read.
  --Available: string # Whether to return only Worker resources that are available or unavailable. Can be `true`, `1`, or `yes` to return Worker resources that are available, and `false`, or any value returns the Worker resources that are not available.
  --FriendlyName: string # The `friendly_name` of the Worker resources to read.
  --TargetWorkersExpression: string # Filter by Workers that would match an expression on a TaskQueue. This is helpful for debugging which Workers would match a potential queue.
  --TaskQueueName: string # The `friendly_name` of the TaskQueue that the Workers to read are eligible for.
  --TaskQueueSid: string # The SID of the TaskQueue that the Workers to read are eligible for.
  --Ordering: string # Sorting parameter for Workers
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workers: table<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "ActivityName" $ActivityName "scalar") (serialize-qp "ActivitySid" $ActivitySid "scalar") (serialize-qp "Available" $Available "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "TargetWorkersExpression" $TargetWorkersExpression "scalar") (serialize-qp "TaskQueueName" $TaskQueueName "scalar") (serialize-qp "TaskQueueSid" $TaskQueueSid "scalar") (serialize-qp "Ordering" $Ordering "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers
#
# operationId: CreateWorker
export def "workspaces-workers CreateWorker" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ActivitySid: string # The SID of a valid Activity that will describe the new Worker's initial state. See [Activities](https://www.twilio.com/docs/taskrouter/api/activity) for more information. If not provided, the new Worker's initial state is the `default_activity_sid` configured on the Workspace.
  --Attributes: string # A valid JSON string that describes the new Worker. For example: `{ "email": "Bob@example.com", "phone": "+5095551234" }`. This data is passed to the `assignment_callback_url` when TaskRouter assigns a Task to the Worker. Defaults to {}.
  FriendlyName: string # A descriptive string that you create to describe the new Worker. It can be up to 64 characters long.
]: any -> record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers")
  let body = {ActivitySid: $ActivitySid, Attributes: $Attributes, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/CumulativeStatistics
#
# operationId: FetchWorkersCumulativeStatistics
export def "workspaces-workers-cumulative-statistics FetchWorkersCumulativeStatistics" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # Only calculate statistics from this date and time and earlier, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --TaskChannel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_durations: list<any>, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, start_time: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/CumulativeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/RealTimeStatistics
#
# operationId: FetchWorkersRealTimeStatistics
export def "workspaces-workers-real-time-statistics FetchWorkersRealTimeStatistics" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --TaskChannel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_statistics: list<any>, total_workers: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "TaskChannel" $TaskChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/RealTimeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/Statistics
#
# operationId: FetchWorkerStatistics
export def "workspaces-workers-statistics FetchWorkerStatistics" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --EndDate: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --TaskQueueSid: string # The SID of the TaskQueue for which to fetch Worker statistics.
  --TaskQueueName: string # The `friendly_name` of the TaskQueue for which to fetch Worker statistics.
  --FriendlyName: string # Only include Workers with `friendly_name` values that match this parameter.
  --TaskChannel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "TaskQueueSid" $TaskQueueSid "scalar") (serialize-qp "TaskQueueName" $TaskQueueName "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/Statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# operationId: DeleteWorker
export def "workspaces-workers DeleteWorker" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($Sid)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# operationId: FetchWorker
export def "workspaces-workers FetchWorker" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# operationId: UpdateWorker
export def "workspaces-workers UpdateWorker" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
  --ActivitySid: string # The SID of a valid Activity that will describe the Worker's initial state. See [Activities](https://www.twilio.com/docs/taskrouter/api/activity) for more information.
  --Attributes: string # The JSON string that describes the Worker. For example: `{ "email": "Bob@example.com", "phone": "+5095551234" }`. This data is passed to the `assignment_callback_url` when TaskRouter assigns a Task to the Worker. Defaults to {}.
  --FriendlyName: string # A descriptive string that you create to describe the Worker. It can be up to 64 characters long.
  --RejectPendingReservations: oneof<nothing, bool> # Whether to reject the Worker's pending reservations. This option is only valid if the Worker's new [Activity](https://www.twilio.com/docs/taskrouter/api/activity) resource has its `availability` property set to `False`.
]: any -> record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($Sid)")
  let body = {ActivitySid: $ActivitySid, Attributes: $Attributes, FriendlyName: $FriendlyName, RejectPendingReservations: $RejectPendingReservations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels
#
# operationId: ListWorkerChannel
export def "workspaces-workers-channels ListWorkerChannel" [
  WorkspaceSid: string
  WorkerSid: string
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
]: nothing -> record<channels: table<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($WorkerSid)/Channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}
#
# operationId: FetchWorkerChannel
export def "workspaces-workers-channels FetchWorkerChannel" [
  WorkspaceSid: string
  WorkerSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($WorkerSid)/Channels/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}
#
# operationId: UpdateWorkerChannel
export def "workspaces-workers-channels UpdateWorkerChannel" [
  WorkspaceSid: string
  WorkerSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Available: oneof<nothing, bool> # Whether the WorkerChannel is available. Set to `false` to prevent the Worker from receiving any new Tasks of this TaskChannel type.
  --Capacity: int # The total number of Tasks that the Worker should handle for the TaskChannel type. TaskRouter creates reservations for Tasks of this TaskChannel type up to the specified capacity. If the capacity is 0, no new reservations will be created.
]: any -> record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($WorkerSid)/Channels/($Sid)")
  let body = {Available: $Available, Capacity: $Capacity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations
#
# operationId: ListWorkerReservation
export def "workspaces-workers-reservations ListWorkerReservation" [
  WorkspaceSid: string
  WorkerSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ReservationStatus: string@ReservationStatus-completer # Returns the list of reservations for a worker with a specified ReservationStatus. Can be: `pending`, `accepted`, `rejected`, `timeout`, `canceled`, or `rescinded`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "ReservationStatus" $ReservationStatus "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($WorkerSid)/Reservations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}
#
# operationId: FetchWorkerReservation
export def "workspaces-workers-reservations FetchWorkerReservation" [
  WorkspaceSid: string
  WorkerSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($WorkerSid)/Reservations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}
#
# operationId: UpdateWorkerReservation
export def "workspaces-workers-reservations UpdateWorkerReservation" [
  WorkspaceSid: string
  WorkerSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-Match: string # The If-Match HTTP request header
  --Beep: string # Whether to play a notification beep when the participant joins or when to play a beep. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --BeepOnCustomerEntrance: oneof<nothing, bool> # Whether to play a notification beep when the customer joins.
  --CallAccept: oneof<nothing, bool> # Whether to accept a reservation when executing a Call instruction.
  --CallFrom: string # The Caller ID of the outbound call when executing a Call instruction.
  --CallRecord: string # Whether to record both legs of a call when executing a Call instruction.
  --CallStatusCallbackUrl: string # The URL to call for the completed call event when executing a Call instruction. (format: uri)
  --CallTimeout: int # The timeout for a call when executing a Call instruction.
  --CallTo: string # The contact URI of the worker when executing a Call instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --CallUrl: string # TwiML URI executed on answering the worker's leg as a result of the Call instruction. (format: uri)
  --ConferenceRecord: string # Whether to record the conference the participant is joining or when to record the conference. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --ConferenceRecordingStatusCallback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --ConferenceRecordingStatusCallbackMethod: string@ConferenceRecordingStatusCallbackMethod-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --ConferenceStatusCallback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --ConferenceStatusCallbackEvent: list # The conference status events that we will send to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `speaker`.
  --ConferenceStatusCallbackMethod: string@ConferenceStatusCallbackMethod-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --ConferenceTrim: string # Whether to trim leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --DequeueFrom: string # The caller ID of the call to the worker when executing a Dequeue instruction.
  --DequeuePostWorkActivitySid: string # The SID of the Activity resource to start after executing a Dequeue instruction.
  --DequeueRecord: string # Whether to record both legs of a call when executing a Dequeue instruction or which leg to record.
  --DequeueStatusCallbackEvent: list # The call progress events sent via webhooks as a result of a Dequeue instruction.
  --DequeueStatusCallbackUrl: string # The callback URL for completed call event when executing a Dequeue instruction. (format: uri)
  --DequeueTimeout: int # The timeout for call when executing a Dequeue instruction.
  --DequeueTo: string # The contact URI of the worker when executing a Dequeue instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --EarlyMedia: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. The default is `true`.
  --EndConferenceOnCustomerExit: oneof<nothing, bool> # Whether to end the conference when the customer leaves.
  --EndConferenceOnExit: oneof<nothing, bool> # Whether to end the conference when the agent leaves.
  --From: string # The caller ID of the call to the worker when executing a Conference instruction.
  --Instruction: string # The assignment instruction for the reservation.
  --MaxParticipants: int # The maximum number of participants allowed in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --Muted: oneof<nothing, bool> # Whether the agent is muted in the conference. Defaults to `false`.
  --PostWorkActivitySid: string # The new worker activity SID after executing a Conference instruction.
  --Record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. Can be `true` or `false` and the default is `false`.
  --RecordingChannels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --RecordingStatusCallback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --RecordingStatusCallbackMethod: string@RecordingStatusCallbackMethod-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --RedirectAccept: oneof<nothing, bool> # Whether the reservation should be accepted when executing a Redirect instruction.
  --RedirectCallSid: string # The Call SID of the call parked in the queue when executing a Redirect instruction.
  --RedirectUrl: string # TwiML URI to redirect the call to when executing the Redirect instruction. (format: uri)
  --Region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --ReservationStatus: string@ReservationStatus-completer
  --SipAuthPassword: string # The SIP password for authentication.
  --SipAuthUsername: string # The SIP username used for authentication.
  --StartConferenceOnEnter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. Can be: `true` or `false` and the default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --StatusCallback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --StatusCallbackEvent: list # The call progress events that we will send to `status_callback`. Can be: `initiated`, `ringing`, `answered`, or `completed`.
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --Timeout: int # The timeout for a call when executing a Conference instruction.
  --To: string # The Contact URI of the worker when executing a Conference instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --WaitMethod: string@WaitMethod-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --WaitUrl: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
  --WorkerActivitySid: string # The new worker activity SID if rejecting a reservation.
]: any -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($WorkerSid)/Reservations/($Sid)")
  let body = {Beep: $Beep, BeepOnCustomerEntrance: $BeepOnCustomerEntrance, CallAccept: $CallAccept, CallFrom: $CallFrom, CallRecord: $CallRecord, CallStatusCallbackUrl: $CallStatusCallbackUrl, CallTimeout: $CallTimeout, CallTo: $CallTo, CallUrl: $CallUrl, ConferenceRecord: $ConferenceRecord, ConferenceRecordingStatusCallback: $ConferenceRecordingStatusCallback, ConferenceRecordingStatusCallbackMethod: $ConferenceRecordingStatusCallbackMethod, ConferenceStatusCallback: $ConferenceStatusCallback, ConferenceStatusCallbackEvent: $ConferenceStatusCallbackEvent, ConferenceStatusCallbackMethod: $ConferenceStatusCallbackMethod, ConferenceTrim: $ConferenceTrim, DequeueFrom: $DequeueFrom, DequeuePostWorkActivitySid: $DequeuePostWorkActivitySid, DequeueRecord: $DequeueRecord, DequeueStatusCallbackEvent: $DequeueStatusCallbackEvent, DequeueStatusCallbackUrl: $DequeueStatusCallbackUrl, DequeueTimeout: $DequeueTimeout, DequeueTo: $DequeueTo, EarlyMedia: $EarlyMedia, EndConferenceOnCustomerExit: $EndConferenceOnCustomerExit, EndConferenceOnExit: $EndConferenceOnExit, From: $From, Instruction: $Instruction, MaxParticipants: $MaxParticipants, Muted: $Muted, PostWorkActivitySid: $PostWorkActivitySid, Record: $Record, RecordingChannels: $RecordingChannels, RecordingStatusCallback: $RecordingStatusCallback, RecordingStatusCallbackMethod: $RecordingStatusCallbackMethod, RedirectAccept: $RedirectAccept, RedirectCallSid: $RedirectCallSid, RedirectUrl: $RedirectUrl, Region: $Region, ReservationStatus: $ReservationStatus, SipAuthPassword: $SipAuthPassword, SipAuthUsername: $SipAuthUsername, StartConferenceOnEnter: $StartConferenceOnEnter, StatusCallback: $StatusCallback, StatusCallbackEvent: $StatusCallbackEvent, StatusCallbackMethod: $StatusCallbackMethod, Timeout: $Timeout, To: $To, WaitMethod: $WaitMethod, WaitUrl: $WaitUrl, WorkerActivitySid: $WorkerActivitySid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Statistics
#
# operationId: FetchWorkerInstanceStatistics
export def "workspaces-workers-statistics FetchWorkerInstanceStatistics" [
  WorkspaceSid: string
  WorkerSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --EndDate: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --TaskChannel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, cumulative: any, url: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workers/($WorkerSid)/Statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows
#
# operationId: ListWorkflow
export def "workspaces-workflows ListWorkflow" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # The `friendly_name` of the Workflow resources to read.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workflows: table<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Workflows
#
# operationId: CreateWorkflow
export def "workspaces-workflows CreateWorkflow" [
  WorkspaceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AssignmentCallbackUrl: string # The URL from your application that will process task assignment events. See [Handling Task Assignment Callback](https://www.twilio.com/docs/taskrouter/handle-assignment-callbacks) for more details. (format: uri)
  Configuration: string # A JSON string that contains the rules to apply to the Workflow. See [Configuring Workflows](https://www.twilio.com/docs/taskrouter/workflow-configuration) for more information.
  --FallbackAssignmentCallbackUrl: string # The URL that we should call when a call to the `assignment_callback_url` fails. (format: uri)
  FriendlyName: string # A descriptive string that you create to describe the Workflow resource. For example, `Inbound Call Workflow` or `2014 Outbound Campaign`.
  --TaskReservationTimeout: int # How long TaskRouter will wait for a confirmation response from your application after it assigns a Task to a Worker. Can be up to `86,400` (24 hours) and the default is `120`.
]: any -> record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows")
  let body = {AssignmentCallbackUrl: $AssignmentCallbackUrl, Configuration: $Configuration, FallbackAssignmentCallbackUrl: $FallbackAssignmentCallbackUrl, FriendlyName: $FriendlyName, TaskReservationTimeout: $TaskReservationTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# operationId: DeleteWorkflow
export def "workspaces-workflows DeleteWorkflow" [
  WorkspaceSid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# operationId: FetchWorkflow
export def "workspaces-workflows FetchWorkflow" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# operationId: UpdateWorkflow
export def "workspaces-workflows UpdateWorkflow" [
  WorkspaceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AssignmentCallbackUrl: string # The URL from your application that will process task assignment events. See [Handling Task Assignment Callback](https://www.twilio.com/docs/taskrouter/handle-assignment-callbacks) for more details. (format: uri)
  --Configuration: string # A JSON string that contains the rules to apply to the Workflow. See [Configuring Workflows](https://www.twilio.com/docs/taskrouter/workflow-configuration) for more information.
  --FallbackAssignmentCallbackUrl: string # The URL that we should call when a call to the `assignment_callback_url` fails. (format: uri)
  --FriendlyName: string # A descriptive string that you create to describe the Workflow resource. For example, `Inbound Call Workflow` or `2014 Outbound Campaign`.
  --ReEvaluateTasks: string # Whether or not to re-evaluate Tasks. The default is `false`, which means Tasks in the Workflow will not be processed through the assignment loop again.
  --TaskReservationTimeout: int # How long TaskRouter will wait for a confirmation response from your application after it assigns a Task to a Worker. Can be up to `86,400` (24 hours) and the default is `120`.
]: any -> record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows/($Sid)")
  let body = {AssignmentCallbackUrl: $AssignmentCallbackUrl, Configuration: $Configuration, FallbackAssignmentCallbackUrl: $FallbackAssignmentCallbackUrl, FriendlyName: $FriendlyName, ReEvaluateTasks: $ReEvaluateTasks, TaskReservationTimeout: $TaskReservationTimeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/CumulativeStatistics
#
# operationId: FetchWorkflowCumulativeStatistics
export def "workspaces-workflows-cumulative-statistics FetchWorkflowCumulativeStatistics" [
  WorkspaceSid: string
  WorkflowSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndDate: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --TaskChannel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --SplitByWaitTime: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA. TaskRouter will calculate statistics on up to 10,000 Tasks for any given threshold.
]: nothing -> record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "SplitByWaitTime" $SplitByWaitTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows/($WorkflowSid)/CumulativeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/RealTimeStatistics
#
# operationId: FetchWorkflowRealTimeStatistics
export def "workspaces-workflows-real-time-statistics FetchWorkflowRealTimeStatistics" [
  WorkspaceSid: string
  WorkflowSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --TaskChannel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, url: string, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "TaskChannel" $TaskChannel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows/($WorkflowSid)/RealTimeStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/Statistics
#
# operationId: FetchWorkflowStatistics
export def "workspaces-workflows-statistics FetchWorkflowStatistics" [
  WorkspaceSid: string
  WorkflowSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --StartDate: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --EndDate: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --TaskChannel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --SplitByWaitTime: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, url: string, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "Minutes" $Minutes "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "TaskChannel" $TaskChannel "scalar") (serialize-qp "SplitByWaitTime" $SplitByWaitTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Workspaces/($WorkspaceSid)/Workflows/($WorkflowSid)/Statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
