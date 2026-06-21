# Auto-generated client for Service Fabric Client APIs v6.5.0.36
# Source: https://api.apis.guru/v2/specs/azure.com/servicefabric/6.5.0.36/swagger.json
# Auth: --token flag or $env.SERVICE_FABRIC_CLIENT_APIS_TOKEN

const BASE_URL = "http://azure.local:19080"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SERVICE_FABRIC_CLIENT_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://azure.local:19080" "https://azure.local:19080"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["6.0"] }
def preparing-health-check-state-completer [] { ["InProgress" "NotStarted" "Skipped" "Succeeded" "TimedOut"] }
def restoring-health-check-state-completer [] { ["InProgress" "NotStarted" "Skipped" "Succeeded" "TimedOut"] }
def result-status-completer [] { ["Cancelled" "Failed" "Interrupted" "Invalid" "Pending" "Succeeded"] }
def state-completer [] { ["Approved" "Claimed" "Completed" "Created" "Executing" "Invalid" "Preparing" "Restoring"] }
def api-version-completer-1 [] { ["6.4"] }
def health-state-completer [] { ["Error" "Invalid" "Ok" "Unknown" "Warning"] }
def upgrade-kind-completer [] { ["Invalid" "Rolling" "Rolling_ForceRestart"] }
def rolling-upgrade-mode-completer [] { ["Invalid" "Monitored" "UnmonitoredAuto" "UnmonitoredManual"] }
def sort-order-completer [] { ["Default" "Invalid" "Lexicographical" "Numeric" "ReverseLexicographical" "ReverseNumeric"] }
def upgrade-kind-completer-1 [] { ["Invalid" "Rolling"] }
def api-version-completer-2 [] { ["6.2"] }
def kind-completer [] { ["ExternalStore" "ImageStorePath" "Invalid"] }
def api-version-completer-3 [] { ["6.1"] }
def default-move-cost-completer [] { ["High" "Low" "Medium" "Zero"] }
def service-kind-completer [] { ["Invalid" "Stateful" "Stateless"] }
def service-package-activation-mode-completer [] { ["ExclusiveProcess" "SharedProcess"] }
def api-version-completer-4 [] { ["6.0-preview"] }
def api-version-completer-5 [] { ["6.4-preview"] }
def api-version-completer-6 [] { ["6.2-preview"] }
def node-transition-type-completer [] { ["Invalid" "Start" "Stop"] }
def data-loss-mode-completer [] { ["FullDataLoss" "Invalid" "PartialDataLoss"] }
def quorum-loss-mode-completer [] { ["AllReplicas" "Invalid" "QuorumReplicas"] }
def restart-partition-mode-completer [] { ["AllReplicasOrInstances" "Invalid" "OnlyActiveSecondaries"] }
def api-version-completer-7 [] { ["6.5"] }
def api-version-completer-8 [] { ["6.3"] }
def node-status-filter-completer [] { ["all" "default" "disabled" "disabling" "down" "enabling" "removed" "unknown" "up"] }
def deactivation-intent-completer [] { ["Pause" "RemoveData" "Restart"] }
def create-fabric-dump-completer [] { ["False" "True"] }
def service-kind-completer-1 [] { ["Stateful" "Stateless"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cancel-repair-task cancel" } } | get name | first)
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

# Requests the cancellation of the given repair task.
#
# POST /$/CancelRepairTask
# operationId: CancelRepairTask
export def "cancel-repair-task cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --request-abort: oneof<nothing, bool> # _True_ if the repair should be stopped as soon as possible even if it has already started executing. _False_ if the repair should be cancelled only if execution has not yet started.
  task_id: string # The ID of the repair task.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current version of the repair task. If zero, then no version check is performed.
]: any -> record<Version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/CancelRepairTask" $qp)
  let req_body = {"RequestAbort": $request_abort, "TaskId": $task_id, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a new repair task.
#
# POST /$/CreateRepairTask
# operationId: CreateRepairTask
# --History shape: {ApprovedUtcTimestamp?: string, ClaimedUtcTimestamp?: string, CompletedUtcTimestamp?: string, CreatedUtcTimestamp?: string, ExecutingUtcTimestamp?: string, PreparingHealthCheckEndUtcTimestamp?: string, PreparingHealthCheckStartUtcTimestamp?: string, PreparingUtcTimestamp?: string, RestoringHealthCheckEndUtcTimestamp?: string, RestoringHealthCheckStartUtcTimestamp?: string, RestoringUtcTimestamp?: string}
# --Impact shape: {Kind: "Invalid"|"Node"}
# --Target shape: {Kind: "Invalid"|"Node"}
export def "create-repair-task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  action: string # The requested repair action. Must be specified when the repair task is created, and is immutable once set.
  --description: string # A description of the purpose of the repair task, or other informational details. May be set when the repair task is created, and is immutable once set.
  --executor: string # The name of the repair executor. Must be specified in Claimed and later states, and is immutable once set.
  --executor-data: string # A data string that the repair executor can use to store its internal state.
  --flags: int # A bitwise-OR of the following values, which gives additional details about the status of the repair task. - 1 - Cancellation of the repair has been requested - 2 - Abort of the repair has been requested - 4 - Approval of the repair was forced via client request
  --history: any # A record of the times when the repair task entered each state. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {ApprovedUtcTimestamp?: string, ClaimedUtcTimestamp?: string, CompletedUtcTimestamp?: string, CreatedUtcTimestamp?: string, ExecutingUtcTimestamp?: string, PreparingHealthCheckEndUtcTimestamp?: string, PreparingHealthCheckStartUtcTimestamp?: string, PreparingUtcTimestamp?: string, RestoringHealthCheckEndUtcTimestamp?: string, RestoringHealthCheckStartUtcTimestamp?: string, RestoringUtcTimestamp?: string}
  --impact: any # Describes the expected impact of executing a repair task. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  --perform-preparing-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Preparing state.
  --perform-restoring-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Restoring state.
  --preparing-health-check-state: string@preparing-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --restoring-health-check-state: string@restoring-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --result-code: int # A numeric value providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-details: string # A string providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-status: string@result-status-completer # A value describing the overall result of the repair task execution. Must be specified in the Restoring and later states, and is immutable once set.
  state: string@state-completer # The workflow state of the repair task. Valid initial states are Created, Claimed, and Preparing.
  --target: any # Describes the entities targeted by a repair action. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  task_id: string # The ID of the repair task.
  --version: string # The version of the repair task. When creating a new repair task, the version must be set to zero. When updating a repair task, the version is used for optimistic concurrency checks. If the version is set to zero, the update will not check for write conflicts. If the version is set to a non-zero value, then the update will only succeed if the actual current version of the repair task matches this value.
]: any -> record<Version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/CreateRepairTask" $qp)
  let req_body = {"Action": $action, "Description": $description, "Executor": $executor, "ExecutorData": $executor_data, "Flags": $flags, "History": $history, "Impact": $impact, "PerformPreparingHealthCheck": $perform_preparing_health_check, "PerformRestoringHealthCheck": $perform_restoring_health_check, "PreparingHealthCheckState": $preparing_health_check_state, "RestoringHealthCheckState": $restoring_health_check_state, "ResultCode": $result_code, "ResultDetails": $result_details, "ResultStatus": $result_status, "State": $state, "Target": $target, "TaskId": $task_id, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes a completed repair task.
#
# POST /$/DeleteRepairTask
# operationId: DeleteRepairTask
export def "delete-repair-task delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  task_id: string # The ID of the completed repair task to be deleted.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current version of the repair task. If zero, then no version check is performed.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/DeleteRepairTask" $qp)
  let req_body = {"TaskId": $task_id, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Forces the approval of the given repair task.
#
# POST /$/ForceApproveRepairTask
# operationId: ForceApproveRepairTask
export def "force-approve-repair-task approve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  task_id: string # The ID of the repair task.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current version of the repair task. If zero, then no version check is performed.
]: any -> record<Version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/ForceApproveRepairTask" $qp)
  let req_body = {"TaskId": $task_id, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the Azure Active Directory metadata used for secured connection to cluster.
#
# GET /$/GetAadMetadata
# operationId: GetAadMetadata
export def "get-aad-metadata get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<metadata: record<authority: string, client: string, cluster: string, login: string, redirect: string, tenant: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetAadMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Get the Service Fabric standalone cluster configuration.
#
# GET /$/GetClusterConfiguration
# operationId: GetClusterConfiguration
export def "get-cluster-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --configuration-api-version: string # The API version of the Standalone cluster json configuration.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ClusterConfiguration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ConfigurationApiVersion" $configuration_api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterConfiguration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ConfigurationApiVersion": $configuration_api_version, "timeout": $timeout} | compact), body: null}
}

# Get the cluster configuration upgrade status of a Service Fabric standalone cluster.
#
# GET /$/GetClusterConfigurationUpgradeStatus
# operationId: GetClusterConfigurationUpgradeStatus
export def "get-cluster-configuration-upgrade-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ConfigVersion: string, Details: string, ProgressStatus: int, UpgradeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterConfigurationUpgradeStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the health of a Service Fabric cluster.
#
# GET /$/GetClusterHealth
# operationId: GetClusterHealth
export def "get-cluster-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --nodes-health-state-filter: int # Allows filtering of the node health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only nodes that match the filter are returned. All nodes are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of nodes with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --applications-health-state-filter: int # Allows filtering of the application health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value obtained from members or bitwise operations on members of HealthStateFilter enumeration. Only applications that match the filter are returned. All applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --include-system-application-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should include the fabric:/System application health statistics. False by default. If IncludeSystemApplicationHealthStatistics is set to true, the health statistics include the entities that belong to the fabric:/System application. Otherwise, the query result includes health statistics only for user applications. The health statistics must be included in the query result for this parameter to be applied. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "NodesHealthStateFilter" $nodes_health_state_filter "scalar") (serialize-qp "ApplicationsHealthStateFilter" $applications_health_state_filter "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "IncludeSystemApplicationHealthStatistics" $include_system_application_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "NodesHealthStateFilter": $nodes_health_state_filter, "ApplicationsHealthStateFilter": $applications_health_state_filter, "EventsHealthStateFilter": $events_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "IncludeSystemApplicationHealthStatistics": $include_system_application_health_statistics, "timeout": $timeout} | compact), body: null}
}

# Gets the health of a Service Fabric cluster using the specified policy.
#
# POST /$/GetClusterHealth
# operationId: GetClusterHealthUsingPolicy
# --ApplicationHealthPolicyMap item shape: {Key: string, Value: any}
# --ClusterHealthPolicy shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
export def "get-cluster-health get-using-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --nodes-health-state-filter: int # Allows filtering of the node health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only nodes that match the filter are returned. All nodes are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of nodes with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --applications-health-state-filter: int # Allows filtering of the application health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value obtained from members or bitwise operations on members of HealthStateFilter enumeration. Only applications that match the filter are returned. All applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --include-system-application-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should include the fabric:/System application health statistics. False by default. If IncludeSystemApplicationHealthStatistics is set to true, the health statistics include the entities that belong to the fabric:/System application. Otherwise, the query result includes health statistics only for user applications. The health statistics must be included in the query result for this parameter to be applied. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy-map: list # Defines a map that contains specific application health policies for different applications. Each entry specifies as key the application name and as value an ApplicationHealthPolicy used to evaluate the application health. If an application is not specified in the map, the application health evaluation uses the ApplicationHealthPolicy found in its application manifest or the default application health policy (if no health policy is defined in the manifest). The map is empty by default. — item shape: {Key: string, Value: any}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
]: any -> record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "NodesHealthStateFilter" $nodes_health_state_filter "scalar") (serialize-qp "ApplicationsHealthStateFilter" $applications_health_state_filter "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "IncludeSystemApplicationHealthStatistics" $include_system_application_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealth" $qp)
  let req_body = {"ApplicationHealthPolicyMap": $application_health_policy_map, "ClusterHealthPolicy": $cluster_health_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "NodesHealthStateFilter": $nodes_health_state_filter, "ApplicationsHealthStateFilter": $applications_health_state_filter, "EventsHealthStateFilter": $events_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "IncludeSystemApplicationHealthStatistics": $include_system_application_health_statistics, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the health of a Service Fabric cluster using health chunks.
#
# GET /$/GetClusterHealthChunk
# operationId: GetClusterHealthChunk
export def "get-cluster-health-chunk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealthChunk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the health of a Service Fabric cluster using health chunks.
#
# POST /$/GetClusterHealthChunk
# operationId: GetClusterHealthChunkUsingPolicyAndAdvancedFilters
# --ApplicationFilters item shape: {ApplicationNameFilter?: string, ApplicationTypeNameFilter?: string, DeployedApplicationFilters?: list, HealthStateFilter?: int, ServiceFilters?: list}
# --ApplicationHealthPolicies shape: {ApplicationHealthPolicyMap?: list}
# --ClusterHealthPolicy shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
# --NodeFilters item shape: {HealthStateFilter?: int, NodeNameFilter?: string}
export def "get-cluster-health-chunk get-using-policy-and-advanced-filters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-filters: list # Defines a list of filters that specify which applications to be included in the returned cluster health chunk. If no filters are specified, no applications are returned. All the applications are used to evaluate the cluster's aggregated health state, regardless of the input filters. The cluster health chunk query may specify multiple application filters. For example, it can specify a filter to return all applications with health state Error and another filter to always include applications of a specified application type. — item shape: {ApplicationNameFilter?: string, ApplicationTypeNameFilter?: string, DeployedApplicationFilters?: list, HealthStateFilter?: int, ServiceFilters?: list}
  --application-health-policies: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --node-filters: list # Defines a list of filters that specify which nodes to be included in the returned cluster health chunk. If no filters are specified, no nodes are returned. All the nodes are used to evaluate the cluster's aggregated health state, regardless of the input filters. The cluster health chunk query may specify multiple node filters. For example, it can specify a filter to return all nodes with health state Error and another filter to always include a node identified by its NodeName. — item shape: {HealthStateFilter?: int, NodeNameFilter?: string}
]: any -> record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealthChunk" $qp)
  let req_body = {"ApplicationFilters": $application_filters, "ApplicationHealthPolicies": $application_health_policies, "ClusterHealthPolicy": $cluster_health_policy, "NodeFilters": $node_filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Get the Service Fabric cluster manifest.
#
# GET /$/GetClusterManifest
# operationId: GetClusterManifest
export def "get-cluster-manifest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Manifest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterManifest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Get the current Service Fabric cluster version.
#
# GET /$/GetClusterVersion
# operationId: GetClusterVersion
export def "get-cluster-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterVersion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the load of a Service Fabric cluster.
#
# GET /$/GetLoadInformation
# operationId: GetClusterLoad
export def "get-load-information get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<LastBalancingEndTimeUtc: string, LastBalancingStartTimeUtc: string, LoadMetricInformation: table<Action: string, ActivityThreshold: string, BalancingThreshold: string, BufferedClusterCapacityRemaining: string, ClusterBufferedCapacity: string, ClusterCapacity: string, ClusterCapacityRemaining: string, ClusterLoad: string, ClusterRemainingBufferedCapacity: string, ClusterRemainingCapacity: string, CurrentClusterLoad: string, DeviationAfter: string, DeviationBefore: string, IsBalancedAfter: bool, IsBalancedBefore: bool, IsClusterCapacityViolation: bool, MaxNodeLoadNodeId: record, MaxNodeLoadValue: string, MaximumNodeLoad: string, MinNodeLoadNodeId: record, MinNodeLoadValue: string, MinimumNodeLoad: string, Name: string, NodeBufferPercentage: string, PlannedLoadRemoval: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetLoadInformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets a list of fabric code versions that are provisioned in a Service Fabric cluster.
#
# GET /$/GetProvisionedCodeVersions
# operationId: GetProvisionedFabricCodeVersionInfoList
export def "get-provisioned-code-versions get-fabric-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --code-version: string # The product version of Service Fabric.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<CodeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "CodeVersion" $code_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetProvisionedCodeVersions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "CodeVersion": $code_version, "timeout": $timeout} | compact), body: null}
}

# Gets a list of fabric config versions that are provisioned in a Service Fabric cluster.
#
# GET /$/GetProvisionedConfigVersions
# operationId: GetProvisionedFabricConfigVersionInfoList
export def "get-provisioned-config-versions get-fabric-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --config-version: string # The config version of Service Fabric.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<ConfigVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ConfigVersion" $config_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetProvisionedConfigVersions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ConfigVersion": $config_version, "timeout": $timeout} | compact), body: null}
}

# Gets a list of repair tasks matching the given filters.
#
# GET /$/GetRepairTaskList
# operationId: GetRepairTaskList
export def "get-repair-task-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --task-id-filter: string # The repair task ID prefix to be matched.
  --state-filter: int # A bitwise-OR of the following values, specifying which task states should be included in the result list. - 1 - Created - 2 - Claimed - 4 - Preparing - 8 - Approved - 16 - Executing - 32 - Restoring - 64 - Completed
  --executor-filter: string # The name of the repair executor whose claimed tasks should be included in the list.
]: nothing -> table<Action: string, Description: string, Executor: string, ExecutorData: string, Flags: int, History: record<ApprovedUtcTimestamp: string, ClaimedUtcTimestamp: string, CompletedUtcTimestamp: string, CreatedUtcTimestamp: string, ExecutingUtcTimestamp: string, PreparingHealthCheckEndUtcTimestamp: string, PreparingHealthCheckStartUtcTimestamp: string, PreparingUtcTimestamp: string, RestoringHealthCheckEndUtcTimestamp: string, RestoringHealthCheckStartUtcTimestamp: string, RestoringUtcTimestamp: string>, Impact: record<Kind: string>, PerformPreparingHealthCheck: bool, PerformRestoringHealthCheck: bool, PreparingHealthCheckState: string, RestoringHealthCheckState: string, ResultCode: int, ResultDetails: string, ResultStatus: string, State: string, Target: record<Kind: string>, TaskId: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "TaskIdFilter" $task_id_filter "scalar") (serialize-qp "StateFilter" $state_filter "scalar") (serialize-qp "ExecutorFilter" $executor_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetRepairTaskList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "TaskIdFilter": $task_id_filter, "StateFilter": $state_filter, "ExecutorFilter": $executor_filter} | compact), body: null}
}

# Get the service state of Service Fabric Upgrade Orchestration Service.
#
# GET /$/GetUpgradeOrchestrationServiceState
# operationId: GetUpgradeOrchestrationServiceState
export def "get-upgrade-orchestration-service-state get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ServiceState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetUpgradeOrchestrationServiceState" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the progress of the current cluster upgrade.
#
# GET /$/GetUpgradeProgress
# operationId: GetClusterUpgradeProgress
export def "get-upgrade-progress get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CodeVersion: string, ConfigVersion: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicyMap: list<record>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, ClusterUpgradeHealthPolicy: record<MaxPercentDeltaUnhealthyNodes: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes: int>, CodeVersion: string, ConfigVersion: string, EnableDeltaHealthEvaluation: bool, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, SortOrder: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetUpgradeProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Invokes an administrative command on the given Infrastructure Service instance.
#
# POST /$/InvokeInfrastructureCommand
# operationId: InvokeInfrastructureCommand
export def "invoke-infrastructure-command create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --command: string # The text of the command to be invoked. The content of the command is infrastructure-specific.
  --service-id: string # The identity of the infrastructure service. This is the full name of the infrastructure service without the 'fabric:' URI scheme. This parameter required only for the cluster that has more than one instance of infrastructure service running.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Command" $command "scalar") (serialize-qp "ServiceId" $service_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/InvokeInfrastructureCommand" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "Command": $command, "ServiceId": $service_id, "timeout": $timeout} | compact), body: null}
}

