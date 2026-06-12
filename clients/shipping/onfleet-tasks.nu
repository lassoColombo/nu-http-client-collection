# Auto-generated client for Onfleet Tasks API v2.7
# Source: https://raw.githubusercontent.com/api-evangelist/onfleet/main/openapi/onfleet-tasks-api-openapi.yml
# Auth: --token flag or $env.ONFLEET_TASKS_API_TOKEN

const BASE_URL = "https://onfleet.com/api/v2"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ONFLEET_TASKS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://onfleet.com/api/v2"] }
def auth-scheme-completer [] { ["basic"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "tasks createTask" } } | get name | first)
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

# Create Task
#
# POST /tasks
# operationId: createTask
# --autoAssign shape: {mode?: "distance"|"load", team?: string, considerDependencies?: bool, excludedWorkerIds?: list, maxAssignedTaskCount?: int}
# --metadata item shape: {name: string, type: "boolean"|"number"|"string"|"object"|"array", value: any, visibility?: list}
# --appearance shape: {triangleColor?: string}
export def "tasks createTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --merchant: string
  --executor: string
  --destination: any
  --recipients: list
  --completeAfter: int # format: int64
  --completeBefore: int # format: int64
  --pickupTask: oneof<nothing, bool>
  --dependencies: list
  --notes: string
  --quantity: int
  --serviceTime: int
  --autoAssign: record # shape: {mode?: "distance"|"load", team?: string, considerDependencies?: bool, excludedWorkerIds?: list, maxAssignedTaskCount?: int}
  --container: record
  --metadata: list # item shape: {name: string, type: "boolean"|"number"|"string"|"object"|"array", value: any, visibility?: list}
  --appearance: record # shape: {triangleColor?: string}
]: any -> record<id: string, shortId: string, organization: string, timeCreated: int, timeLastModified: int, executor: string, merchant: string, creator: string, worker: string, destination: record<id: string, address: record<unparsed: string, number: string, street: string, city: string, state: string, postalCode: string, country: string, apartment: string>, location: list<float>, notes: string, warnings: list<string>>, recipients: table<id: string, name: string, phone: string, notes: string, skipSMSNotifications: bool, organization: string>, completeAfter: int, completeBefore: int, pickupTask: bool, dependencies: list<string>, notes: string, quantity: int, serviceTime: int, state: int, completionDetails: record<success: bool, time: int, notes: string, photoUploadIds: list<string>, signatureUploadId: string, events: list<record>>, feedback: table<time: int, rating: int, comments: string>, metadata: table<name: string, type: string, value: any, visibility: list>, trackingURL: string, trackingViewed: bool, eta: int, delayTime: int, appearance: record<triangleColor: string>, container: record<type: string, organization: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks")
  let body = {merchant: $merchant, executor: $executor, destination: $destination, recipients: $recipients, completeAfter: $completeAfter, completeBefore: $completeBefore, pickupTask: $pickupTask, dependencies: $dependencies, notes: $notes, quantity: $quantity, serviceTime: $serviceTime, autoAssign: $autoAssign, container: $container, metadata: $metadata, appearance: $appearance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Tasks In Batch
#
# POST /tasks/batch
# operationId: createTaskBatch
# --tasks item shape: {merchant?: string, executor?: string, destination?: any, recipients?: list, completeAfter?: int, completeBefore?: int, pickupTask?: bool, dependencies?: list, notes?: string, quantity?: int, serviceTime?: int, autoAssign?: record, container?: record, metadata?: list, appearance?: record}
export def "tasks-batch createTaskBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tasks: list # item shape: {merchant?: string, executor?: string, destination?: any, recipients?: list, completeAfter?: int, completeBefore?: int, pickupTask?: bool, dependencies?: list, notes?: string, quantity?: int, serviceTime?: int, autoAssign?: record, container?: record, metadata?: list, appearance?: record}
]: any -> record<status: string, jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tasks/batch")
  let body = {tasks: $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Tasks
#
# GET /tasks/all
# operationId: listTasks
export def "tasks-all listTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: int # Start of the search range in Unix milliseconds. (format: int64)
  --qp-to: int # End of the search range in Unix milliseconds. (format: int64)
  --lastId: string # Cursor returned from a previous call to walk pagination.
  --state: string # Comma-separated list of task state values (0=Unassigned, 1=Assigned, 2=Active, 3=Completed).
  --worker: string
  --completeBeforeBefore: int # format: int64
  --completeAfterAfter: int # format: int64
  --dependencies: string
  --containers: string
]: nothing -> record<lastId: string, tasks: table<id: string, shortId: string, organization: string, timeCreated: int, timeLastModified: int, executor: string, merchant: string, creator: string, worker: string, destination: record, recipients: list, completeAfter: int, completeBefore: int, pickupTask: bool, dependencies: list, notes: string, quantity: int, serviceTime: int, state: int, completionDetails: record, feedback: list, metadata: list, trackingURL: string, trackingViewed: bool, eta: int, delayTime: int, appearance: record, container: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "lastId" $lastId "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "worker" $worker "scalar") (serialize-qp "completeBeforeBefore" $completeBeforeBefore "scalar") (serialize-qp "completeAfterAfter" $completeAfterAfter "scalar") (serialize-qp "dependencies" $dependencies "scalar") (serialize-qp "containers" $containers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Single Task
#
# GET /tasks/{taskId}
# operationId: getTask
export def "tasks get" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, shortId: string, organization: string, timeCreated: int, timeLastModified: int, executor: string, merchant: string, creator: string, worker: string, destination: record<id: string, address: record<unparsed: string, number: string, street: string, city: string, state: string, postalCode: string, country: string, apartment: string>, location: list<float>, notes: string, warnings: list<string>>, recipients: table<id: string, name: string, phone: string, notes: string, skipSMSNotifications: bool, organization: string>, completeAfter: int, completeBefore: int, pickupTask: bool, dependencies: list<string>, notes: string, quantity: int, serviceTime: int, state: int, completionDetails: record<success: bool, time: int, notes: string, photoUploadIds: list<string>, signatureUploadId: string, events: list<record>>, feedback: table<time: int, rating: int, comments: string>, metadata: table<name: string, type: string, value: any, visibility: list>, trackingURL: string, trackingViewed: bool, eta: int, delayTime: int, appearance: record<triangleColor: string>, container: record<type: string, organization: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Task
#
# PUT /tasks/{taskId}
# operationId: updateTask
# --metadata item shape: {name: string, type: "boolean"|"number"|"string"|"object"|"array", value: any, visibility?: list}
export def "tasks updateTask" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string
  --completeAfter: int # format: int64
  --completeBefore: int # format: int64
  --pickupTask: oneof<nothing, bool>
  --quantity: int
  --serviceTime: int
  --metadata: list # item shape: {name: string, type: "boolean"|"number"|"string"|"object"|"array", value: any, visibility?: list}
]: any -> record<id: string, shortId: string, organization: string, timeCreated: int, timeLastModified: int, executor: string, merchant: string, creator: string, worker: string, destination: record<id: string, address: record<unparsed: string, number: string, street: string, city: string, state: string, postalCode: string, country: string, apartment: string>, location: list<float>, notes: string, warnings: list<string>>, recipients: table<id: string, name: string, phone: string, notes: string, skipSMSNotifications: bool, organization: string>, completeAfter: int, completeBefore: int, pickupTask: bool, dependencies: list<string>, notes: string, quantity: int, serviceTime: int, state: int, completionDetails: record<success: bool, time: int, notes: string, photoUploadIds: list<string>, signatureUploadId: string, events: list<record>>, feedback: table<time: int, rating: int, comments: string>, metadata: table<name: string, type: string, value: any, visibility: list>, trackingURL: string, trackingViewed: bool, eta: int, delayTime: int, appearance: record<triangleColor: string>, container: record<type: string, organization: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)")
  let body = {notes: $notes, completeAfter: $completeAfter, completeBefore: $completeBefore, pickupTask: $pickupTask, quantity: $quantity, serviceTime: $serviceTime, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Task
#
# DELETE /tasks/{taskId}
# operationId: deleteTask
export def "tasks delete" [
  taskId: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Task By Short ID
#
# GET /tasks/shortId/{shortId}
# operationId: getTaskByShortId
export def "tasks-short-id get" [
  shortId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, shortId: string, organization: string, timeCreated: int, timeLastModified: int, executor: string, merchant: string, creator: string, worker: string, destination: record<id: string, address: record<unparsed: string, number: string, street: string, city: string, state: string, postalCode: string, country: string, apartment: string>, location: list<float>, notes: string, warnings: list<string>>, recipients: table<id: string, name: string, phone: string, notes: string, skipSMSNotifications: bool, organization: string>, completeAfter: int, completeBefore: int, pickupTask: bool, dependencies: list<string>, notes: string, quantity: int, serviceTime: int, state: int, completionDetails: record<success: bool, time: int, notes: string, photoUploadIds: list<string>, signatureUploadId: string, events: list<record>>, feedback: table<time: int, rating: int, comments: string>, metadata: table<name: string, type: string, value: any, visibility: list>, trackingURL: string, trackingViewed: bool, eta: int, delayTime: int, appearance: record<triangleColor: string>, container: record<type: string, organization: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/shortId/($shortId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clone Task
#
# POST /tasks/{taskId}/clone
# operationId: cloneTask
export def "tasks-clone cloneTask" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, shortId: string, organization: string, timeCreated: int, timeLastModified: int, executor: string, merchant: string, creator: string, worker: string, destination: record<id: string, address: record<unparsed: string, number: string, street: string, city: string, state: string, postalCode: string, country: string, apartment: string>, location: list<float>, notes: string, warnings: list<string>>, recipients: table<id: string, name: string, phone: string, notes: string, skipSMSNotifications: bool, organization: string>, completeAfter: int, completeBefore: int, pickupTask: bool, dependencies: list<string>, notes: string, quantity: int, serviceTime: int, state: int, completionDetails: record<success: bool, time: int, notes: string, photoUploadIds: list<string>, signatureUploadId: string, events: list<record>>, feedback: table<time: int, rating: int, comments: string>, metadata: table<name: string, type: string, value: any, visibility: list>, trackingURL: string, trackingViewed: bool, eta: int, delayTime: int, appearance: record<triangleColor: string>, container: record<type: string, organization: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/clone")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force-Complete Task
#
# POST /tasks/{taskId}/complete
# operationId: forceCompleteTask
# --completionDetails shape: {success?: bool, notes?: string}
export def "tasks-complete forceCompleteTask" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --completionDetails: record # shape: {success?: bool, notes?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/complete")
  let body = {completionDetails: $completionDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Assign Tasks To Worker
#
# PUT /containers/workers/{workerId}
# operationId: assignTasksToWorker
export def "containers-workers assignTasksToWorker" [
  workerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tasks: list
  --considerDependencies: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/workers/($workerId)")
  let body = {tasks: $tasks, considerDependencies: $considerDependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
