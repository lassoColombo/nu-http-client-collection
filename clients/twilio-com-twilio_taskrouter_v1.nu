# Auto-generated client for Twilio - Taskrouter v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_taskrouter_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_TASKROUTER_TOKEN

const BASE_URL = "https://taskrouter.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_TASKROUTER_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://taskrouter.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def prioritize-queue-order-completer [] { ["FIFO" "LIFO"] }
def task-order-completer [] { ["FIFO" "LIFO"] }
def assignment-status-completer [] { ["assigned" "canceled" "completed" "pending" "reserved" "wrapping"] }
def reservation-status-completer [] { ["accepted" "canceled" "completed" "pending" "rejected" "rescinded" "timeout" "wrapping"] }
def conference-recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def conference-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def supervisor-mode-completer [] { ["barge" "monitor" "whisper"] }
def wait-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "workspaces list" } } | get name | first)
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
export def "workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Workspace resources to read. For example `Customer Support` or `2014 Election Campaign`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workspaces: table<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FriendlyName": $friendly_name, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Workspaces
#
# operationId: CreateWorkspace
export def "workspaces create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-callback-url: string # The URL we should call when an event occurs. If provided, the Workspace will publish events to this URL, for example, to collect data for reporting. See [Workspace Events](https://www.twilio.com/docs/taskrouter/api/event) for more information. This parameter supports Twilio's [Webhooks (HTTP callbacks) Connection Overrides](https://www.twilio.com/docs/usage/webhooks/webhooks-connection-overrides). (format: uri)
  --events-filter: string # The list of Workspace events for which to call event_callback_url. For example, if `EventsFilter=task.created, task.canceled, worker.activity.update`, then TaskRouter will call event_callback_url only when a task is created, canceled, or a Worker activity is updated.
  friendly_name: string # A descriptive string that you create to describe the Workspace resource. It can be up to 64 characters long. For example: `Customer Support` or `2014 Election Campaign`.
  --multi-task-enabled: oneof<nothing, bool> # Whether to enable multi-tasking. Can be: `true` to enable multi-tasking, or `false` to disable it. However, all workspaces should be created as multi-tasking. The default is `true`. Multi-tasking allows Workers to handle multiple Tasks simultaneously. When enabled (`true`), each Worker can receive parallel reservations up to the per-channel maximums defined in the Workers section. In single-tasking mode (legacy mode), each Worker will only receive a new reservation when the previous task is completed. Learn more at [Multitasking](https://www.twilio.com/docs/taskrouter/multitasking).
  --prioritize-queue-order: string@prioritize-queue-order-completer
  --template: string # An available template name. Can be: `NONE` or `FIFO` and the default is `NONE`. Pre-configures the Workspace with the Workflow and Activities specified in the template. `NONE` will create a Workspace with only a set of default activities. `FIFO` will configure TaskRouter with a set of default activities and a single TaskQueue for first-in, first-out distribution, which can be useful when you are getting started with TaskRouter.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  let full_url = (build-url $base "/v1/Workspaces")
  let req_body = {"EventCallbackUrl": $event_callback_url, "EventsFilter": $events_filter, "FriendlyName": $friendly_name, "MultiTaskEnabled": $multi_task_enabled, "PrioritizeQueueOrder": $prioritize_queue_order, "Template": $template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Workspaces/{Sid}
#
# operationId: DeleteWorkspace
export def "workspaces delete" [
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{Sid}
#
# operationId: FetchWorkspace
export def "workspaces get" [
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{Sid}
#
# operationId: UpdateWorkspace
export def "workspaces update" [
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
  --default-activity-sid: string # The SID of the Activity that will be used when new Workers are created in the Workspace.
  --event-callback-url: string # The URL we should call when an event occurs. See [Workspace Events](https://www.twilio.com/docs/taskrouter/api/event) for more information. This parameter supports Twilio's [Webhooks (HTTP callbacks) Connection Overrides](https://www.twilio.com/docs/usage/webhooks/webhooks-connection-overrides). (format: uri)
  --events-filter: string # The list of Workspace events for which to call event_callback_url. For example if `EventsFilter=task.created,task.canceled,worker.activity.update`, then TaskRouter will call event_callback_url only when a task is created, canceled, or a Worker activity is updated.
  --friendly-name: string # A descriptive string that you create to describe the Workspace resource. For example: `Sales Call Center` or `Customer Support Team`.
  --multi-task-enabled: oneof<nothing, bool> # Whether to enable multi-tasking. Can be: `true` to enable multi-tasking, or `false` to disable it. However, all workspaces should be maintained as multi-tasking. There is no default when omitting this parameter. A multi-tasking Workspace can't be updated to single-tasking unless it is not a Flex Project and another (legacy) single-tasking Workspace exists. Multi-tasking allows Workers to handle multiple Tasks simultaneously. In multi-tasking mode, each Worker can receive parallel reservations up to the per-channel maximums defined in the Workers section. In single-tasking mode (legacy mode), each Worker will only receive a new reservation when the previous task is completed. Learn more at [Multitasking](https://www.twilio.com/docs/taskrouter/multitasking).
  --prioritize-queue-order: string@prioritize-queue-order-completer
  --timeout-activity-sid: string # The SID of the Activity that will be assigned to a Worker when a Task reservation times out without a response.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_activity_name: string, default_activity_sid: string, event_callback_url: string, events_filter: string, friendly_name: string, links: record, multi_task_enabled: bool, prioritize_queue_order: string, sid: string, timeout_activity_name: string, timeout_activity_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{sid}"))
  let req_body = {"DefaultActivitySid": $default_activity_sid, "EventCallbackUrl": $event_callback_url, "EventsFilter": $events_filter, "FriendlyName": $friendly_name, "MultiTaskEnabled": $multi_task_enabled, "PrioritizeQueueOrder": $prioritize_queue_order, "TimeoutActivitySid": $timeout_activity_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Activities
#
# operationId: ListActivity
export def "workspaces-activities list-activity" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Activity resources to read.
  --available: string # Whether return only Activity resources that are available or unavailable. A value of `true` returns only available activities. Values of '1' or `yes` also indicate `true`. All other values represent `false` and return activities that are unavailable.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<activities: table<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "Available" $available "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FriendlyName": $friendly_name, "Available": $available, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Activities
#
# operationId: CreateActivity
export def "workspaces-activities create-activity" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --available: oneof<nothing, bool> # Whether the Worker should be eligible to receive a Task when it occupies the Activity. A value of `true`, `1`, or `yes` specifies the Activity is available. All other values specify that it is not. The value cannot be changed after the Activity is created.
  friendly_name: string # A descriptive string that you create to describe the Activity resource. It can be up to 64 characters long. These names are used to calculate and expose statistics about Workers, and provide visibility into the state of each Worker. Examples of friendly names include: `on-call`, `break`, and `email`.
]: any -> record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Activities"))
  let req_body = {"Available": $available, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# operationId: DeleteActivity
export def "workspaces-activities delete-activity" [
  workspace_sid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Activities/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# operationId: FetchActivity
export def "workspaces-activities get-activity" [
  workspace_sid: string
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
]: nothing -> record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Activities/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Activities/{Sid}
#
# operationId: UpdateActivity
export def "workspaces-activities update-activity" [
  workspace_sid: string
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
  --friendly-name: string # A descriptive string that you create to describe the Activity resource. It can be up to 64 characters long. These names are used to calculate and expose statistics about Workers, and provide visibility into the state of each Worker. Examples of friendly names include: `on-call`, `break`, and `email`.
]: any -> record<account_sid: string, available: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Activities/{sid}"))
  let req_body = {"FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/CumulativeStatistics
#
# operationId: FetchWorkspaceCumulativeStatistics
export def "workspaces-cumulative-statistics get" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA. TaskRouter will calculate statistics on up to 10,000 Tasks for any given threshold.
]: nothing -> record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_created: int, tasks_deleted: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "SplitByWaitTime" $split_by_wait_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/CumulativeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndDate": $end_date, "Minutes": $minutes, "StartDate": $start_date, "TaskChannel": $task_channel, "SplitByWaitTime": $split_by_wait_time} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Events
#
# operationId: ListEvent
export def "workspaces-events list" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only include Events that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --event-type: string # The type of Events to read. Returns only Events of the type specified.
  --minutes: int # The period of events to read in minutes. Returns only Events that occurred since this many minutes in the past. The default is `15` minutes. Task Attributes for Events occuring more 43,200 minutes ago will be redacted.
  --reservation-sid: string # The SID of the Reservation with the Events to read. Returns only Events that pertain to the specified Reservation.
  --start-date: string # Only include Events from on or after this date and time, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. Task Attributes for Events older than 30 days will be redacted. (format: date-time)
  --task-queue-sid: string # The SID of the TaskQueue with the Events to read. Returns only the Events that pertain to the specified TaskQueue.
  --task-sid: string # The SID of the Task with the Events to read. Returns only the Events that pertain to the specified Task.
  --worker-sid: string # The SID of the Worker with the Events to read. Returns only the Events that pertain to the specified Worker.
  --workflow-sid: string # The SID of the Workflow with the Events to read. Returns only the Events that pertain to the specified Workflow.
  --task-channel: string # The TaskChannel with the Events to read. Returns only the Events that pertain to the specified TaskChannel.
  --sid: string # The SID of the Event resource to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<events: table<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "EndDate" $end_date "scalar") (serialize-qp "EventType" $event_type "scalar") (serialize-qp "Minutes" $minutes "scalar") (serialize-qp "ReservationSid" $reservation_sid "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "TaskQueueSid" $task_queue_sid "scalar") (serialize-qp "TaskSid" $task_sid "scalar") (serialize-qp "WorkerSid" $worker_sid "scalar") (serialize-qp "WorkflowSid" $workflow_sid "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "Sid" $sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndDate": $end_date, "EventType": $event_type, "Minutes": $minutes, "ReservationSid": $reservation_sid, "StartDate": $start_date, "TaskQueueSid": $task_queue_sid, "TaskSid": $task_sid, "WorkerSid": $worker_sid, "WorkflowSid": $workflow_sid, "TaskChannel": $task_channel, "Sid": $sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Events/{Sid}
#
# operationId: FetchEvent
export def "workspaces-events get" [
  workspace_sid: string
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
]: nothing -> record<account_sid: string, actor_sid: string, actor_type: string, actor_url: string, description: string, event_data: any, event_date: string, event_date_ms: int, event_type: string, resource_sid: string, resource_type: string, resource_url: string, sid: string, source: string, source_ip_address: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Events/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/RealTimeStatistics
#
# operationId: FetchWorkspaceRealTimeStatistics
export def "workspaces-real-time-statistics get" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_statistics: list<any>, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, total_workers: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "TaskChannel" $task_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/RealTimeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"TaskChannel": $task_channel} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Statistics
#
# operationId: FetchWorkspaceStatistics
export def "workspaces-statistics get" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "SplitByWaitTime" $split_by_wait_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Minutes": $minutes, "StartDate": $start_date, "EndDate": $end_date, "TaskChannel": $task_channel, "SplitByWaitTime": $split_by_wait_time} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskChannels
#
# operationId: ListTaskChannel
export def "workspaces-task-channels list" [
  workspace_sid: string
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
]: nothing -> record<channels: table<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskChannels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskChannels
#
# operationId: CreateTaskChannel
export def "workspaces-task-channels create" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-optimized-routing: oneof<nothing, bool> # Whether the Task Channel should prioritize Workers that have been idle. If `true`, Workers that have been idle the longest are prioritized.
  friendly_name: string # A descriptive string that you create to describe the Task Channel. It can be up to 64 characters long.
  unique_name: string # An application-defined string that uniquely identifies the Task Channel, such as `voice` or `sms`.
]: any -> record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskChannels"))
  let req_body = {"ChannelOptimizedRouting": $channel_optimized_routing, "FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# operationId: DeleteTaskChannel
export def "workspaces-task-channels delete" [
  workspace_sid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskChannels/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# operationId: FetchTaskChannel
export def "workspaces-task-channels get" [
  workspace_sid: string
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
]: nothing -> record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskChannels/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskChannels/{Sid}
#
# operationId: UpdateTaskChannel
export def "workspaces-task-channels update" [
  workspace_sid: string
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
  --channel-optimized-routing: oneof<nothing, bool> # Whether the TaskChannel should prioritize Workers that have been idle. If `true`, Workers that have been idle the longest are prioritized.
  --friendly-name: string # A descriptive string that you create to describe the Task Channel. It can be up to 64 characters long.
]: any -> record<account_sid: string, channel_optimized_routing: bool, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskChannels/{sid}"))
  let req_body = {"ChannelOptimizedRouting": $channel_optimized_routing, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues
#
# operationId: ListTaskQueue
export def "workspaces-task-queues list" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the TaskQueue resources to read.
  --evaluate-worker-attributes: string # The attributes of the Workers to read. Returns the TaskQueues with Workers that match the attributes specified in this parameter.
  --worker-sid: string # The SID of the Worker with the TaskQueue resources to read.
  --ordering: string # Sorting parameter for TaskQueues
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues: table<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "EvaluateWorkerAttributes" $evaluate_worker_attributes "scalar") (serialize-qp "WorkerSid" $worker_sid "scalar") (serialize-qp "Ordering" $ordering "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FriendlyName": $friendly_name, "EvaluateWorkerAttributes": $evaluate_worker_attributes, "WorkerSid": $worker_sid, "Ordering": $ordering, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskQueues
#
# operationId: CreateTaskQueue
export def "workspaces-task-queues create" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment-activity-sid: string # The SID of the Activity to assign Workers when a task is assigned to them.
  friendly_name: string # A descriptive string that you create to describe the TaskQueue. For example `Support-Tier 1`, `Sales`, or `Escalation`.
  --max-reserved-workers: int # The maximum number of Workers to reserve for the assignment of a Task in the queue. Can be an integer between 1 and 50, inclusive and defaults to 1.
  --reservation-activity-sid: string # The SID of the Activity to assign Workers when a task is reserved for them.
  --target-workers: string # A string that describes the Worker selection criteria for any Tasks that enter the TaskQueue. For example, `'"language" == "spanish"'`. The default value is `1==1`. If this value is empty, Tasks will wait in the TaskQueue until they are deleted or moved to another TaskQueue. For more information about Worker selection, see [Describing Worker selection criteria](https://www.twilio.com/docs/taskrouter/api/taskqueues#target-workers).
  --task-order: string@task-order-completer
]: any -> record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues"))
  let req_body = {"AssignmentActivitySid": $assignment_activity_sid, "FriendlyName": $friendly_name, "MaxReservedWorkers": $max_reserved_workers, "ReservationActivitySid": $reservation_activity_sid, "TargetWorkers": $target_workers, "TaskOrder": $task_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/Statistics
#
# operationId: ListTaskQueuesStatistics
export def "workspaces-task-queues-statistics list" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --friendly-name: string # The `friendly_name` of the TaskQueue statistics to read.
  --minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, task_queues_statistics: table<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "EndDate" $end_date "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "SplitByWaitTime" $split_by_wait_time "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues/Statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndDate": $end_date, "FriendlyName": $friendly_name, "Minutes": $minutes, "StartDate": $start_date, "TaskChannel": $task_channel, "SplitByWaitTime": $split_by_wait_time, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# DELETE /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# operationId: DeleteTaskQueue
export def "workspaces-task-queues delete" [
  workspace_sid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# operationId: FetchTaskQueue
export def "workspaces-task-queues get" [
  workspace_sid: string
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
]: nothing -> record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/TaskQueues/{Sid}
#
# operationId: UpdateTaskQueue
export def "workspaces-task-queues update" [
  workspace_sid: string
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
  --assignment-activity-sid: string # The SID of the Activity to assign Workers when a task is assigned for them.
  --friendly-name: string # A descriptive string that you create to describe the TaskQueue. For example `Support-Tier 1`, `Sales`, or `Escalation`.
  --max-reserved-workers: int # The maximum number of Workers to create reservations for the assignment of a task while in the queue. Maximum of 50.
  --reservation-activity-sid: string # The SID of the Activity to assign Workers when a task is reserved for them.
  --target-workers: string # A string describing the Worker selection criteria for any Tasks that enter the TaskQueue. For example '"language" == "spanish"' If no TargetWorkers parameter is provided, Tasks will wait in the queue until they are either deleted or moved to another queue. Additional examples on how to describing Worker selection criteria below.
  --task-order: string@task-order-completer
]: any -> record<account_sid: string, assignment_activity_name: string, assignment_activity_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, max_reserved_workers: int, reservation_activity_name: string, reservation_activity_sid: string, sid: string, target_workers: string, task_order: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues/{sid}"))
  let req_body = {"AssignmentActivitySid": $assignment_activity_sid, "FriendlyName": $friendly_name, "MaxReservedWorkers": $max_reserved_workers, "ReservationActivitySid": $reservation_activity_sid, "TargetWorkers": $target_workers, "TaskOrder": $task_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/CumulativeStatistics
#
# operationId: FetchTaskQueueCumulativeStatistics
export def "workspaces-task-queues-cumulative-statistics get" [
  workspace_sid: string
  task_queue_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. TaskRouter will calculate statistics on up to 10,000 Tasks/Reservations for any given threshold.
]: nothing -> record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, task_queue_sid: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, url: string, wait_duration_in_queue_until_accepted: any, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($task_queue_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskQueueSid' must be non-empty" } }
  let qp = [(serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "SplitByWaitTime" $split_by_wait_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), task_queue_sid: (encode-path-segment $task_queue_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues/{task_queue_sid}/CumulativeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndDate": $end_date, "Minutes": $minutes, "StartDate": $start_date, "TaskChannel": $task_channel, "SplitByWaitTime": $split_by_wait_time} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/RealTimeStatistics
#
# operationId: FetchTaskQueueRealTimeStatistics
export def "workspaces-task-queues-real-time-statistics get" [
  workspace_sid: string
  task_queue_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # The TaskChannel for which to fetch statistics. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_statistics: list<any>, longest_relative_task_age_in_queue: int, longest_relative_task_sid_in_queue: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, task_queue_sid: string, tasks_by_priority: any, tasks_by_status: any, total_available_workers: int, total_eligible_workers: int, total_tasks: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($task_queue_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskQueueSid' must be non-empty" } }
  let qp = [(serialize-qp "TaskChannel" $task_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), task_queue_sid: (encode-path-segment $task_queue_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues/{task_queue_sid}/RealTimeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"TaskChannel": $task_channel} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/TaskQueues/{TaskQueueSid}/Statistics
#
# operationId: FetchTaskQueueStatistics
export def "workspaces-task-queues-statistics get" [
  workspace_sid: string
  task_queue_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default is 15 minutes.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate real-time and cumulative statistics for the specified TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, task_queue_sid: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($task_queue_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskQueueSid' must be non-empty" } }
  let qp = [(serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "SplitByWaitTime" $split_by_wait_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), task_queue_sid: (encode-path-segment $task_queue_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/TaskQueues/{task_queue_sid}/Statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndDate": $end_date, "Minutes": $minutes, "StartDate": $start_date, "TaskChannel": $task_channel, "SplitByWaitTime": $split_by_wait_time} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks
#
# operationId: ListTask
export def "workspaces-tasks list" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --priority: int # The priority value of the Tasks to read. Returns the list of all Tasks in the Workspace with the specified priority.
  --assignment-status: list<string> # The `assignment_status` of the Tasks you want to read. Can be: `pending`, `reserved`, `assigned`, `canceled`, `wrapping`, or `completed`. Returns all Tasks in the Workspace with the specified `assignment_status`.
  --workflow-sid: string # The SID of the Workflow with the Tasks to read. Returns the Tasks controlled by the Workflow identified by this SID.
  --workflow-name: string # The friendly name of the Workflow with the Tasks to read. Returns the Tasks controlled by the Workflow identified by this friendly name.
  --task-queue-sid: string # The SID of the TaskQueue with the Tasks to read. Returns the Tasks waiting in the TaskQueue identified by this SID.
  --task-queue-name: string # The `friendly_name` of the TaskQueue with the Tasks to read. Returns the Tasks waiting in the TaskQueue identified by this friendly name.
  --evaluate-task-attributes: string # The attributes of the Tasks to read. Returns the Tasks that match the attributes specified in this parameter.
  --ordering: string # How to order the returned Task resources. y default, Tasks are sorted by ascending DateCreated. This value is specified as: `Attribute:Order`, where `Attribute` can be either `Priority` or `DateCreated` and `Order` can be either `asc` or `desc`. For example, `Priority:desc` returns Tasks ordered in descending order of their Priority. Multiple sort orders can be specified in a comma-separated list such as `Priority:desc,DateCreated:asc`, which returns the Tasks in descending Priority order and ascending DateCreated Order.
  --has-addons: oneof<nothing, bool> # Whether to read Tasks with addons. If `true`, returns only Tasks with addons. If `false`, returns only Tasks without addons.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "Priority" $priority "scalar") (serialize-qp "AssignmentStatus" $assignment_status "multi") (serialize-qp "WorkflowSid" $workflow_sid "scalar") (serialize-qp "WorkflowName" $workflow_name "scalar") (serialize-qp "TaskQueueSid" $task_queue_sid "scalar") (serialize-qp "TaskQueueName" $task_queue_name "scalar") (serialize-qp "EvaluateTaskAttributes" $evaluate_task_attributes "scalar") (serialize-qp "Ordering" $ordering "scalar") (serialize-qp "HasAddons" $has_addons "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Priority": $priority, "AssignmentStatus": $assignment_status, "WorkflowSid": $workflow_sid, "WorkflowName": $workflow_name, "TaskQueueSid": $task_queue_sid, "TaskQueueName": $task_queue_name, "EvaluateTaskAttributes": $evaluate_task_attributes, "Ordering": $ordering, "HasAddons": $has_addons, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks
#
# operationId: CreateTask
export def "workspaces-tasks create" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: string # A URL-encoded JSON string with the attributes of the new task. This value is passed to the Workflow's `assignment_callback_url` when the Task is assigned to a Worker. For example: `{ "task_type": "call", "twilio_call_sid": "CAxxx", "customer_ticket_number": "12345" }`.
  --priority: int # The priority to assign the new task and override the default. When supplied, the new Task will have this priority unless it matches a Workflow Target with a Priority set. When not supplied, the new Task will have the priority of the matching Workflow Target. Value can be 0 to 2^31^ (2,147,483,647).
  --task-channel: string # When MultiTasking is enabled, specify the TaskChannel by passing either its `unique_name` or `sid`. Default value is `default`.
  --timeout: int # The amount of time in seconds the new task can live before being assigned. Can be up to a maximum of 2 weeks (1,209,600 seconds). The default value is 24 hours (86,400 seconds). On timeout, the `task.canceled` event will fire with description `Task TTL Exceeded`.
  --workflow-sid: string # The SID of the Workflow that you would like to handle routing for the new Task. If there is only one Workflow defined for the Workspace that you are posting the new task to, this parameter is optional.
]: any -> record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks"))
  let req_body = {"Attributes": $attributes, "Priority": $priority, "TaskChannel": $task_channel, "Timeout": $timeout, "WorkflowSid": $workflow_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# operationId: DeleteTask
export def "workspaces-tasks delete" [
  workspace_sid: string
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
  --if-match: string # If provided, deletes this Task if (and only if) the [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) header of the Task matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# operationId: FetchTask
export def "workspaces-tasks get" [
  workspace_sid: string
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
]: nothing -> record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks/{Sid}
#
# operationId: UpdateTask
export def "workspaces-tasks update" [
  workspace_sid: string
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
  --if-match: string # If provided, applies this mutation if (and only if) the [ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) header of the Task matches the provided value. This matches the semantics of (and is implemented with) the HTTP [If-Match header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match).
  --assignment-status: string@assignment-status-completer
  --attributes: string # The JSON string that describes the custom attributes of the task.
  --priority: int # The Task's new priority value. When supplied, the Task takes on the specified priority unless it matches a Workflow Target with a Priority set. Value can be 0 to 2^31^ (2,147,483,647).
  --reason: string # The reason that the Task was canceled or completed. This parameter is required only if the Task is canceled or completed. Setting this value queues the task for deletion and logs the reason.
  --task-channel: string # When MultiTasking is enabled, specify the TaskChannel with the task to update. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: any -> record<account_sid: string, addons: string, age: int, assignment_status: string, attributes: string, date_created: string, date_updated: string, links: record, priority: int, reason: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, task_queue_entered_date: string, task_queue_friendly_name: string, task_queue_sid: string, timeout: int, url: string, workflow_friendly_name: string, workflow_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks/{sid}"))
  let req_body = {"AssignmentStatus": $assignment_status, "Attributes": $attributes, "Priority": $priority, "Reason": $reason, "TaskChannel": $task_channel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations
#
# operationId: ListTaskReservation
export def "workspaces-tasks-reservations list" [
  workspace_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation-status: string@reservation-status-completer # Returns the list of reservations for a task with a specified ReservationStatus. Can be: `pending`, `accepted`, `rejected`, or `timeout`.
  --worker-sid: string # The SID of the reserved Worker resource to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let qp = [(serialize-qp "ReservationStatus" $reservation_status "scalar") (serialize-qp "WorkerSid" $worker_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks/{task_sid}/Reservations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservationStatus": $reservation_status, "WorkerSid": $worker_sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}
#
# operationId: FetchTaskReservation
export def "workspaces-tasks-reservations get" [
  workspace_sid: string
  task_sid: string
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), task_sid: (encode-path-segment $task_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks/{task_sid}/Reservations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Tasks/{TaskSid}/Reservations/{Sid}
#
# operationId: UpdateTaskReservation
export def "workspaces-tasks-reservations update" [
  workspace_sid: string
  task_sid: string
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
  --if-match: string # The If-Match HTTP request header
  --beep: string # Whether to play a notification beep when the participant joins or when to play a beep. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --beep-on-customer-entrance: oneof<nothing, bool> # Whether to play a notification beep when the customer joins.
  --call-accept: oneof<nothing, bool> # Whether to accept a reservation when executing a Call instruction.
  --call-from: string # The Caller ID of the outbound call when executing a Call instruction.
  --call-record: string # Whether to record both legs of a call when executing a Call instruction or which leg to record.
  --call-status-callback-url: string # The URL to call for the completed call event when executing a Call instruction. (format: uri)
  --call-timeout: int # Timeout for call when executing a Call instruction.
  --call-to: string # The Contact URI of the worker when executing a Call instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --call-url: string # TwiML URI executed on answering the worker's leg as a result of the Call instruction. (format: uri)
  --conference-record: string # Whether to record the conference the participant is joining or when to record the conference. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --conference-recording-status-callback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --conference-recording-status-callback-method: string@conference-recording-status-callback-method-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-status-callback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --conference-status-callback-event: list<string> # The conference status events that we will send to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `speaker`.
  --conference-status-callback-method: string@conference-status-callback-method-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-trim: string # How to trim the leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --dequeue-from: string # The Caller ID of the call to the worker when executing a Dequeue instruction.
  --dequeue-post-work-activity-sid: string # The SID of the Activity resource to start after executing a Dequeue instruction.
  --dequeue-record: string # Whether to record both legs of a call when executing a Dequeue instruction or which leg to record.
  --dequeue-status-callback-event: list<string> # The Call progress events sent via webhooks as a result of a Dequeue instruction.
  --dequeue-status-callback-url: string # The Callback URL for completed call event when executing a Dequeue instruction. (format: uri)
  --dequeue-timeout: int # Timeout for call when executing a Dequeue instruction.
  --dequeue-to: string # The Contact URI of the worker when executing a Dequeue instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --early-media: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. The default is `true`.
  --end-conference-on-customer-exit: oneof<nothing, bool> # Whether to end the conference when the customer leaves.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the agent leaves.
  --body-from: string # The Caller ID of the call to the worker when executing a Conference instruction.
  --instruction: string # The assignment instruction for reservation.
  --max-participants: int # The maximum number of participants in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --muted: oneof<nothing, bool> # Whether the agent is muted in the conference. The default is `false`.
  --post-work-activity-sid: string # The new worker activity SID after executing a Conference instruction.
  --record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. The default is `false`.
  --recording-channels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --recording-status-callback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --redirect-accept: oneof<nothing, bool> # Whether the reservation should be accepted when executing a Redirect instruction.
  --redirect-call-sid: string # The Call SID of the call parked in the queue when executing a Redirect instruction.
  --redirect-url: string # TwiML URI to redirect the call to when executing the Redirect instruction. (format: uri)
  --region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --reservation-status: string@reservation-status-completer
  --sip-auth-password: string # The SIP password for authentication.
  --sip-auth-username: string # The SIP username used for authentication.
  --start-conference-on-enter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. The default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-event: list<string> # The call progress events that we will send to `status_callback`. Can be: `initiated`, `ringing`, `answered`, or `completed`.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --supervisor: string # The Supervisor SID/URI when executing the Supervise instruction.
  --supervisor-mode: string@supervisor-mode-completer
  --timeout: int # Timeout for call when executing a Conference instruction.
  --body-to: string # The Contact URI of the worker when executing a Conference instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
  --worker-activity-sid: string # The new worker activity SID if rejecting a reservation.
]: any -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), task_sid: (encode-path-segment $task_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Tasks/{task_sid}/Reservations/{sid}"))
  let req_body = {"Beep": $beep, "BeepOnCustomerEntrance": $beep_on_customer_entrance, "CallAccept": $call_accept, "CallFrom": $call_from, "CallRecord": $call_record, "CallStatusCallbackUrl": $call_status_callback_url, "CallTimeout": $call_timeout, "CallTo": $call_to, "CallUrl": $call_url, "ConferenceRecord": $conference_record, "ConferenceRecordingStatusCallback": $conference_recording_status_callback, "ConferenceRecordingStatusCallbackMethod": $conference_recording_status_callback_method, "ConferenceStatusCallback": $conference_status_callback, "ConferenceStatusCallbackEvent": $conference_status_callback_event, "ConferenceStatusCallbackMethod": $conference_status_callback_method, "ConferenceTrim": $conference_trim, "DequeueFrom": $dequeue_from, "DequeuePostWorkActivitySid": $dequeue_post_work_activity_sid, "DequeueRecord": $dequeue_record, "DequeueStatusCallbackEvent": $dequeue_status_callback_event, "DequeueStatusCallbackUrl": $dequeue_status_callback_url, "DequeueTimeout": $dequeue_timeout, "DequeueTo": $dequeue_to, "EarlyMedia": $early_media, "EndConferenceOnCustomerExit": $end_conference_on_customer_exit, "EndConferenceOnExit": $end_conference_on_exit, "From": $body_from, "Instruction": $instruction, "MaxParticipants": $max_participants, "Muted": $muted, "PostWorkActivitySid": $post_work_activity_sid, "Record": $record, "RecordingChannels": $recording_channels, "RecordingStatusCallback": $recording_status_callback, "RecordingStatusCallbackMethod": $recording_status_callback_method, "RedirectAccept": $redirect_accept, "RedirectCallSid": $redirect_call_sid, "RedirectUrl": $redirect_url, "Region": $region, "ReservationStatus": $reservation_status, "SipAuthPassword": $sip_auth_password, "SipAuthUsername": $sip_auth_username, "StartConferenceOnEnter": $start_conference_on_enter, "StatusCallback": $status_callback, "StatusCallbackEvent": $status_callback_event, "StatusCallbackMethod": $status_callback_method, "Supervisor": $supervisor, "SupervisorMode": $supervisor_mode, "Timeout": $timeout, "To": $body_to, "WaitMethod": $wait_method, "WaitUrl": $wait_url, "WorkerActivitySid": $worker_activity_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers
#
# operationId: ListWorker
export def "workspaces-workers list" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-name: string # The `activity_name` of the Worker resources to read.
  --activity-sid: string # The `activity_sid` of the Worker resources to read.
  --available: string # Whether to return only Worker resources that are available or unavailable. Can be `true`, `1`, or `yes` to return Worker resources that are available, and `false`, or any value returns the Worker resources that are not available.
  --friendly-name: string # The `friendly_name` of the Worker resources to read.
  --target-workers-expression: string # Filter by Workers that would match an expression on a TaskQueue. This is helpful for debugging which Workers would match a potential queue.
  --task-queue-name: string # The `friendly_name` of the TaskQueue that the Workers to read are eligible for.
  --task-queue-sid: string # The SID of the TaskQueue that the Workers to read are eligible for.
  --ordering: string # Sorting parameter for Workers
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workers: table<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "ActivityName" $activity_name "scalar") (serialize-qp "ActivitySid" $activity_sid "scalar") (serialize-qp "Available" $available "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "TargetWorkersExpression" $target_workers_expression "scalar") (serialize-qp "TaskQueueName" $task_queue_name "scalar") (serialize-qp "TaskQueueSid" $task_queue_sid "scalar") (serialize-qp "Ordering" $ordering "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ActivityName": $activity_name, "ActivitySid": $activity_sid, "Available": $available, "FriendlyName": $friendly_name, "TargetWorkersExpression": $target_workers_expression, "TaskQueueName": $task_queue_name, "TaskQueueSid": $task_queue_sid, "Ordering": $ordering, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers
#
# operationId: CreateWorker
export def "workspaces-workers create" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-sid: string # The SID of a valid Activity that will describe the new Worker's initial state. See [Activities](https://www.twilio.com/docs/taskrouter/api/activity) for more information. If not provided, the new Worker's initial state is the `default_activity_sid` configured on the Workspace.
  --attributes: string # A valid JSON string that describes the new Worker. For example: `{ "email": "Bob@example.com", "phone": "+5095551234" }`. This data is passed to the `assignment_callback_url` when TaskRouter assigns a Task to the Worker. Defaults to {}.
  friendly_name: string # A descriptive string that you create to describe the new Worker. It can be up to 64 characters long.
]: any -> record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers"))
  let req_body = {"ActivitySid": $activity_sid, "Attributes": $attributes, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/CumulativeStatistics
#
# operationId: FetchWorkersCumulativeStatistics
export def "workspaces-workers-cumulative-statistics get" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_durations: list<any>, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, start_time: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/CumulativeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndDate": $end_date, "Minutes": $minutes, "StartDate": $start_date, "TaskChannel": $task_channel} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/RealTimeStatistics
#
# operationId: FetchWorkersRealTimeStatistics
export def "workspaces-workers-real-time-statistics get" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, activity_statistics: list<any>, total_workers: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "TaskChannel" $task_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/RealTimeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"TaskChannel": $task_channel} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/Statistics
#
# operationId: FetchWorkerStatistics
export def "workspaces-workers-statistics get" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-queue-sid: string # The SID of the TaskQueue for which to fetch Worker statistics.
  --task-queue-name: string # The `friendly_name` of the TaskQueue for which to fetch Worker statistics.
  --friendly-name: string # Only include Workers with `friendly_name` values that match this parameter.
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "TaskQueueSid" $task_queue_sid "scalar") (serialize-qp "TaskQueueName" $task_queue_name "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "TaskChannel" $task_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/Statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Minutes": $minutes, "StartDate": $start_date, "EndDate": $end_date, "TaskQueueSid": $task_queue_sid, "TaskQueueName": $task_queue_name, "FriendlyName": $friendly_name, "TaskChannel": $task_channel} | compact), body: null}
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# operationId: DeleteWorker
export def "workspaces-workers delete" [
  workspace_sid: string
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
  --if-match: string # The If-Match HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# operationId: FetchWorker
export def "workspaces-workers get" [
  workspace_sid: string
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
]: nothing -> record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{Sid}
#
# operationId: UpdateWorker
export def "workspaces-workers update" [
  workspace_sid: string
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
  --if-match: string # The If-Match HTTP request header
  --activity-sid: string # The SID of a valid Activity that will describe the Worker's initial state. See [Activities](https://www.twilio.com/docs/taskrouter/api/activity) for more information.
  --attributes: string # The JSON string that describes the Worker. For example: `{ "email": "Bob@example.com", "phone": "+5095551234" }`. This data is passed to the `assignment_callback_url` when TaskRouter assigns a Task to the Worker. Defaults to {}.
  --friendly-name: string # A descriptive string that you create to describe the Worker. It can be up to 64 characters long.
  --reject-pending-reservations: oneof<nothing, bool> # Whether to reject the Worker's pending reservations. This option is only valid if the Worker's new [Activity](https://www.twilio.com/docs/taskrouter/api/activity) resource has its `availability` property set to `False`.
]: any -> record<account_sid: string, activity_name: string, activity_sid: string, attributes: string, available: bool, date_created: string, date_status_changed: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{sid}"))
  let req_body = {"ActivitySid": $activity_sid, "Attributes": $attributes, "FriendlyName": $friendly_name, "RejectPendingReservations": $reject_pending_reservations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels
#
# operationId: ListWorkerChannel
export def "workspaces-workers-channels list" [
  workspace_sid: string
  worker_sid: string
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
]: nothing -> record<channels: table<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($worker_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkerSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), worker_sid: (encode-path-segment $worker_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{worker_sid}/Channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}
#
# operationId: FetchWorkerChannel
export def "workspaces-workers-channels get" [
  workspace_sid: string
  worker_sid: string
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
]: nothing -> record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($worker_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkerSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), worker_sid: (encode-path-segment $worker_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{worker_sid}/Channels/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Channels/{Sid}
#
# operationId: UpdateWorkerChannel
export def "workspaces-workers-channels update" [
  workspace_sid: string
  worker_sid: string
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
  --available: oneof<nothing, bool> # Whether the WorkerChannel is available. Set to `false` to prevent the Worker from receiving any new Tasks of this TaskChannel type.
  --capacity: int # The total number of Tasks that the Worker should handle for the TaskChannel type. TaskRouter creates reservations for Tasks of this TaskChannel type up to the specified capacity. If the capacity is 0, no new reservations will be created.
]: any -> record<account_sid: string, assigned_tasks: int, available: bool, available_capacity_percentage: int, configured_capacity: int, date_created: string, date_updated: string, sid: string, task_channel_sid: string, task_channel_unique_name: string, url: string, worker_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($worker_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkerSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), worker_sid: (encode-path-segment $worker_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{worker_sid}/Channels/{sid}"))
  let req_body = {"Available": $available, "Capacity": $capacity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations
#
# operationId: ListWorkerReservation
export def "workspaces-workers-reservations list" [
  workspace_sid: string
  worker_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reservation-status: string@reservation-status-completer # Returns the list of reservations for a worker with a specified ReservationStatus. Can be: `pending`, `accepted`, `rejected`, `timeout`, `canceled`, or `rescinded`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, reservations: table<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($worker_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkerSid' must be non-empty" } }
  let qp = [(serialize-qp "ReservationStatus" $reservation_status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), worker_sid: (encode-path-segment $worker_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{worker_sid}/Reservations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ReservationStatus": $reservation_status, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}
#
# operationId: FetchWorkerReservation
export def "workspaces-workers-reservations get" [
  workspace_sid: string
  worker_sid: string
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
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($worker_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkerSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), worker_sid: (encode-path-segment $worker_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{worker_sid}/Reservations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Reservations/{Sid}
#
# operationId: UpdateWorkerReservation
export def "workspaces-workers-reservations update" [
  workspace_sid: string
  worker_sid: string
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
  --if-match: string # The If-Match HTTP request header
  --beep: string # Whether to play a notification beep when the participant joins or when to play a beep. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --beep-on-customer-entrance: oneof<nothing, bool> # Whether to play a notification beep when the customer joins.
  --call-accept: oneof<nothing, bool> # Whether to accept a reservation when executing a Call instruction.
  --call-from: string # The Caller ID of the outbound call when executing a Call instruction.
  --call-record: string # Whether to record both legs of a call when executing a Call instruction.
  --call-status-callback-url: string # The URL to call for the completed call event when executing a Call instruction. (format: uri)
  --call-timeout: int # The timeout for a call when executing a Call instruction.
  --call-to: string # The contact URI of the worker when executing a Call instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --call-url: string # TwiML URI executed on answering the worker's leg as a result of the Call instruction. (format: uri)
  --conference-record: string # Whether to record the conference the participant is joining or when to record the conference. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --conference-recording-status-callback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --conference-recording-status-callback-method: string@conference-recording-status-callback-method-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-status-callback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --conference-status-callback-event: list<string> # The conference status events that we will send to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `speaker`.
  --conference-status-callback-method: string@conference-status-callback-method-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-trim: string # Whether to trim leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --dequeue-from: string # The caller ID of the call to the worker when executing a Dequeue instruction.
  --dequeue-post-work-activity-sid: string # The SID of the Activity resource to start after executing a Dequeue instruction.
  --dequeue-record: string # Whether to record both legs of a call when executing a Dequeue instruction or which leg to record.
  --dequeue-status-callback-event: list<string> # The call progress events sent via webhooks as a result of a Dequeue instruction.
  --dequeue-status-callback-url: string # The callback URL for completed call event when executing a Dequeue instruction. (format: uri)
  --dequeue-timeout: int # The timeout for call when executing a Dequeue instruction.
  --dequeue-to: string # The contact URI of the worker when executing a Dequeue instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --early-media: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. The default is `true`.
  --end-conference-on-customer-exit: oneof<nothing, bool> # Whether to end the conference when the customer leaves.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the agent leaves.
  --body-from: string # The caller ID of the call to the worker when executing a Conference instruction.
  --instruction: string # The assignment instruction for the reservation.
  --max-participants: int # The maximum number of participants allowed in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --muted: oneof<nothing, bool> # Whether the agent is muted in the conference. Defaults to `false`.
  --post-work-activity-sid: string # The new worker activity SID after executing a Conference instruction.
  --record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. Can be `true` or `false` and the default is `false`.
  --recording-channels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --recording-status-callback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --redirect-accept: oneof<nothing, bool> # Whether the reservation should be accepted when executing a Redirect instruction.
  --redirect-call-sid: string # The Call SID of the call parked in the queue when executing a Redirect instruction.
  --redirect-url: string # TwiML URI to redirect the call to when executing the Redirect instruction. (format: uri)
  --region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --reservation-status: string@reservation-status-completer
  --sip-auth-password: string # The SIP password for authentication.
  --sip-auth-username: string # The SIP username used for authentication.
  --start-conference-on-enter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. Can be: `true` or `false` and the default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-event: list<string> # The call progress events that we will send to `status_callback`. Can be: `initiated`, `ringing`, `answered`, or `completed`.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --timeout: int # The timeout for a call when executing a Conference instruction.
  --body-to: string # The Contact URI of the worker when executing a Conference instruction. Can be the URI of the Twilio Client, the SIP URI for Programmable SIP, or the [E.164](https://www.twilio.com/docs/glossary/what-e164) formatted phone number, depending on the destination.
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
  --worker-activity-sid: string # The new worker activity SID if rejecting a reservation.
]: any -> record<account_sid: string, date_created: string, date_updated: string, links: record, reservation_status: string, sid: string, task_sid: string, url: string, worker_name: string, worker_sid: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($worker_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkerSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), worker_sid: (encode-path-segment $worker_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{worker_sid}/Reservations/{sid}"))
  let req_body = {"Beep": $beep, "BeepOnCustomerEntrance": $beep_on_customer_entrance, "CallAccept": $call_accept, "CallFrom": $call_from, "CallRecord": $call_record, "CallStatusCallbackUrl": $call_status_callback_url, "CallTimeout": $call_timeout, "CallTo": $call_to, "CallUrl": $call_url, "ConferenceRecord": $conference_record, "ConferenceRecordingStatusCallback": $conference_recording_status_callback, "ConferenceRecordingStatusCallbackMethod": $conference_recording_status_callback_method, "ConferenceStatusCallback": $conference_status_callback, "ConferenceStatusCallbackEvent": $conference_status_callback_event, "ConferenceStatusCallbackMethod": $conference_status_callback_method, "ConferenceTrim": $conference_trim, "DequeueFrom": $dequeue_from, "DequeuePostWorkActivitySid": $dequeue_post_work_activity_sid, "DequeueRecord": $dequeue_record, "DequeueStatusCallbackEvent": $dequeue_status_callback_event, "DequeueStatusCallbackUrl": $dequeue_status_callback_url, "DequeueTimeout": $dequeue_timeout, "DequeueTo": $dequeue_to, "EarlyMedia": $early_media, "EndConferenceOnCustomerExit": $end_conference_on_customer_exit, "EndConferenceOnExit": $end_conference_on_exit, "From": $body_from, "Instruction": $instruction, "MaxParticipants": $max_participants, "Muted": $muted, "PostWorkActivitySid": $post_work_activity_sid, "Record": $record, "RecordingChannels": $recording_channels, "RecordingStatusCallback": $recording_status_callback, "RecordingStatusCallbackMethod": $recording_status_callback_method, "RedirectAccept": $redirect_accept, "RedirectCallSid": $redirect_call_sid, "RedirectUrl": $redirect_url, "Region": $region, "ReservationStatus": $reservation_status, "SipAuthPassword": $sip_auth_password, "SipAuthUsername": $sip_auth_username, "StartConferenceOnEnter": $start_conference_on_enter, "StatusCallback": $status_callback, "StatusCallbackEvent": $status_callback_event, "StatusCallbackMethod": $status_callback_method, "Timeout": $timeout, "To": $body_to, "WaitMethod": $wait_method, "WaitUrl": $wait_url, "WorkerActivitySid": $worker_activity_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workers/{WorkerSid}/Statistics
#
# operationId: FetchWorkerInstanceStatistics
export def "workspaces-workers-statistics get-instance" [
  workspace_sid: string
  worker_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-channel: string # Only calculate statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, cumulative: any, url: string, worker_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($worker_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkerSid' must be non-empty" } }
  let qp = [(serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), worker_sid: (encode-path-segment $worker_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workers/{worker_sid}/Statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Minutes": $minutes, "StartDate": $start_date, "EndDate": $end_date, "TaskChannel": $task_channel} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows
#
# operationId: ListWorkflow
export def "workspaces-workflows list" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The `friendly_name` of the Workflow resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, workflows: table<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FriendlyName": $friendly_name, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Workflows
#
# operationId: CreateWorkflow
export def "workspaces-workflows create" [
  workspace_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignment-callback-url: string # The URL from your application that will process task assignment events. See [Handling Task Assignment Callback](https://www.twilio.com/docs/taskrouter/handle-assignment-callbacks) for more details. (format: uri)
  configuration: string # A JSON string that contains the rules to apply to the Workflow. See [Configuring Workflows](https://www.twilio.com/docs/taskrouter/workflow-configuration) for more information.
  --fallback-assignment-callback-url: string # The URL that we should call when a call to the `assignment_callback_url` fails. (format: uri)
  friendly_name: string # A descriptive string that you create to describe the Workflow resource. For example, `Inbound Call Workflow` or `2014 Outbound Campaign`.
  --task-reservation-timeout: int # How long TaskRouter will wait for a confirmation response from your application after it assigns a Task to a Worker. Can be up to `86,400` (24 hours) and the default is `120`.
]: any -> record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows"))
  let req_body = {"AssignmentCallbackUrl": $assignment_callback_url, "Configuration": $configuration, "FallbackAssignmentCallbackUrl": $fallback_assignment_callback_url, "FriendlyName": $friendly_name, "TaskReservationTimeout": $task_reservation_timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# operationId: DeleteWorkflow
export def "workspaces-workflows delete" [
  workspace_sid: string
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
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# operationId: FetchWorkflow
export def "workspaces-workflows get" [
  workspace_sid: string
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
]: nothing -> record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /v1/Workspaces/{WorkspaceSid}/Workflows/{Sid}
#
# operationId: UpdateWorkflow
export def "workspaces-workflows update" [
  workspace_sid: string
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
  --assignment-callback-url: string # The URL from your application that will process task assignment events. See [Handling Task Assignment Callback](https://www.twilio.com/docs/taskrouter/handle-assignment-callbacks) for more details. (format: uri)
  --configuration: string # A JSON string that contains the rules to apply to the Workflow. See [Configuring Workflows](https://www.twilio.com/docs/taskrouter/workflow-configuration) for more information.
  --fallback-assignment-callback-url: string # The URL that we should call when a call to the `assignment_callback_url` fails. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the Workflow resource. For example, `Inbound Call Workflow` or `2014 Outbound Campaign`.
  --re-evaluate-tasks: string # Whether or not to re-evaluate Tasks. The default is `false`, which means Tasks in the Workflow will not be processed through the assignment loop again.
  --task-reservation-timeout: int # How long TaskRouter will wait for a confirmation response from your application after it assigns a Task to a Worker. Can be up to `86,400` (24 hours) and the default is `120`.
]: any -> record<account_sid: string, assignment_callback_url: string, configuration: string, date_created: string, date_updated: string, document_content_type: string, fallback_assignment_callback_url: string, friendly_name: string, links: record, sid: string, task_reservation_timeout: int, url: string, workspace_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows/{sid}"))
  let req_body = {"AssignmentCallbackUrl": $assignment_callback_url, "Configuration": $configuration, "FallbackAssignmentCallbackUrl": $fallback_assignment_callback_url, "FriendlyName": $friendly_name, "ReEvaluateTasks": $re_evaluate_tasks, "TaskReservationTimeout": $task_reservation_timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/CumulativeStatistics
#
# operationId: FetchWorkflowCumulativeStatistics
export def "workspaces-workflows-cumulative-statistics get" [
  workspace_sid: string
  workflow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # Only include usage that occurred on or before this date, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --task-channel: string # Only calculate cumulative statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA. TaskRouter will calculate statistics on up to 10,000 Tasks for any given threshold.
]: nothing -> record<account_sid: string, avg_task_acceptance_time: int, end_time: string, reservations_accepted: int, reservations_canceled: int, reservations_created: int, reservations_rejected: int, reservations_rescinded: int, reservations_timed_out: int, split_by_wait_time: any, start_time: string, tasks_canceled: int, tasks_completed: int, tasks_deleted: int, tasks_entered: int, tasks_moved: int, tasks_timed_out_in_workflow: int, url: string, wait_duration_until_accepted: any, wait_duration_until_canceled: any, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($workflow_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkflowSid' must be non-empty" } }
  let qp = [(serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "SplitByWaitTime" $split_by_wait_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), workflow_sid: (encode-path-segment $workflow_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows/{workflow_sid}/CumulativeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"EndDate": $end_date, "Minutes": $minutes, "StartDate": $start_date, "TaskChannel": $task_channel, "SplitByWaitTime": $split_by_wait_time} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/RealTimeStatistics
#
# operationId: FetchWorkflowRealTimeStatistics
export def "workspaces-workflows-real-time-statistics get" [
  workspace_sid: string
  workflow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
]: nothing -> record<account_sid: string, longest_task_waiting_age: int, longest_task_waiting_sid: string, tasks_by_priority: any, tasks_by_status: any, total_tasks: int, url: string, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($workflow_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkflowSid' must be non-empty" } }
  let qp = [(serialize-qp "TaskChannel" $task_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), workflow_sid: (encode-path-segment $workflow_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows/{workflow_sid}/RealTimeStatistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"TaskChannel": $task_channel} | compact), body: null}
}

# GET /v1/Workspaces/{WorkspaceSid}/Workflows/{WorkflowSid}/Statistics
#
# operationId: FetchWorkflowStatistics
export def "workspaces-workflows-statistics get" [
  workspace_sid: string
  workflow_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --minutes: int # Only calculate statistics since this many minutes in the past. The default 15 minutes. This is helpful for displaying statistics for the last 15 minutes, 240 minutes (4 hours), and 480 minutes (8 hours) to see trends.
  --start-date: string # Only calculate statistics from this date and time and later, specified in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date-time)
  --end-date: string # Only calculate statistics from this date and time and earlier, specified in GMT as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time. (format: date-time)
  --task-channel: string # Only calculate real-time statistics on this TaskChannel. Can be the TaskChannel's SID or its `unique_name`, such as `voice`, `sms`, or `default`.
  --split-by-wait-time: string # A comma separated list of values that describes the thresholds, in seconds, to calculate statistics on. For each threshold specified, the number of Tasks canceled and reservations accepted above and below the specified thresholds in seconds are computed. For example, `5,30` would show splits of Tasks that were canceled or accepted before and after 5 seconds and before and after 30 seconds. This can be used to show short abandoned Tasks or Tasks that failed to meet an SLA.
]: nothing -> record<account_sid: string, cumulative: any, realtime: any, url: string, workflow_sid: string, workspace_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://taskrouter.twilio.com")
  if ($workspace_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkspaceSid' must be non-empty" } }
  if ($workflow_sid | is-empty) { error make --unspanned { msg: "path parameter 'WorkflowSid' must be non-empty" } }
  let qp = [(serialize-qp "Minutes" $minutes "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "TaskChannel" $task_channel "scalar") (serialize-qp "SplitByWaitTime" $split_by_wait_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workspace_sid: (encode-path-segment $workspace_sid), workflow_sid: (encode-path-segment $workflow_sid)} | format pattern "/v1/Workspaces/{workspace_sid}/Workflows/{workflow_sid}/Statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Minutes": $minutes, "StartDate": $start_date, "EndDate": $end_date, "TaskChannel": $task_channel, "SplitByWaitTime": $split_by_wait_time} | compact), body: null}
}