# Invokes a read-only query on the given infrastructure service instance.
#
# GET /$/InvokeInfrastructureQuery
# operationId: InvokeInfrastructureQuery
export def "invoke-infrastructure-query list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --command: string # The text of the command to be invoked. The content of the command is infrastructure-specific.
  --service-id: string # The identity of the infrastructure service. This is the full name of the infrastructure service without the 'fabric:' URI scheme. This parameter required only for the cluster that has more than one instance of infrastructure service running.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Command" $command "scalar") (serialize-qp "ServiceId" $service_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/InvokeInfrastructureQuery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "Command": $command, "ServiceId": $service_id, "timeout": $timeout} | compact), body: null}
}

# Make the cluster upgrade move on to the next upgrade domain.
#
# POST /$/MoveToNextUpgradeDomain
# operationId: ResumeClusterUpgrade
export def "move-to-next-upgrade-domain create-resume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  upgrade_domain: string # The next upgrade domain for this cluster upgrade.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/MoveToNextUpgradeDomain" $qp)
  let req_body = {"UpgradeDomain": $upgrade_domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Provision the code or configuration packages of a Service Fabric cluster.
#
# POST /$/Provision
# operationId: ProvisionCluster
export def "provision create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --cluster-manifest-file-path: string # The cluster manifest file path.
  --code-file-path: string # The cluster code package file path.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/Provision" $qp)
  let req_body = {"ClusterManifestFilePath": $cluster_manifest_file_path, "CodeFilePath": $code_file_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Indicates to the Service Fabric cluster that it should attempt to recover any services (including system services) which are currently stuck in quorum loss.
#
# POST /$/RecoverAllPartitions
# operationId: RecoverAllPartitions
export def "recover-all-partitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/RecoverAllPartitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Indicates to the Service Fabric cluster that it should attempt to recover the system services that are currently stuck in quorum loss.
#
# POST /$/RecoverSystemPartitions
# operationId: RecoverSystemPartitions
export def "recover-system-partitions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/RecoverSystemPartitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Sends a health report on the Service Fabric cluster.
#
# POST /$/ReportClusterHealth
# operationId: ReportClusterHealth
export def "report-cluster-health create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/ReportClusterHealth" $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Roll back the upgrade of a Service Fabric cluster.
#
# POST /$/RollbackUpgrade
# operationId: RollbackClusterUpgrade
export def "rollback-upgrade create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/RollbackUpgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Update the service state of Service Fabric Upgrade Orchestration Service.
#
# POST /$/SetUpgradeOrchestrationServiceState
# operationId: SetUpgradeOrchestrationServiceState
export def "set-upgrade-orchestration-service-state update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --service-state: string # The state of Service Fabric Upgrade Orchestration Service.
]: any -> record<CurrentCodeVersion: string, CurrentManifestVersion: string, PendingUpgradeType: string, TargetCodeVersion: string, TargetManifestVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/SetUpgradeOrchestrationServiceState" $qp)
  let req_body = {"ServiceState": $service_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Start upgrading the configuration of a Service Fabric standalone cluster.
#
# POST /$/StartClusterConfigurationUpgrade
# operationId: StartClusterConfigurationUpgrade
# --ApplicationHealthPolicies shape: {ApplicationHealthPolicyMap?: list}
export def "start-cluster-configuration-upgrade start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policies: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  cluster_config: string # The cluster configuration as a JSON string. For example, [this file](https://github.com/Azure-Samples/service-fabric-dotnet-standalone-cluster-configuration/blob/master/Samples/ClusterConfig.Unsecure.DevCluster.json) contains JSON describing the [nodes and other properties of the cluster](https://docs.microsoft.com/azure/service-fabric/service-fabric-cluster-manifest).
  --health-check-retry-timeout: string # The length of time between attempts to perform health checks if the application or cluster is not healthy. (format: duration, default: PT0H0M0S)
  --health-check-stable-duration-in-seconds: string # The length of time that the application or cluster must remain healthy before the upgrade proceeds to the next upgrade domain. (format: duration, default: PT0H0M0S)
  --health-check-wait-duration-in-seconds: string # The length of time to wait after completing an upgrade domain before starting the health checks process. (format: duration, default: PT0H0M0S)
  --max-percent-delta-unhealthy-nodes: int # The maximum allowed percentage of delta health degradation during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --max-percent-unhealthy-applications: int # The maximum allowed percentage of unhealthy applications during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --max-percent-unhealthy-nodes: int # The maximum allowed percentage of unhealthy nodes during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --max-percent-upgrade-domain-delta-unhealthy-nodes: int # The maximum allowed percentage of upgrade domain delta health degradation during the upgrade. Allowed values are integer values from zero to 100. (default: 0)
  --upgrade-domain-timeout-in-seconds: string # The timeout for the upgrade domain. (format: duration, default: PT0H0M0S)
  --upgrade-timeout-in-seconds: string # The upgrade timeout. (format: duration, default: PT0H0M0S)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/StartClusterConfigurationUpgrade" $qp)
  let req_body = {"ApplicationHealthPolicies": $application_health_policies, "ClusterConfig": $cluster_config, "HealthCheckRetryTimeout": $health_check_retry_timeout, "HealthCheckStableDurationInSeconds": $health_check_stable_duration_in_seconds, "HealthCheckWaitDurationInSeconds": $health_check_wait_duration_in_seconds, "MaxPercentDeltaUnhealthyNodes": $max_percent_delta_unhealthy_nodes, "MaxPercentUnhealthyApplications": $max_percent_unhealthy_applications, "MaxPercentUnhealthyNodes": $max_percent_unhealthy_nodes, "MaxPercentUpgradeDomainDeltaUnhealthyNodes": $max_percent_upgrade_domain_delta_unhealthy_nodes, "UpgradeDomainTimeoutInSeconds": $upgrade_domain_timeout_in_seconds, "UpgradeTimeoutInSeconds": $upgrade_timeout_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Changes the verbosity of service placement health reporting.
#
# POST /$/ToggleVerboseServicePlacementHealthReporting
# operationId: ToggleVerboseServicePlacementHealthReporting
export def "toggle-verbose-service-placement-health-reporting create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --enabled: oneof<nothing, bool> # The verbosity of service placement health reporting.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Enabled" $enabled "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/ToggleVerboseServicePlacementHealthReporting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "Enabled": $enabled, "timeout": $timeout} | compact), body: null}
}

# Unprovision the code or configuration packages of a Service Fabric cluster.
#
# POST /$/Unprovision
# operationId: UnprovisionCluster
export def "unprovision create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --code-version: string # The cluster code package version.
  --config-version: string # The cluster manifest version.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/Unprovision" $qp)
  let req_body = {"CodeVersion": $code_version, "ConfigVersion": $config_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Updates the execution state of a repair task.
#
# POST /$/UpdateRepairExecutionState
# operationId: UpdateRepairExecutionState
# --History shape: {ApprovedUtcTimestamp?: string, ClaimedUtcTimestamp?: string, CompletedUtcTimestamp?: string, CreatedUtcTimestamp?: string, ExecutingUtcTimestamp?: string, PreparingHealthCheckEndUtcTimestamp?: string, PreparingHealthCheckStartUtcTimestamp?: string, PreparingUtcTimestamp?: string, RestoringHealthCheckEndUtcTimestamp?: string, RestoringHealthCheckStartUtcTimestamp?: string, RestoringUtcTimestamp?: string}
# --Impact shape: {Kind: "Invalid"|"Node"}
# --Target shape: {Kind: "Invalid"|"Node"}
export def "update-repair-execution-state update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  action: string # The requested repair action. Must be specified when the repair task is created, and is immutable once set.
  --description: string # A description of the purpose of the repair task, or other informational details. May be set when the repair task is created, and is immutable once set.
  --executor: string # The name of the repair executor. Must be specified in Claimed and later states, and is immutable once set.
  --executor-data: string # A data string that the repair executor can use to store its internal state.
  --flags: int # A bitwise-OR of the following values, which gives additional details about the status of the repair task. - 1 - Cancellation of the repair has been requested - 2 - Abort of the repair has been requested - 4 - Approval of the repair was forced via client request
  --history: any # A record of the times when the repair task entered each state. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {ApprovedUtcTimestamp?: string, ClaimedUtcTimestamp?: string, CompletedUtcTimestamp?: string, CreatedUtcTimestamp?: string, ExecutingUtcTimestamp?: string, PreparingHealthCheckEndUtcTimestamp?: string, PreparingHealthCheckStartUtcTimestamp?: string, PreparingUtcTimestamp?: string, RestoringHealthCheckEndUtcTimestamp?: string, RestoringHealthCheckStartUtcTimestamp?: string, RestoringUtcTimestamp?: string}
  --impact: any # Describes the expected impact of executing a repair task. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  --perform-preparing-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Preparing state.
  --perform-restoring-health-check: oneof<nothing, bool> # A value to determine if health checks will be performed when the repair task enters the Restoring state.
  --preparing-health-check-state: string@preparing-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --restoring-health-check-state: string@restoring-health-check-state-completer # Specifies the workflow state of a repair task's health check. This type supports the Service Fabric platform; it is not meant to be used directly from your code.
  --result-code: int # A numeric value providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-details: string # A string providing additional details about the result of the repair task execution. May be specified in the Restoring and later states, and is immutable once set.
  --result-status: string@result-status-completer # A value describing the overall result of the repair task execution. Must be specified in the Restoring and later states, and is immutable once set.
  state: string@state-completer # The workflow state of the repair task. Valid initial states are Created, Claimed, and Preparing.
  --target: any # Describes the entities targeted by a repair action. This type supports the Service Fabric platform; it is not meant to be used directly from your code. — shape: {Kind: "Invalid"|"Node"}
  task_id: string # The ID of the repair task.
  --version: string # The version of the repair task. When creating a new repair task, the version must be set to zero. When updating a repair task, the version is used for optimistic concurrency checks. If the version is set to zero, the update will not check for write conflicts. If the version is set to a non-zero value, then the update will only succeed if the actual current version of the repair task matches this value.
]: any -> record<Version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/UpdateRepairExecutionState" $qp)
  let req_body = {"Action": $action, "Description": $description, "Executor": $executor, "ExecutorData": $executor_data, "Flags": $flags, "History": $history, "Impact": $impact, "PerformPreparingHealthCheck": $perform_preparing_health_check, "PerformRestoringHealthCheck": $perform_restoring_health_check, "PreparingHealthCheckState": $preparing_health_check_state, "RestoringHealthCheckState": $restoring_health_check_state, "ResultCode": $result_code, "ResultDetails": $result_details, "ResultStatus": $result_status, "State": $state, "Target": $target, "TaskId": $task_id, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Updates the health policy of the given repair task.
#
# POST /$/UpdateRepairTaskHealthPolicy
# operationId: UpdateRepairTaskHealthPolicy
export def "update-repair-task-health-policy update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --perform-preparing-health-check: oneof<nothing, bool> # A boolean indicating if health check is to be performed in the Preparing stage of the repair task. If not specified the existing value should not be altered. Otherwise, specify the desired new value.
  --perform-restoring-health-check: oneof<nothing, bool> # A boolean indicating if health check is to be performed in the Restoring stage of the repair task. If not specified the existing value should not be altered. Otherwise, specify the desired new value.
  task_id: string # The ID of the repair task to be updated.
  --version: string # The current version number of the repair task. If non-zero, then the request will only succeed if this value matches the actual current value of the repair task. If zero, then no version check is performed.
]: any -> record<Version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/UpdateRepairTaskHealthPolicy" $qp)
  let req_body = {"PerformPreparingHealthCheck": $perform_preparing_health_check, "PerformRestoringHealthCheck": $perform_restoring_health_check, "TaskId": $task_id, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Update the upgrade parameters of a Service Fabric cluster upgrade.
#
# POST /$/UpdateUpgrade
# operationId: UpdateClusterUpgrade
# --ApplicationHealthPolicyMap shape: {ApplicationHealthPolicyMap?: list}
# --ClusterHealthPolicy shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
# --ClusterUpgradeHealthPolicy shape: {MaxPercentDeltaUnhealthyNodes?: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes?: int}
# --UpdateDescription shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", ForceRestart?: bool, HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, ReplicaSetCheckTimeoutInMilliseconds?: int, RollingUpgradeMode: "Invalid"|"UnmonitoredAuto"|"UnmonitoredManual"|"Monitored", UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
export def "update-upgrade update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy-map: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --cluster-upgrade-health-policy: any # Defines a health policy used to evaluate the health of the cluster during a cluster upgrade. — shape: {MaxPercentDeltaUnhealthyNodes?: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes?: int}
  --enable-delta-health-evaluation: oneof<nothing, bool> # When true, enables delta health evaluation rather than absolute health evaluation after completion of each upgrade domain.
  --update-description: any # Describes the parameters for updating a rolling upgrade of application or cluster. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", ForceRestart?: bool, HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, ReplicaSetCheckTimeoutInMilliseconds?: int, RollingUpgradeMode: "Invalid"|"UnmonitoredAuto"|"UnmonitoredManual"|"Monitored", UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  --upgrade-kind: string@upgrade-kind-completer # The type of upgrade out of the following possible values. (default: Rolling)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/UpdateUpgrade" $qp)
  let req_body = {"ApplicationHealthPolicyMap": $application_health_policy_map, "ClusterHealthPolicy": $cluster_health_policy, "ClusterUpgradeHealthPolicy": $cluster_upgrade_health_policy, "EnableDeltaHealthEvaluation": $enable_delta_health_evaluation, "UpdateDescription": $update_description, "UpgradeKind": $upgrade_kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Start upgrading the code or configuration version of a Service Fabric cluster.
#
# POST /$/Upgrade
# operationId: StartClusterUpgrade
# --ApplicationHealthPolicyMap shape: {ApplicationHealthPolicyMap?: list}
# --ClusterHealthPolicy shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
# --ClusterUpgradeHealthPolicy shape: {MaxPercentDeltaUnhealthyNodes?: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes?: int}
# --MonitoringPolicy shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
export def "upgrade start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy-map: any # Defines the application health policy map used to evaluate the health of an application or one of its children entities. — shape: {ApplicationHealthPolicyMap?: list}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --cluster-upgrade-health-policy: any # Defines a health policy used to evaluate the health of the cluster during a cluster upgrade. — shape: {MaxPercentDeltaUnhealthyNodes?: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes?: int}
  --code-version: string # The cluster code version.
  --config-version: string # The cluster configuration version.
  --enable-delta-health-evaluation: oneof<nothing, bool> # When true, enables delta health evaluation rather than absolute health evaluation after completion of each upgrade domain.
  --force-restart: oneof<nothing, bool> # If true, then processes are forcefully restarted during upgrade even when the code version has not changed (the upgrade only changes configuration or data). (default: false)
  --monitoring-policy: any # Describes the parameters for monitoring an upgrade in Monitored mode. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  --rolling-upgrade-mode: string@rolling-upgrade-mode-completer # The mode used to monitor health during a rolling upgrade. The values are UnmonitoredAuto, UnmonitoredManual, and Monitored. (default: UnmonitoredAuto)
  --sort-order: string@sort-order-completer # Defines the order in which an upgrade proceeds through the cluster. (default: Default)
  --upgrade-kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
  --upgrade-replica-set-check-timeout-in-seconds: int # The maximum amount of time to block processing of an upgrade domain and prevent loss of availability when there are unexpected issues. When this timeout expires, processing of the upgrade domain will proceed regardless of availability loss issues. The timeout is reset at the start of each upgrade domain. Valid values are between 0 and 42949672925 inclusive. (unsigned 32-bit integer). (format: int64, default: 42949672925)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/Upgrade" $qp)
  let req_body = {"ApplicationHealthPolicyMap": $application_health_policy_map, "ClusterHealthPolicy": $cluster_health_policy, "ClusterUpgradeHealthPolicy": $cluster_upgrade_health_policy, "CodeVersion": $code_version, "ConfigVersion": $config_version, "EnableDeltaHealthEvaluation": $enable_delta_health_evaluation, "ForceRestart": $force_restart, "MonitoringPolicy": $monitoring_policy, "RollingUpgradeMode": $rolling_upgrade_mode, "SortOrder": $sort_order, "UpgradeKind": $upgrade_kind, "UpgradeReplicaSetCheckTimeoutInSeconds": $upgrade_replica_set_check_timeout_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of application types in the Service Fabric cluster.
#
# GET /ApplicationTypes
# operationId: GetApplicationTypeInfoList
export def "application-types get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --application-type-definition-kind-filter: int # Used to filter on ApplicationTypeDefinitionKind which is the mechanism used to define a Service Fabric application type. - Default - Default value, which performs the same function as selecting "All". The value is 0. - All - Filter that matches input with any ApplicationTypeDefinitionKind value. The value is 65535. - ServiceFabricApplicationPackage - Filter that matches input with ApplicationTypeDefinitionKind value ServiceFabricApplicationPackage. The value is 1. - Compose - Filter that matches input with ApplicationTypeDefinitionKind value Compose. The value is 2. (default: 0)
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeDefinitionKindFilter" $application_type_definition_kind_filter "scalar") (serialize-qp "ExcludeApplicationParameters" $exclude_application_parameters "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ApplicationTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ApplicationTypeDefinitionKindFilter": $application_type_definition_kind_filter, "ExcludeApplicationParameters": $exclude_application_parameters, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Provisions or registers a Service Fabric application type with the cluster using the '.sfpkg' package in the external store or using the application package in the image store.
#
# POST /ApplicationTypes/$/Provision
# Discriminator (request): Kind
# operationId: ProvisionApplicationType
export def "application-types-provision create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --async: oneof<nothing, bool> # Indicates whether or not provisioning should occur asynchronously. When set to true, the provision operation returns when the request is accepted by the system, and the provision operation continues without any timeout limit. The default value is false. For large application packages, we recommend setting the value to true.
  kind: string@kind-completer # The kind of application type registration or provision requested. The application package can be registered or provisioned either from the image store or from an external store. Following are the kinds of the application type provision.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ApplicationTypes/$/Provision" $qp)
  let req_body = {"Async": $async, "Kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of application types in the Service Fabric cluster matching exactly the specified name.
#
# GET /ApplicationTypes/{applicationTypeName}
# operationId: GetApplicationTypeInfoListByName
export def "application-types get-list-by-name" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --application-type-version: string # The version of the application type.
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $application_type_version "scalar") (serialize-qp "ExcludeApplicationParameters" $exclude_application_parameters "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_type_name: (encode-path-segment $application_type_name)} | format pattern "/ApplicationTypes/{application_type_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ApplicationTypeVersion": $application_type_version, "ExcludeApplicationParameters": $exclude_application_parameters, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Gets the manifest describing an application type.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetApplicationManifest
# operationId: GetApplicationManifest
export def "application-types-get-application-manifest get" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --application-type-version: string # The version of the application type.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Manifest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $application_type_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_type_name: (encode-path-segment $application_type_name)} | format pattern "/ApplicationTypes/{application_type_name}/$/GetApplicationManifest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ApplicationTypeVersion": $application_type_version, "timeout": $timeout} | compact), body: null}
}

# Gets the manifest describing a service type.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceManifest
# operationId: GetServiceManifest
export def "application-types-get-service-manifest get" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --application-type-version: string # The version of the application type.
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Manifest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $application_type_version "scalar") (serialize-qp "ServiceManifestName" $service_manifest_name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_type_name: (encode-path-segment $application_type_name)} | format pattern "/ApplicationTypes/{application_type_name}/$/GetServiceManifest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ApplicationTypeVersion": $application_type_version, "ServiceManifestName": $service_manifest_name, "timeout": $timeout} | compact), body: null}
}

# Gets the list containing the information about service types that are supported by a provisioned application type in a Service Fabric cluster.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceTypes
# operationId: GetServiceTypeInfoList
export def "application-types-get-service-types get-list" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --application-type-version: string # The version of the application type.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list, IsStateful: bool, Kind: string, LoadMetrics: list, PlacementConstraints: string, ServicePlacementPolicies: list, ServiceTypeName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $application_type_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_type_name: (encode-path-segment $application_type_name)} | format pattern "/ApplicationTypes/{application_type_name}/$/GetServiceTypes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ApplicationTypeVersion": $application_type_version, "timeout": $timeout} | compact), body: null}
}

# Gets the information about a specific service type that is supported by a provisioned application type in a Service Fabric cluster.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceTypes/{serviceTypeName}
# operationId: GetServiceTypeInfoByName
export def "application-types-get-service-types get-by-name" [
  application_type_name: string
  service_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --application-type-version: string # The version of the application type.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list<record>, IsStateful: bool, Kind: string, LoadMetrics: list<record>, PlacementConstraints: string, ServicePlacementPolicies: list<record>, ServiceTypeName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  if ($service_type_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $application_type_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_type_name: (encode-path-segment $application_type_name), service_type_name: (encode-path-segment $service_type_name)} | format pattern "/ApplicationTypes/{application_type_name}/$/GetServiceTypes/{service_type_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ApplicationTypeVersion": $application_type_version, "timeout": $timeout} | compact), body: null}
}

# Removes or unregisters a Service Fabric application type from the cluster.
#
# POST /ApplicationTypes/{applicationTypeName}/$/Unprovision
# operationId: UnprovisionApplicationType
export def "application-types-unprovision create" [
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  application_type_version: string # The version of the application type as defined in the application manifest.
  --async: oneof<nothing, bool> # The flag indicating whether or not unprovision should occur asynchronously. When set to true, the unprovision operation returns when the request is accepted by the system, and the unprovision operation continues without any timeout limit. The default value is false. However, we recommend setting it to true for large application packages that were provisioned.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_type_name: (encode-path-segment $application_type_name)} | format pattern "/ApplicationTypes/{application_type_name}/$/Unprovision") $qp)
  let req_body = {"ApplicationTypeVersion": $application_type_version, "Async": $async} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of applications created in the Service Fabric cluster that match the specified filters.
#
# GET /Applications
# operationId: GetApplicationInfoList
export def "applications get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.1)
  --application-definition-kind-filter: int # Used to filter on ApplicationDefinitionKind, which is the mechanism used to define a Service Fabric application. - Default - Default value, which performs the same function as selecting "All". The value is 0. - All - Filter that matches input with any ApplicationDefinitionKind value. The value is 65535. - ServiceFabricApplicationDescription - Filter that matches input with ApplicationDefinitionKind value ServiceFabricApplicationDescription. The value is 1. - Compose - Filter that matches input with ApplicationDefinitionKind value Compose. The value is 2. (default: 0)
  --application-type-name: string # The application type name used to filter the applications to query for. This value should not contain the application type version.
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: list, Status: string, TypeName: string, TypeVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationDefinitionKindFilter" $application_definition_kind_filter "scalar") (serialize-qp "ApplicationTypeName" $application_type_name "scalar") (serialize-qp "ExcludeApplicationParameters" $exclude_application_parameters "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ApplicationDefinitionKindFilter": $application_definition_kind_filter, "ApplicationTypeName": $application_type_name, "ExcludeApplicationParameters": $exclude_application_parameters, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Creates a Service Fabric application.
#
# POST /Applications/$/Create
# operationId: CreateApplication
# --ApplicationCapacity shape: {ApplicationMetrics?: list, MaximumNodes?: int, MinimumNodes?: int}
# --ManagedApplicationIdentity shape: {ManagedIdentities?: list, TokenServiceEndpoint?: string}
# --ParameterList item shape: {Key: string, Value: string}
export def "applications-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-capacity: any # Describes capacity information for services of this application. This description can be used for describing the following. - Reserving the capacity for the services on the nodes - Limiting the total number of nodes that services of this application can run on - Limiting the custom capacity metrics to limit the total consumption of this metric by the services of this application — shape: {ApplicationMetrics?: list, MaximumNodes?: int, MinimumNodes?: int}
  --managed-application-identity: any # Managed application identity description. — shape: {ManagedIdentities?: list, TokenServiceEndpoint?: string}
  name: string # The name of the application, including the 'fabric:' URI scheme.
  --parameter-list: list # List of application parameters with overridden values from their default values specified in the application manifest. — item shape: {Key: string, Value: string}
  type_name: string # The application type name as defined in the application manifest.
  type_version: string # The version of the application type as defined in the application manifest.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Applications/$/Create" $qp)
  let req_body = {"ApplicationCapacity": $application_capacity, "ManagedApplicationIdentity": $managed_application_identity, "Name": $name, "ParameterList": $parameter_list, "TypeName": $type_name, "TypeVersion": $type_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets information about a Service Fabric application.
#
# GET /Applications/{applicationId}
# operationId: GetApplicationInfo
export def "applications get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --exclude-application-parameters: oneof<nothing, bool> # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: table<Key: string, Value: string>, Status: string, TypeName: string, TypeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ExcludeApplicationParameters" $exclude_application_parameters "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ExcludeApplicationParameters": $exclude_application_parameters, "timeout": $timeout} | compact), body: null}
}

# Deletes an existing Service Fabric application.
#
# POST /Applications/{applicationId}/$/Delete
# operationId: DeleteApplication
export def "applications-delete delete" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --force-remove: oneof<nothing, bool> # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ForceRemove" $force_remove "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/Delete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ForceRemove": $force_remove, "timeout": $timeout} | compact), body: null}
}

# Disables periodic backup of Service Fabric application.
#
# POST /Applications/{applicationId}/$/DisableBackup
# operationId: DisableApplicationBackup
export def "applications-disable-backup disable" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --clean-backup: oneof<nothing, bool> # Boolean flag to delete backups. It can be set to true for deleting all the backups which were created for the backup entity that is getting disabled for backup.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/DisableBackup") $qp)
  let req_body = {"CleanBackup": $clean_backup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Enables periodic backup of stateful partitions under this Service Fabric application.
#
# POST /Applications/{applicationId}/$/EnableBackup
# operationId: EnableApplicationBackup
export def "applications-enable-backup enable" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_policy_name: string # Name of the backup policy to be used for enabling periodic backups.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/EnableBackup") $qp)
  let req_body = {"BackupPolicyName": $backup_policy_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the Service Fabric application backup configuration information.
#
# GET /Applications/{applicationId}/$/GetBackupConfigurationInfo
# operationId: GetApplicationBackupConfigurationInfo
export def "applications-get-backup-configuration-info get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetBackupConfigurationInfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Gets the list of backups available for every partition in this application.
#
# GET /Applications/{applicationId}/$/GetBackups
# operationId: GetApplicationBackupList
export def "applications-get-backups list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --latest: oneof<nothing, bool> # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --start-date-time-filter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --end-date-time-filter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "Latest" $latest "scalar") (serialize-qp "StartDateTimeFilter" $start_date_time_filter "scalar") (serialize-qp "EndDateTimeFilter" $end_date_time_filter "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetBackups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "Latest": $latest, "StartDateTimeFilter": $start_date_time_filter, "EndDateTimeFilter": $end_date_time_filter, "ContinuationToken": $continuation_token, "MaxResults": $max_results} | compact), body: null}
}

# Gets the health of the service fabric application.
#
# GET /Applications/{applicationId}/$/GetHealth
# operationId: GetApplicationHealth
export def "applications-get-health get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-applications-health-state-filter: int # Allows filtering of the deployed applications health state objects returned in the result of application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed applications that match the filter will be returned. All deployed applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of deployed applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --services-health-state-filter: int # Allows filtering of the services health state objects returned in the result of services health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only services that match the filter are returned. All services are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of services with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "DeployedApplicationsHealthStateFilter" $deployed_applications_health_state_filter "scalar") (serialize-qp "ServicesHealthStateFilter" $services_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "DeployedApplicationsHealthStateFilter": $deployed_applications_health_state_filter, "ServicesHealthStateFilter": $services_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: null}
}

# Gets the health of a Service Fabric application using the specified policy.
#
# POST /Applications/{applicationId}/$/GetHealth
# operationId: GetApplicationHealthUsingPolicy
# --DefaultServiceTypeHealthPolicy shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
# --ServiceTypeHealthPolicyMap item shape: {Key: string, Value: any}
export def "applications-get-health get-using-policy" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-applications-health-state-filter: int # Allows filtering of the deployed applications health state objects returned in the result of application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed applications that match the filter will be returned. All deployed applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of deployed applications with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --services-health-state-filter: int # Allows filtering of the services health state objects returned in the result of services health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only services that match the filter are returned. All services are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of services with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "DeployedApplicationsHealthStateFilter" $deployed_applications_health_state_filter "scalar") (serialize-qp "ServicesHealthStateFilter" $services_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetHealth") $qp)
  let req_body = {"ConsiderWarningAsError": $consider_warning_as_error, "DefaultServiceTypeHealthPolicy": $default_service_type_health_policy, "MaxPercentUnhealthyDeployedApplications": $max_percent_unhealthy_deployed_applications, "ServiceTypeHealthPolicyMap": $service_type_health_policy_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "DeployedApplicationsHealthStateFilter": $deployed_applications_health_state_filter, "ServicesHealthStateFilter": $services_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: $req_body}
}

# Gets load information about a Service Fabric application.
#
# GET /Applications/{applicationId}/$/GetLoadInformation
# operationId: GetApplicationLoadInfo
export def "applications-get-load-information get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationLoadMetricInformation: table<MaximumCapacity: int, Name: string, ReservationCapacity: int, TotalApplicationCapacity: int>, Id: string, MaximumNodes: int, MinimumNodes: int, NodeCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetLoadInformation") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the information about all services belonging to the application specified by the application ID.
#
# GET /Applications/{applicationId}/$/GetServices
# operationId: GetServiceInfoList
export def "applications-get-services get-list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-type-name: string # The service type name used to filter the services to query for.
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "ServiceTypeName" $service_type_name "scalar") (serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetServices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ServiceTypeName": $service_type_name, "api-version": $api_version, "ContinuationToken": $continuation_token, "timeout": $timeout} | compact), body: null}
}

# Creates the specified Service Fabric service.
#
# POST /Applications/{applicationId}/$/GetServices/$/Create
# Discriminator (request): ServiceKind
# operationId: CreateService
# --CorrelationScheme item shape: {Scheme: "Invalid"|"Affinity"|"AlignedAffinity"|"NonAlignedAffinity", ServiceName: string}
# --PartitionDescription shape: {PartitionScheme: "Invalid"|"Singleton"|"UniformInt64Range"|"Named"}
# --ScalingPolicies item shape: {ScalingMechanism: any, ScalingTrigger: any}
# --ServiceLoadMetrics item shape: {DefaultLoad?: int, Name: string, PrimaryDefaultLoad?: int, SecondaryDefaultLoad?: int, Weight?: "Zero"|"Low"|"Medium"|"High"}
# --ServicePlacementPolicies item shape: {Type: "Invalid"|"InvalidDomain"|"RequireDomain"|"PreferPrimaryDomain"|"RequireDomainDistribution"|"NonPartiallyPlaceService"}
export def "applications-get-services-create create" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-name: string # The name of the application, including the 'fabric:' URI scheme.
  --correlation-scheme: list # A list that describes the correlation of the service with other services. — item shape: {Scheme: "Invalid"|"Affinity"|"AlignedAffinity"|"NonAlignedAffinity", ServiceName: string}
  --default-move-cost: string@default-move-cost-completer # Specifies the move cost for the service.
  --initialization-data: list<int> # Array of bytes to be sent as an integer array. Each element of array is a number between 0 and 255.
  --is-default-move-cost-specified: oneof<nothing, bool> # Indicates if the DefaultMoveCost property is specified.
  partition_description: any # Describes how the service is partitioned. — shape: {PartitionScheme: "Invalid"|"Singleton"|"UniformInt64Range"|"Named"}
  --placement-constraints: string # The placement constraints as a string. Placement constraints are boolean expressions on node properties and allow for restricting a service to particular nodes based on the service requirements. For example, to place a service on nodes where NodeType is blue specify the following: "NodeColor == blue)".
  --scaling-policies: list # A list that describes the scaling policies. — item shape: {ScalingMechanism: any, ScalingTrigger: any}
  --service-dns-name: string # The DNS name of the service. It requires the DNS system service to be enabled in Service Fabric cluster.
  service_kind: string@service-kind-completer # The kind of service (Stateless or Stateful).
  --service-load-metrics: list # The service load metrics is given as an array of ServiceLoadMetricDescription objects. — item shape: {DefaultLoad?: int, Name: string, PrimaryDefaultLoad?: int, SecondaryDefaultLoad?: int, Weight?: "Zero"|"Low"|"Medium"|"High"}
  service_name: string # The full name of the service with 'fabric:' URI scheme.
  --service-package-activation-mode: string@service-package-activation-mode-completer # The activation mode of service package to be used for a Service Fabric service. This is specified at the time of creating the Service.
  --service-placement-policies: list # A list that describes the correlation of the service with other services. — item shape: {Type: "Invalid"|"InvalidDomain"|"RequireDomain"|"PreferPrimaryDomain"|"RequireDomainDistribution"|"NonPartiallyPlaceService"}
  service_type_name: string # Name of the service type as specified in the service manifest.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetServices/$/Create") $qp)
  let req_body = {"ApplicationName": $application_name, "CorrelationScheme": $correlation_scheme, "DefaultMoveCost": $default_move_cost, "InitializationData": $initialization_data, "IsDefaultMoveCostSpecified": $is_default_move_cost_specified, "PartitionDescription": $partition_description, "PlacementConstraints": $placement_constraints, "ScalingPolicies": $scaling_policies, "ServiceDnsName": $service_dns_name, "ServiceKind": $service_kind, "ServiceLoadMetrics": $service_load_metrics, "ServiceName": $service_name, "ServicePackageActivationMode": $service_package_activation_mode, "ServicePlacementPolicies": $service_placement_policies, "ServiceTypeName": $service_type_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Creates a Service Fabric service from the service template.
#
# POST /Applications/{applicationId}/$/GetServices/$/CreateFromTemplate
# operationId: CreateServiceFromTemplate
export def "applications-get-services-create-from-template create" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  application_name: string # The name of the application, including the 'fabric:' URI scheme.
  --initialization-data: list<int> # Array of bytes to be sent as an integer array. Each element of array is a number between 0 and 255.
  --service-dns-name: string # The DNS name of the service. It requires the DNS system service to be enabled in Service Fabric cluster.
  service_name: string # The full name of the service with 'fabric:' URI scheme.
  --service-package-activation-mode: string@service-package-activation-mode-completer # The activation mode of service package to be used for a Service Fabric service. This is specified at the time of creating the Service.
  service_type_name: string # Name of the service type as specified in the service manifest.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetServices/$/CreateFromTemplate") $qp)
  let req_body = {"ApplicationName": $application_name, "InitializationData": $initialization_data, "ServiceDnsName": $service_dns_name, "ServiceName": $service_name, "ServicePackageActivationMode": $service_package_activation_mode, "ServiceTypeName": $service_type_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the information about the specific service belonging to the Service Fabric application.
#
# GET /Applications/{applicationId}/$/GetServices/{serviceId}
# operationId: GetServiceInfo
export def "applications-get-services get" [
  application_id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id), service_id: (encode-path-segment $service_id)} | format pattern "/Applications/{application_id}/$/GetServices/{service_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets details for the latest upgrade performed on this application.
#
# GET /Applications/{applicationId}/$/GetUpgradeProgress
# operationId: GetApplicationUpgrade
export def "applications-get-upgrade-progress get" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, Name: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, TypeName: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list>, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, Name: string, Parameters: list<record>, RollingUpgradeMode: string, SortOrder: string, TargetApplicationTypeVersion: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string, UpgradeStatusDetails: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/GetUpgradeProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Resumes upgrading an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/MoveToNextUpgradeDomain
# operationId: ResumeApplicationUpgrade
export def "applications-move-to-next-upgrade-domain create-resume" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  upgrade_domain_name: string # The name of the upgrade domain in which to resume the upgrade.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/MoveToNextUpgradeDomain") $qp)
  let req_body = {"UpgradeDomainName": $upgrade_domain_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Sends a health report on the Service Fabric application.
#
# POST /Applications/{applicationId}/$/ReportHealth
# operationId: ReportApplicationHealth
export def "applications-report-health create" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/ReportHealth") $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Resumes periodic backup of a Service Fabric application which was previously suspended.
#
# POST /Applications/{applicationId}/$/ResumeBackup
# operationId: ResumeApplicationBackup
export def "applications-resume-backup create" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/ResumeBackup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Starts rolling back the currently on-going upgrade of an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/RollbackUpgrade
# operationId: RollbackApplicationUpgrade
export def "applications-rollback-upgrade create" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/RollbackUpgrade") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Suspends periodic backup for the specified Service Fabric application.
#
# POST /Applications/{applicationId}/$/SuspendBackup
# operationId: SuspendApplicationBackup
export def "applications-suspend-backup create" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/SuspendBackup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Updates an ongoing application upgrade in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/UpdateUpgrade
# operationId: UpdateApplicationUpgrade
# --ApplicationHealthPolicy shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
# --UpdateDescription shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", ForceRestart?: bool, HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, ReplicaSetCheckTimeoutInMilliseconds?: int, RollingUpgradeMode: "Invalid"|"UnmonitoredAuto"|"UnmonitoredManual"|"Monitored", UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
export def "applications-update-upgrade update" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy: any # Defines a health policy used to evaluate the health of an application or one of its children entities. — shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
  name: string # The name of the application, including the 'fabric:' URI scheme.
  --update-description: any # Describes the parameters for updating a rolling upgrade of application or cluster. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", ForceRestart?: bool, HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, ReplicaSetCheckTimeoutInMilliseconds?: int, RollingUpgradeMode: "Invalid"|"UnmonitoredAuto"|"UnmonitoredManual"|"Monitored", UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  upgrade_kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/UpdateUpgrade") $qp)
  let req_body = {"ApplicationHealthPolicy": $application_health_policy, "Name": $name, "UpdateDescription": $update_description, "UpgradeKind": $upgrade_kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Starts upgrading an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/Upgrade
# operationId: StartApplicationUpgrade
# --ApplicationHealthPolicy shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
# --MonitoringPolicy shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
# --Parameters item shape: {Key: string, Value: string}
export def "applications-upgrade start" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy: any # Defines a health policy used to evaluate the health of an application or one of its children entities. — shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
  --force-restart: oneof<nothing, bool> # If true, then processes are forcefully restarted during upgrade even when the code version has not changed (the upgrade only changes configuration or data). (default: false)
  --monitoring-policy: any # Describes the parameters for monitoring an upgrade in Monitored mode. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  name: string # The name of the target application, including the 'fabric:' URI scheme.
  --parameters: list # List of application parameters with overridden values from their default values specified in the application manifest. — item shape: {Key: string, Value: string}
  --rolling-upgrade-mode: string@rolling-upgrade-mode-completer # The mode used to monitor health during a rolling upgrade. The values are UnmonitoredAuto, UnmonitoredManual, and Monitored. (default: UnmonitoredAuto)
  --sort-order: string@sort-order-completer # Defines the order in which an upgrade proceeds through the cluster. (default: Default)
  target_application_type_version: string # The target application type version (found in the application manifest) for the application upgrade.
  upgrade_kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
  --upgrade-replica-set-check-timeout-in-seconds: int # The maximum amount of time to block processing of an upgrade domain and prevent loss of availability when there are unexpected issues. When this timeout expires, processing of the upgrade domain will proceed regardless of availability loss issues. The timeout is reset at the start of each upgrade domain. Valid values are between 0 and 42949672925 inclusive. (unsigned 32-bit integer). (format: int64, default: 42949672925)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/Applications/{application_id}/$/Upgrade") $qp)
  let req_body = {"ApplicationHealthPolicy": $application_health_policy, "ForceRestart": $force_restart, "MonitoringPolicy": $monitoring_policy, "Name": $name, "Parameters": $parameters, "RollingUpgradeMode": $rolling_upgrade_mode, "SortOrder": $sort_order, "TargetApplicationTypeVersion": $target_application_type_version, "UpgradeKind": $upgrade_kind, "UpgradeReplicaSetCheckTimeoutInSeconds": $upgrade_replica_set_check_timeout_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of backups available for the specified backed up entity at the specified backup location.
#
# POST /BackupRestore/$/GetBackups
# operationId: GetBackupsFromBackupLocation
# --BackupEntity shape: {EntityKind: "Invalid"|"Partition"|"Service"|"Application"}
# --Storage shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
export def "backup-restore-get-backups get-from-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  backup_entity: any # Describes the Service Fabric entity that is configured for backup. — shape: {EntityKind: "Invalid"|"Partition"|"Service"|"Application"}
  --end-date-time-filter: string # Specifies the end date time in ISO8601 till which to enumerate backups. If not specified, backups are enumerated till the end. (format: date-time)
  --latest: oneof<nothing, bool> # If specified as true, gets the most recent backup (within the specified time range) for every partition under the specified backup entity. (default: false)
  --start-date-time-filter: string # Specifies the start date time in ISO8601 from which to enumerate backups. If not specified, backups are enumerated from the beginning. (format: date-time)
  storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BackupRestore/$/GetBackups" $qp)
  let req_body = {"BackupEntity": $backup_entity, "EndDateTimeFilter": $end_date_time_filter, "Latest": $latest, "StartDateTimeFilter": $start_date_time_filter, "Storage": $storage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout, "ContinuationToken": $continuation_token, "MaxResults": $max_results} | compact), body: $req_body}
}

# Gets all the backup policies configured.
#
# GET /BackupRestore/BackupPolicies
# operationId: GetBackupPolicyList
export def "backup-restore-backup-policies get-policy-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record, Schedule: record, Storage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BackupRestore/BackupPolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Creates a backup policy.
#
# POST /BackupRestore/BackupPolicies/$/Create
# operationId: CreateBackupPolicy
# --RetentionPolicy shape: {RetentionPolicyType: "Basic"|"Invalid"}
# --Schedule shape: {ScheduleKind: "Invalid"|"TimeBased"|"FrequencyBased"}
# --Storage shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
export def "backup-restore-backup-policies-create create-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --auto-restore-on-data-loss: oneof<nothing, bool> # Specifies whether to trigger restore automatically using the latest available backup in case the partition experiences a data loss event.
  max_incremental_backups: int # Defines the maximum number of incremental backups to be taken between two full backups. This is just the upper limit. A full backup may be taken before specified number of incremental backups are completed in one of the following conditions - The replica has never taken a full backup since it has become primary, - Some of the log records since the last backup has been truncated, or - Replica passed the MaxAccumulatedBackupLogSizeInMB limit.
  name: string # The unique name identifying this backup policy.
  --retention-policy: any # Describes the retention policy configured. — shape: {RetentionPolicyType: "Basic"|"Invalid"}
  schedule: any # Describes the backup schedule parameters. — shape: {ScheduleKind: "Invalid"|"TimeBased"|"FrequencyBased"}
  storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BackupRestore/BackupPolicies/$/Create" $qp)
  let req_body = {"AutoRestoreOnDataLoss": $auto_restore_on_data_loss, "MaxIncrementalBackups": $max_incremental_backups, "Name": $name, "RetentionPolicy": $retention_policy, "Schedule": $schedule, "Storage": $storage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets a particular backup policy by name.
#
# GET /BackupRestore/BackupPolicies/{backupPolicyName}
# operationId: GetBackupPolicyByName
export def "backup-restore-backup-policies get-policy-by-name" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record<RetentionPolicyType: string>, Schedule: record<ScheduleKind: string>, Storage: record<FriendlyName: string, StorageKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($backup_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'backupPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({backup_policy_name: (encode-path-segment $backup_policy_name)} | format pattern "/BackupRestore/BackupPolicies/{backup_policy_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Deletes the backup policy.
#
# POST /BackupRestore/BackupPolicies/{backupPolicyName}/$/Delete
# operationId: DeleteBackupPolicy
export def "backup-restore-backup-policies-delete delete-policy" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($backup_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'backupPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({backup_policy_name: (encode-path-segment $backup_policy_name)} | format pattern "/BackupRestore/BackupPolicies/{backup_policy_name}/$/Delete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the list of backup entities that are associated with this policy.
#
# GET /BackupRestore/BackupPolicies/{backupPolicyName}/$/GetBackupEnabledEntities
# operationId: GetAllEntitiesBackedUpByPolicy
export def "backup-restore-backup-policies-get-backup-enabled-entities list-backed-up-by-policy" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<EntityKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($backup_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'backupPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({backup_policy_name: (encode-path-segment $backup_policy_name)} | format pattern "/BackupRestore/BackupPolicies/{backup_policy_name}/$/GetBackupEnabledEntities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Updates the backup policy.
#
# POST /BackupRestore/BackupPolicies/{backupPolicyName}/$/Update
# operationId: UpdateBackupPolicy
# --RetentionPolicy shape: {RetentionPolicyType: "Basic"|"Invalid"}
# --Schedule shape: {ScheduleKind: "Invalid"|"TimeBased"|"FrequencyBased"}
# --Storage shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
export def "backup-restore-backup-policies-update update-policy" [
  backup_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --auto-restore-on-data-loss: oneof<nothing, bool> # Specifies whether to trigger restore automatically using the latest available backup in case the partition experiences a data loss event.
  max_incremental_backups: int # Defines the maximum number of incremental backups to be taken between two full backups. This is just the upper limit. A full backup may be taken before specified number of incremental backups are completed in one of the following conditions - The replica has never taken a full backup since it has become primary, - Some of the log records since the last backup has been truncated, or - Replica passed the MaxAccumulatedBackupLogSizeInMB limit.
  name: string # The unique name identifying this backup policy.
  --retention-policy: any # Describes the retention policy configured. — shape: {RetentionPolicyType: "Basic"|"Invalid"}
  schedule: any # Describes the backup schedule parameters. — shape: {ScheduleKind: "Invalid"|"TimeBased"|"FrequencyBased"}
  storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($backup_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'backupPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({backup_policy_name: (encode-path-segment $backup_policy_name)} | format pattern "/BackupRestore/BackupPolicies/{backup_policy_name}/$/Update") $qp)
  let req_body = {"AutoRestoreOnDataLoss": $auto_restore_on_data_loss, "MaxIncrementalBackups": $max_incremental_backups, "Name": $name, "RetentionPolicy": $retention_policy, "Schedule": $schedule, "Storage": $storage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of compose deployments created in the Service Fabric cluster.
#
# GET /ComposeDeployments
# operationId: GetComposeDeploymentStatusList
export def "compose-deployments get-status-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, Name: string, Status: string, StatusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ComposeDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Creates a Service Fabric compose deployment.
#
# PUT /ComposeDeployments/$/Create
# operationId: CreateComposeDeployment
# --RegistryCredential shape: {PasswordEncrypted?: bool, RegistryPassword?: string, RegistryUserName?: string}
export def "compose-deployments-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  compose_file_content: string # The content of the compose file that describes the deployment to create.
  deployment_name: string # The name of the deployment.
  --registry-credential: any # Credential information to connect to container registry. — shape: {PasswordEncrypted?: bool, RegistryPassword?: string, RegistryUserName?: string}
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ComposeDeployments/$/Create" $qp)
  let req_body = {"ComposeFileContent": $compose_file_content, "DeploymentName": $deployment_name, "RegistryCredential": $registry_credential} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets information about a Service Fabric compose deployment.
#
# GET /ComposeDeployments/{deploymentName}
# operationId: GetComposeDeploymentStatus
export def "compose-deployments get-status" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationName: string, Name: string, Status: string, StatusDetails: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_name: (encode-path-segment $deployment_name)} | format pattern "/ComposeDeployments/{deployment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Deletes an existing Service Fabric compose deployment from cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/Delete
# operationId: RemoveComposeDeployment
export def "compose-deployments-delete delete" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_name: (encode-path-segment $deployment_name)} | format pattern "/ComposeDeployments/{deployment_name}/$/Delete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets details for the latest upgrade performed on this Service Fabric compose deployment.
#
# GET /ComposeDeployments/{deploymentName}/$/GetUpgradeProgress
# operationId: GetComposeDeploymentUpgradeProgress
export def "compose-deployments-get-upgrade-progress get" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record<MaxPercentUnhealthyPartitionsPerService: int, MaxPercentUnhealthyReplicasPerPartition: int, MaxPercentUnhealthyServices: int>, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list<record>>, ApplicationName: string, ApplicationUnhealthyEvaluations: table<HealthEvaluation: record>, ApplicationUpgradeStatusDetails: string, CurrentUpgradeDomainDuration: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, DeploymentName: string, FailureReason: string, FailureTimestampUtc: string, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDuration: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int, UpgradeState: string, UpgradeStatusDetails: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_name: (encode-path-segment $deployment_name)} | format pattern "/ComposeDeployments/{deployment_name}/$/GetUpgradeProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Starts rolling back a compose deployment upgrade in the Service Fabric cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/RollbackUpgrade
# operationId: StartRollbackComposeDeploymentUpgrade
export def "compose-deployments-rollback-upgrade start" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_name: (encode-path-segment $deployment_name)} | format pattern "/ComposeDeployments/{deployment_name}/$/RollbackUpgrade") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Starts upgrading a compose deployment in the Service Fabric cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/Upgrade
# operationId: StartComposeDeploymentUpgrade
# --ApplicationHealthPolicy shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
# --MonitoringPolicy shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
# --RegistryCredential shape: {PasswordEncrypted?: bool, RegistryPassword?: string, RegistryUserName?: string}
export def "compose-deployments-upgrade start" [
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-health-policy: any # Defines a health policy used to evaluate the health of an application or one of its children entities. — shape: {ConsiderWarningAsError?: bool, DefaultServiceTypeHealthPolicy?: any, MaxPercentUnhealthyDeployedApplications?: int, ServiceTypeHealthPolicyMap?: list}
  compose_file_content: string # The content of the compose file that describes the deployment to create.
  --body-deployment-name: string # The name of the deployment.
  --force-restart: oneof<nothing, bool> # If true, then processes are forcefully restarted during upgrade even when the code version has not changed (the upgrade only changes configuration or data). (default: false)
  --monitoring-policy: any # Describes the parameters for monitoring an upgrade in Monitored mode. — shape: {FailureAction?: "Invalid"|"Rollback"|"Manual", HealthCheckRetryTimeoutInMilliseconds?: string, HealthCheckStableDurationInMilliseconds?: string, HealthCheckWaitDurationInMilliseconds?: string, UpgradeDomainTimeoutInMilliseconds?: string, UpgradeTimeoutInMilliseconds?: string}
  --registry-credential: any # Credential information to connect to container registry. — shape: {PasswordEncrypted?: bool, RegistryPassword?: string, RegistryUserName?: string}
  --rolling-upgrade-mode: string@rolling-upgrade-mode-completer # The mode used to monitor health during a rolling upgrade. The values are UnmonitoredAuto, UnmonitoredManual, and Monitored. (default: UnmonitoredAuto)
  upgrade_kind: string@upgrade-kind-completer-1 # The kind of upgrade out of the following possible values. (default: Rolling)
  --upgrade-replica-set-check-timeout-in-seconds: int # The maximum amount of time to block processing of an upgrade domain and prevent loss of availability when there are unexpected issues. When this timeout expires, processing of the upgrade domain will proceed regardless of availability loss issues. The timeout is reset at the start of each upgrade domain. Valid values are between 0 and 42949672925 inclusive. (unsigned 32-bit integer). (format: int64, default: 42949672925)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($deployment_name | is-empty) { error make --unspanned { msg: "path parameter 'deploymentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({deployment_name: (encode-path-segment $deployment_name)} | format pattern "/ComposeDeployments/{deployment_name}/$/Upgrade") $qp)
  let req_body = {"ApplicationHealthPolicy": $application_health_policy, "ComposeFileContent": $compose_file_content, "DeploymentName": $body_deployment_name, "ForceRestart": $force_restart, "MonitoringPolicy": $monitoring_policy, "RegistryCredential": $registry_credential, "RollingUpgradeMode": $rolling_upgrade_mode, "UpgradeKind": $upgrade_kind, "UpgradeReplicaSetCheckTimeoutInSeconds": $upgrade_replica_set_check_timeout_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets all Applications-related events.
#
# GET /EventsStore/Applications/Events
# operationId: GetApplicationsEventList
export def "events-store-applications-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Applications/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets an Application-related events.
#
# GET /EventsStore/Applications/{applicationId}/$/Events
# operationId: GetApplicationEventList
export def "events-store-applications-events get-list" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/EventsStore/Applications/{application_id}/$/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets all Cluster-related events.
#
# GET /EventsStore/Cluster/Events
# operationId: GetClusterEventList
export def "events-store-cluster-events get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Cluster/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets all Containers-related events.
#
# GET /EventsStore/Containers/Events
# operationId: GetContainersEventList
export def "events-store-containers-events get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-6 # The version of the API. This parameter is required and its value must be '6.2-preview'. (default: 6.2-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Containers/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets all correlated events for a given event.
#
# GET /EventsStore/CorrelatedEvents/{eventInstanceId}/$/Events
# operationId: GetCorrelatedEventList
export def "events-store-correlated-events-events get-list" [
  event_instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_instance_id | is-empty) { error make --unspanned { msg: "path parameter 'eventInstanceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_instance_id: (encode-path-segment $event_instance_id)} | format pattern "/EventsStore/CorrelatedEvents/{event_instance_id}/$/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets all Nodes-related Events.
#
# GET /EventsStore/Nodes/Events
# operationId: GetNodesEventList
export def "events-store-nodes-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Nodes/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets a Node-related events.
#
# GET /EventsStore/Nodes/{nodeName}/$/Events
# operationId: GetNodeEventList
export def "events-store-nodes-events get-list" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/EventsStore/Nodes/{node_name}/$/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets all Partitions-related events.
#
# GET /EventsStore/Partitions/Events
# operationId: GetPartitionsEventList
export def "events-store-partitions-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Partitions/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets a Partition-related events.
#
# GET /EventsStore/Partitions/{partitionId}/$/Events
# operationId: GetPartitionEventList
export def "events-store-partitions-events get-list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/EventsStore/Partitions/{partition_id}/$/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets all Replicas-related events for a Partition.
#
# GET /EventsStore/Partitions/{partitionId}/$/Replicas/Events
# operationId: GetPartitionReplicasEventList
export def "events-store-partitions-replicas-events list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/EventsStore/Partitions/{partition_id}/$/Replicas/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets a Partition Replica-related events.
#
# GET /EventsStore/Partitions/{partitionId}/$/Replicas/{replicaId}/$/Events
# operationId: GetPartitionReplicaEventList
export def "events-store-partitions-replicas-events get-list" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/EventsStore/Partitions/{partition_id}/$/Replicas/{replica_id}/$/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets all Services-related events.
#
# GET /EventsStore/Services/Events
# operationId: GetServicesEventList
export def "events-store-services-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Services/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets a Service-related events.
#
# GET /EventsStore/Services/{serviceId}/$/Events
# operationId: GetServiceEventList
export def "events-store-services-events get-list" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --start-time-utc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --end-time-utc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --events-types-filter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --exclude-analysis-events: oneof<nothing, bool> # This param disables the retrieval of AnalysisEvents if true is passed.
  --skip-correlation-lookup: oneof<nothing, bool> # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "EventsTypesFilter" $events_types_filter "scalar") (serialize-qp "ExcludeAnalysisEvents" $exclude_analysis_events "scalar") (serialize-qp "SkipCorrelationLookup" $skip_correlation_lookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/EventsStore/Services/{service_id}/$/Events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "EventsTypesFilter": $events_types_filter, "ExcludeAnalysisEvents": $exclude_analysis_events, "SkipCorrelationLookup": $skip_correlation_lookup} | compact), body: null}
}

# Gets a list of user-induced fault operations filtered by provided input.
#
# GET /Faults/
# operationId: GetFaultOperationList
export def "faults get-operation-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --type-filter: int # Used to filter on OperationType for user-induced operations. - 65535 - select all - 1 - select PartitionDataLoss. - 2 - select PartitionQuorumLoss. - 4 - select PartitionRestart. - 8 - select NodeTransition. (default: 65535)
  --state-filter: int # Used to filter on OperationState's for user-induced operations. - 65535 - select All - 1 - select Running - 2 - select RollingBack - 8 - select Completed - 16 - select Faulted - 32 - select Cancelled - 64 - select ForceCancelled (default: 65535)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<OperationId: string, State: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "TypeFilter" $type_filter "scalar") (serialize-qp "StateFilter" $state_filter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Faults/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "TypeFilter": $type_filter, "StateFilter": $state_filter, "timeout": $timeout} | compact), body: null}
}

# Cancels a user-induced fault operation.
#
# POST /Faults/$/Cancel
# operationId: CancelOperation
export def "faults-cancel cancel-operation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --force: oneof<nothing, bool> # Indicates whether to gracefully roll back and clean up internal system state modified by executing the user-induced operation. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "Force" $force "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Faults/$/Cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "Force": $force, "timeout": $timeout} | compact), body: null}
}

# Gets the progress of an operation started using StartNodeTransition.
#
# GET /Faults/Nodes/{nodeName}/$/GetTransitionProgress
# operationId: GetNodeTransitionProgress
export def "faults-nodes-get-transition-progress get" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<NodeTransitionResult: record<ErrorCode: int, NodeResult: record<NodeInstanceId: string, NodeName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Faults/Nodes/{node_name}/$/GetTransitionProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "timeout": $timeout} | compact), body: null}
}

# Starts or stops a cluster node.
#
# POST /Faults/Nodes/{nodeName}/$/StartTransition/
# operationId: StartNodeTransition
export def "faults-nodes-start-transition start" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --node-transition-type: string@node-transition-type-completer # Indicates the type of transition to perform. NodeTransitionType.Start will start a stopped node. NodeTransitionType.Stop will stop a node that is up.
  --node-instance-id: string # The node instance ID of the target node. This can be determined through GetNodeInfo API.
  --stop-duration-in-seconds: int # The duration, in seconds, to keep the node stopped. The minimum value is 600, the maximum is 14400. After this time expires, the node will automatically come back up. (format: int32)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "NodeTransitionType" $node_transition_type "scalar") (serialize-qp "NodeInstanceId" $node_instance_id "scalar") (serialize-qp "StopDurationInSeconds" $stop_duration_in_seconds "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Faults/Nodes/{node_name}/$/StartTransition/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "NodeTransitionType": $node_transition_type, "NodeInstanceId": $node_instance_id, "StopDurationInSeconds": $stop_duration_in_seconds, "timeout": $timeout} | compact), body: null}
}

# Gets the progress of a partition data loss operation started using the StartDataLoss API.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetDataLossProgress
# operationId: GetDataLossProgress
export def "faults-services-get-partitions-get-data-loss-progress get" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<InvokeDataLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), partition_id: (encode-path-segment $partition_id)} | format pattern "/Faults/Services/{service_id}/$/GetPartitions/{partition_id}/$/GetDataLossProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "timeout": $timeout} | compact), body: null}
}

# Gets the progress of a quorum loss operation on a partition started using the StartQuorumLoss API.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetQuorumLossProgress
# operationId: GetQuorumLossProgress
export def "faults-services-get-partitions-get-quorum-loss-progress get" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<InvokeQuorumLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), partition_id: (encode-path-segment $partition_id)} | format pattern "/Faults/Services/{service_id}/$/GetPartitions/{partition_id}/$/GetQuorumLossProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "timeout": $timeout} | compact), body: null}
}

# Gets the progress of a PartitionRestart operation started using StartPartitionRestart.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetRestartProgress
# operationId: GetPartitionRestartProgress
export def "faults-services-get-partitions-get-restart-progress get" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<RestartPartitionResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), partition_id: (encode-path-segment $partition_id)} | format pattern "/Faults/Services/{service_id}/$/GetPartitions/{partition_id}/$/GetRestartProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "timeout": $timeout} | compact), body: null}
}

# This API will induce data loss for the specified partition. It will trigger a call to the OnDataLossAsync API of the partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartDataLoss
# operationId: StartDataLoss
export def "faults-services-get-partitions-start-data-loss start" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --data-loss-mode: string@data-loss-mode-completer # This enum is passed to the StartDataLoss API to indicate what type of data loss to induce.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "DataLossMode" $data_loss_mode "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), partition_id: (encode-path-segment $partition_id)} | format pattern "/Faults/Services/{service_id}/$/GetPartitions/{partition_id}/$/StartDataLoss") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "DataLossMode": $data_loss_mode, "timeout": $timeout} | compact), body: null}
}

# Induces quorum loss for a given stateful service partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartQuorumLoss
# operationId: StartQuorumLoss
export def "faults-services-get-partitions-start-quorum-loss start" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --quorum-loss-mode: string@quorum-loss-mode-completer # This enum is passed to the StartQuorumLoss API to indicate what type of quorum loss to induce.
  --quorum-loss-duration: int # The amount of time for which the partition will be kept in quorum loss. This must be specified in seconds.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "QuorumLossMode" $quorum_loss_mode "scalar") (serialize-qp "QuorumLossDuration" $quorum_loss_duration "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), partition_id: (encode-path-segment $partition_id)} | format pattern "/Faults/Services/{service_id}/$/GetPartitions/{partition_id}/$/StartQuorumLoss") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "QuorumLossMode": $quorum_loss_mode, "QuorumLossDuration": $quorum_loss_duration, "timeout": $timeout} | compact), body: null}
}

# This API will restart some or all replicas or instances of the specified partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartRestart
# operationId: StartPartitionRestart
export def "faults-services-get-partitions-start-restart start" [
  service_id: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --operation-id: string # A GUID that identifies a call of this API. This is passed into the corresponding GetProgress API (format: uuid)
  --restart-partition-mode: string@restart-partition-mode-completer # Describe which partitions to restart.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $operation_id "scalar") (serialize-qp "RestartPartitionMode" $restart_partition_mode "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), partition_id: (encode-path-segment $partition_id)} | format pattern "/Faults/Services/{service_id}/$/GetPartitions/{partition_id}/$/StartRestart") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "OperationId": $operation_id, "RestartPartitionMode": $restart_partition_mode, "timeout": $timeout} | compact), body: null}
}

# Gets the content information at the root of the image store.
#
# GET /ImageStore
# operationId: GetImageStoreRootContent
export def "image-store get-root-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Commit an image store upload session.
#
# POST /ImageStore/$/CommitUploadSession
# operationId: CommitImageStoreUploadSession
export def "image-store-commit-upload-session commit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/CommitUploadSession" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "session-id": $session_id, "timeout": $timeout} | compact), body: null}
}

# Copies image store content internally
#
# POST /ImageStore/$/Copy
# operationId: CopyImageStoreContent
export def "image-store-copy copy-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --check-mark-file: oneof<nothing, bool> # Indicates whether to check mark file during copying. The property is true if checking mark file is required, false otherwise. The mark file is used to check whether the folder is well constructed. If the property is true and mark file does not exist, the copy is skipped.
  remote_destination: string # The relative path of destination image store content to be copied to.
  remote_source: string # The relative path of source image store content to be copied from.
  --skip-files: list<string> # The list of the file names to be skipped for copying.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/Copy" $qp)
  let req_body = {"CheckMarkFile": $check_mark_file, "RemoteDestination": $remote_destination, "RemoteSource": $remote_source, "SkipFiles": $skip_files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Cancels an image store upload session.
#
# DELETE /ImageStore/$/DeleteUploadSession
# operationId: DeleteImageStoreUploadSession
export def "image-store-delete-upload-session delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/DeleteUploadSession" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "session-id": $session_id, "timeout": $timeout} | compact), body: null}
}

# Get the folder size at the root of the image store.
#
# GET /ImageStore/$/FolderSize
# operationId: GetImageStoreRootFolderSize
export def "image-store-folder-size get-root" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<FolderSize: string, StoreRelativePath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/FolderSize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Get the image store upload session by ID.
#
# GET /ImageStore/$/GetUploadSession
# operationId: GetImageStoreUploadSessionById
export def "image-store-get-upload-session get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/GetUploadSession" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "session-id": $session_id, "timeout": $timeout} | compact), body: null}
}

# Deletes existing image store content.
#
# DELETE /ImageStore/{contentPath}
# operationId: DeleteImageStoreContent
export def "image-store delete-content" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_path | is-empty) { error make --unspanned { msg: "path parameter 'contentPath' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_path: (encode-path-segment $content_path)} | format pattern "/ImageStore/{content_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the image store content information.
#
# GET /ImageStore/{contentPath}
# operationId: GetImageStoreContent
export def "image-store get-content" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_path | is-empty) { error make --unspanned { msg: "path parameter 'contentPath' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_path: (encode-path-segment $content_path)} | format pattern "/ImageStore/{content_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Uploads contents of the file to the image store.
#
# PUT /ImageStore/{contentPath}
# operationId: UploadFile
export def "image-store upload-file" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_path | is-empty) { error make --unspanned { msg: "path parameter 'contentPath' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_path: (encode-path-segment $content_path)} | format pattern "/ImageStore/{content_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Get the size of a folder in image store
#
# GET /ImageStore/{contentPath}/$/FolderSize
# operationId: GetImageStoreFolderSize
export def "image-store-folder-size get" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<FolderSize: string, StoreRelativePath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_path | is-empty) { error make --unspanned { msg: "path parameter 'contentPath' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_path: (encode-path-segment $content_path)} | format pattern "/ImageStore/{content_path}/$/FolderSize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Get the image store upload session by relative path.
#
# GET /ImageStore/{contentPath}/$/GetUploadSession
# operationId: GetImageStoreUploadSessionByPath
export def "image-store-get-upload-session get-by-path" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_path | is-empty) { error make --unspanned { msg: "path parameter 'contentPath' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_path: (encode-path-segment $content_path)} | format pattern "/ImageStore/{content_path}/$/GetUploadSession") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Uploads a file chunk to the image store relative path.
#
# PUT /ImageStore/{contentPath}/$/UploadChunk
# operationId: UploadFileChunk
export def "image-store-upload-chunk upload-file" [
  content_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --content-range: string # When uploading file chunks to the image store, the Content-Range header field need to be configured and sent with a request. The format should looks like "bytes {First-Byte-Position}-{Last-Byte-Position}/{File-Length}". For example, Content-Range:bytes 300-5000/20000 indicates that user is sending bytes 300 through 5,000 and the total file length is 20,000 bytes.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_path | is-empty) { error make --unspanned { msg: "path parameter 'contentPath' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_path: (encode-path-segment $content_path)} | format pattern "/ImageStore/{content_path}/$/UploadChunk") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Range": $content_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "session-id": $session_id, "timeout": $timeout} | compact), body: null}
}

# Creates a Service Fabric name.
#
# POST /Names/$/Create
# operationId: CreateName
export def "names-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  name: string # The Service Fabric name, including the 'fabric:' URI scheme.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Names/$/Create" $qp)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Deletes a Service Fabric name.
#
# DELETE /Names/{nameId}
# operationId: DeleteName
export def "names delete" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Returns whether the Service Fabric name exists.
#
# GET /Names/{nameId}
# operationId: GetNameExistsInfo
export def "names get-exists" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets information on all Service Fabric properties under a given name.
#
# GET /Names/{nameId}/$/GetProperties
# operationId: GetPropertyInfoList
export def "names-get-properties get-property-list" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --include-values: oneof<nothing, bool> # Allows specifying whether to include the values of the properties returned. True if values should be returned with the metadata; False to return only property metadata. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, IsConsistent: bool, Properties: table<Metadata: record, Name: string, Value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "IncludeValues" $include_values "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}/$/GetProperties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "IncludeValues": $include_values, "ContinuationToken": $continuation_token, "timeout": $timeout} | compact), body: null}
}

# Submits a property batch.
#
# POST /Names/{nameId}/$/GetProperties/$/SubmitBatch
# operationId: SubmitPropertyBatch
# --Operations item shape: {Kind: "Invalid"|"Put"|"Get"|"CheckExists"|"CheckSequence"|"Delete"|"CheckValue", PropertyName: string}
export def "names-get-properties-submit-batch submit-property" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --operations: list # A list of the property batch operations to be executed. — item shape: {Kind: "Invalid"|"Put"|"Get"|"CheckExists"|"CheckSequence"|"Delete"|"CheckValue", PropertyName: string}
]: any -> record<Properties: any, Kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}/$/GetProperties/$/SubmitBatch") $qp)
  let req_body = {"Operations": $operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Deletes the specified Service Fabric property.
#
# DELETE /Names/{nameId}/$/GetProperty
# operationId: DeleteProperty
export def "names-get-property delete" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --property-name: string # Specifies the name of the property to get.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PropertyName" $property_name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}/$/GetProperty") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "PropertyName": $property_name, "timeout": $timeout} | compact), body: null}
}

# Gets the specified Service Fabric property.
#
# GET /Names/{nameId}/$/GetProperty
# operationId: GetPropertyInfo
export def "names-get-property get" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --property-name: string # Specifies the name of the property to get.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Metadata: record<CustomTypeId: string, LastModifiedUtcTimestamp: string, Parent: string, SequenceNumber: string, SizeInBytes: int, TypeId: string>, Name: string, Value: record<Kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PropertyName" $property_name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}/$/GetProperty") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "PropertyName": $property_name, "timeout": $timeout} | compact), body: null}
}

# Creates or updates a Service Fabric property.
#
# PUT /Names/{nameId}/$/GetProperty
# operationId: PutProperty
# --Value shape: {Kind: "Invalid"|"Binary"|"Int64"|"Double"|"String"|"Guid"}
export def "names-get-property update" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --custom-type-id: string # The property's custom type ID. Using this property, the user is able to tag the type of the value of the property.
  property_name: string # The name of the Service Fabric property.
  value: any # Describes a Service Fabric property value. — shape: {Kind: "Invalid"|"Binary"|"Int64"|"Double"|"String"|"Guid"}
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}/$/GetProperty") $qp)
  let req_body = {"CustomTypeId": $custom_type_id, "PropertyName": $property_name, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Enumerates all the Service Fabric names under a given name.
#
# GET /Names/{nameId}/$/GetSubNames
# operationId: GetSubNameInfoList
export def "names-get-sub-names get-list" [
  name_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --recursive: oneof<nothing, bool> # Allows specifying that the search performed should be recursive. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, IsConsistent: bool, SubNames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_id | is-empty) { error make --unspanned { msg: "path parameter 'nameId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Recursive" $recursive "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_id: (encode-path-segment $name_id)} | format pattern "/Names/{name_id}/$/GetSubNames") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "Recursive": $recursive, "ContinuationToken": $continuation_token, "timeout": $timeout} | compact), body: null}
}

# Gets the list of nodes in the Service Fabric cluster.
#
# GET /Nodes
# operationId: GetNodeInfoList
export def "nodes get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-8 # The version of the API. This parameter is required and its value must be '6.3'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.3)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --node-status-filter: string@node-status-filter-completer # Allows filtering the nodes based on the NodeStatus. Only the nodes that are matching the specified filter value will be returned. The filter value can be one of the following. (default: default)
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "NodeStatusFilter" $node_status_filter "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "NodeStatusFilter": $node_status_filter, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Gets the information about a specific node in the Service Fabric cluster.
#
# GET /Nodes/{nodeName}
# operationId: GetNodeInfo
export def "nodes get" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record<Id: string>, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record<NodeDeactivationIntent: string, NodeDeactivationStatus: string, NodeDeactivationTask: list<record>, PendingSafetyChecks: list<record>>, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Activate a Service Fabric cluster node that is currently deactivated.
#
# POST /Nodes/{nodeName}/$/Activate
# operationId: EnableNode
export def "nodes-activate enable" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/Activate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Deactivate a Service Fabric cluster node with the specified deactivation intent.
#
# POST /Nodes/{nodeName}/$/Deactivate
# operationId: DisableNode
export def "nodes-deactivate disable" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --deactivation-intent: string@deactivation-intent-completer # Describes the intent or reason for deactivating the node. The possible values are following.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/Deactivate") $qp)
  let req_body = {"DeactivationIntent": $deactivation_intent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Downloads all of the code packages associated with specified service manifest on the specified node.
#
# POST /Nodes/{nodeName}/$/DeployServicePackage
# operationId: DeployServicePackageToNode
# --PackageSharingPolicy item shape: {PackageSharingScope?: "None"|"All"|"Code"|"Config"|"Data", SharedPackageName?: string}
export def "nodes-deploy-service-package create" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  application_type_name: string # The application type name as defined in the application manifest.
  application_type_version: string # The version of the application type as defined in the application manifest.
  --body-node-name: string # The name of a Service Fabric node.
  --package-sharing-policy: list # List of package sharing policy information. — item shape: {PackageSharingScope?: "None"|"All"|"Code"|"Config"|"Data", SharedPackageName?: string}
  service_manifest_name: string # The name of the service manifest.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/DeployServicePackage") $qp)
  let req_body = {"ApplicationTypeName": $application_type_name, "ApplicationTypeVersion": $application_type_version, "NodeName": $body_node_name, "PackageSharingPolicy": $package_sharing_policy, "ServiceManifestName": $service_manifest_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of applications deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications
# operationId: GetDeployedApplicationInfoList
export def "nodes-get-applications get-deployed-list" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.1)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --include-health-state: oneof<nothing, bool> # Include the health state of an entity. If this parameter is false or not specified, then the health state returned is "Unknown". When set to true, the query goes in parallel to the node and the health system service before the results are merged. As a result, the query is more expensive and may take a longer time. (default: false)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> record<ContinuationToken: string, Items: table<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "IncludeHealthState" $include_health_state "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/GetApplications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "IncludeHealthState": $include_health_state, "ContinuationToken": $continuation_token, "MaxResults": $max_results} | compact), body: null}
}

# Gets the information about an application deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}
# operationId: GetDeployedApplicationInfo
export def "nodes-get-applications get-deployed" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.1)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --include-health-state: oneof<nothing, bool> # Include the health state of an entity. If this parameter is false or not specified, then the health state returned is "Unknown". When set to true, the query goes in parallel to the node and the health system service before the results are merged. As a result, the query is more expensive and may take a longer time. (default: false)
]: nothing -> record<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "IncludeHealthState" $include_health_state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "IncludeHealthState": $include_health_state} | compact), body: null}
}

# Gets the list of code packages deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages
# operationId: GetDeployedCodePackageInfoList
export def "nodes-get-applications-get-code-packages get-deployed-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --code-package-name: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<HostIsolationMode: string, HostType: string, MainEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Name: string, RunFrequencyInterval: string, ServiceManifestName: string, ServicePackageActivationId: string, SetupEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Status: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $service_manifest_name "scalar") (serialize-qp "CodePackageName" $code_package_name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetCodePackages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ServiceManifestName": $service_manifest_name, "CodePackageName": $code_package_name, "timeout": $timeout} | compact), body: null}
}

# Invoke container API on a container deployed on a Service Fabric node.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerApi
# operationId: InvokeContainerApi
export def "nodes-get-applications-get-code-packages-container-api create-invoke" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --code-package-name: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster.
  --code-package-instance-id: string # ID that uniquely identifies a code package instance deployed on a service fabric node.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --body: string # HTTP request body of container REST API
  --content-type: string # Content type of container REST API request, defaults to "application/json"
  --http-verb: string # HTTP verb of container REST API, defaults to "GET"
  uri_path: string # URI path of container REST API
]: any -> record<ContainerApiResult: record<Body: string, Content_Encoding: string, Content_Type: string, Status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $service_manifest_name "scalar") (serialize-qp "CodePackageName" $code_package_name "scalar") (serialize-qp "CodePackageInstanceId" $code_package_instance_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetCodePackages/$/ContainerApi") $qp)
  let req_body = {"Body": $body, "Content-Type": $content_type, "HttpVerb": $http_verb, "UriPath": $uri_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "ServiceManifestName": $service_manifest_name, "CodePackageName": $code_package_name, "CodePackageInstanceId": $code_package_instance_id, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the container logs for container deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerLogs
# operationId: GetContainerLogsDeployedOnNode
export def "nodes-get-applications-get-code-packages-container-logs get-deployed" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --code-package-name: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster.
  --tail: string # Number of lines to show from the end of the logs. Default is 100. 'all' to show the complete logs.
  --previous: oneof<nothing, bool> # Specifies whether to get container logs from exited/dead containers of the code package instance. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $service_manifest_name "scalar") (serialize-qp "CodePackageName" $code_package_name "scalar") (serialize-qp "Tail" $tail "scalar") (serialize-qp "Previous" $previous "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetCodePackages/$/ContainerLogs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ServiceManifestName": $service_manifest_name, "CodePackageName": $code_package_name, "Tail": $tail, "Previous": $previous, "timeout": $timeout} | compact), body: null}
}

# Restarts a code package deployed on a Service Fabric node in a cluster.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/Restart
# operationId: RestartDeployedCodePackage
export def "nodes-get-applications-get-code-packages-restart restart-deployed" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  code_package_instance_id: string # The instance ID for current running entry point. For a code package setup entry point (if specified) runs first and after it finishes main entry point is started. Each time entry point executable is run, its instance id will change.
  code_package_name: string # The name of the code package defined in the service manifest.
  service_manifest_name: string # The name of the service manifest.
  --service-package-activation-id: string # The ActivationId of a deployed service package. If ServicePackageActivationMode specified at the time of creating the service is 'SharedProcess' (or if it is not specified, in which case it defaults to 'SharedProcess'), then value of ServicePackageActivationId is always an empty string.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetCodePackages/$/Restart") $qp)
  let req_body = {"CodePackageInstanceId": $code_package_instance_id, "CodePackageName": $code_package_name, "ServiceManifestName": $service_manifest_name, "ServicePackageActivationId": $service_package_activation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the information about health of an application deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth
# operationId: GetDeployedApplicationHealth
export def "nodes-get-applications-get-health get-deployed" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-service-packages-health-state-filter: int # Allows filtering of the deployed service package health state objects returned in the result of deployed application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed service packages that match the filter are returned. All deployed service packages are used to evaluate the aggregated health state of the deployed application. If not specified, all entries are returned. The state values are flag-based enumeration, so the value can be a combination of these values, obtained using the bitwise 'OR' operator. For example, if the provided value is 6 then health state of service packages with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "DeployedServicePackagesHealthStateFilter" $deployed_service_packages_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "DeployedServicePackagesHealthStateFilter": $deployed_service_packages_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: null}
}

# Gets the information about health of an application deployed on a Service Fabric node. using the specified policy.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth
# operationId: GetDeployedApplicationHealthUsingPolicy
# --DefaultServiceTypeHealthPolicy shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
# --ServiceTypeHealthPolicyMap item shape: {Key: string, Value: any}
export def "nodes-get-applications-get-health get-deployed-using-policy" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --deployed-service-packages-health-state-filter: int # Allows filtering of the deployed service package health state objects returned in the result of deployed application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed service packages that match the filter are returned. All deployed service packages are used to evaluate the aggregated health state of the deployed application. If not specified, all entries are returned. The state values are flag-based enumeration, so the value can be a combination of these values, obtained using the bitwise 'OR' operator. For example, if the provided value is 6 then health state of service packages with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "DeployedServicePackagesHealthStateFilter" $deployed_service_packages_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetHealth") $qp)
  let req_body = {"ConsiderWarningAsError": $consider_warning_as_error, "DefaultServiceTypeHealthPolicy": $default_service_type_health_policy, "MaxPercentUnhealthyDeployedApplications": $max_percent_unhealthy_deployed_applications, "ServiceTypeHealthPolicyMap": $service_type_health_policy_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "DeployedServicePackagesHealthStateFilter": $deployed_service_packages_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of replicas deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetReplicas
# operationId: GetDeployedServiceReplicaInfoList
export def "nodes-get-applications-get-replicas get-deployed-service-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --partition-id: string # The identity of the partition. (format: uuid)
  --service-manifest-name: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Address: string, CodePackageName: string, HostProcessId: string, PartitionId: string, ReplicaStatus: string, ServiceKind: string, ServiceManifestName: string, ServiceName: string, ServicePackageActivationId: string, ServiceTypeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PartitionId" $partition_id "scalar") (serialize-qp "ServiceManifestName" $service_manifest_name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetReplicas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "PartitionId": $partition_id, "ServiceManifestName": $service_manifest_name, "timeout": $timeout} | compact), body: null}
}

# Gets the list of service packages deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages
# operationId: GetDeployedServicePackageInfoList
export def "nodes-get-applications-get-service-packages get-deployed-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Name: string, ServicePackageActivationId: string, Status: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetServicePackages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the list of service packages deployed on a Service Fabric node matching exactly the specified name.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}
# operationId: GetDeployedServicePackageInfoListByName
export def "nodes-get-applications-get-service-packages get-deployed-list-by-name" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Name: string, ServicePackageActivationId: string, Status: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  if ($service_package_name | is-empty) { error make --unspanned { msg: "path parameter 'servicePackageName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id), service_package_name: (encode-path-segment $service_package_name)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetServicePackages/{service_package_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the information about health of a service package for a specific application deployed for a Service Fabric node and application.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth
# operationId: GetDeployedServicePackageHealth
export def "nodes-get-applications-get-service-packages-get-health get-deployed" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  if ($service_package_name | is-empty) { error make --unspanned { msg: "path parameter 'servicePackageName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id), service_package_name: (encode-path-segment $service_package_name)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetServicePackages/{service_package_name}/$/GetHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "timeout": $timeout} | compact), body: null}
}

# Gets the information about health of service package for a specific application deployed on a Service Fabric node using the specified policy.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth
# operationId: GetDeployedServicePackageHealthUsingPolicy
# --DefaultServiceTypeHealthPolicy shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
# --ServiceTypeHealthPolicyMap item shape: {Key: string, Value: any}
export def "nodes-get-applications-get-service-packages-get-health get-deployed-using-policy" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  if ($service_package_name | is-empty) { error make --unspanned { msg: "path parameter 'servicePackageName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id), service_package_name: (encode-path-segment $service_package_name)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetServicePackages/{service_package_name}/$/GetHealth") $qp)
  let req_body = {"ConsiderWarningAsError": $consider_warning_as_error, "DefaultServiceTypeHealthPolicy": $default_service_type_health_policy, "MaxPercentUnhealthyDeployedApplications": $max_percent_unhealthy_deployed_applications, "ServiceTypeHealthPolicyMap": $service_type_health_policy_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "timeout": $timeout} | compact), body: $req_body}
}

# Sends a health report on the Service Fabric deployed service package.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/ReportHealth
# operationId: ReportDeployedServicePackageHealth
export def "nodes-get-applications-get-service-packages-report-health create-deployed" [
  node_name: string
  application_id: string
  service_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  if ($service_package_name | is-empty) { error make --unspanned { msg: "path parameter 'servicePackageName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id), service_package_name: (encode-path-segment $service_package_name)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetServicePackages/{service_package_name}/$/ReportHealth") $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list containing the information about service types from the applications deployed on a node in a Service Fabric cluster.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes
# operationId: GetDeployedServiceTypeInfoList
export def "nodes-get-applications-get-service-types get-deployed-list" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --service-manifest-name: string # The name of the service manifest to filter the list of deployed service type information. If specified, the response will only contain the information about service types that are defined in this service manifest.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $service_manifest_name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetServiceTypes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ServiceManifestName": $service_manifest_name, "timeout": $timeout} | compact), body: null}
}

# Gets the information about a specified service type of the application deployed on a node in a Service Fabric cluster.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes/{serviceTypeName}
# operationId: GetDeployedServiceTypeInfoByName
export def "nodes-get-applications-get-service-types get-deployed-by-name" [
  node_name: string
  application_id: string
  service_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --service-manifest-name: string # The name of the service manifest to filter the list of deployed service type information. If specified, the response will only contain the information about service types that are defined in this service manifest.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  if ($service_type_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $service_manifest_name "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id), service_type_name: (encode-path-segment $service_type_name)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/GetServiceTypes/{service_type_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ServiceManifestName": $service_manifest_name, "timeout": $timeout} | compact), body: null}
}

# Sends a health report on the Service Fabric application deployed on a Service Fabric node.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/ReportHealth
# operationId: ReportDeployedApplicationHealth
export def "nodes-get-applications-report-health create-deployed" [
  node_name: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), application_id: (encode-path-segment $application_id)} | format pattern "/Nodes/{node_name}/$/GetApplications/{application_id}/$/ReportHealth") $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the health of a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetHealth
# operationId: GetNodeHealth
export def "nodes-get-health get" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/GetHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "timeout": $timeout} | compact), body: null}
}

# Gets the health of a Service Fabric node, by using the specified health policy.
#
# POST /Nodes/{nodeName}/$/GetHealth
# operationId: GetNodeHealthUsingPolicy
# --ApplicationTypeHealthPolicyMap item shape: {Key: string, Value: int}
export def "nodes-get-health get-using-policy" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --application-type-health-policy-map: list # Defines a map with max percentage unhealthy applications for specific application types. Each entry specifies as key the application type name and as value an integer that represents the MaxPercentUnhealthyApplications percentage used to evaluate the applications of the specified application type. The application type health policy map can be used during cluster health evaluation to describe special application types. The application types included in the map are evaluated against the percentage specified in the map, and not with the global MaxPercentUnhealthyApplications defined in the cluster health policy. The applications of application types specified in the map are not counted against the global pool of applications. For example, if some applications of a type are critical, the cluster administrator can add an entry to the map for that application type and assign it a value of 0% (that is, do not tolerate any failures). All other applications can be evaluated with MaxPercentUnhealthyApplications set to 20% to tolerate some failures out of the thousands of application instances. The application type health policy map is used only if the cluster manifest enables application type health evaluation using the configuration entry for HealthManager/EnableApplicationTypeHealthEvaluation. — item shape: {Key: string, Value: int}
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --max-percent-unhealthy-applications: int # The maximum allowed percentage of unhealthy applications before reporting an error. For example, to allow 10% of applications to be unhealthy, this value would be 10. The percentage represents the maximum tolerated percentage of applications that can be unhealthy before the cluster is considered in error. If the percentage is respected but there is at least one unhealthy application, the health is evaluated as Warning. This is calculated by dividing the number of unhealthy applications over the total number of application instances in the cluster, excluding applications of application types that are included in the ApplicationTypeHealthPolicyMap. The computation rounds up to tolerate one failure on small numbers of applications. Default percentage is zero. (default: 0)
  --max-percent-unhealthy-nodes: int # The maximum allowed percentage of unhealthy nodes before reporting an error. For example, to allow 10% of nodes to be unhealthy, this value would be 10. The percentage represents the maximum tolerated percentage of nodes that can be unhealthy before the cluster is considered in error. If the percentage is respected but there is at least one unhealthy node, the health is evaluated as Warning. The percentage is calculated by dividing the number of unhealthy nodes over the total number of nodes in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. In large clusters, some nodes will always be down or out for repairs, so this percentage should be configured to tolerate that. (default: 0)
]: any -> record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/GetHealth") $qp)
  let req_body = {"ApplicationTypeHealthPolicyMap": $application_type_health_policy_map, "ConsiderWarningAsError": $consider_warning_as_error, "MaxPercentUnhealthyApplications": $max_percent_unhealthy_applications, "MaxPercentUnhealthyNodes": $max_percent_unhealthy_nodes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the load information of a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetLoadInformation
# operationId: GetNodeLoadInfo
export def "nodes-get-load-information get" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<NodeLoadMetricInformation: table<BufferedNodeCapacityRemaining: string, CurrentNodeLoad: string, IsCapacityViolation: bool, Name: string, NodeBufferedCapacity: string, NodeCapacity: string, NodeCapacityRemaining: string, NodeLoad: string, NodeRemainingBufferedCapacity: string, NodeRemainingCapacity: string, PlannedNodeLoadRemoval: string>, NodeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/GetLoadInformation") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the details of replica deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas
# operationId: GetDeployedServiceReplicaDetailInfoByPartitionId
export def "nodes-get-partitions-get-replicas get-deployed-service-detail" [
  node_name: string
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), partition_id: (encode-path-segment $partition_id)} | format pattern "/Nodes/{node_name}/$/GetPartitions/{partition_id}/$/GetReplicas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Removes a service replica running on a node.
#
# POST /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Delete
# operationId: RemoveReplica
export def "nodes-get-partitions-get-replicas-delete delete" [
  node_name: string
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --force-remove: oneof<nothing, bool> # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ForceRemove" $force_remove "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/Nodes/{node_name}/$/GetPartitions/{partition_id}/$/GetReplicas/{replica_id}/$/Delete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ForceRemove": $force_remove, "timeout": $timeout} | compact), body: null}
}

# Gets the details of replica deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetDetail
# operationId: GetDeployedServiceReplicaDetailInfo
export def "nodes-get-partitions-get-replicas-get-detail get-deployed-service" [
  node_name: string
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/Nodes/{node_name}/$/GetPartitions/{partition_id}/$/GetReplicas/{replica_id}/$/GetDetail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Restarts a service replica of a persisted service running on a node.
#
# POST /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Restart
# operationId: RestartReplica
export def "nodes-get-partitions-get-replicas-restart restart" [
  node_name: string
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name), partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/Nodes/{node_name}/$/GetPartitions/{partition_id}/$/GetReplicas/{replica_id}/$/Restart") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Notifies Service Fabric that the persisted state on a node has been permanently removed or lost.
#
# POST /Nodes/{nodeName}/$/RemoveNodeState
# operationId: RemoveNodeState
export def "nodes-remove-node-state delete" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/RemoveNodeState") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Sends a health report on the Service Fabric node.
#
# POST /Nodes/{nodeName}/$/ReportHealth
# operationId: ReportNodeHealth
export def "nodes-report-health create" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/ReportHealth") $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Restarts a Service Fabric cluster node.
#
# POST /Nodes/{nodeName}/$/Restart
# operationId: RestartNode
export def "nodes-restart restart" [
  node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --create-fabric-dump: string@create-fabric-dump-completer # Specify True to create a dump of the fabric node process. This is case-sensitive. (default: False)
  node_instance_id: string # The instance ID of the target node. If instance ID is specified the node is restarted only if it matches with the current instance of the node. A default value of "0" would match any instance ID. The instance ID can be obtained using get node query. (default: 0)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_name | is-empty) { error make --unspanned { msg: "path parameter 'nodeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_name: (encode-path-segment $node_name)} | format pattern "/Nodes/{node_name}/$/Restart") $qp)
  let req_body = {"CreateFabricDump": $create_fabric_dump, "NodeInstanceId": $node_instance_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the information about a Service Fabric partition.
#
# GET /Partitions/{partitionId}
# operationId: GetPartitionInfo
export def "partitions get" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<HealthState: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, PartitionStatus: string, ServiceKind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Triggers backup of the partition's state.
#
# POST /Partitions/{partitionId}/$/Backup
# operationId: BackupPartition
# --BackupStorage shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
export def "partitions-backup create" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --backup-timeout: int # Specifies the maximum amount of time, in minutes, to wait for the backup operation to complete. Post that, the operation completes with timeout error. However, in certain corner cases it could be that though the operation returns back timeout, the backup actually goes through. In case of timeout error, its recommended to invoke this operation again with a greater timeout value. The default value for the same is 10 minutes. (default: 10)
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --backup-storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "BackupTimeout" $backup_timeout "scalar") (serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/Backup") $qp)
  let req_body = {"BackupStorage": $backup_storage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"BackupTimeout": $backup_timeout, "api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Disables periodic backup of Service Fabric partition which was previously enabled.
#
# POST /Partitions/{partitionId}/$/DisableBackup
# operationId: DisablePartitionBackup
export def "partitions-disable-backup disable" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --clean-backup: oneof<nothing, bool> # Boolean flag to delete backups. It can be set to true for deleting all the backups which were created for the backup entity that is getting disabled for backup.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/DisableBackup") $qp)
  let req_body = {"CleanBackup": $clean_backup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Enables periodic backup of the stateful persisted partition.
#
# POST /Partitions/{partitionId}/$/EnableBackup
# operationId: EnablePartitionBackup
export def "partitions-enable-backup enable" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_policy_name: string # Name of the backup policy to be used for enabling periodic backups.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/EnableBackup") $qp)
  let req_body = {"BackupPolicyName": $backup_policy_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the partition backup configuration information
#
# GET /Partitions/{partitionId}/$/GetBackupConfigurationInfo
# operationId: GetPartitionBackupConfigurationInfo
export def "partitions-get-backup-configuration-info get" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ServiceName: string, Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record<IsSuspended: bool, SuspensionInheritedFrom: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetBackupConfigurationInfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets details for the latest backup triggered for this partition.
#
# GET /Partitions/{partitionId}/$/GetBackupProgress
# operationId: GetPartitionBackupProgress
export def "partitions-get-backup-progress get" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<BackupId: string, BackupLocation: string, BackupState: string, EpochOfLastBackupRecord: record<ConfigurationVersion: string, DataLossVersion: string>, FailureError: record<Code: string, Message: string>, LsnOfLastBackupRecord: string, TimeStampUtc: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetBackupProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the list of backups available for the specified partition.
#
# GET /Partitions/{partitionId}/$/GetBackups
# operationId: GetPartitionBackupList
export def "partitions-get-backups list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --latest: oneof<nothing, bool> # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --start-date-time-filter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --end-date-time-filter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "Latest" $latest "scalar") (serialize-qp "StartDateTimeFilter" $start_date_time_filter "scalar") (serialize-qp "EndDateTimeFilter" $end_date_time_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetBackups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "Latest": $latest, "StartDateTimeFilter": $start_date_time_filter, "EndDateTimeFilter": $end_date_time_filter} | compact), body: null}
}

# Gets the health of the specified Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetHealth
# operationId: GetPartitionHealth
export def "partitions-get-health get" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --replicas-health-state-filter: int # Allows filtering the collection of ReplicaHealthState objects on the partition. The value can be obtained from members or bitwise operations on members of HealthStateFilter. Only replicas that match the filter will be returned. All replicas will be used to evaluate the aggregated health state. If not specified, all entries will be returned.The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) will be returned. The possible values for this parameter include integer value of one of the following health states. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "ReplicasHealthStateFilter" $replicas_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "ReplicasHealthStateFilter": $replicas_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: null}
}

# Gets the health of the specified Service Fabric partition, by using the specified health policy.
#
# POST /Partitions/{partitionId}/$/GetHealth
# operationId: GetPartitionHealthUsingPolicy
# --DefaultServiceTypeHealthPolicy shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
# --ServiceTypeHealthPolicyMap item shape: {Key: string, Value: any}
export def "partitions-get-health get-using-policy" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --replicas-health-state-filter: int # Allows filtering the collection of ReplicaHealthState objects on the partition. The value can be obtained from members or bitwise operations on members of HealthStateFilter. Only replicas that match the filter will be returned. All replicas will be used to evaluate the aggregated health state. If not specified, all entries will be returned.The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) will be returned. The possible values for this parameter include integer value of one of the following health states. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "ReplicasHealthStateFilter" $replicas_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetHealth") $qp)
  let req_body = {"ConsiderWarningAsError": $consider_warning_as_error, "DefaultServiceTypeHealthPolicy": $default_service_type_health_policy, "MaxPercentUnhealthyDeployedApplications": $max_percent_unhealthy_deployed_applications, "ServiceTypeHealthPolicyMap": $service_type_health_policy_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "ReplicasHealthStateFilter": $replicas_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the load information of the specified Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetLoadInformation
# operationId: GetPartitionLoadInformation
export def "partitions-get-load-information get" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, PrimaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>, SecondaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetLoadInformation") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the information about replicas of a Service Fabric service partition.
#
# GET /Partitions/{partitionId}/$/GetReplicas
# operationId: GetReplicaInfoList
export def "partitions-get-replicas get-list" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetReplicas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "timeout": $timeout} | compact), body: null}
}

# Gets the information about a replica of a Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetReplicas/{replicaId}
# operationId: GetReplicaInfo
export def "partitions-get-replicas get" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/Partitions/{partition_id}/$/GetReplicas/{replica_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the health of a Service Fabric stateful service replica or stateless service instance.
#
# GET /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth
# operationId: GetReplicaHealth
export def "partitions-get-replicas-get-health get" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/Partitions/{partition_id}/$/GetReplicas/{replica_id}/$/GetHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "timeout": $timeout} | compact), body: null}
}

# Gets the health of a Service Fabric stateful service replica or stateless service instance using the specified policy.
#
# POST /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth
# operationId: GetReplicaHealthUsingPolicy
# --DefaultServiceTypeHealthPolicy shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
# --ServiceTypeHealthPolicyMap item shape: {Key: string, Value: any}
export def "partitions-get-replicas-get-health get-using-policy" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/Partitions/{partition_id}/$/GetReplicas/{replica_id}/$/GetHealth") $qp)
  let req_body = {"ConsiderWarningAsError": $consider_warning_as_error, "DefaultServiceTypeHealthPolicy": $default_service_type_health_policy, "MaxPercentUnhealthyDeployedApplications": $max_percent_unhealthy_deployed_applications, "ServiceTypeHealthPolicyMap": $service_type_health_policy_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "timeout": $timeout} | compact), body: $req_body}
}

# Sends a health report on the Service Fabric replica.
#
# POST /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/ReportHealth
# operationId: ReportReplicaHealth
export def "partitions-get-replicas-report-health create" [
  partition_id: string
  replica_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --service-kind: string@service-kind-completer-1 # The kind of service replica (Stateless or Stateful) for which the health is being reported. Following are the possible values. (default: Stateful)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  if ($replica_id | is-empty) { error make --unspanned { msg: "path parameter 'replicaId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceKind" $service_kind "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id), replica_id: (encode-path-segment $replica_id)} | format pattern "/Partitions/{partition_id}/$/GetReplicas/{replica_id}/$/ReportHealth") $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "ServiceKind": $service_kind, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Gets details for the latest restore operation triggered for this partition.
#
# GET /Partitions/{partitionId}/$/GetRestoreProgress
# operationId: GetPartitionRestoreProgress
export def "partitions-get-restore-progress get" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<FailureError: record<Code: string, Message: string>, RestoreState: string, RestoredEpoch: record<ConfigurationVersion: string, DataLossVersion: string>, RestoredLsn: string, TimeStampUtc: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetRestoreProgress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the name of the Service Fabric service for a partition.
#
# GET /Partitions/{partitionId}/$/GetServiceName
# operationId: GetServiceNameInfo
export def "partitions-get-service-name get" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Id: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/GetServiceName") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Moves the primary replica of a partition of a stateful service.
#
# POST /Partitions/{partitionId}/$/MovePrimaryReplica
# operationId: MovePrimaryReplica
export def "partitions-move-primary-replica move" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --node-name: string # The name of the node.
  --ignore-constraints: oneof<nothing, bool> # Ignore constraints when moving a replica. If this parameter is not specified, all constraints are honored. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "NodeName" $node_name "scalar") (serialize-qp "IgnoreConstraints" $ignore_constraints "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/MovePrimaryReplica") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "NodeName": $node_name, "IgnoreConstraints": $ignore_constraints, "timeout": $timeout} | compact), body: null}
}

# Moves the secondary replica of a partition of a stateful service.
#
# POST /Partitions/{partitionId}/$/MoveSecondaryReplica
# operationId: MoveSecondaryReplica
export def "partitions-move-secondary-replica move" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --current-node-name: string # The name of the source node for secondary replica move.
  --new-node-name: string # The name of the target node for secondary replica move. If not specified, replica is moved to a random node.
  --ignore-constraints: oneof<nothing, bool> # Ignore constraints when moving a replica. If this parameter is not specified, all constraints are honored. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "CurrentNodeName" $current_node_name "scalar") (serialize-qp "NewNodeName" $new_node_name "scalar") (serialize-qp "IgnoreConstraints" $ignore_constraints "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/MoveSecondaryReplica") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "CurrentNodeName": $current_node_name, "NewNodeName": $new_node_name, "IgnoreConstraints": $ignore_constraints, "timeout": $timeout} | compact), body: null}
}

# Indicates to the Service Fabric cluster that it should attempt to recover a specific partition that is currently stuck in quorum loss.
#
# POST /Partitions/{partitionId}/$/Recover
# operationId: RecoverPartition
export def "partitions-recover create" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/Recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Sends a health report on the Service Fabric partition.
#
# POST /Partitions/{partitionId}/$/ReportHealth
# operationId: ReportPartitionHealth
export def "partitions-report-health create" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/ReportHealth") $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Resets the current load of a Service Fabric partition.
#
# POST /Partitions/{partitionId}/$/ResetLoad
# operationId: ResetPartitionLoad
export def "partitions-reset-load reset" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/ResetLoad") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Triggers restore of the state of the partition using the specified restore partition description.
#
# POST /Partitions/{partitionId}/$/Restore
# operationId: RestorePartition
# --BackupStorage shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
export def "partitions-restore create" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --restore-timeout: int # Specifies the maximum amount of time to wait, in minutes, for the restore operation to complete. Post that, the operation returns back with timeout error. However, in certain corner cases it could be that the restore operation goes through even though it completes with timeout. In case of timeout error, its recommended to invoke this operation again with a greater timeout value. the default value for the same is 10 minutes. (default: 10)
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_id: string # Unique backup ID. (format: uuid)
  backup_location: string # Location of the backup relative to the backup storage specified/ configured.
  --backup-storage: any # Describes the parameters for the backup storage. — shape: {FriendlyName?: string, StorageKind: "Invalid"|"FileShare"|"AzureBlobStore"}
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "RestoreTimeout" $restore_timeout "scalar") (serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/Restore") $qp)
  let req_body = {"BackupId": $backup_id, "BackupLocation": $backup_location, "BackupStorage": $backup_storage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"RestoreTimeout": $restore_timeout, "api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Resumes periodic backup of partition which was previously suspended.
#
# POST /Partitions/{partitionId}/$/ResumeBackup
# operationId: ResumePartitionBackup
export def "partitions-resume-backup create" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/ResumeBackup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Suspends periodic backup for the specified partition.
#
# POST /Partitions/{partitionId}/$/SuspendBackup
# operationId: SuspendPartitionBackup
export def "partitions-suspend-backup create" [
  partition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partition_id | is-empty) { error make --unspanned { msg: "path parameter 'partitionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partition_id: (encode-path-segment $partition_id)} | format pattern "/Partitions/{partition_id}/$/SuspendBackup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Lists all the application resources.
#
# GET /Resources/Applications
# operationId: MeshApplication_List
export def "resources-applications list-mesh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<identity: record, name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the Application resource.
#
# DELETE /Resources/Applications/{applicationResourceName}
# operationId: MeshApplication_Delete
export def "resources-applications delete-mesh" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name)} | format pattern "/Resources/Applications/{application_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the Application resource with the given name.
#
# GET /Resources/Applications/{applicationResourceName}
# operationId: MeshApplication_Get
export def "resources-applications get-mesh" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name)} | format pattern "/Resources/Applications/{application_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a Application resource.
#
# PUT /Resources/Applications/{applicationResourceName}
# operationId: MeshApplication_CreateOrUpdate
# --identity shape: {principalId?: string, tenantId?: string, tokenServiceEndpoint?: string, type: string, userAssignedIdentities?: record}
# --properties shape: {debugParams?: string, description?: string, diagnostics?: any, healthState?: "Invalid"|"Ok"|"Warning"|"Error"|"Unknown", services?: list, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed"}
export def "resources-applications create-mesh-or-update" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  --identity: any # Information describing the identities associated with this application. — shape: {principalId?: string, tenantId?: string, tokenServiceEndpoint?: string, type: string, userAssignedIdentities?: record}
  name: string # Name of the Application resource.
  properties: any # Describes properties of a application resource. — shape: {debugParams?: string, description?: string, diagnostics?: any, healthState?: "Invalid"|"Ok"|"Warning"|"Error"|"Unknown", services?: list, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed"}
]: any -> record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name)} | format pattern "/Resources/Applications/{application_resource_name}") $qp)
  let req_body = {"identity": $identity, "name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all the service resources.
#
# GET /Resources/Applications/{applicationResourceName}/Services
# operationId: MeshService_List
export def "resources-applications-services list-mesh" [
  application_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name)} | format pattern "/Resources/Applications/{application_resource_name}/Services") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the Service resource with the given name.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}
# operationId: MeshService_Get
export def "resources-applications-services get-mesh" [
  application_resource_name: string
  service_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<codePackages: list<record>, diagnostics: record<enabled: bool, sinkRefs: list>, networkRefs: list<record>, osType: string, autoScalingPolicies: list<record>, description: string, healthState: string, identityRefs: list<record>, replicaCount: int, status: string, statusDetails: string, unhealthyEvaluation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  if ($service_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name), service_resource_name: (encode-path-segment $service_resource_name)} | format pattern "/Resources/Applications/{application_resource_name}/Services/{service_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists all the replicas of a service.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas
# operationId: MeshServiceReplica_List
export def "resources-applications-services-replicas list-mesh" [
  application_resource_name: string
  service_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<replicaName: string, codePackages: list, diagnostics: record, networkRefs: list, osType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  if ($service_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name), service_resource_name: (encode-path-segment $service_resource_name)} | format pattern "/Resources/Applications/{application_resource_name}/Services/{service_resource_name}/Replicas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the given replica of the service of an application.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}
# operationId: MeshServiceReplica_Get
export def "resources-applications-services-replicas get-mesh" [
  application_resource_name: string
  service_resource_name: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<replicaName: string, codePackages: table<commands: list, diagnostics: record, endpoints: list, entrypoint: string, environmentVariables: list, image: string, imageRegistryCredential: record, instanceView: record, labels: list, name: string, reliableCollectionsRefs: list, resources: record, settings: list, volumeRefs: list, volumes: list>, diagnostics: record<enabled: bool, sinkRefs: list<string>>, networkRefs: table<endpointRefs: list, name: string>, osType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  if ($service_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceResourceName' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replicaName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name), service_resource_name: (encode-path-segment $service_resource_name), replica_name: (encode-path-segment $replica_name)} | format pattern "/Resources/Applications/{application_resource_name}/Services/{service_resource_name}/Replicas/{replica_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the logs from the container.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}/CodePackages/{codePackageName}/Logs
# operationId: MeshCodePackage_GetContainerLogs
export def "resources-applications-services-replicas-code-packages-logs get-mesh-container" [
  application_resource_name: string
  service_resource_name: string
  replica_name: string
  code_package_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  --tail: string # Number of lines to show from the end of the logs. Default is 100. 'all' to show the complete logs.
]: nothing -> record<Content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationResourceName' must be non-empty" } }
  if ($service_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceResourceName' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replicaName' must be non-empty" } }
  if ($code_package_name | is-empty) { error make --unspanned { msg: "path parameter 'codePackageName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_resource_name: (encode-path-segment $application_resource_name), service_resource_name: (encode-path-segment $service_resource_name), replica_name: (encode-path-segment $replica_name), code_package_name: (encode-path-segment $code_package_name)} | format pattern "/Resources/Applications/{application_resource_name}/Services/{service_resource_name}/Replicas/{replica_name}/CodePackages/{code_package_name}/Logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "Tail": $tail} | compact), body: null}
}

# Lists all the gateway resources.
#
# GET /Resources/Gateways
# operationId: MeshGateway_List
export def "resources-gateways list-mesh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Gateways" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the Gateway resource.
#
# DELETE /Resources/Gateways/{gatewayResourceName}
# operationId: MeshGateway_Delete
export def "resources-gateways delete-mesh" [
  gateway_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'gatewayResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({gateway_resource_name: (encode-path-segment $gateway_resource_name)} | format pattern "/Resources/Gateways/{gateway_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the Gateway resource with the given name.
#
# GET /Resources/Gateways/{gatewayResourceName}
# operationId: MeshGateway_Get
export def "resources-gateways get-mesh" [
  gateway_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'gatewayResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({gateway_resource_name: (encode-path-segment $gateway_resource_name)} | format pattern "/Resources/Gateways/{gateway_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a Gateway resource.
#
# PUT /Resources/Gateways/{gatewayResourceName}
# operationId: MeshGateway_CreateOrUpdate
# --properties shape: {description?: string, destinationNetwork: any, http?: list, sourceNetwork: any, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", tcp?: list}
export def "resources-gateways create-mesh-or-update" [
  gateway_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  name: string # Name of the Gateway resource.
  properties: any # Describes properties of a gateway resource. — shape: {description?: string, destinationNetwork: any, http?: list, sourceNetwork: any, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", tcp?: list}
]: any -> record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($gateway_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'gatewayResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({gateway_resource_name: (encode-path-segment $gateway_resource_name)} | format pattern "/Resources/Gateways/{gateway_resource_name}") $qp)
  let req_body = {"name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all the network resources.
#
# GET /Resources/Networks
# operationId: MeshNetwork_List
export def "resources-networks list-mesh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the Network resource.
#
# DELETE /Resources/Networks/{networkResourceName}
# operationId: MeshNetwork_Delete
export def "resources-networks delete-mesh" [
  network_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($network_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'networkResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_resource_name: (encode-path-segment $network_resource_name)} | format pattern "/Resources/Networks/{network_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the Network resource with the given name.
#
# GET /Resources/Networks/{networkResourceName}
# operationId: MeshNetwork_Get
export def "resources-networks get-mesh" [
  network_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<description: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($network_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'networkResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_resource_name: (encode-path-segment $network_resource_name)} | format pattern "/Resources/Networks/{network_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a Network resource.
#
# PUT /Resources/Networks/{networkResourceName}
# operationId: MeshNetwork_CreateOrUpdate
# --properties shape: {description?: string, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", kind: "Local"}
export def "resources-networks create-mesh-or-update" [
  network_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  name: string # Name of the Network resource.
  properties: record # Describes properties of a network resource. — shape: {description?: string, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", kind: "Local"}
]: any -> record<name: string, properties: record<description: string, status: string, statusDetails: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($network_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'networkResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_resource_name: (encode-path-segment $network_resource_name)} | format pattern "/Resources/Networks/{network_resource_name}") $qp)
  let req_body = {"name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all the secret resources.
#
# GET /Resources/Secrets
# operationId: MeshSecret_List
export def "resources-secrets list-mesh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the Secret resource.
#
# DELETE /Resources/Secrets/{secretResourceName}
# operationId: MeshSecret_Delete
export def "resources-secrets delete-mesh" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the Secret resource with the given name.
#
# GET /Resources/Secrets/{secretResourceName}
# operationId: MeshSecret_Get
export def "resources-secrets get-mesh" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a Secret resource.
#
# PUT /Resources/Secrets/{secretResourceName}
# operationId: MeshSecret_CreateOrUpdate
# --properties shape: {contentType?: string, description?: string, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", kind: "inlinedValue"}
export def "resources-secrets create-mesh-or-update" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  name: string # Name of the Secret resource.
  properties: record # Describes the properties of a secret resource. — shape: {contentType?: string, description?: string, status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed", kind: "inlinedValue"}
]: any -> record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}") $qp)
  let req_body = {"name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# List names of all values of the specified secret resource.
#
# GET /Resources/Secrets/{secretResourceName}/values
# operationId: MeshSecretValue_List
export def "resources-secrets-values list-mesh" [
  secret_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}/values") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the specified value of the named secret resource.
#
# DELETE /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# operationId: MeshSecretValue_Delete
export def "resources-secrets-values delete-mesh" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  if ($secret_value_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretValueResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name), secret_value_resource_name: (encode-path-segment $secret_value_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}/values/{secret_value_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the specified secret value resource.
#
# GET /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# operationId: MeshSecretValue_Get
export def "resources-secrets-values get-mesh" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  if ($secret_value_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretValueResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name), secret_value_resource_name: (encode-path-segment $secret_value_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}/values/{secret_value_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Adds the specified value as a new version of the specified secret resource.
#
# PUT /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# operationId: MeshSecretValue_AddValue
export def "resources-secrets-values create-mesh" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  name: string # Version identifier of the secret value.
  properties: any # This type describes properties of a secret value resource.
]: any -> record<name: string, properties: record<value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  if ($secret_value_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretValueResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name), secret_value_resource_name: (encode-path-segment $secret_value_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}/values/{secret_value_resource_name}") $qp)
  let req_body = {"name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists the specified value of the secret resource.
#
# POST /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}/list_value
# operationId: MeshSecretValue_Show
export def "resources-secrets-values-list-value create-mesh-show" [
  secret_resource_name: string
  secret_value_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretResourceName' must be non-empty" } }
  if ($secret_value_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'secretValueResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_resource_name: (encode-path-segment $secret_resource_name), secret_value_resource_name: (encode-path-segment $secret_value_resource_name)} | format pattern "/Resources/Secrets/{secret_resource_name}/values/{secret_value_resource_name}/list_value") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists all the volume resources.
#
# GET /Resources/Volumes
# operationId: MeshVolume_List
export def "resources-volumes list-mesh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the Volume resource.
#
# DELETE /Resources/Volumes/{volumeResourceName}
# operationId: MeshVolume_Delete
export def "resources-volumes delete-mesh" [
  volume_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'volumeResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_resource_name: (encode-path-segment $volume_resource_name)} | format pattern "/Resources/Volumes/{volume_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the Volume resource with the given name.
#
# GET /Resources/Volumes/{volumeResourceName}
# operationId: MeshVolume_Get
export def "resources-volumes get-mesh" [
  volume_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'volumeResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_resource_name: (encode-path-segment $volume_resource_name)} | format pattern "/Resources/Volumes/{volume_resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates or updates a Volume resource.
#
# PUT /Resources/Volumes/{volumeResourceName}
# operationId: MeshVolume_CreateOrUpdate
# --properties shape: {azureFileParameters?: any, description?: string, provider: "SFAzureFile", status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed"}
export def "resources-volumes create-mesh-or-update" [
  volume_resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  name: string # Name of the Volume resource.
  properties: any # Describes properties of a volume resource. — shape: {azureFileParameters?: any, description?: string, provider: "SFAzureFile", status?: "Unknown"|"Ready"|"Upgrading"|"Creating"|"Deleting"|"Failed"}
]: any -> record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_resource_name | is-empty) { error make --unspanned { msg: "path parameter 'volumeResourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_resource_name: (encode-path-segment $volume_resource_name)} | format pattern "/Resources/Volumes/{volume_resource_name}") $qp)
  let req_body = {"name": $name, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Indicates to the Service Fabric cluster that it should attempt to recover the specified service that is currently stuck in quorum loss.
#
# POST /Services/$/{serviceId}/$/GetPartitions/$/Recover
# operationId: RecoverServicePartitions
export def "services-get-partitions-recover create" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/$/{service_id}/$/GetPartitions/$/Recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Deletes an existing Service Fabric service.
#
# POST /Services/{serviceId}/$/Delete
# operationId: DeleteService
export def "services-delete delete" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --force-remove: oneof<nothing, bool> # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ForceRemove" $force_remove "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/Delete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ForceRemove": $force_remove, "timeout": $timeout} | compact), body: null}
}

# Disables periodic backup of Service Fabric service which was previously enabled.
#
# POST /Services/{serviceId}/$/DisableBackup
# operationId: DisableServiceBackup
export def "services-disable-backup disable" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --clean-backup: oneof<nothing, bool> # Boolean flag to delete backups. It can be set to true for deleting all the backups which were created for the backup entity that is getting disabled for backup.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/DisableBackup") $qp)
  let req_body = {"CleanBackup": $clean_backup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Enables periodic backup of stateful partitions under this Service Fabric service.
#
# POST /Services/{serviceId}/$/EnableBackup
# operationId: EnableServiceBackup
export def "services-enable-backup enable" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  backup_policy_name: string # Name of the backup policy to be used for enabling periodic backups.
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/EnableBackup") $qp)
  let req_body = {"BackupPolicyName": $backup_policy_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the name of the Service Fabric application for a service.
#
# GET /Services/{serviceId}/$/GetApplicationName
# operationId: GetApplicationNameInfo
export def "services-get-application-name get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Id: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetApplicationName") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the Service Fabric service backup configuration information.
#
# GET /Services/{serviceId}/$/GetBackupConfigurationInfo
# operationId: GetServiceBackupConfigurationInfo
export def "services-get-backup-configuration-info get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetBackupConfigurationInfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Gets the list of backups available for every partition in this service.
#
# GET /Services/{serviceId}/$/GetBackups
# operationId: GetServiceBackupList
export def "services-get-backups list" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --latest: oneof<nothing, bool> # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --start-date-time-filter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --end-date-time-filter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "Latest" $latest "scalar") (serialize-qp "StartDateTimeFilter" $start_date_time_filter "scalar") (serialize-qp "EndDateTimeFilter" $end_date_time_filter "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "MaxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetBackups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout, "Latest": $latest, "StartDateTimeFilter": $start_date_time_filter, "EndDateTimeFilter": $end_date_time_filter, "ContinuationToken": $continuation_token, "MaxResults": $max_results} | compact), body: null}
}

# Gets the description of an existing Service Fabric service.
#
# GET /Services/{serviceId}/$/GetDescription
# operationId: GetServiceDescription
export def "services-get-description get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationName: string, CorrelationScheme: table<Scheme: string, ServiceName: string>, DefaultMoveCost: string, InitializationData: list<int>, IsDefaultMoveCostSpecified: bool, PartitionDescription: record<PartitionScheme: string>, PlacementConstraints: string, ScalingPolicies: table<ScalingMechanism: record, ScalingTrigger: record>, ServiceDnsName: string, ServiceKind: string, ServiceLoadMetrics: table<DefaultLoad: int, Name: string, PrimaryDefaultLoad: int, SecondaryDefaultLoad: int, Weight: string>, ServiceName: string, ServicePackageActivationMode: string, ServicePlacementPolicies: table<Type: string>, ServiceTypeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetDescription") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the health of the specified Service Fabric service.
#
# GET /Services/{serviceId}/$/GetHealth
# operationId: GetServiceHealth
export def "services-get-health get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --partitions-health-state-filter: int # Allows filtering of the partitions health state objects returned in the result of service health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only partitions that match the filter are returned. All partitions are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these value obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of partitions with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "PartitionsHealthStateFilter" $partitions_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "PartitionsHealthStateFilter": $partitions_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: null}
}

# Gets the health of the specified Service Fabric service, by using the specified health policy.
#
# POST /Services/{serviceId}/$/GetHealth
# operationId: GetServiceHealthUsingPolicy
# --DefaultServiceTypeHealthPolicy shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
# --ServiceTypeHealthPolicyMap item shape: {Key: string, Value: any}
export def "services-get-health get-using-policy" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --events-health-state-filter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --partitions-health-state-filter: int # Allows filtering of the partitions health state objects returned in the result of service health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only partitions that match the filter are returned. All partitions are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these value obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of partitions with HealthState value of OK (2) and Warning (4) will be returned. - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --exclude-health-statistics: oneof<nothing, bool> # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --consider-warning-as-error: oneof<nothing, bool> # Indicates whether warnings are treated with the same severity as errors. (default: false)
  --default-service-type-health-policy: any # Represents the health policy used to evaluate the health of services belonging to a service type. — shape: {MaxPercentUnhealthyPartitionsPerService?: int, MaxPercentUnhealthyReplicasPerPartition?: int, MaxPercentUnhealthyServices?: int}
  --max-percent-unhealthy-deployed-applications: int # The maximum allowed percentage of unhealthy deployed applications. Allowed values are Byte values from zero to 100. The percentage represents the maximum tolerated percentage of deployed applications that can be unhealthy before the application is considered in error. This is calculated by dividing the number of unhealthy deployed applications over the number of nodes where the application is currently deployed on in the cluster. The computation rounds up to tolerate one failure on small numbers of nodes. Default percentage is zero. (default: 0)
  --service-type-health-policy-map: list # Defines a ServiceTypeHealthPolicy per service type name. The entries in the map replace the default service type health policy for each specified service type. For example, in an application that contains both a stateless gateway service type and a stateful engine service type, the health policies for the stateless and stateful services can be configured differently. With policy per service type, there's more granular control of the health of the service. If no policy is specified for a service type name, the DefaultServiceTypeHealthPolicy is used for evaluation. — item shape: {Key: string, Value: any}
]: any -> record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $events_health_state_filter "scalar") (serialize-qp "PartitionsHealthStateFilter" $partitions_health_state_filter "scalar") (serialize-qp "ExcludeHealthStatistics" $exclude_health_statistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetHealth") $qp)
  let req_body = {"ConsiderWarningAsError": $consider_warning_as_error, "DefaultServiceTypeHealthPolicy": $default_service_type_health_policy, "MaxPercentUnhealthyDeployedApplications": $max_percent_unhealthy_deployed_applications, "ServiceTypeHealthPolicyMap": $service_type_health_policy_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "EventsHealthStateFilter": $events_health_state_filter, "PartitionsHealthStateFilter": $partitions_health_state_filter, "ExcludeHealthStatistics": $exclude_health_statistics, "timeout": $timeout} | compact), body: $req_body}
}

# Gets the list of partitions of a Service Fabric service.
#
# GET /Services/{serviceId}/$/GetPartitions
# operationId: GetPartitionInfoList
export def "services-get-partitions get-list" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<HealthState: string, PartitionInformation: record, PartitionStatus: string, ServiceKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetPartitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "timeout": $timeout} | compact), body: null}
}

# Gets the information about unplaced replica of the service.
#
# GET /Services/{serviceId}/$/GetUnplacedReplicaInformation
# operationId: GetUnplacedReplicaInformation
export def "services-get-unplaced-replica-information get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --partition-id: string # The identity of the partition. (format: uuid)
  --only-query-primaries: oneof<nothing, bool> # Indicates that unplaced replica information will be queries only for primary replicas. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ServiceName: string, UnplacedReplicaDetails: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PartitionId" $partition_id "scalar") (serialize-qp "OnlyQueryPrimaries" $only_query_primaries "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/GetUnplacedReplicaInformation") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "PartitionId": $partition_id, "OnlyQueryPrimaries": $only_query_primaries, "timeout": $timeout} | compact), body: null}
}

# Sends a health report on the Service Fabric service.
#
# POST /Services/{serviceId}/$/ReportHealth
# operationId: ReportServiceHealth
export def "services-report-health create" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --immediate: oneof<nothing, bool> # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --description: string # The description of the health information. It represents free text used to add human readable information about the report. The maximum string length for the description is 4096 characters. If the provided string is longer, it will be automatically truncated. When truncated, the last characters of the description contain a marker "[Truncated]", and total string size is 4096 characters. The presence of the marker indicates to users that truncation occurred. Note that when truncated, the description has less than 4096 characters from the original string.
  health_state: string@health-state-completer # The health state of a Service Fabric entity such as Cluster, Node, Application, Service, Partition, Replica etc.
  property: string # The property of the health information. An entity can have health reports for different properties. The property is a string and not a fixed enumeration to allow the reporter flexibility to categorize the state condition that triggers the report. For example, a reporter with SourceId "LocalWatchdog" can monitor the state of the available disk on a node, so it can report "AvailableDisk" property on that node. The same reporter can monitor the node connectivity, so it can report a property "Connectivity" on the same node. In the health store, these reports are treated as separate health events for the specified node. Together with the SourceId, the property uniquely identifies the health information.
  --remove-when-expired: oneof<nothing, bool> # Value that indicates whether the report is removed from health store when it expires. If set to true, the report is removed from the health store after it expires. If set to false, the report is treated as an error when expired. The value of this property is false by default. When clients report periodically, they should set RemoveWhenExpired false (default). This way, if the reporter has issues (e.g. deadlock) and can't report, the entity is evaluated at error when the health report expires. This flags the entity as being in Error health state.
  --sequence-number: string # The sequence number for this health report as a numeric string. The report sequence number is used by the health store to detect stale reports. If not specified, a sequence number is auto-generated by the health client when a report is added.
  source_id: string # The source name that identifies the client/watchdog/system component that generated the health information.
  --time-to-live-in-milli-seconds: string # The duration for which this health report is valid. This field uses ISO8601 format for specifying the duration. When clients report periodically, they should send reports with higher frequency than time to live. If clients report on transition, they can set the time to live to infinite. When time to live expires, the health event that contains the health information is either removed from health store, if RemoveWhenExpired is true, or evaluated at error, if RemoveWhenExpired false. If not specified, time to live defaults to infinite value. (format: duration)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/ReportHealth") $qp)
  let req_body = {"Description": $description, "HealthState": $health_state, "Property": $property, "RemoveWhenExpired": $remove_when_expired, "SequenceNumber": $sequence_number, "SourceId": $source_id, "TimeToLiveInMilliSeconds": $time_to_live_in_milli_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "Immediate": $immediate, "timeout": $timeout} | compact), body: $req_body}
}

# Resolve a Service Fabric partition.
#
# GET /Services/{serviceId}/$/ResolvePartition
# operationId: ResolveService
export def "services-resolve-partition get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --partition-key-type: int # Key type for the partition. This parameter is required if the partition scheme for the service is Int64Range or Named. The possible values are following. - None (1) - Indicates that the PartitionKeyValue parameter is not specified. This is valid for the partitions with partitioning scheme as Singleton. This is the default value. The value is 1. - Int64Range (2) - Indicates that the PartitionKeyValue parameter is an int64 partition key. This is valid for the partitions with partitioning scheme as Int64Range. The value is 2. - Named (3) - Indicates that the PartitionKeyValue parameter is a name of the partition. This is valid for the partitions with partitioning scheme as Named. The value is 3.
  --partition-key-value: string # Partition key. This is required if the partition scheme for the service is Int64Range or Named. This is not the partition ID, but rather, either the integer key value, or the name of the partition ID. For example, if your service is using ranged partitions from 0 to 10, then they PartitionKeyValue would be an integer in that range. Query service description to see the range or name.
  --previous-rsp-version: string # The value in the Version field of the response that was received previously. This is required if the user knows that the result that was gotten previously is stale.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Endpoints: table<Address: string, Kind: string>, Name: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PartitionKeyType" $partition_key_type "scalar") (serialize-qp "PartitionKeyValue" $partition_key_value "scalar") (serialize-qp "PreviousRspVersion" $previous_rsp_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/ResolvePartition") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "PartitionKeyType": $partition_key_type, "PartitionKeyValue": $partition_key_value, "PreviousRspVersion": $previous_rsp_version, "timeout": $timeout} | compact), body: null}
}

# Resumes periodic backup of a Service Fabric service which was previously suspended.
#
# POST /Services/{serviceId}/$/ResumeBackup
# operationId: ResumeServiceBackup
export def "services-resume-backup create" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/ResumeBackup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Suspends periodic backup for the specified Service Fabric service.
#
# POST /Services/{serviceId}/$/SuspendBackup
# operationId: SuspendServiceBackup
export def "services-suspend-backup create" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/SuspendBackup") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Updates a Service Fabric service using the specified update description.
#
# POST /Services/{serviceId}/$/Update
# Discriminator (request): ServiceKind
# operationId: UpdateService
# --CorrelationScheme item shape: {Scheme: "Invalid"|"Affinity"|"AlignedAffinity"|"NonAlignedAffinity", ServiceName: string}
# --LoadMetrics item shape: {DefaultLoad?: int, Name: string, PrimaryDefaultLoad?: int, SecondaryDefaultLoad?: int, Weight?: "Zero"|"Low"|"Medium"|"High"}
# --ScalingPolicies item shape: {ScalingMechanism: any, ScalingTrigger: any}
# --ServicePlacementPolicies item shape: {Type: "Invalid"|"InvalidDomain"|"RequireDomain"|"PreferPrimaryDomain"|"RequireDomainDistribution"|"NonPartiallyPlaceService"}
export def "services-update update" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --correlation-scheme: list # A list that describes the correlation of the service with other services. — item shape: {Scheme: "Invalid"|"Affinity"|"AlignedAffinity"|"NonAlignedAffinity", ServiceName: string}
  --default-move-cost: string@default-move-cost-completer # Specifies the move cost for the service.
  --flags: string # Flags indicating whether other properties are set. Each of the associated properties corresponds to a flag, specified below, which, if set, indicate that the property is specified. This property can be a combination of those flags obtained using bitwise 'OR' operator. For example, if the provided value is 6 then the flags for ReplicaRestartWaitDuration (2) and QuorumLossWaitDuration (4) are set. - None - Does not indicate any other properties are set. The value is zero. - TargetReplicaSetSize/InstanceCount - Indicates whether the TargetReplicaSetSize property (for Stateful services) or the InstanceCount property (for Stateless services) is set. The value is 1. - ReplicaRestartWaitDuration - Indicates the ReplicaRestartWaitDuration property is set. The value is 2. - QuorumLossWaitDuration - Indicates the QuorumLossWaitDuration property is set. The value is 4. - StandByReplicaKeepDuration - Indicates the StandByReplicaKeepDuration property is set. The value is 8. - MinReplicaSetSize - Indicates the MinReplicaSetSize property is set. The value is 16. - PlacementConstraints - Indicates the PlacementConstraints property is set. The value is 32. - PlacementPolicyList - Indicates the ServicePlacementPolicies property is set. The value is 64. - Correlation - Indicates the CorrelationScheme property is set. The value is 128. - Metrics - Indicates the ServiceLoadMetrics property is set. The value is 256. - DefaultMoveCost - Indicates the DefaultMoveCost property is set. The value is 512. - ScalingPolicy - Indicates the ScalingPolicies property is set. The value is 1024.
  --load-metrics: list # The service load metrics is given as an array of ServiceLoadMetricDescription objects. — item shape: {DefaultLoad?: int, Name: string, PrimaryDefaultLoad?: int, SecondaryDefaultLoad?: int, Weight?: "Zero"|"Low"|"Medium"|"High"}
  --placement-constraints: string # The placement constraints as a string. Placement constraints are boolean expressions on node properties and allow for restricting a service to particular nodes based on the service requirements. For example, to place a service on nodes where NodeType is blue specify the following: "NodeColor == blue)".
  --scaling-policies: list # A list that describes the scaling policies. — item shape: {ScalingMechanism: any, ScalingTrigger: any}
  service_kind: string@service-kind-completer # The kind of service (Stateless or Stateful).
  --service-placement-policies: list # A list that describes the correlation of the service with other services. — item shape: {Type: "Invalid"|"InvalidDomain"|"RequireDomain"|"PreferPrimaryDomain"|"RequireDomainDistribution"|"NonPartiallyPlaceService"}
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/Services/{service_id}/$/Update") $qp)
  let req_body = {"CorrelationScheme": $correlation_scheme, "DefaultMoveCost": $default_move_cost, "Flags": $flags, "LoadMetrics": $load_metrics, "PlacementConstraints": $placement_constraints, "ScalingPolicies": $scaling_policies, "ServiceKind": $service_kind, "ServicePlacementPolicies": $service_placement_policies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Get the status of Chaos.
#
# GET /Tools/Chaos
# operationId: GetChaos
export def "tools-chaos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ChaosParameters: record<ChaosTargetFilter: record<ApplicationInclusionList: list, NodeTypeInclusionList: list>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, Context: record<Map: any>, EnableMoveReplicaFaults: bool, MaxClusterStabilizationTimeoutInSeconds: int, MaxConcurrentFaults: int, TimeToRunInSeconds: string, WaitTimeBetweenFaultsInSeconds: int, WaitTimeBetweenIterationsInSeconds: int>, ScheduleStatus: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Starts Chaos in the cluster.
#
# POST /Tools/Chaos/$/Start
# operationId: StartChaos
# --ChaosTargetFilter shape: {ApplicationInclusionList?: list<string>, NodeTypeInclusionList?: list<string>}
# --ClusterHealthPolicy shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
# --Context shape: {Map?: any}
export def "tools-chaos-start start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --chaos-target-filter: any # Defines all filters for targeted Chaos faults, for example, faulting only certain node types or faulting only certain applications. If ChaosTargetFilter is not used, Chaos faults all cluster entities. If ChaosTargetFilter is used, Chaos faults only the entities that meet the ChaosTargetFilter specification. NodeTypeInclusionList and ApplicationInclusionList allow a union semantics only. It is not possible to specify an intersection of NodeTypeInclusionList and ApplicationInclusionList. For example, it is not possible to specify "fault this application only when it is on that node type." Once an entity is included in either NodeTypeInclusionList or ApplicationInclusionList, that entity cannot be excluded using ChaosTargetFilter. Even if applicationX does not appear in ApplicationInclusionList, in some Chaos iteration applicationX can be faulted because it happens to be on a node of nodeTypeY that is included in NodeTypeInclusionList. If both NodeTypeInclusionList and ApplicationInclusionList are null or empty, an ArgumentException is thrown. — shape: {ApplicationInclusionList?: list<string>, NodeTypeInclusionList?: list<string>}
  --cluster-health-policy: any # Defines a health policy used to evaluate the health of the cluster or of a cluster node. — shape: {ApplicationTypeHealthPolicyMap?: list, ConsiderWarningAsError?: bool, MaxPercentUnhealthyApplications?: int, MaxPercentUnhealthyNodes?: int}
  --context: any # Describes a map, which is a collection of (string, string) type key-value pairs. The map can be used to record information about the Chaos run. There cannot be more than 100 such pairs and each string (key or value) can be at most 4095 characters long. This map is set by the starter of the Chaos run to optionally store the context about the specific run. — shape: {Map?: any}
  --enable-move-replica-faults: oneof<nothing, bool> # Enables or disables the move primary and move secondary faults. (default: true)
  --max-cluster-stabilization-timeout-in-seconds: int # The maximum amount of time to wait for all cluster entities to become stable and healthy. Chaos executes in iterations and at the start of each iteration it validates the health of cluster entities. During validation if a cluster entity is not stable and healthy within MaxClusterStabilizationTimeoutInSeconds, Chaos generates a validation failed event. (format: int64, default: 60)
  --max-concurrent-faults: int # MaxConcurrentFaults is the maximum number of concurrent faults induced per iteration. Chaos executes in iterations and two consecutive iterations are separated by a validation phase. The higher the concurrency, the more aggressive the injection of faults, leading to inducing more complex series of states to uncover bugs. The recommendation is to start with a value of 2 or 3 and to exercise caution while moving up. (format: int64, default: 1)
  --time-to-run-in-seconds: string # Total time (in seconds) for which Chaos will run before automatically stopping. The maximum allowed value is 4,294,967,295 (System.UInt32.MaxValue). (default: 4294967295)
  --wait-time-between-faults-in-seconds: int # Wait time (in seconds) between consecutive faults within a single iteration. The larger the value, the lower the overlapping between faults and the simpler the sequence of state transitions that the cluster goes through. The recommendation is to start with a value between 1 and 5 and exercise caution while moving up. (format: int64, default: 20)
  --wait-time-between-iterations-in-seconds: int # Time-separation (in seconds) between two consecutive iterations of Chaos. The larger the value, the lower the fault injection rate. (format: int64, default: 30)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/$/Start" $qp)
  let req_body = {"ChaosTargetFilter": $chaos_target_filter, "ClusterHealthPolicy": $cluster_health_policy, "Context": $context, "EnableMoveReplicaFaults": $enable_move_replica_faults, "MaxClusterStabilizationTimeoutInSeconds": $max_cluster_stabilization_timeout_in_seconds, "MaxConcurrentFaults": $max_concurrent_faults, "TimeToRunInSeconds": $time_to_run_in_seconds, "WaitTimeBetweenFaultsInSeconds": $wait_time_between_faults_in_seconds, "WaitTimeBetweenIterationsInSeconds": $wait_time_between_iterations_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}

# Stops Chaos if it is running in the cluster and put the Chaos Schedule in a stopped state.
#
# POST /Tools/Chaos/$/Stop
# operationId: StopChaos
export def "tools-chaos-stop stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/$/Stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Gets the next segment of the Chaos events based on the continuation token or the time range.
#
# GET /Tools/Chaos/Events
# operationId: GetChaosEvents
export def "tools-chaos-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --continuation-token: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --start-time-utc: string # The Windows file time representing the start time of the time range for which a Chaos report is to be generated. Consult [DateTime.ToFileTimeUtc Method](https://msdn.microsoft.com/library/system.datetime.tofiletimeutc(v=vs.110).aspx) for details.
  --end-time-utc: string # The Windows file time representing the end time of the time range for which a Chaos report is to be generated. Consult [DateTime.ToFileTimeUtc Method](https://msdn.microsoft.com/library/system.datetime.tofiletimeutc(v=vs.110).aspx) for details.
  --max-results: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, History: table<ChaosEvent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $continuation_token "scalar") (serialize-qp "StartTimeUtc" $start_time_utc "scalar") (serialize-qp "EndTimeUtc" $end_time_utc "scalar") (serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "ContinuationToken": $continuation_token, "StartTimeUtc": $start_time_utc, "EndTimeUtc": $end_time_utc, "MaxResults": $max_results, "timeout": $timeout} | compact), body: null}
}

# Get the Chaos Schedule defining when and how to run Chaos.
#
# GET /Tools/Chaos/Schedule
# operationId: GetChaosSchedule
export def "tools-chaos-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Schedule: record<ChaosParametersDictionary: list<record>, ExpiryDate: string, Jobs: list<record>, StartDate: string>, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/Schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: null}
}

# Set the schedule used by Chaos.
#
# POST /Tools/Chaos/Schedule
# operationId: PostChaosSchedule
# --Schedule shape: {ChaosParametersDictionary?: list, ExpiryDate?: string, Jobs?: list, StartDate?: string}
export def "tools-chaos-schedule create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'. Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification. Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --schedule: any # Defines the schedule used by Chaos. — shape: {ChaosParametersDictionary?: list, ExpiryDate?: string, Jobs?: list, StartDate?: string}
  --version: int # The version number of the Schedule. (format: int32)
]: any -> record<Error: record<Code: string, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/Schedule" $qp)
  let req_body = {"Schedule": $schedule, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version, "timeout": $timeout} | compact), body: $req_body}
}
