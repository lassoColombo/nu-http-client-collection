# Auto-generated client for  v0.0.1
# Source: https://raw.githubusercontent.com/temporalio/api/master/openapi/openapiv3.yaml
# Auth: --token flag or $env._TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o _TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def historyArchivalState-completer [] { ["ARCHIVAL_STATE_DISABLED" "ARCHIVAL_STATE_ENABLED" "ARCHIVAL_STATE_UNSPECIFIED"] }
def visibilityArchivalState-completer [] { ["ARCHIVAL_STATE_DISABLED" "ARCHIVAL_STATE_ENABLED" "ARCHIVAL_STATE_UNSPECIFIED"] }
def idReusePolicy-completer [] { ["ACTIVITY_ID_REUSE_POLICY_ALLOW_DUPLICATE" "ACTIVITY_ID_REUSE_POLICY_ALLOW_DUPLICATE_FAILED_ONLY" "ACTIVITY_ID_REUSE_POLICY_REJECT_DUPLICATE" "ACTIVITY_ID_REUSE_POLICY_UNSPECIFIED"] }
def idConflictPolicy-completer [] { ["ACTIVITY_ID_CONFLICT_POLICY_FAIL" "ACTIVITY_ID_CONFLICT_POLICY_UNSPECIFIED" "ACTIVITY_ID_CONFLICT_POLICY_USE_EXISTING"] }
def idReusePolicy-completer-1 [] { ["NEXUS_OPERATION_ID_REUSE_POLICY_ALLOW_DUPLICATE" "NEXUS_OPERATION_ID_REUSE_POLICY_ALLOW_DUPLICATE_FAILED_ONLY" "NEXUS_OPERATION_ID_REUSE_POLICY_REJECT_DUPLICATE" "NEXUS_OPERATION_ID_REUSE_POLICY_UNSPECIFIED"] }
def idConflictPolicy-completer-1 [] { ["NEXUS_OPERATION_ID_CONFLICT_POLICY_FAIL" "NEXUS_OPERATION_ID_CONFLICT_POLICY_UNSPECIFIED" "NEXUS_OPERATION_ID_CONFLICT_POLICY_USE_EXISTING"] }
def waitStage-completer [] { ["NEXUS_OPERATION_WAIT_STAGE_CLOSED" "NEXUS_OPERATION_WAIT_STAGE_STARTED" "NEXUS_OPERATION_WAIT_STAGE_UNSPECIFIED"] }
def taskQueueType-completer [] { ["TASK_QUEUE_TYPE_ACTIVITY" "TASK_QUEUE_TYPE_NEXUS" "TASK_QUEUE_TYPE_UNSPECIFIED" "TASK_QUEUE_TYPE_WORKFLOW"] }
def taskQueuekind-completer [] { ["TASK_QUEUE_KIND_NORMAL" "TASK_QUEUE_KIND_STICKY" "TASK_QUEUE_KIND_UNSPECIFIED" "TASK_QUEUE_KIND_WORKER_COMMANDS"] }
def apiMode-completer [] { ["DESCRIBE_TASK_QUEUE_MODE_ENHANCED" "DESCRIBE_TASK_QUEUE_MODE_UNSPECIFIED"] }
def reachability-completer [] { ["TASK_REACHABILITY_CLOSED_WORKFLOWS" "TASK_REACHABILITY_EXISTING_WORKFLOWS" "TASK_REACHABILITY_NEW_WORKFLOWS" "TASK_REACHABILITY_OPEN_WORKFLOWS" "TASK_REACHABILITY_UNSPECIFIED"] }
def historyEventFilterType-completer [] { ["HISTORY_EVENT_FILTER_TYPE_ALL_EVENT" "HISTORY_EVENT_FILTER_TYPE_CLOSE_EVENT" "HISTORY_EVENT_FILTER_TYPE_UNSPECIFIED"] }
def queryRejectCondition-completer [] { ["QUERY_REJECT_CONDITION_NONE" "QUERY_REJECT_CONDITION_NOT_COMPLETED_CLEANLY" "QUERY_REJECT_CONDITION_NOT_OPEN" "QUERY_REJECT_CONDITION_UNSPECIFIED"] }
def workflowIdReusePolicy-completer [] { ["WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE" "WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE_FAILED_ONLY" "WORKFLOW_ID_REUSE_POLICY_REJECT_DUPLICATE" "WORKFLOW_ID_REUSE_POLICY_TERMINATE_IF_RUNNING" "WORKFLOW_ID_REUSE_POLICY_UNSPECIFIED"] }
def workflowIdConflictPolicy-completer [] { ["WORKFLOW_ID_CONFLICT_POLICY_FAIL" "WORKFLOW_ID_CONFLICT_POLICY_TERMINATE_EXISTING" "WORKFLOW_ID_CONFLICT_POLICY_UNSPECIFIED" "WORKFLOW_ID_CONFLICT_POLICY_USE_EXISTING"] }
def resetReapplyType-completer [] { ["RESET_REAPPLY_TYPE_ALL_ELIGIBLE" "RESET_REAPPLY_TYPE_NONE" "RESET_REAPPLY_TYPE_SIGNAL" "RESET_REAPPLY_TYPE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cluster-info GetClusterInfo" } } | get name | first)
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

# GetClusterInfo returns information about temporal cluster
#
# GET /api/v1/cluster-info
# operationId: GetClusterInfo
export def "cluster-info GetClusterInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<supportedClients: record, serverVersion: string, clusterId: string, versionInfo: record<current: record<version: string, releaseTime: string, notes: string>, recommended: record<version: string, releaseTime: string, notes: string>, instructions: string, alerts: list<record>, lastUpdateTime: string>, clusterName: string, historyShardCount: int, persistenceStore: string, visibilityStore: string, initialFailoverVersion: string, failoverVersionIncrement: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/cluster-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListNamespaces returns the information and configuration for all namespaces.
#
# GET /api/v1/namespaces
# operationId: ListNamespaces
export def "namespaces ListNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --namespaceFilterincludeDeleted: oneof<nothing, bool> # By default namespaces in NAMESPACE_STATE_DELETED state are not included.  Setting include_deleted to true will include deleted namespaces.  Note: Namespace is in NAMESPACE_STATE_DELETED state when it was deleted from the system but associated data is not deleted yet.
]: nothing -> record<namespaces: table<namespaceInfo: record, config: record, replicationConfig: record, failoverVersion: string, isGlobalNamespace: bool, failoverHistory: list, pollerGroupInfos: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "namespaceFilter.includeDeleted" $namespaceFilterincludeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# RegisterNamespace creates a new namespace which can be used as a container for all resources.   A Namespace is a top level entity within Temporal, and is used as a container for resources  like workflow executions, task queues, etc. A Namespace acts as a sandbox and provides  isolation for all resources within the namespace. All resources belongs to exactly one  namespace.
#
# POST /api/v1/namespaces
# operationId: RegisterNamespace
# --clusters item shape: {clusterName?: string}
export def "namespaces RegisterNamespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --description: string
  --ownerEmail: string
  --workflowExecutionRetentionPeriod: string
  --clusters: list # item shape: {clusterName?: string}
  --activeClusterName: string
  --data: record # A key-value map for any customized purpose.
  --securityToken: string
  --isGlobalNamespace: oneof<nothing, bool>
  --historyArchivalState: string@historyArchivalState-completer # If unspecified (ARCHIVAL_STATE_UNSPECIFIED) then default server configuration is used. (format: enum)
  --historyArchivalUri: string
  --visibilityArchivalState: string@visibilityArchivalState-completer # If unspecified (ARCHIVAL_STATE_UNSPECIFIED) then default server configuration is used. (format: enum)
  --visibilityArchivalUri: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/namespaces")
  let body = {namespace: $namespace, description: $description, ownerEmail: $ownerEmail, workflowExecutionRetentionPeriod: $workflowExecutionRetentionPeriod, clusters: $clusters, activeClusterName: $activeClusterName, data: $data, securityToken: $securityToken, isGlobalNamespace: $isGlobalNamespace, historyArchivalState: $historyArchivalState, historyArchivalUri: $historyArchivalUri, visibilityArchivalState: $visibilityArchivalState, visibilityArchivalUri: $visibilityArchivalUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DescribeNamespace returns the information and configuration for a registered namespace.
#
# GET /api/v1/namespaces/{namespace}
# operationId: DescribeNamespace
export def "namespaces DescribeNamespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --weakConsistency: oneof<nothing, bool> # If true, the server may serve the response from an eventually-consistent  source instead of reading through to persistence. Defaults to false,  which preserves read-after-write consistency. SDKs should set this when  fetching namespace capabilities on worker/client startup.
]: nothing -> record<namespaceInfo: record<name: string, state: string, description: string, ownerEmail: string, data: record, id: string, capabilities: record<eagerWorkflowStart: bool, syncUpdate: bool, asyncUpdate: bool, workerHeartbeats: bool, reportedProblemsSearchAttribute: bool, workflowPause: bool, standaloneActivities: bool, workerPollCompleteOnShutdown: bool, pollerAutoscaling: bool, workerCommands: bool, standaloneNexusOperation: bool, workflowUpdateCallbacks: bool>, limits: record<blobSizeLimitError: string, memoSizeLimitError: string>, supportsSchedules: bool>, config: record<workflowExecutionRetentionTtl: string, badBinaries: record<binaries: record>, historyArchivalState: string, historyArchivalUri: string, visibilityArchivalState: string, visibilityArchivalUri: string, customSearchAttributeAliases: record>, replicationConfig: record<activeClusterName: string, clusters: list<record>, state: string>, failoverVersion: string, isGlobalNamespace: bool, failoverHistory: table<failoverTime: string, failoverVersion: string>, pollerGroupInfos: table<id: string, weight: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "weakConsistency" $weakConsistency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListActivityExecutions is a visibility API to list activity executions in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/activities
# operationId: ListActivityExecutions
export def "namespaces-activities ListActivityExecutions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Max number of executions to return per page. (format: int32)
  --nextPageToken: string # Token returned in ListActivityExecutionsResponse. (format: bytes)
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.
]: nothing -> record<executions: table<activityId: string, runId: string, activityType: record, scheduleTime: string, closeTime: string, status: string, searchAttributes: record, taskQueue: string, stateTransitionCount: string, stateSizeBytes: string, executionDuration: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PauseActivity pauses the execution of an activity specified by its ID or type.  If there are multiple pending activities of the provided type - all of them will be paused   Pausing an activity means:  - If the activity is currently waiting for a retry or is running and subsequently fails,    it will not be rescheduled until it is unpaused.  - If the activity is already paused, calling this method will have no effect.  - If the activity is running and finishes successfully, the activity will be completed.  - If the activity is running and finishes with failure:    * if there is no retry left - the activity will be completed.    * if there are more retries left - the activity will be paused.  For long-running activities:  - activities in paused state will send a cancellation with "activity_paused" set to 'true' in response to 'RecordActivityTaskHeartbeat'.  - The activity should respond to the cancellation accordingly.   Returns a `NotFound` error if there is no pending activity with the provided ID or type  This API will be deprecated soon and replaced with a newer PauseActivityExecution that is better named and  structured to work well for standalone activities.
#
# POST /api/v1/namespaces/{namespace}/activities-deprecated/pause
# operationId: PauseActivity
export def "namespaces-activities-deprecated-pause PauseActivity-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request.
  --id: string # Only the activity with this ID will be paused.
  --type: string # Pause all running activities of this type.  Note: Experimental - the behavior of pause by activity type might change in a future release.
  --reason: string # Reason to pause the activity.
  --requestId: string # Used to de-dupe pause requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities-deprecated/pause")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, id: $id, type: $type, reason: $reason, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetActivity resets the execution of an activity specified by its ID or type.  If there are multiple pending activities of the provided type - all of them will be reset.   Resetting an activity means:  * number of attempts will be reset to 0.  * activity timeouts will be reset.  * if the activity is waiting for retry, and it is not paused or 'keep_paused' is not provided:     it will be scheduled immediately (* see 'jitter' flag),   Flags:   'jitter': the activity will be scheduled at a random time within the jitter duration.  If the activity currently paused it will be unpaused, unless 'keep_paused' flag is provided.  'reset_heartbeats': the activity heartbeat timer and heartbeats will be reset.  'keep_paused': if the activity is paused, it will remain paused.   Returns a `NotFound` error if there is no pending activity with the provided ID or type.  This API will be deprecated soon and replaced with a newer ResetActivityExecution that is better named and  structured to work well for standalone activities.
#
# POST /api/v1/namespaces/{namespace}/activities-deprecated/reset
# operationId: ResetActivity
export def "namespaces-activities-deprecated-reset ResetActivity-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request.
  --id: string # Only activity with this ID will be reset.
  --type: string # Reset all running activities with of this type.
  --matchAll: oneof<nothing, bool> # Reset all running activities.
  --resetHeartbeat: oneof<nothing, bool> # Indicates that activity should reset heartbeat details.  This flag will be applied only to the new instance of the activity.
  --keepPaused: oneof<nothing, bool> # If activity is paused, it will remain paused after reset
  --jitter: string # If set, and activity is in backoff, the activity will start at a random time within the specified jitter duration.  (unless it is paused and keep_paused is set)
  --restoreOriginalOptions: oneof<nothing, bool> # If set, the activity options will be restored to the defaults.  Default options are then options activity was created with.  They are part of the first schedule event.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities-deprecated/reset")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, id: $id, type: $type, matchAll: $matchAll, resetHeartbeat: $resetHeartbeat, keepPaused: $keepPaused, jitter: $jitter, restoreOriginalOptions: $restoreOriginalOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UnpauseActivity unpauses the execution of an activity specified by its ID or type.  If there are multiple pending activities of the provided type - all of them will be unpaused.   If activity is not paused, this call will have no effect.  If the activity was paused while waiting for retry, it will be scheduled immediately (* see 'jitter' flag).  Once the activity is unpaused, all timeout timers will be regenerated.   Flags:  'jitter': the activity will be scheduled at a random time within the jitter duration.  'reset_attempts': the number of attempts will be reset.  'reset_heartbeat': the activity heartbeat timer and heartbeats will be reset.   Returns a `NotFound` error if there is no pending activity with the provided ID or type  This API will be deprecated soon and replaced with a newer UnpauseActivityExecution that is better named and  structured to work well for standalone activities.
#
# POST /api/v1/namespaces/{namespace}/activities-deprecated/unpause
# operationId: UnpauseActivity
export def "namespaces-activities-deprecated-unpause UnpauseActivity-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request.
  --id: string # Only the activity with this ID will be unpaused.
  --type: string # Unpause all running activities with of this type.
  --unpauseAll: oneof<nothing, bool> # Unpause all running activities.
  --resetAttempts: oneof<nothing, bool> # Providing this flag will also reset the number of attempts.
  --resetHeartbeat: oneof<nothing, bool> # Providing this flag will also reset the heartbeat details.
  --jitter: string # If set, the activity will start at a random time within the specified jitter duration.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities-deprecated/unpause")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, id: $id, type: $type, unpauseAll: $unpauseAll, resetAttempts: $resetAttempts, resetHeartbeat: $resetHeartbeat, jitter: $jitter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateActivityOptions is called by the client to update the options of an activity by its ID or type.  If there are multiple pending activities of the provided type - all of them will be updated.  This API will be deprecated soon and replaced with a newer UpdateActivityExecutionOptions that is better named and  structured to work well for standalone activities.
#
# POST /api/v1/namespaces/{namespace}/activities-deprecated/update-options
# operationId: UpdateActivityOptions
export def "namespaces-activities-deprecated-update-options UpdateActivityOptions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request
  --activityOptions: any # Activity options. Partial updates are accepted and controlled by update_mask
  --updateMask: string # Controls which fields from `activity_options` will be applied (format: field-mask)
  --id: string # Only activity with this ID will be updated.
  --type: string # Update all running activities of this type.
  --matchAll: oneof<nothing, bool> # Update all running activities.
  --restoreOriginal: oneof<nothing, bool> # If set, the activity options will be restored to the default.  Default options are then options activity was created with.  They are part of the first schedule event.  This flag cannot be combined with any other option; if you supply  restore_original together with other options, the request will be rejected.
]: any -> record<activityOptions: record<taskQueue: record<name: string, kind: string, normalName: string>, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities-deprecated/update-options")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, activityOptions: $activityOptions, updateMask: $updateMask, id: $id, type: $type, matchAll: $matchAll, restoreOriginal: $restoreOriginal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DescribeActivityExecution returns information about an activity execution.  It can be used to:  - Get current activity info without waiting  - Long-poll for next state change and return new activity info  Response can optionally include activity input or outcome (if the activity has completed).
#
# GET /api/v1/namespaces/{namespace}/activities/{activityId}
# operationId: DescribeActivityExecution
export def "namespaces-activities DescribeActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Activity run ID. If empty the request targets the latest run.
  --includeInput: oneof<nothing, bool> # Include the input field in the response.
  --includeOutcome: oneof<nothing, bool> # Include the outcome (result/failure) in the response if the activity has completed.
  --longPollToken: string # Token from a previous DescribeActivityExecutionResponse. If present, long-poll until activity  state changes from the state encoded in this token. If absent, return current state immediately.  If present, run_id must also be present.  Note that activity state may change multiple times between requests, therefore it is not  guaranteed that a client making a sequence of long-poll requests will see a complete  sequence of state changes. (format: bytes)
  --includeHeartbeatDetails: oneof<nothing, bool> # Include the heartbeat_details field inside info in the response if available.
  --includeLastFailure: oneof<nothing, bool> # Include the last_failure field inside info in the response if available.
]: nothing -> record<runId: string, info: record<activityId: string, runId: string, activityType: record<name: string>, status: string, runState: string, taskQueue: string, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, heartbeatDetails: record<payloads: list>, lastHeartbeatTime: string, lastStartedTime: string, attempt: int, executionDuration: string, scheduleTime: string, expirationTime: string, closeTime: string, lastFailure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, lastWorkerIdentity: string, currentRetryInterval: string, lastAttemptCompleteTime: string, nextAttemptScheduleTime: string, lastDeploymentVersion: record<buildId: string, deploymentName: string>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>, stateTransitionCount: string, stateSizeBytes: string, searchAttributes: record<indexedFields: record>, header: record<fields: record>, userMetadata: record<summary: record, details: record>, canceledReason: string, links: list<record>, totalHeartbeatCount: string, sdkName: string, sdkVersion: string, startDelay: string>, input: record<payloads: list<any>>, outcome: record<result: record<payloads: list>, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>>, longPollToken: string, callbacks: table<callback: record, registrationTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, blockedReason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar") (serialize-qp "includeInput" $includeInput "scalar") (serialize-qp "includeOutcome" $includeOutcome "scalar") (serialize-qp "longPollToken" $longPollToken "scalar") (serialize-qp "includeHeartbeatDetails" $includeHeartbeatDetails "scalar") (serialize-qp "includeLastFailure" $includeLastFailure "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StartActivityExecution starts a new activity execution.   Returns an `ActivityExecutionAlreadyStarted` error if an instance already exists with same activity ID in this namespace  unless permitted by the specified ID conflict policy.
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}
# operationId: StartActivityExecution
# --completionCallbacks item shape: {nexus?: record, internal?: record, links?: list}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-activities StartActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --identity: string # The identity of the client who initiated this request
  --requestId: string # A unique identifier for this start request. Typically UUIDv4.
  --body-activityId: string # Identifier for this activity. Required. This identifier should be meaningful in the user's  own system. It must be unique among activities in the same namespace, subject to the rules  imposed by id_reuse_policy and id_conflict_policy.
  --activityType: any # The type of the activity, a string that corresponds to a registered activity on a worker.
  --taskQueue: any # Task queue to schedule this activity on.
  --scheduleToCloseTimeout: string # Indicates how long the caller is willing to wait for an activity completion. Limits how long  retries will be attempted. Either this or `start_to_close_timeout` must be specified.   (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --scheduleToStartTimeout: string # Limits time an activity task can stay in a task queue before a worker picks it up. This  timeout is always non retryable, as all a retry would achieve is to put it back into the same  queue. Defaults to `schedule_to_close_timeout` if not specified.   (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --startToCloseTimeout: string # Maximum time an activity is allowed to execute after being picked up by a worker. This  timeout is always retryable. Either this or `schedule_to_close_timeout` must be  specified.   (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --heartbeatTimeout: string # Maximum permitted time between successful worker heartbeats.
  --retryPolicy: any # The retry policy for the activity. Will never exceed `schedule_to_close_timeout`.
  --input: any # Serialized arguments to the activity. These are passed as arguments to the activity function.
  --idReusePolicy: string@idReusePolicy-completer # Defines whether to allow re-using the activity id from a previously *closed* activity.  The default policy is ACTIVITY_ID_REUSE_POLICY_ALLOW_DUPLICATE. (format: enum)
  --idConflictPolicy: string@idConflictPolicy-completer # Defines how to resolve an activity id conflict with a *running* activity.  The default policy is ACTIVITY_ID_CONFLICT_POLICY_FAIL. (format: enum)
  --searchAttributes: any # Search attributes for indexing.
  --header: any # Header for context propagation and tracing purposes.
  --userMetadata: any # Metadata for use by user interfaces to display the fixed as-of-start summary and details of the activity.
  --priority: any # Priority metadata.
  --completionCallbacks: list # Callbacks to be called by the server when this activity reaches a terminal state.  Callback addresses must be whitelisted in the server's dynamic configuration. — item shape: {nexus?: record, internal?: record, links?: list}
  --links: list # Links to be associated with the activity. Callbacks may also have associated links;  links already included with a callback should not be duplicated here. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
  --onConflictOptions: any # Options for handling conflicts when using ACTIVITY_ID_CONFLICT_POLICY_USE_EXISTING.
  --startDelay: string # Time to wait before dispatching the first activity task. This delay is not applied to retry attempts.
]: any -> record<runId: string, started: bool, link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)")
  let body = {namespace: $body_namespace, identity: $identity, requestId: $requestId, activityId: $body_activityId, activityType: $activityType, taskQueue: $taskQueue, scheduleToCloseTimeout: $scheduleToCloseTimeout, scheduleToStartTimeout: $scheduleToStartTimeout, startToCloseTimeout: $startToCloseTimeout, heartbeatTimeout: $heartbeatTimeout, retryPolicy: $retryPolicy, input: $input, idReusePolicy: $idReusePolicy, idConflictPolicy: $idConflictPolicy, searchAttributes: $searchAttributes, header: $header, userMetadata: $userMetadata, priority: $priority, completionCallbacks: $completionCallbacks, links: $links, onConflictOptions: $onConflictOptions, startDelay: $startDelay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RequestCancelActivityExecution requests cancellation of an activity execution.   Cancellation is cooperative: this call records the request, but the activity must detect and  acknowledge it for the activity to reach CANCELED status. The cancellation signal is  delivered via `cancel_requested` in the heartbeat response; SDKs surface this via  language-idiomatic mechanisms (context cancellation, exceptions, abort signals).
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/cancel
# operationId: RequestCancelActivityExecution
export def "namespaces-activities-cancel RequestCancelActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-activityId: string
  --runId: string # Activity run ID, targets the latest run if run_id is empty.
  --identity: string # The identity of the worker/client.
  --requestId: string # Used to de-dupe cancellation requests.
  --reason: string # Reason for requesting the cancellation, recorded and available via the PollActivityExecution API.  Not propagated to a worker if an activity attempt is currently running.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/cancel")
  let body = {namespace: $body_namespace, activityId: $body_activityId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCompleted`. This version allows clients to record completions by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/complete
# operationId: RespondActivityTaskCompletedById
export def "namespaces-activities-complete RespondActivityTaskCompletedById-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to complete
  --body-result: any # The serialized result of activity execution
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/complete")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, result: $body_result, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskFailed`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/fail
# operationId: RespondActivityTaskFailedById
export def "namespaces-activities-fail RespondActivityTaskFailedById-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to fail
  --failure: any # Detailed failure information
  --identity: string # The identity of the worker/client
  --lastHeartbeatDetails: any # Additional details to be stored as last activity heartbeat
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<failures: table<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/fail")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, failure: $failure, identity: $identity, lastHeartbeatDetails: $lastHeartbeatDetails, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskHeartbeat`. This version allows clients to record heartbeats by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/heartbeat
# operationId: RecordActivityTaskHeartbeatById
export def "namespaces-activities-heartbeat RecordActivityTaskHeartbeatById-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity we're heartbeating
  --details: any # Arbitrary data, of which the most recent call is kept, to store for this activity
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<cancelRequested: bool, activityPaused: bool, activityReset: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/heartbeat")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PollActivityExecution long-polls for an activity execution to complete and returns the  outcome (result or failure).
#
# GET /api/v1/namespaces/{namespace}/activities/{activityId}/outcome
# operationId: PollActivityExecution
export def "namespaces-activities-outcome PollActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Activity run ID. If empty the request targets the latest run.
]: nothing -> record<runId: string, outcome: record<result: record<payloads: list>, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/outcome" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PauseActivityExecution pauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity   Pausing an activity means:  - If the activity is currently waiting for a retry or is running and subsequently fails,    it will not be rescheduled until it is unpaused.  - If the activity is already paused, calling this method will have no effect.  - If the activity is running and finishes successfully, the activity will be completed.  - If the activity is running and finishes with failure:    * if there is no retry left - the activity will be completed.    * if there are more retries left - the activity will be paused.  For long-running activities:  - activities in paused state will send a cancellation with "activity_paused" set to 'true' in response to 'RecordActivityTaskHeartbeat'.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/pause
# operationId: PauseActivityExecution
export def "namespaces-activities-pause PauseActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --workflowId: string # If provided, pause a workflow activity (or activities) for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to pause the activity.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
  --requestId: string # Used to de-dupe pause requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/pause")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, reason: $reason, resourceId: $resourceId, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetActivityExecution resets the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   Resetting an activity means:  * number of attempts will be reset to 0.  * activity timeouts will be reset.  * if the activity is waiting for retry, and it is not paused or 'keep_paused' is not provided:     it will be scheduled immediately (* see 'jitter' flag)   Returns a `NotFound` error if there is no pending activity with the provided ID or type.
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/reset
# operationId: ResetActivityExecution
export def "namespaces-activities-reset ResetActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetHeartbeat: oneof<nothing, bool> # Indicates that activity should reset heartbeat details.  This flag will be applied only to the new instance of the activity.
  --keepPaused: oneof<nothing, bool> # If activity is paused, it will remain paused after reset
  --jitter: string # If set, and activity is in backoff, the activity will start at a random time within the specified jitter duration.  (unless it is paused and keep_paused is set)
  --restoreOriginalOptions: oneof<nothing, bool> # If set, the activity options will be restored to the defaults.  Default options are then options activity was created with.  They are part of the first schedule event.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/reset")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetHeartbeat: $resetHeartbeat, keepPaused: $keepPaused, jitter: $jitter, restoreOriginalOptions: $restoreOriginalOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCanceled`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/resolve-as-canceled
# operationId: RespondActivityTaskCanceledById
export def "namespaces-activities-resolve-as-canceled RespondActivityTaskCanceledById-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to confirm is cancelled
  --details: any # Serialized additional information to attach to the cancellation
  --identity: string # The identity of the worker/client
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/resolve-as-canceled")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, deploymentOptions: $deploymentOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# TerminateActivityExecution terminates an existing activity execution immediately.   Termination does not reach the worker and the activity code cannot react to it. A terminated activity may have a  running attempt.
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/terminate
# operationId: TerminateActivityExecution
export def "namespaces-activities-terminate TerminateActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-activityId: string
  --runId: string # Activity run ID, targets the latest run if run_id is empty.
  --identity: string # The identity of the worker/client.
  --requestId: string # Used to de-dupe termination requests.
  --reason: string # Reason for requesting the termination, recorded in in the activity's result failure outcome.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/terminate")
  let body = {namespace: $body_namespace, activityId: $body_activityId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UnpauseActivityExecution unpauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   If activity is not paused, this call will have no effect.  If the activity was paused while waiting for retry, it will be scheduled immediately (* see 'jitter' flag).  Once the activity is unpaused, all timeout timers will be regenerated.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/unpause
# operationId: UnpauseActivityExecution
export def "namespaces-activities-unpause UnpauseActivityExecution-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetAttempts: oneof<nothing, bool> # Providing this flag will also reset the number of attempts.
  --resetHeartbeat: oneof<nothing, bool> # Providing this flag will also reset the heartbeat details.
  --reason: string # Reason to unpause the activity.
  --jitter: string # If set, the activity will start at a random time within the specified jitter duration.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/unpause")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetAttempts: $resetAttempts, resetHeartbeat: $resetHeartbeat, reason: $reason, jitter: $jitter, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateActivityExecutionOptions is called by the client to update the options of an activity by its ID.  This API can be used to target a workflow activity or a standalone activity.
#
# POST /api/v1/namespaces/{namespace}/activities/{activityId}/update-options
# operationId: UpdateActivityExecutionOptions
export def "namespaces-activities-update-options UpdateActivityExecutionOptions-by-namespace-activityId" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request
  --activityOptions: any # Activity options. Partial updates are accepted and controlled by update_mask
  --updateMask: string # Controls which fields from `activity_options` will be applied (format: field-mask)
  --restoreOriginal: oneof<nothing, bool> # If set, the activity options will be restored to the default.  Default options are then options activity was created with.  They are part of the first schedule event.  This flag cannot be combined with any other option; if you supply  restore_original together with other options, the request will be rejected.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record<activityOptions: record<taskQueue: record<name: string, kind: string, normalName: string>, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activities/($activityId)/update-options")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, activityOptions: $activityOptions, updateMask: $updateMask, restoreOriginal: $restoreOriginal, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RespondActivityTaskCompleted is called by workers when they successfully complete an activity  task.   For workflow activities, this results in a new `ACTIVITY_TASK_COMPLETED` event being written to the workflow history  and a new workflow task created for the workflow. Fails with `NotFound` if the task token is  no longer valid due to activity timeout, already being completed, or never having existed.
#
# POST /api/v1/namespaces/{namespace}/activity-complete
# operationId: RespondActivityTaskCompleted
export def "namespaces-activity-complete RespondActivityTaskCompleted-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --body-result: any # The result of successfully executing the activity
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
  --workerVersion: any # Version info of the worker who processed this task. This message's `build_id` field should  always be set by SDKs. Workers opting into versioning will also set the `use_versioning`  field to true. See message docstrings for more.  Deprecated. Use `deployment_options` instead.
  --deployment: any # Deployment info of the worker that completed this task. Must be present if user has set  `WorkerDeploymentOptions` regardless of versioning being enabled or not.  Deprecated. Replaced with `deployment_options`.
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activity-complete")
  let body = {taskToken: $taskToken, result: $body_result, identity: $identity, namespace: $body_namespace, resourceId: $resourceId, workerVersion: $workerVersion, deployment: $deployment, deploymentOptions: $deploymentOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CountActivityExecutions is a visibility API to count activity executions in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/activity-count
# operationId: CountActivityExecutions
export def "namespaces-activity-count CountActivityExecutions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activity-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# RespondActivityTaskFailed is called by workers when processing an activity task fails.   This results in a new `ACTIVITY_TASK_FAILED` event being written to the workflow history and  a new workflow task created for the workflow. Fails with `NotFound` if the task token is no  longer valid due to activity timeout, already being completed, or never having existed.
#
# POST /api/v1/namespaces/{namespace}/activity-fail
# operationId: RespondActivityTaskFailed
export def "namespaces-activity-fail RespondActivityTaskFailed-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --failure: any # Detailed failure information
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
  --lastHeartbeatDetails: any # Additional details to be stored as last activity heartbeat
  --workerVersion: any # Version info of the worker who processed this task. This message's `build_id` field should  always be set by SDKs. Workers opting into versioning will also set the `use_versioning`  field to true. See message docstrings for more.  Deprecated. Use `deployment_options` instead.
  --deployment: any # Deployment info of the worker that completed this task. Must be present if user has set  `WorkerDeploymentOptions` regardless of versioning being enabled or not.  Deprecated. Replaced with `deployment_options`.
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
]: any -> record<failures: table<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activity-fail")
  let body = {taskToken: $taskToken, failure: $failure, identity: $identity, namespace: $body_namespace, resourceId: $resourceId, lastHeartbeatDetails: $lastHeartbeatDetails, workerVersion: $workerVersion, deployment: $deployment, deploymentOptions: $deploymentOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RecordActivityTaskHeartbeat is optionally called by workers while they execute activities.   If a worker fails to heartbeat within the `heartbeat_timeout` interval for the activity task,  then the current attempt times out. Depending on RetryPolicy, this may trigger a retry or  time out the activity.   For workflow activities, an `ACTIVITY_TASK_TIMED_OUT` event will be written to the workflow  history. Calling `RecordActivityTaskHeartbeat` will fail with `NotFound` in such situations,  in that event, the SDK should request cancellation of the activity.   The request may contain response `details` which will be persisted by the server and may be  used by the activity to checkpoint progress. The `cancel_requested` field in the response  indicates whether cancellation has been requested for the activity.
#
# POST /api/v1/namespaces/{namespace}/activity-heartbeat
# operationId: RecordActivityTaskHeartbeat
export def "namespaces-activity-heartbeat RecordActivityTaskHeartbeat-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --details: any # Arbitrary data, of which the most recent call is kept, to store for this activity
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
]: any -> record<cancelRequested: bool, activityPaused: bool, activityReset: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activity-heartbeat")
  let body = {taskToken: $taskToken, details: $details, identity: $identity, namespace: $body_namespace, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RespondActivityTaskFailed is called by workers when processing an activity task fails.   For workflow activities, this results in a new `ACTIVITY_TASK_CANCELED` event being written to the workflow history  and a new workflow task created for the workflow. Fails with `NotFound` if the task token is  no longer valid due to activity timeout, already being completed, or never having existed.
#
# POST /api/v1/namespaces/{namespace}/activity-resolve-as-canceled
# operationId: RespondActivityTaskCanceled
export def "namespaces-activity-resolve-as-canceled RespondActivityTaskCanceled-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --details: any # Serialized additional information to attach to the cancellation
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
  --workerVersion: any # Version info of the worker who processed this task. This message's `build_id` field should  always be set by SDKs. Workers opting into versioning will also set the `use_versioning`  field to true. See message docstrings for more.  Deprecated. Use `deployment_options` instead.
  --deployment: any # Deployment info of the worker that completed this task. Must be present if user has set  `WorkerDeploymentOptions` regardless of versioning being enabled or not.  Deprecated. Replaced with `deployment_options`.
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/activity-resolve-as-canceled")
  let body = {taskToken: $taskToken, details: $details, identity: $identity, namespace: $body_namespace, resourceId: $resourceId, workerVersion: $workerVersion, deployment: $deployment, deploymentOptions: $deploymentOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ListArchivedWorkflowExecutions is a visibility API to list archived workflow executions in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/archived-workflows
# operationId: ListArchivedWorkflowExecutions
export def "namespaces-archived-workflows ListArchivedWorkflowExecutions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --qp-query: string
]: nothing -> record<executions: table<execution: record, type: record, startTime: string, closeTime: string, status: string, historyLength: string, parentNamespaceId: string, parentExecution: record, executionTime: string, memo: record, searchAttributes: record, autoResetPoints: record, taskQueue: string, stateTransitionCount: string, historySizeBytes: string, mostRecentWorkerVersionStamp: record, executionDuration: string, rootExecution: record, assignedBuildId: string, inheritedBuildId: string, firstRunId: string, versioningInfo: record, workerDeploymentName: string, priority: record, externalPayloadSizeBytes: string, externalPayloadCount: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/archived-workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListBatchOperations returns a list of batch operations
#
# GET /api/v1/namespaces/{namespace}/batch-operations
# operationId: ListBatchOperations
export def "namespaces-batch-operations ListBatchOperations-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # List page size (format: int32)
  --nextPageToken: string # Next page token (format: bytes)
]: nothing -> record<operationInfo: table<jobId: string, state: string, startTime: string, closeTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/batch-operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeBatchOperation returns the information about a batch operation
#
# GET /api/v1/namespaces/{namespace}/batch-operations/{jobId}
# operationId: DescribeBatchOperation
export def "namespaces-batch-operations DescribeBatchOperation-by-namespace-jobId" [
  namespace: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<operationType: string, jobId: string, state: string, startTime: string, closeTime: string, totalOperationCount: string, completeOperationCount: string, failureOperationCount: string, identity: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/batch-operations/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StartBatchOperation starts a new batch operation
#
# POST /api/v1/namespaces/{namespace}/batch-operations/{jobId}
# operationId: StartBatchOperation
# --executions item shape: {workflowId?: string, runId?: string}
# --terminationOperation shape: {details?: any, identity?: string}
# --signalOperation shape: {signal?: string, input?: any, header?: any, identity?: string}
# --cancellationOperation shape: {identity?: string}
# --deletionOperation shape: {identity?: string}
# --resetOperation shape: {identity?: string, options?: any, resetType?: "RESET_TYPE_UNSPECIFIED"|"RESET_TYPE_FIRST_WORKFLOW_TASK"|"RESET_TYPE_LAST_WORKFLOW_TASK", resetReapplyType?: "RESET_REAPPLY_TYPE_UNSPECIFIED"|"RESET_REAPPLY_TYPE_SIGNAL"|"RESET_REAPPLY_TYPE_NONE"|"RESET_REAPPLY_TYPE_ALL_ELIGIBLE", postResetOperations?: list}
# --updateWorkflowOptionsOperation shape: {identity?: string, workflowExecutionOptions?: any, updateMask?: string}
# --unpauseActivitiesOperation shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, jitter?: string}
# --resetActivitiesOperation shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, keepPaused?: bool, jitter?: string, restoreOriginalOptions?: bool}
# --updateActivityOptionsOperation shape: {identity?: string, type?: string, matchAll?: bool, activityOptions?: any, updateMask?: string, restoreOriginal?: bool}
export def "namespaces-batch-operations StartBatchOperation-by-namespace-jobId" [
  namespace: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace that contains the batch operation
  --visibilityQuery: string # Visibility query defines the the group of workflow to apply the batch operation  This field and `executions` are mutually exclusive
  --body-jobId: string # Job ID defines the unique ID for the batch job
  --reason: string # Reason to perform the batch operation
  --executions: list # Executions to apply the batch operation  This field and `visibility_query` are mutually exclusive — item shape: {workflowId?: string, runId?: string}
  --maxOperationsPerSecond: float # Limit for the number of operations processed per second within this batch.  Its purpose is to reduce the stress on the system caused by batch operations, which helps to prevent system  overload and minimize potential delays in executing ongoing tasks for user workers.  Note that when no explicit limit is provided, the server will operate according to its limit defined by the  dynamic configuration key `worker.batcherRPS`. This also applies if the value in this field exceeds the  server's configured limit. (format: float)
  --terminationOperation: record # BatchOperationTermination sends terminate requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.TerminateWorkflowExecutionRequest.  Ignore first_execution_run_id because this is used for single workflow operation. — shape: {details?: any, identity?: string}
  --signalOperation: record # BatchOperationSignal sends signals to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest. — shape: {signal?: string, input?: any, header?: any, identity?: string}
  --cancellationOperation: record # BatchOperationCancellation sends cancel requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionRequest.  Ignore first_execution_run_id because this is used for single workflow operation. — shape: {identity?: string}
  --deletionOperation: record # BatchOperationDeletion sends deletion requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.DeleteWorkflowExecutionRequest. — shape: {identity?: string}
  --resetOperation: record # BatchOperationReset sends reset requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.ResetWorkflowExecutionRequest. — shape: {identity?: string, options?: any, resetType?: "RESET_TYPE_UNSPECIFIED"|"RESET_TYPE_FIRST_WORKFLOW_TASK"|"RESET_TYPE_LAST_WORKFLOW_TASK", resetReapplyType?: "RESET_REAPPLY_TYPE_UNSPECIFIED"|"RESET_REAPPLY_TYPE_SIGNAL"|"RESET_REAPPLY_TYPE_NONE"|"RESET_REAPPLY_TYPE_ALL_ELIGIBLE", postResetOperations?: list}
  --updateWorkflowOptionsOperation: record # BatchOperationUpdateWorkflowExecutionOptions sends UpdateWorkflowExecutionOptions requests to batch workflows.  Keep the parameters in sync with temporal.api.workflowservice.v1.UpdateWorkflowExecutionOptionsRequest. — shape: {identity?: string, workflowExecutionOptions?: any, updateMask?: string}
  --unpauseActivitiesOperation: record # BatchOperationUnpauseActivities sends unpause requests to batch workflows. — shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, jitter?: string}
  --resetActivitiesOperation: record # BatchOperationResetActivities sends activity reset requests in a batch.  NOTE: keep in sync with temporal.api.workflowservice.v1.ResetActivityRequest — shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, keepPaused?: bool, jitter?: string, restoreOriginalOptions?: bool}
  --updateActivityOptionsOperation: record # BatchOperationUpdateActivityOptions sends an update-activity-options requests in a batch.  NOTE: keep in sync with temporal.api.workflowservice.v1.UpdateActivityRequest — shape: {identity?: string, type?: string, matchAll?: bool, activityOptions?: any, updateMask?: string, restoreOriginal?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/batch-operations/($jobId)")
  let body = {namespace: $body_namespace, visibilityQuery: $visibilityQuery, jobId: $body_jobId, reason: $reason, executions: $executions, maxOperationsPerSecond: $maxOperationsPerSecond, terminationOperation: $terminationOperation, signalOperation: $signalOperation, cancellationOperation: $cancellationOperation, deletionOperation: $deletionOperation, resetOperation: $resetOperation, updateWorkflowOptionsOperation: $updateWorkflowOptionsOperation, unpauseActivitiesOperation: $unpauseActivitiesOperation, resetActivitiesOperation: $resetActivitiesOperation, updateActivityOptionsOperation: $updateActivityOptionsOperation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# StopBatchOperation stops a batch operation
#
# POST /api/v1/namespaces/{namespace}/batch-operations/{jobId}/stop
# operationId: StopBatchOperation
export def "namespaces-batch-operations-stop StopBatchOperation-by-namespace-jobId" [
  namespace: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace that contains the batch operation
  --body-jobId: string # Batch job id
  --reason: string # Reason to stop a batch operation
  --identity: string # Identity of the operator
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/batch-operations/($jobId)/stop")
  let body = {namespace: $body_namespace, jobId: $body_jobId, reason: $reason, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets a deployment as the current deployment for its deployment series. Can optionally update  the metadata of the deployment as well.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced by `SetWorkerDeploymentCurrentVersion`.
#
# POST /api/v1/namespaces/{namespace}/current-deployment/{deployment.series_name}
# operationId: SetCurrentDeployment
# --deployment shape: {seriesName?: string, buildId?: string}
export def "namespaces-current-deployment SetCurrentDeployment-by-namespace-deployment.series_name" [
  namespace: string
  deployment.series_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deployment: record # `Deployment` identifies a deployment of Temporal workers. The combination of deployment series  name + build ID serves as the identifier. User can use `WorkerDeploymentOptions` in their worker  programs to specify these values.  Deprecated. — shape: {seriesName?: string, buildId?: string}
  --identity: string # Optional. The identity of the client who initiated this request.
  --updateMetadata: any # Optional. Use to add or remove user-defined metadata entries. Metadata entries are exposed  when describing a deployment. It is a good place for information such as operator name,  links to internal deployment pipelines, etc.
]: any -> record<currentDeploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>, previousDeploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/current-deployment/($deployment.series_name)")
  let body = {namespace: $body_namespace, deployment: $deployment, identity: $identity, updateMetadata: $updateMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the current deployment (and its info) for a given deployment series.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced by `current_version` returned by `DescribeWorkerDeployment`.
#
# GET /api/v1/namespaces/{namespace}/current-deployment/{seriesName}
# operationId: GetCurrentDeployment
export def "namespaces-current-deployment GetCurrentDeployment-by-namespace-seriesName" [
  namespace: string
  seriesName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentDeploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/current-deployment/($seriesName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists worker deployments in the namespace. Optionally can filter based on deployment series  name.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced with `ListWorkerDeployments`.
#
# GET /api/v1/namespaces/{namespace}/deployments
# operationId: ListDeployments
export def "namespaces-deployments ListDeployments-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --seriesName: string # Optional. Use to filter based on exact series name match.
]: nothing -> record<nextPageToken: string, deployments: table<deployment: record, createTime: string, isCurrent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "seriesName" $seriesName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a worker deployment.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced with `DescribeWorkerDeploymentVersion`.
#
# GET /api/v1/namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}
# operationId: DescribeDeployment
export def "namespaces-deployments DescribeDeployment-by-namespace-deployment.series_name-deployment.build_id" [
  namespace: string
  deployment.series_name: string
  deployment.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploymentseriesName: string # Different versions of the same worker service/application are related together by having a  shared series name.  Out of all deployments of a series, one can be designated as the current deployment, which  receives new workflow executions and new tasks of workflows with  `VERSIONING_BEHAVIOR_AUTO_UPGRADE` versioning behavior.
  --deploymentbuildId: string # Build ID changes with each version of the worker when the worker program code and/or config  changes.
]: nothing -> record<deploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment.seriesName" $deploymentseriesName "scalar") (serialize-qp "deployment.buildId" $deploymentbuildId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/deployments/($deployment.series_name)/($deployment.build_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the reachability level of a worker deployment to help users decide when it is time  to decommission a deployment. Reachability level is calculated based on the deployment's  `status` and existing workflows that depend on the given deployment for their execution.  Calculating reachability is relatively expensive. Therefore, server might return a recently  cached value. In such a case, the `last_update_time` will inform you about the actual  reachability calculation time.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced with `DrainageInfo` returned by `DescribeWorkerDeploymentVersion`.
#
# GET /api/v1/namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}/reachability
# operationId: GetDeploymentReachability
export def "namespaces-deployments-reachability GetDeploymentReachability-by-namespace-deployment.series_name-deployment.build_id" [
  namespace: string
  deployment.series_name: string
  deployment.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploymentseriesName: string # Different versions of the same worker service/application are related together by having a  shared series name.  Out of all deployments of a series, one can be designated as the current deployment, which  receives new workflow executions and new tasks of workflows with  `VERSIONING_BEHAVIOR_AUTO_UPGRADE` versioning behavior.
  --deploymentbuildId: string # Build ID changes with each version of the worker when the worker program code and/or config  changes.
]: nothing -> record<deploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>, reachability: string, lastUpdateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment.seriesName" $deploymentseriesName "scalar") (serialize-qp "deployment.buildId" $deploymentbuildId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/deployments/($deployment.series_name)/($deployment.build_id)/reachability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CountNexusOperationExecutions is a visibility API to count Nexus operations in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/nexus-operation-count
# operationId: CountNexusOperationExecutions
export def "namespaces-nexus-operation-count CountNexusOperationExecutions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.  See also ListNexusOperationExecutionsRequest for search attributes available for Nexus operations.
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/nexus-operation-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListNexusOperationExecutions is a visibility API to list Nexus operations in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/nexus-operations
# operationId: ListNexusOperationExecutions
export def "namespaces-nexus-operations ListNexusOperationExecutions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Max number of operations to return per page. (format: int32)
  --nextPageToken: string # Token returned in ListNexusOperationExecutionsResponse. (format: bytes)
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.  Search attributes that are avaialble for Nexus operations include:  - OperationId  - RunId  - Endpoint  - Service  - Operation  - RequestId  - StartTime  - ExecutionTime  - CloseTime  - ExecutionStatus  - ExecutionDuration  - StateTransitionCount
]: nothing -> record<operations: table<operationId: string, runId: string, endpoint: string, service: string, operation: string, scheduleTime: string, closeTime: string, status: string, searchAttributes: record, stateTransitionCount: string, executionDuration: string, stateSizeBytes: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/nexus-operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeNexusOperationExecution returns information about a Nexus operation.  Supported use cases include:  - Get current operation info without waiting  - Long-poll for next state change and return new operation info  Response can optionally include operation input or outcome (if the operation has completed).
#
# GET /api/v1/namespaces/{namespace}/nexus-operations/{operationId}
# operationId: DescribeNexusOperationExecution
export def "namespaces-nexus-operations DescribeNexusOperationExecution-by-namespace-operationId" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Operation run ID. If empty the request targets the latest run.
  --includeInput: oneof<nothing, bool> # Include the input field in the response.
  --includeOutcome: oneof<nothing, bool> # Include the outcome (result/failure) in the response if the operation has completed.
  --longPollToken: string # Token from a previous DescribeNexusOperationExecutionResponse. If present, this RPC will long-poll until operation  state changes from the state encoded in this token. If absent, return current state immediately.  If present, run_id must also be present.  Note that operation state may change multiple times between requests, therefore it is not  guaranteed that a client making a sequence of long-poll requests will see a complete  sequence of state changes. (format: bytes)
]: nothing -> record<runId: string, info: record<operationId: string, runId: string, endpoint: string, service: string, operation: string, status: string, state: string, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, attempt: int, scheduleTime: string, expirationTime: string, closeTime: string, lastAttemptCompleteTime: string, lastAttemptFailure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, nextAttemptScheduleTime: string, executionDuration: string, cancellationInfo: record<requestedTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, blockedReason: string, reason: string>, blockedReason: string, requestId: string, operationToken: string, stateTransitionCount: string, searchAttributes: record<indexedFields: record>, nexusHeader: record, userMetadata: record<summary: record, details: record>, links: list<record>, identity: string, stateSizeBytes: string>, input: record, result: record, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, applicationFailureInfo: record<type: string, nonRetryable: bool, details: record, nextRetryDelay: string, category: string>, timeoutFailureInfo: record<timeoutType: string, lastHeartbeatDetails: record>, canceledFailureInfo: record<details: record, identity: string>, terminatedFailureInfo: record<identity: string>, serverFailureInfo: record<nonRetryable: bool>, resetWorkflowFailureInfo: record<lastHeartbeatDetails: record>, activityFailureInfo: record<scheduledEventId: string, startedEventId: string, identity: string, activityType: record, activityId: string, retryState: string>, childWorkflowExecutionFailureInfo: record<namespace: string, workflowExecution: record, workflowType: record, initiatedEventId: string, startedEventId: string, retryState: string>, nexusOperationExecutionFailureInfo: record<scheduledEventId: string, endpoint: string, service: string, operation: string, operationId: string, operationToken: string>, nexusHandlerFailureInfo: record<type: string, retryBehavior: string>>, longPollToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar") (serialize-qp "includeInput" $includeInput "scalar") (serialize-qp "includeOutcome" $includeOutcome "scalar") (serialize-qp "longPollToken" $longPollToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/nexus-operations/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StartNexusOperationExecution starts a new Nexus operation.   Returns a `NexusOperationExecutionAlreadyStarted` error if an instance already exists with same operation ID in this  namespace unless permitted by the specified ID conflict policy.
#
# POST /api/v1/namespaces/{namespace}/nexus-operations/{operationId}
# operationId: StartNexusOperationExecution
export def "namespaces-nexus-operations StartNexusOperationExecution-by-namespace-operationId" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this caller-side start request. Typically UUIDv4.  StartOperation requests sent to the handler will use a server-generated request ID.
  --body-operationId: string # Identifier for this operation. This is a caller-side ID, distinct from any internal  operation identifiers generated by the handler. Must be unique among operations in the  same namespace, subject to the rules imposed by id_reuse_policy and id_conflict_policy.
  --endpoint: string # Endpoint name, resolved to a URL via the cluster's endpoint registry.
  --service: string # Service name.
  --operation: string # Operation name.
  --scheduleToCloseTimeout: string # Schedule-to-close timeout for this operation.  Indicates how long the caller is willing to wait for operation completion.  Calls are retried internally by the server.  (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --scheduleToStartTimeout: string # Schedule-to-start timeout for this operation.  Indicates how long the caller is willing to wait for the operation to be started (or completed if synchronous)  by the handler.  If not set or zero, no schedule-to-start timeout is enforced.  (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --startToCloseTimeout: string # Start-to-close timeout for this operation.  Indicates how long the caller is willing to wait for an asynchronous operation to complete after it has been  started. Synchronous operations ignore this timeout.  If not set or zero, no start-to-close timeout is enforced.  (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --input: any # Serialized input to the operation. Passed as the request payload.
  --idReusePolicy: string@idReusePolicy-completer-1 # Defines whether to allow re-using the operation id from a previously *closed* operation.  The default policy is NEXUS_OPERATION_ID_REUSE_POLICY_ALLOW_DUPLICATE. (format: enum)
  --idConflictPolicy: string@idConflictPolicy-completer-1 # Defines how to resolve an operation id conflict with a *running* operation.  The default policy is NEXUS_OPERATION_ID_CONFLICT_POLICY_FAIL. (format: enum)
  --searchAttributes: any # Search attributes for indexing.
  --nexusHeader: record # Header to attach to the Nexus request.  Users are responsible for encrypting sensitive data in this header as it is stored in workflow history and  transmitted to external services as-is.  This is useful for propagating tracing information.  Note these headers are not the same as Temporal headers on internal activities and child workflows, these are  transmitted to Nexus operations that may be external and are not traditional payloads.
  --userMetadata: any # Metadata for use by user interfaces to display the fixed as-of-start summary and details of the operation.
]: any -> record<runId: string, started: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/nexus-operations/($operationId)")
  let body = {namespace: $body_namespace, identity: $identity, requestId: $requestId, operationId: $body_operationId, endpoint: $endpoint, service: $service, operation: $operation, scheduleToCloseTimeout: $scheduleToCloseTimeout, scheduleToStartTimeout: $scheduleToStartTimeout, startToCloseTimeout: $startToCloseTimeout, input: $input, idReusePolicy: $idReusePolicy, idConflictPolicy: $idConflictPolicy, searchAttributes: $searchAttributes, nexusHeader: $nexusHeader, userMetadata: $userMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RequestCancelNexusOperationExecution requests cancellation of a Nexus operation.   Requesting to cancel an operation does not automatically transition the operation to canceled status.  The operation will only transition to canceled status if it supports cancellation and the handler  processes the cancellation request.
#
# POST /api/v1/namespaces/{namespace}/nexus-operations/{operationId}/cancel
# operationId: RequestCancelNexusOperationExecution
export def "namespaces-nexus-operations-cancel RequestCancelNexusOperationExecution-by-namespace-operationId" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-operationId: string
  --runId: string # Operation run ID, targets the latest run if empty.
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # Used to de-dupe cancellation requests.
  --reason: string # Reason for requesting the cancellation, recorded and available via the DescribeNexusOperationExecution API.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/nexus-operations/($operationId)/cancel")
  let body = {namespace: $body_namespace, operationId: $body_operationId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PollNexusOperationExecution long-polls for a Nexus operation for a given wait stage to complete and returns  the outcome (result or failure).
#
# GET /api/v1/namespaces/{namespace}/nexus-operations/{operationId}/poll
# operationId: PollNexusOperationExecution
export def "namespaces-nexus-operations-poll PollNexusOperationExecution-by-namespace-operationId" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Operation run ID. If empty the request targets the latest run.
  --waitStage: string@waitStage-completer # Stage to wait for. The operation may be in a more advanced stage when the poll is unblocked. (format: enum)
]: nothing -> record<runId: string, waitStage: string, operationToken: string, result: record, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, applicationFailureInfo: record<type: string, nonRetryable: bool, details: record, nextRetryDelay: string, category: string>, timeoutFailureInfo: record<timeoutType: string, lastHeartbeatDetails: record>, canceledFailureInfo: record<details: record, identity: string>, terminatedFailureInfo: record<identity: string>, serverFailureInfo: record<nonRetryable: bool>, resetWorkflowFailureInfo: record<lastHeartbeatDetails: record>, activityFailureInfo: record<scheduledEventId: string, startedEventId: string, identity: string, activityType: record, activityId: string, retryState: string>, childWorkflowExecutionFailureInfo: record<namespace: string, workflowExecution: record, workflowType: record, initiatedEventId: string, startedEventId: string, retryState: string>, nexusOperationExecutionFailureInfo: record<scheduledEventId: string, endpoint: string, service: string, operation: string, operationId: string, operationToken: string>, nexusHandlerFailureInfo: record<type: string, retryBehavior: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar") (serialize-qp "waitStage" $waitStage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/nexus-operations/($operationId)/poll" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# TerminateNexusOperationExecution terminates an existing Nexus operation immediately.   Termination happens immediately and the operation handler cannot react to it. A terminated operation will have  its outcome set to a failure with a termination reason.
#
# POST /api/v1/namespaces/{namespace}/nexus-operations/{operationId}/terminate
# operationId: TerminateNexusOperationExecution
export def "namespaces-nexus-operations-terminate TerminateNexusOperationExecution-by-namespace-operationId" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-operationId: string
  --runId: string # Operation run ID, targets the latest run if empty.
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # Used to de-dupe termination requests.
  --reason: string # Reason for requesting the termination, recorded in the operation's result failure outcome.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/nexus-operations/($operationId)/terminate")
  let body = {namespace: $body_namespace, operationId: $body_operationId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CountSchedules is a visibility API to count schedules in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/schedule-count
# operationId: CountSchedules
export def "namespaces-schedule-count CountSchedules-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedule-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all schedules in a namespace.
#
# GET /api/v1/namespaces/{namespace}/schedules
# operationId: ListSchedules
export def "namespaces-schedules ListSchedules-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximumPageSize: int # How many to return at once. (format: int32)
  --nextPageToken: string # Token to get the next page of results. (format: bytes)
  --qp-query: string # Query to filter schedules.
]: nothing -> record<schedules: table<scheduleId: string, memo: record, searchAttributes: record, info: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maximumPageSize" $maximumPageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the schedule description and current state of an existing schedule.
#
# GET /api/v1/namespaces/{namespace}/schedules/{scheduleId}
# operationId: DescribeSchedule
export def "namespaces-schedules DescribeSchedule-by-namespace-scheduleId" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule: record<spec: record<structuredCalendar: list, cronString: list, calendar: list, interval: list, excludeCalendar: list, excludeStructuredCalendar: list, startTime: string, endTime: string, jitter: string, timezoneName: string, timezoneData: string>, action: record<startWorkflow: record>, policies: record<overlapPolicy: string, catchupWindow: string, pauseOnFailure: bool, keepOriginalWorkflowId: bool>, state: record<notes: string, paused: bool, limitedActions: bool, remainingActions: string>>, info: record<actionCount: string, missedCatchupWindow: string, overlapSkipped: string, bufferDropped: string, bufferSize: string, runningWorkflows: list<record>, recentActions: list<record>, futureActionTimes: list<string>, createTime: string, updateTime: string, invalidScheduleError: string, stateSizeBytes: string>, memo: record<fields: record>, searchAttributes: record<indexedFields: record>, conflictToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new schedule.
#
# POST /api/v1/namespaces/{namespace}/schedules/{scheduleId}
# operationId: CreateSchedule
# --searchAttributes shape: {indexedFields?: record}
export def "namespaces-schedules CreateSchedule-by-namespace-scheduleId" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace the schedule should be created in.
  --body-scheduleId: string # The id of the new schedule.
  --schedule: any # The schedule spec, policies, action, and initial state.
  --initialPatch: any # Optional initial patch (e.g. to run the action once immediately).
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.
  --memo: any # Memo and search attributes to attach to the schedule itself.
  --searchAttributes: record # A user-defined set of *indexed* fields that are used/exposed when listing/searching workflows.  The payload is not serialized in a user-defined way. — shape: {indexedFields?: record}
]: any -> record<conflictToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedules/($scheduleId)")
  let body = {namespace: $body_namespace, scheduleId: $body_scheduleId, schedule: $schedule, initialPatch: $initialPatch, identity: $identity, requestId: $requestId, memo: $memo, searchAttributes: $searchAttributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a schedule, removing it from the system.
#
# DELETE /api/v1/namespaces/{namespace}/schedules/{scheduleId}
# operationId: DeleteSchedule
export def "namespaces-schedules DeleteSchedule-by-namespace-scheduleId" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # The identity of the client who initiated this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity" $identity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedules/($scheduleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists matching times within a range.
#
# GET /api/v1/namespaces/{namespace}/schedules/{scheduleId}/matching-times
# operationId: ListScheduleMatchingTimes
export def "namespaces-schedules-matching-times ListScheduleMatchingTimes-by-namespace-scheduleId" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startTime: string # Time range to query. (format: date-time)
  --endTime: string # format: date-time
]: nothing -> record<startTime: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedules/($scheduleId)/matching-times" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Makes a specific change to a schedule or triggers an immediate action.
#
# POST /api/v1/namespaces/{namespace}/schedules/{scheduleId}/patch
# operationId: PatchSchedule
# --patch shape: {triggerImmediately?: any, backfillRequest?: list, pause?: string, unpause?: string}
export def "namespaces-schedules-patch PatchSchedule-by-namespace-scheduleId" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace of the schedule to patch.
  --body-scheduleId: string # The id of the schedule to patch.
  --patch: record # shape: {triggerImmediately?: any, backfillRequest?: list, pause?: string, unpause?: string}
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this update request for idempotence. Typically UUIDv4.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedules/($scheduleId)/patch")
  let body = {namespace: $body_namespace, scheduleId: $body_scheduleId, patch: $patch, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Changes the configuration or state of an existing schedule.
#
# POST /api/v1/namespaces/{namespace}/schedules/{scheduleId}/update
# operationId: UpdateSchedule
export def "namespaces-schedules-update UpdateSchedule-by-namespace-scheduleId" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace of the schedule to update.
  --body-scheduleId: string # The id of the schedule to update.
  --schedule: any # The new schedule. The four main fields of the schedule (spec, action,  policies, state) are replaced completely by the values in this message.
  --conflictToken: string # This can be the value of conflict_token from a DescribeScheduleResponse,  which will cause this request to fail if the schedule has been modified  between the Describe and this Update.  If missing, the schedule will be updated unconditionally. (format: bytes)
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this update request for idempotence. Typically UUIDv4.
  --searchAttributes: any # Schedule search attributes to be updated.  Do not set this field if you do not want to update the search attributes.  A non-null empty object will set the search attributes to an empty map.  Note: you cannot only update the search attributes with `UpdateScheduleRequest`,  you must also set the `schedule` field; otherwise, it will unset the schedule.
  --memo: any # Schedule memo to replace. If set, replaces the entire memo.  Do not set this field if you do not want to update the memo.  A non-null empty object will clear the memo.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/schedules/($scheduleId)/update")
  let body = {namespace: $body_namespace, scheduleId: $body_scheduleId, schedule: $schedule, conflictToken: $conflictToken, identity: $identity, requestId: $requestId, searchAttributes: $searchAttributes, memo: $memo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ListSearchAttributes returns comprehensive information about search attributes.
#
# GET /api/v1/namespaces/{namespace}/search-attributes
# operationId: ListSearchAttributes
export def "namespaces-search-attributes ListSearchAttributes" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customAttributes: record, systemAttributes: record, storageSchema: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/search-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates task queue configuration.  For the overall queue rate limit: the rate limit set by this api overrides the worker-set rate limit,  which uncouples the rate limit from the worker lifecycle.  If the overall queue rate limit is unset, the worker-set rate limit takes effect.
#
# POST /api/v1/namespaces/{namespace}/task-queues/{taskQueue}/update-config
# operationId: UpdateTaskQueueConfig
export def "namespaces-task-queues-update-config UpdateTaskQueueConfig-by-namespace-taskQueue" [
  namespace: string
  taskQueue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --identity: string
  --body-taskQueue: string # Selects the task queue to update.
  --taskQueueType: string@taskQueueType-completer # format: enum
  --updateQueueRateLimit: any # Update to queue-wide rate limit.  If not set, this configuration is unchanged.  NOTE: A limit set by the worker is overriden; and restored again when reset.  If the `rate_limit` field in the `RateLimitUpdate` is missing, remove the existing rate limit.
  --updateFairnessKeyRateLimitDefault: any # Update to the default fairness key rate limit.  If not set, this configuration is unchanged.  If the `rate_limit` field in the `RateLimitUpdate` is missing, remove the existing rate limit.
  --setFairnessWeightOverrides: record # If set, overrides the fairness weight for each specified fairness key.  Fairness keys not listed in this map will keep their existing overrides (if any).
  --unsetFairnessWeightOverrides: list # If set, removes any existing fairness weight overrides for each specified fairness key.  Fairness weights for corresponding keys fall back to the values set during task creation (if any),  or to the default weight of 1.0.
]: any -> record<config: record<queueRateLimit: record<rateLimit: record, metadata: record>, fairnessKeysRateLimitDefault: record<rateLimit: record, metadata: record>, fairnessWeightOverrides: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/task-queues/($taskQueue)/update-config")
  let body = {namespace: $body_namespace, identity: $identity, taskQueue: $body_taskQueue, taskQueueType: $taskQueueType, updateQueueRateLimit: $updateQueueRateLimit, updateFairnessKeyRateLimitDefault: $updateFairnessKeyRateLimitDefault, setFairnessWeightOverrides: $setFairnessWeightOverrides, unsetFairnessWeightOverrides: $unsetFairnessWeightOverrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deprecated. Use `GetWorkerVersioningRules`.  Will be removed in server version v1.32.0.  Fetches the worker build id versioning sets for a task queue.
#
# GET /api/v1/namespaces/{namespace}/task-queues/{taskQueue}/worker-build-id-compatibility
# operationId: GetWorkerBuildIdCompatibility
export def "namespaces-task-queues-worker-build-id-compatibility GetWorkerBuildIdCompatibility-by-namespace-taskQueue" [
  namespace: string
  taskQueue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxSets: int # Limits how many compatible sets will be returned. Specify 1 to only return the current  default major version set. 0 returns all sets. (format: int32)
]: nothing -> record<majorVersionSets: table<buildIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxSets" $maxSets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/task-queues/($taskQueue)/worker-build-id-compatibility" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches the Build ID assignment and redirect rules for a Task Queue.  Will be removed in server version v1.32.0.
#
# GET /api/v1/namespaces/{namespace}/task-queues/{taskQueue}/worker-versioning-rules
# operationId: GetWorkerVersioningRules
export def "namespaces-task-queues-worker-versioning-rules GetWorkerVersioningRules-by-namespace-taskQueue" [
  namespace: string
  taskQueue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignmentRules: table<rule: record, createTime: string>, compatibleRedirectRules: table<rule: record, createTime: string>, conflictToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/task-queues/($taskQueue)/worker-versioning-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeTaskQueue returns the following information about the target task queue, broken down by Build ID:    - List of pollers    - Workflow Reachability status    - Backlog info for Workflow and/or Activity tasks
#
# GET /api/v1/namespaces/{namespace}/task-queues/{task_queue.name}
# operationId: DescribeTaskQueue
export def "namespaces-task-queues DescribeTaskQueue-by-namespace-task_queue.name" [
  namespace: string
  task_queue.name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskQueuename: string
  --taskQueuekind: string@taskQueuekind-completer # Default: TASK_QUEUE_KIND_NORMAL. (format: enum)
  --taskQueuenormalName: string # Iff kind == TASK_QUEUE_KIND_STICKY, then this field contains the name of  the normal task queue that the sticky worker is running on.
  --taskQueueType: string@taskQueueType-completer # If unspecified (TASK_QUEUE_TYPE_UNSPECIFIED), then default value (TASK_QUEUE_TYPE_WORKFLOW) will be used.  Only supported in default mode (use `task_queue_types` in ENHANCED mode instead). (format: enum)
  --reportStats: oneof<nothing, bool> # Report stats for the requested task queue type(s).
  --reportConfig: oneof<nothing, bool> # Report Task Queue Config
  --includeTaskQueueStatus: oneof<nothing, bool> # Deprecated, use `report_stats` instead.  If true, the task queue status will be included in the response.
  --apiMode: string@apiMode-completer # Deprecated. ENHANCED mode is also being deprecated.  Select the API mode to use for this request: DEFAULT mode (if unset) or ENHANCED mode.  Consult the documentation for each field to understand which mode it is supported in. (format: enum)
  --versionsbuildIds: list # Include specific Build IDs.
  --versionsunversioned: oneof<nothing, bool> # Include the unversioned queue.
  --versionsallActive: oneof<nothing, bool> # Include all active versions. A version is considered active if, in the last few minutes,  it has had new tasks or polls, or it has been the subject of certain task queue API calls.
  --taskQueueTypes: list # Deprecated (as part of the ENHANCED mode deprecation).  Task queue types to report info about. If not specified, all types are considered.
  --reportPollers: oneof<nothing, bool> # Deprecated (as part of the ENHANCED mode deprecation).  Report list of pollers for requested task queue types and versions.
  --reportTaskReachability: oneof<nothing, bool> # Deprecated (as part of the ENHANCED mode deprecation).  Report task reachability for the requested versions and all task types (task reachability is not reported  per task type).
]: nothing -> record<pollers: table<lastAccessTime: string, identity: string, ratePerSecond: float, workerVersionCapabilities: record, deploymentOptions: record>, stats: record<approximateBacklogCount: string, approximateBacklogAge: string, tasksAddRate: float, tasksDispatchRate: float>, statsByPriorityKey: record, versioningInfo: record<currentDeploymentVersion: record<buildId: string, deploymentName: string>, currentVersion: string, rampingDeploymentVersion: record<buildId: string, deploymentName: string>, rampingVersion: string, rampingVersionPercentage: float, updateTime: string>, config: record<queueRateLimit: record<rateLimit: record, metadata: record>, fairnessKeysRateLimitDefault: record<rateLimit: record, metadata: record>, fairnessWeightOverrides: record>, effectiveRateLimit: record<requestsPerSecond: float, rateLimitSource: string>, taskQueueStatus: record<backlogCountHint: string, readLevel: string, ackLevel: string, ratePerSecond: float, taskIdBlock: record<startId: string, endId: string>>, versionsInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskQueue.name" $taskQueuename "scalar") (serialize-qp "taskQueue.kind" $taskQueuekind "scalar") (serialize-qp "taskQueue.normalName" $taskQueuenormalName "scalar") (serialize-qp "taskQueueType" $taskQueueType "scalar") (serialize-qp "reportStats" $reportStats "scalar") (serialize-qp "reportConfig" $reportConfig "scalar") (serialize-qp "includeTaskQueueStatus" $includeTaskQueueStatus "scalar") (serialize-qp "apiMode" $apiMode "scalar") (serialize-qp "versions.buildIds" $versionsbuildIds "multi") (serialize-qp "versions.unversioned" $versionsunversioned "scalar") (serialize-qp "versions.allActive" $versionsallActive "scalar") (serialize-qp "taskQueueTypes" $taskQueueTypes "multi") (serialize-qp "reportPollers" $reportPollers "scalar") (serialize-qp "reportTaskReachability" $reportTaskReachability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/task-queues/($task_queue.name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# UpdateNamespace is used to update the information and configuration of a registered  namespace.
#
# POST /api/v1/namespaces/{namespace}/update
# operationId: UpdateNamespace
# --updateInfo shape: {description?: string, ownerEmail?: string, data?: record, state?: "NAMESPACE_STATE_UNSPECIFIED"|"NAMESPACE_STATE_REGISTERED"|"NAMESPACE_STATE_DEPRECATED"|"NAMESPACE_STATE_DELETED"}
# --config shape: {workflowExecutionRetentionTtl?: string, badBinaries?: record, historyArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", historyArchivalUri?: string, visibilityArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", visibilityArchivalUri?: string, customSearchAttributeAliases?: record}
# --replicationConfig shape: {activeClusterName?: string, clusters?: list, state?: "REPLICATION_STATE_UNSPECIFIED"|"REPLICATION_STATE_NORMAL"|"REPLICATION_STATE_HANDOVER"}
export def "namespaces-update UpdateNamespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --updateInfo: record # shape: {description?: string, ownerEmail?: string, data?: record, state?: "NAMESPACE_STATE_UNSPECIFIED"|"NAMESPACE_STATE_REGISTERED"|"NAMESPACE_STATE_DEPRECATED"|"NAMESPACE_STATE_DELETED"}
  --config: record # shape: {workflowExecutionRetentionTtl?: string, badBinaries?: record, historyArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", historyArchivalUri?: string, visibilityArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", visibilityArchivalUri?: string, customSearchAttributeAliases?: record}
  --replicationConfig: record # shape: {activeClusterName?: string, clusters?: list, state?: "REPLICATION_STATE_UNSPECIFIED"|"REPLICATION_STATE_NORMAL"|"REPLICATION_STATE_HANDOVER"}
  --securityToken: string
  --deleteBadBinary: string
  --promoteNamespace: oneof<nothing, bool> # promote local namespace to global namespace. Ignored if namespace is already global namespace.
]: any -> record<namespaceInfo: record<name: string, state: string, description: string, ownerEmail: string, data: record, id: string, capabilities: record<eagerWorkflowStart: bool, syncUpdate: bool, asyncUpdate: bool, workerHeartbeats: bool, reportedProblemsSearchAttribute: bool, workflowPause: bool, standaloneActivities: bool, workerPollCompleteOnShutdown: bool, pollerAutoscaling: bool, workerCommands: bool, standaloneNexusOperation: bool, workflowUpdateCallbacks: bool>, limits: record<blobSizeLimitError: string, memoSizeLimitError: string>, supportsSchedules: bool>, config: record<workflowExecutionRetentionTtl: string, badBinaries: record<binaries: record>, historyArchivalState: string, historyArchivalUri: string, visibilityArchivalState: string, visibilityArchivalUri: string, customSearchAttributeAliases: record>, replicationConfig: record<activeClusterName: string, clusters: list<record>, state: string>, failoverVersion: string, isGlobalNamespace: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/update")
  let body = {namespace: $body_namespace, updateInfo: $updateInfo, config: $config, replicationConfig: $replicationConfig, securityToken: $securityToken, deleteBadBinary: $deleteBadBinary, promoteNamespace: $promoteNamespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CountWorkers counts the number of workers in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/worker-count
# operationId: CountWorkers
export def "namespaces-worker-count CountWorkers-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to filter workers before counting.  Supported filter fields are the same as in ListWorkersRequest.
  --includeSystemWorkers: oneof<nothing, bool> # When true, the count will include system workers that are created implicitly  by the server and not by the user. By default, system workers are excluded.
]: nothing -> record<count: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "includeSystemWorkers" $includeSystemWorkers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Worker Deployment Version.   Experimental. This API might significantly change or be removed in a  future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}
# operationId: CreateWorkerDeploymentVersion
export def "namespaces-worker-deployment-versions CreateWorkerDeploymentVersion-by-namespace-deployment_version.deployment_name" [
  namespace: string
  deployment_version.deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deploymentVersion: any # Required.
  --computeConfig: any # Optional. Contains the new worker compute configuration for the Worker  Deployment. Used for worker scale management.
  --identity: string # Optional. The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.  If a second request with the same ID is recieved, it is considered a successful no-op.  Retrying with a different request ID for the same deployment name + build ID is an error.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)")
  let body = {namespace: $body_namespace, deploymentVersion: $deploymentVersion, computeConfig: $computeConfig, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a worker deployment version.  Experimental. This API might significantly change or be removed in a future release.
#
# GET /api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}
# operationId: DescribeWorkerDeploymentVersion
export def "namespaces-worker-deployment-versions DescribeWorkerDeploymentVersion-by-namespace-deployment_version.deployment_name-deployment_version.build_id" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Deprecated. Use `deployment_version`.
  --deploymentVersionbuildId: string # A unique identifier for this Version within the Deployment it is a part of.  Not necessarily unique within the namespace.  The combination of `deployment_name` and `build_id` uniquely identifies this  Version within the namespace, because Deployment names are unique within a namespace.
  --deploymentVersiondeploymentName: string # Identifies the Worker Deployment this Version is part of.
  --reportTaskQueueStats: oneof<nothing, bool> # Report stats for task queues which have been polled by this version.
]: nothing -> record<workerDeploymentVersionInfo: record<version: string, status: string, deploymentVersion: record<buildId: string, deploymentName: string>, deploymentName: string, createTime: string, routingChangedTime: string, currentSinceTime: string, rampingSinceTime: string, firstActivationTime: string, lastCurrentTime: string, lastDeactivationTime: string, rampPercentage: float, taskQueueInfos: list<record>, drainageInfo: record<status: string, lastChangedTime: string, lastCheckedTime: string>, metadata: record<entries: record>, computeConfig: record<scalingGroups: record>, lastModifierIdentity: string>, versionTaskQueues: table<name: string, type: string, stats: record, statsByPriorityKey: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "deploymentVersion.buildId" $deploymentVersionbuildId "scalar") (serialize-qp "deploymentVersion.deploymentName" $deploymentVersiondeploymentName "scalar") (serialize-qp "reportTaskQueueStats" $reportTaskQueueStats "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used for manual deletion of Versions. User can delete a Version only when all the  following conditions are met:   - It is not the Current or Ramping Version of its Deployment.   - It has no active pollers (none of the task queues in the Version have pollers)   - It is not draining (see WorkerDeploymentVersionInfo.drainage_info). This condition     can be skipped by passing `skip-drainage=true`.  Experimental. This API might significantly change or be removed in a future release.
#
# DELETE /api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}
# operationId: DeleteWorkerDeploymentVersion
export def "namespaces-worker-deployment-versions DeleteWorkerDeploymentVersion-by-namespace-deployment_version.deployment_name-deployment_version.build_id" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Deprecated. Use `deployment_version`.
  --deploymentVersionbuildId: string # A unique identifier for this Version within the Deployment it is a part of.  Not necessarily unique within the namespace.  The combination of `deployment_name` and `build_id` uniquely identifies this  Version within the namespace, because Deployment names are unique within a namespace.
  --deploymentVersiondeploymentName: string # Identifies the Worker Deployment this Version is part of.
  --skipDrainage: oneof<nothing, bool> # Pass to force deletion even if the Version is draining. In this case the open pinned  workflows will be stuck until manually moved to another version by UpdateWorkflowExecutionOptions.
  --identity: string # Optional. The identity of the client who initiated this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "deploymentVersion.buildId" $deploymentVersionbuildId "scalar") (serialize-qp "deploymentVersion.deploymentName" $deploymentVersiondeploymentName "scalar") (serialize-qp "skipDrainage" $skipDrainage "scalar") (serialize-qp "identity" $identity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the compute config attached to a Worker Deployment Version.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/update-compute-config
# operationId: UpdateWorkerDeploymentVersionComputeConfig
export def "namespaces-worker-deployment-versions-update-compute-config UpdateWorkerDeploymentVersionComputeConfig-by-namespace-deployment_version.deployment_name-deployment_version.build_id" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deploymentVersion: any # Required.
  --computeConfigScalingGroups: record # Optional. Contains the compute config scaling groups to add or update for the Worker  Deployment.
  --removeComputeConfigScalingGroups: list # Optional. Contains the compute config scaling groups to remove from the Worker Deployment.
  --identity: string # Optional. The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.  If a second request with the same ID is recieved, it is considered a successful no-op.  Retrying with a different request ID for the same deployment name + build ID is an error.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)/update-compute-config")
  let body = {namespace: $body_namespace, deploymentVersion: $deploymentVersion, computeConfigScalingGroups: $computeConfigScalingGroups, removeComputeConfigScalingGroups: $removeComputeConfigScalingGroups, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the user-given metadata attached to a Worker Deployment Version.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/update-metadata
# operationId: UpdateWorkerDeploymentVersionMetadata
export def "namespaces-worker-deployment-versions-update-metadata UpdateWorkerDeploymentVersionMetadata-by-namespace-deployment_version.deployment_name-deployment_version.build_id" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --version: string # Deprecated. Use `deployment_version`.
  --deploymentVersion: any # Required.
  --upsertEntries: record
  --removeEntries: list # List of keys to remove from the metadata.
  --identity: string # Optional. The identity of the client who initiated this request.
]: any -> record<metadata: record<entries: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)/update-metadata")
  let body = {namespace: $body_namespace, version: $version, deploymentVersion: $deploymentVersion, upsertEntries: $upsertEntries, removeEntries: $removeEntries, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validates the compute config without attaching it to a Worker Deployment Version.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/validate-compute-config
# operationId: ValidateWorkerDeploymentVersionComputeConfig
export def "namespaces-worker-deployment-versions-validate-compute-config ValidateWorkerDeploymentVersionComputeConfig-by-namespace-deployment_version.deployment_name-deployment_version.build_id" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deploymentVersion: any # Required.
  --computeConfigScalingGroups: record # Optional. Contains the compute config scaling groups to add or update for the Worker  Deployment.
  --removeComputeConfigScalingGroups: list # Optional. Contains the compute config scaling groups to remove from the Worker Deployment.
  --identity: string # Optional. The identity of the client who initiated this request.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)/validate-compute-config")
  let body = {namespace: $body_namespace, deploymentVersion: $deploymentVersion, computeConfigScalingGroups: $computeConfigScalingGroups, removeComputeConfigScalingGroups: $removeComputeConfigScalingGroups, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all Worker Deployments that are tracked in the Namespace.  Experimental. This API might significantly change or be removed in a future release.
#
# GET /api/v1/namespaces/{namespace}/worker-deployments
# operationId: ListWorkerDeployments
export def "namespaces-worker-deployments ListWorkerDeployments-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
]: nothing -> record<nextPageToken: string, workerDeployments: table<name: string, createTime: string, routingConfig: record, latestVersionSummary: record, currentVersionSummary: record, rampingVersionSummary: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a Worker Deployment.  Experimental. This API might significantly change or be removed in a future release.
#
# GET /api/v1/namespaces/{namespace}/worker-deployments/{deploymentName}
# operationId: DescribeWorkerDeployment
export def "namespaces-worker-deployments DescribeWorkerDeployment-by-namespace-deploymentName" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conflictToken: string, workerDeploymentInfo: record<name: string, versionSummaries: list<record>, createTime: string, routingConfig: record<currentDeploymentVersion: record, currentVersion: string, rampingDeploymentVersion: record, rampingVersion: string, rampingVersionPercentage: float, currentVersionChangedTime: string, rampingVersionChangedTime: string, rampingVersionPercentageChangedTime: string, revisionNumber: string>, lastModifierIdentity: string, managerIdentity: string, routingConfigUpdateState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployments/($deploymentName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Worker Deployment.   Experimental. This API might significantly change or be removed in a  future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployments/{deploymentName}
# operationId: CreateWorkerDeployment
export def "namespaces-worker-deployments CreateWorkerDeployment-by-namespace-deploymentName" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string # The name of the Worker Deployment to create. If a Worker Deployment with  this name already exists, an error will be returned.
  --identity: string # Optional. The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.
]: any -> record<conflictToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployments/($deploymentName)")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes records of (an old) Deployment. A deployment can only be deleted if  it has no Version in it.  Experimental. This API might significantly change or be removed in a future release.
#
# DELETE /api/v1/namespaces/{namespace}/worker-deployments/{deploymentName}
# operationId: DeleteWorkerDeployment
export def "namespaces-worker-deployments DeleteWorkerDeployment-by-namespace-deploymentName" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # Optional. The identity of the client who initiated this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity" $identity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set/unset the Current Version of a Worker Deployment. Automatically unsets the Ramping  Version if it is the Version being set as Current.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployments/{deploymentName}/set-current-version
# operationId: SetWorkerDeploymentCurrentVersion
export def "namespaces-worker-deployments-set-current-version SetWorkerDeploymentCurrentVersion-by-namespace-deploymentName" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string
  --version: string # Deprecated. Use `build_id`.
  --buildId: string # The build id of the Version that you want to set as Current.  Pass an empty value to set the Current Version to nil.  A nil Current Version represents all the unversioned workers (those with `UNVERSIONED` (or unspecified) `WorkerVersioningMode`.)
  --conflictToken: string # Optional. This can be the value of conflict_token from a Describe, or another Worker  Deployment API. Passing a non-nil conflict token will cause this request to fail if the  Deployment's configuration has been modified between the API call that generated the  token and this one. (format: bytes)
  --identity: string # Optional. The identity of the client who initiated this request.
  --ignoreMissingTaskQueues: oneof<nothing, bool> # Optional. By default this request would be rejected if not all the expected Task Queues are  being polled by the new Version, to protect against accidental removal of Task Queues, or  worker health issues. Pass `true` here to bypass this protection.  The set of expected Task Queues is the set of all the Task Queues that were ever poller by  the existing Current Version of the Deployment, with the following exclusions:    - Task Queues that are not used anymore (inferred by having empty backlog and a task      add_rate of 0.)    - Task Queues that are moved to another Worker Deployment (inferred by the Task Queue      having a different Current Version than the Current Version of this deployment.)  WARNING: Do not set this flag unless you are sure that the missing task queue pollers are not  needed. If the request is unexpectedly rejected due to missing pollers, then that means the  pollers have not reached to the server yet. Only set this if you expect those pollers to  never arrive.
  --allowNoPollers: oneof<nothing, bool> # Optional. By default this request will be rejected if no pollers have been seen for the proposed  Current Version, in order to protect users from routing tasks to pollers that do not exist, leading  to possible timeouts. Pass `true` here to bypass this protection.
]: any -> record<conflictToken: string, previousVersion: string, previousDeploymentVersion: record<buildId: string, deploymentName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployments/($deploymentName)/set-current-version")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, version: $version, buildId: $buildId, conflictToken: $conflictToken, identity: $identity, ignoreMissingTaskQueues: $ignoreMissingTaskQueues, allowNoPollers: $allowNoPollers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set/unset the ManagerIdentity of a Worker Deployment.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployments/{deploymentName}/set-manager
# operationId: SetWorkerDeploymentManager
export def "namespaces-worker-deployments-set-manager SetWorkerDeploymentManager-by-namespace-deploymentName" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string
  --managerIdentity: string # Arbitrary value for `manager_identity`.  Empty will unset the field.
  --self: oneof<nothing, bool> # True will set `manager_identity` to `identity`.
  --conflictToken: string # Optional. This can be the value of conflict_token from a Describe, or another Worker  Deployment API. Passing a non-nil conflict token will cause this request to fail if the  Deployment's configuration has been modified between the API call that generated the  token and this one. (format: bytes)
  --identity: string # Required. The identity of the client who initiated this request.
]: any -> record<conflictToken: string, previousManagerIdentity: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployments/($deploymentName)/set-manager")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, managerIdentity: $managerIdentity, self: $self, conflictToken: $conflictToken, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set/unset the Ramping Version of a Worker Deployment and its ramp percentage. Can be used for  gradual ramp to unversioned workers too.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /api/v1/namespaces/{namespace}/worker-deployments/{deploymentName}/set-ramping-version
# operationId: SetWorkerDeploymentRampingVersion
export def "namespaces-worker-deployments-set-ramping-version SetWorkerDeploymentRampingVersion-by-namespace-deploymentName" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string
  --version: string # Deprecated. Use `build_id`.
  --buildId: string # The build id of the Version that you want to ramp traffic to.  Pass an empty value to set the Ramping Version to nil.  A nil Ramping Version represents all the unversioned workers (those with `UNVERSIONED` (or unspecified) `WorkerVersioningMode`.)
  --percentage: float # Ramp percentage to set. Valid range: [0,100]. (format: float)
  --conflictToken: string # Optional. This can be the value of conflict_token from a Describe, or another Worker  Deployment API. Passing a non-nil conflict token will cause this request to fail if the  Deployment's configuration has been modified between the API call that generated the  token and this one. (format: bytes)
  --identity: string # Optional. The identity of the client who initiated this request.
  --ignoreMissingTaskQueues: oneof<nothing, bool> # Optional. By default this request would be rejected if not all the expected Task Queues are  being polled by the new Version, to protect against accidental removal of Task Queues, or  worker health issues. Pass `true` here to bypass this protection.  The set of expected Task Queues equals to all the Task Queues ever polled from the existing  Current Version of the Deployment, with the following exclusions:    - Task Queues that are not used anymore (inferred by having empty backlog and a task      add_rate of 0.)    - Task Queues that are moved to another Worker Deployment (inferred by the Task Queue      having a different Current Version than the Current Version of this deployment.)  WARNING: Do not set this flag unless you are sure that the missing task queue poller are not  needed. If the request is unexpectedly rejected due to missing pollers, then that means the  pollers have not reached to the server yet. Only set this if you expect those pollers to  never arrive.  Note: this check only happens when the ramping version is about to change, not every time  that the percentage changes. Also note that the check is against the deployment's Current  Version, not the previous Ramping Version.
  --allowNoPollers: oneof<nothing, bool> # Optional. By default this request will be rejected if no pollers have been seen for the proposed  Current Version, in order to protect users from routing tasks to pollers that do not exist, leading  to possible timeouts. Pass `true` here to bypass this protection.
]: any -> record<conflictToken: string, previousVersion: string, previousDeploymentVersion: record<buildId: string, deploymentName: string>, previousPercentage: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-deployments/($deploymentName)/set-ramping-version")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, version: $version, buildId: $buildId, percentage: $percentage, conflictToken: $conflictToken, identity: $identity, ignoreMissingTaskQueues: $ignoreMissingTaskQueues, allowNoPollers: $allowNoPollers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deprecated. Use `DescribeTaskQueue`.  Will be removed in server version v1.32.0.   Fetches task reachability to determine whether a worker may be retired.  The request may specify task queues to query for or let the server fetch all task queues mapped to the given  build IDs.   When requesting a large number of task queues or all task queues associated with the given build ids in a  namespace, all task queues will be listed in the response but some of them may not contain reachability  information due to a server enforced limit. When reaching the limit, task queues that reachability information  could not be retrieved for will be marked with a single TASK_REACHABILITY_UNSPECIFIED entry. The caller may issue  another call to get the reachability for those task queues.   Open source users can adjust this limit by setting the server's dynamic config value for  `limit.reachabilityTaskQueueScan` with the caveat that this call can strain the visibility store.
#
# GET /api/v1/namespaces/{namespace}/worker-task-reachability
# operationId: GetWorkerTaskReachability
export def "namespaces-worker-task-reachability GetWorkerTaskReachability-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --buildIds: list # Build ids to retrieve reachability for. An empty string will be interpreted as an unversioned worker.  The number of build ids that can be queried in a single API call is limited.  Open source users can adjust this limit by setting the server's dynamic config value for  `limit.reachabilityQueryBuildIds` with the caveat that this call can strain the visibility store.
  --taskQueues: list # Task queues to retrieve reachability for. Leave this empty to query for all task queues associated with given  build ids in the namespace.  Must specify at least one task queue if querying for an unversioned worker.  The number of task queues that the server will fetch reachability information for is limited.  See the `GetWorkerTaskReachabilityResponse` documentation for more information.
  --reachability: string@reachability-completer # Type of reachability to query for.  `TASK_REACHABILITY_NEW_WORKFLOWS` is always returned in the response.  Use `TASK_REACHABILITY_EXISTING_WORKFLOWS` if your application needs to respond to queries on closed workflows.  Otherwise, use `TASK_REACHABILITY_OPEN_WORKFLOWS`. Default is `TASK_REACHABILITY_EXISTING_WORKFLOWS` if left  unspecified.  See the TaskReachability docstring for information about each enum variant. (format: enum)
]: nothing -> record<buildIdReachability: table<buildId: string, taskQueueReachability: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "buildIds" $buildIds "multi") (serialize-qp "taskQueues" $taskQueues "multi") (serialize-qp "reachability" $reachability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/worker-task-reachability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListWorkers is a visibility API to list worker status information in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/workers
# operationId: ListWorkers
export def "namespaces-workers ListWorkers-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --qp-query: string # `query` in ListWorkers is used to filter workers based on worker attributes.  Supported attributes: * WorkerInstanceKey * WorkerIdentity * HostName * TaskQueue * DeploymentName * BuildId * SdkName * SdkVersion * StartTime * Status
  --includeSystemWorkers: oneof<nothing, bool> # When true, the response will include system workers that are created implicitly  by the server and not by the user. By default, system workers are excluded.
]: nothing -> record<workersInfo: table<workerHeartbeat: record>, workers: table<workerInstanceKey: string, workerIdentity: string, taskQueue: string, deploymentVersion: record, sdkName: string, sdkVersion: string, status: string, startTime: string, hostName: string, workerGroupingKey: string, processId: string, plugins: list, drivers: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "includeSystemWorkers" $includeSystemWorkers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeWorker returns information about the specified worker.
#
# GET /api/v1/namespaces/{namespace}/workers/describe/{workerInstanceKey}
# operationId: DescribeWorker
export def "namespaces-workers-describe DescribeWorker-by-namespace-workerInstanceKey" [
  namespace: string
  workerInstanceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workerInfo: record<workerHeartbeat: record<workerInstanceKey: string, workerIdentity: string, hostInfo: record, taskQueue: string, deploymentVersion: record, sdkName: string, sdkVersion: string, status: string, startTime: string, heartbeatTime: string, elapsedSinceLastHeartbeat: string, workflowTaskSlotsInfo: record, activityTaskSlotsInfo: record, nexusTaskSlotsInfo: record, localActivitySlotsInfo: record, workflowPollerInfo: record, workflowStickyPollerInfo: record, activityPollerInfo: record, nexusPollerInfo: record, totalStickyCacheHit: int, totalStickyCacheMiss: int, currentStickyCacheSize: int, plugins: list, drivers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workers/describe/($workerInstanceKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FetchWorkerConfig returns the worker configuration for a specific worker.
#
# POST /api/v1/namespaces/{namespace}/workers/fetch-config
# operationId: FetchWorkerConfig
export def "namespaces-workers-fetch-config FetchWorkerConfig-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace this worker belongs to.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason for sending worker command, can be used for audit purpose.
  --selector: any # Defines which workers should receive this command.  only single worker is supported at this time.
  --resourceId: string # Resource ID for routing. Contains the worker grouping key.
]: any -> record<workerConfig: record<workflowCacheSize: int, simplePollerBehavior: record<maxPollers: int>, autoscalingPollerBehavior: record<minPollers: int, maxPollers: int, initialPollers: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workers/fetch-config")
  let body = {namespace: $body_namespace, identity: $identity, reason: $reason, selector: $selector, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# WorkerHeartbeat receive heartbeat request from the worker.
#
# POST /api/v1/namespaces/{namespace}/workers/heartbeat
# operationId: RecordWorkerHeartbeat
# --workerHeartbeat item shape: {workerInstanceKey?: string, workerIdentity?: string, hostInfo?: any, taskQueue?: string, deploymentVersion?: record, sdkName?: string, sdkVersion?: string, status?: "WORKER_STATUS_UNSPECIFIED"|"WORKER_STATUS_RUNNING"|"WORKER_STATUS_SHUTTING_DOWN"|"WORKER_STATUS_SHUTDOWN", startTime?: string, heartbeatTime?: string, elapsedSinceLastHeartbeat?: string, workflowTaskSlotsInfo?: record, activityTaskSlotsInfo?: record, nexusTaskSlotsInfo?: record, localActivitySlotsInfo?: record, workflowPollerInfo?: record, workflowStickyPollerInfo?: record, activityPollerInfo?: record, nexusPollerInfo?: record, totalStickyCacheHit?: int, totalStickyCacheMiss?: int, currentStickyCacheSize?: int, plugins?: list, drivers?: list}
export def "namespaces-workers-heartbeat RecordWorkerHeartbeat-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace this worker belongs to.
  --identity: string # The identity of the client who initiated this request.
  --workerHeartbeat: list # item shape: {workerInstanceKey?: string, workerIdentity?: string, hostInfo?: any, taskQueue?: string, deploymentVersion?: record, sdkName?: string, sdkVersion?: string, status?: "WORKER_STATUS_UNSPECIFIED"|"WORKER_STATUS_RUNNING"|"WORKER_STATUS_SHUTTING_DOWN"|"WORKER_STATUS_SHUTDOWN", startTime?: string, heartbeatTime?: string, elapsedSinceLastHeartbeat?: string, workflowTaskSlotsInfo?: record, activityTaskSlotsInfo?: record, nexusTaskSlotsInfo?: record, localActivitySlotsInfo?: record, workflowPollerInfo?: record, workflowStickyPollerInfo?: record, activityPollerInfo?: record, nexusPollerInfo?: record, totalStickyCacheHit?: int, totalStickyCacheMiss?: int, currentStickyCacheSize?: int, plugins?: list, drivers?: list}
  --resourceId: string # Resource ID for routing. Contains the worker grouping key.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workers/heartbeat")
  let body = {namespace: $body_namespace, identity: $identity, workerHeartbeat: $workerHeartbeat, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateWorkerConfig updates the worker configuration of one or more workers.  Can be used to partially update the worker configuration.  Can be used to update the configuration of multiple workers.
#
# POST /api/v1/namespaces/{namespace}/workers/update-config
# operationId: UpdateWorkerConfig
export def "namespaces-workers-update-config UpdateWorkerConfig-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace this worker belongs to.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason for sending worker command, can be used for audit purpose.
  --workerConfig: any # Partial updates are accepted and controlled by update_mask.  The worker configuration to set.
  --updateMask: string # Controls which fields from `worker_config` will be applied (format: field-mask)
  --selector: any # Defines which workers should receive this command.
  --resourceId: string # Resource ID for routing. Contains the worker grouping key.
]: any -> record<workerConfig: record<workflowCacheSize: int, simplePollerBehavior: record<maxPollers: int>, autoscalingPollerBehavior: record<minPollers: int, maxPollers: int, initialPollers: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workers/update-config")
  let body = {namespace: $body_namespace, identity: $identity, reason: $reason, workerConfig: $workerConfig, updateMask: $updateMask, selector: $selector, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CountWorkflowExecutions is a visibility API to count of workflow executions in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/workflow-count
# operationId: CountWorkflowExecutions
export def "namespaces-workflow-count CountWorkflowExecutions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflow-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return all namespace workflow rules
#
# GET /api/v1/namespaces/{namespace}/workflow-rules
# operationId: ListWorkflowRules
export def "namespaces-workflow-rules ListWorkflowRules-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextPageToken: string # format: bytes
]: nothing -> record<rules: table<createTime: string, spec: record, createdByIdentity: string, description: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflow-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new workflow rule. The rules are used to control the workflow execution.  The rule will be applied to all running and new workflows in the namespace.  If the rule with such ID already exist this call will fail  Note: the rules are part of namespace configuration and will be stored in the namespace config.  Namespace config is eventually consistent.
#
# POST /api/v1/namespaces/{namespace}/workflow-rules
# operationId: CreateWorkflowRule
export def "namespaces-workflow-rules CreateWorkflowRule-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --spec: any # The rule specification .
  --forceScan: oneof<nothing, bool> # If true, the rule will be applied to the currently running workflows via batch job.  If not set , the rule will only be applied when triggering condition is satisfied.  visibility_query in the rule will be used to select the workflows to apply the rule to.
  --requestId: string # Used to de-dupe requests. Typically should be UUID.
  --identity: string # Identity of the actor who created the rule. Will be stored with the rule.
  --description: string # Rule description.Will be stored with the rule.
]: any -> record<rule: record<createTime: string, spec: record<id: string, activityStart: record, visibilityQuery: string, actions: list, expirationTime: string>, createdByIdentity: string, description: string>, jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflow-rules")
  let body = {namespace: $body_namespace, spec: $spec, forceScan: $forceScan, requestId: $requestId, identity: $identity, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DescribeWorkflowRule return the rule specification for existing rule id.  If there is no rule with such id - NOT FOUND error will be returned.
#
# GET /api/v1/namespaces/{namespace}/workflow-rules/{ruleId}
# operationId: DescribeWorkflowRule
export def "namespaces-workflow-rules DescribeWorkflowRule-by-namespace-ruleId" [
  namespace: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rule: record<createTime: string, spec: record<id: string, activityStart: record, visibilityQuery: string, actions: list, expirationTime: string>, createdByIdentity: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflow-rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete rule by rule id
#
# DELETE /api/v1/namespaces/{namespace}/workflow-rules/{ruleId}
# operationId: DeleteWorkflowRule
export def "namespaces-workflow-rules DeleteWorkflowRule-by-namespace-ruleId" [
  namespace: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflow-rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListWorkflowExecutions is a visibility API to list workflow executions in a specific namespace.
#
# GET /api/v1/namespaces/{namespace}/workflows
# operationId: ListWorkflowExecutions
export def "namespaces-workflows ListWorkflowExecutions-by-namespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --qp-query: string
]: nothing -> record<executions: table<execution: record, type: record, startTime: string, closeTime: string, status: string, historyLength: string, parentNamespaceId: string, parentExecution: record, executionTime: string, memo: record, searchAttributes: record, autoResetPoints: record, taskQueue: string, stateTransitionCount: string, historySizeBytes: string, mostRecentWorkerVersionStamp: record, executionDuration: string, rootExecution: record, assignedBuildId: string, inheritedBuildId: string, firstRunId: string, versioningInfo: record, workerDeploymentName: string, priority: record, externalPayloadSizeBytes: string, externalPayloadCount: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeWorkflowExecution returns information about the specified workflow execution.
#
# GET /api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}
# operationId: DescribeWorkflowExecution
export def "namespaces-workflows DescribeWorkflowExecution-by-namespace-execution.workflow_id" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --executionworkflowId: string
  --executionrunId: string
]: nothing -> record<executionConfig: record<taskQueue: record<name: string, kind: string, normalName: string>, workflowExecutionTimeout: string, workflowRunTimeout: string, defaultWorkflowTaskTimeout: string, userMetadata: record<summary: record, details: record>>, workflowExecutionInfo: record<execution: record<workflowId: string, runId: string>, type: record<name: string>, startTime: string, closeTime: string, status: string, historyLength: string, parentNamespaceId: string, parentExecution: record<workflowId: string, runId: string>, executionTime: string, memo: record<fields: record>, searchAttributes: record<indexedFields: record>, autoResetPoints: record<points: list>, taskQueue: string, stateTransitionCount: string, historySizeBytes: string, mostRecentWorkerVersionStamp: record<buildId: string, useVersioning: bool>, executionDuration: string, rootExecution: record<workflowId: string, runId: string>, assignedBuildId: string, inheritedBuildId: string, firstRunId: string, versioningInfo: record<behavior: string, deployment: record, version: string, deploymentVersion: record, versioningOverride: record, deploymentTransition: record, versionTransition: record, revisionNumber: string, continueAsNewInitialVersioningBehavior: string>, workerDeploymentName: string, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>, externalPayloadSizeBytes: string, externalPayloadCount: string>, pendingActivities: table<activityId: string, activityType: record, state: string, heartbeatDetails: record, lastHeartbeatTime: string, lastStartedTime: string, attempt: int, maximumAttempts: int, scheduledTime: string, expirationTime: string, lastFailure: record, lastWorkerIdentity: string, lastIndependentlyAssignedBuildId: string, lastWorkerVersionStamp: record, currentRetryInterval: string, lastAttemptCompleteTime: string, nextAttemptScheduleTime: string, paused: bool, lastDeployment: record, lastWorkerDeploymentVersion: string, lastDeploymentVersion: record, priority: record, pauseInfo: record, activityOptions: record>, pendingChildren: table<workflowId: string, runId: string, workflowTypeName: string, initiatedId: string, parentClosePolicy: string>, pendingWorkflowTask: record<state: string, scheduledTime: string, originalScheduledTime: string, startedTime: string, attempt: int>, callbacks: table<callback: record, registrationTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, blockedReason: string>, pendingNexusOperations: table<endpoint: string, service: string, operation: string, operationId: string, scheduleToCloseTimeout: string, scheduledTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, cancellationInfo: record, scheduledEventId: string, blockedReason: string, operationToken: string, scheduleToStartTimeout: string, startToCloseTimeout: string>, workflowExtendedInfo: record<executionExpirationTime: string, runExpirationTime: string, cancelRequested: bool, lastResetTime: string, originalStartTime: string, resetRunId: string, requestIdInfos: record, pauseInfo: record<identity: string, pausedTime: string, reason: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "execution.workflowId" $executionworkflowId "scalar") (serialize-qp "execution.runId" $executionrunId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($execution.workflow_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetWorkflowExecutionHistory returns the history of specified workflow execution. Fails with  `NotFound` if the specified workflow execution is unknown to the service.
#
# GET /api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/history
# operationId: GetWorkflowExecutionHistory
export def "namespaces-workflows-history GetWorkflowExecutionHistory-by-namespace-execution.workflow_id" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --executionworkflowId: string
  --executionrunId: string
  --maximumPageSize: int # format: int32
  --nextPageToken: string # If a `GetWorkflowExecutionHistoryResponse` or a `PollWorkflowTaskQueueResponse` had one of  these, it should be passed here to fetch the next page. (format: bytes)
  --waitNewEvent: oneof<nothing, bool> # If set to true, the RPC call will not resolve until there is a new event which matches  the `history_event_filter_type`, or a timeout is hit.
  --historyEventFilterType: string@historyEventFilterType-completer # Filter returned events such that they match the specified filter type.  Default: HISTORY_EVENT_FILTER_TYPE_ALL_EVENT. (format: enum)
  --skipArchival: oneof<nothing, bool>
]: nothing -> record<history: record<events: list<record>>, rawHistory: table<encodingType: string, data: string>, nextPageToken: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "execution.workflowId" $executionworkflowId "scalar") (serialize-qp "execution.runId" $executionrunId "scalar") (serialize-qp "maximumPageSize" $maximumPageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "waitNewEvent" $waitNewEvent "scalar") (serialize-qp "historyEventFilterType" $historyEventFilterType "scalar") (serialize-qp "skipArchival" $skipArchival "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($execution.workflow_id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetWorkflowExecutionHistoryReverse returns the history of specified workflow execution in reverse  order (starting from last event). Fails with`NotFound` if the specified workflow execution is  unknown to the service.
#
# GET /api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/history-reverse
# operationId: GetWorkflowExecutionHistoryReverse
export def "namespaces-workflows-history-reverse GetWorkflowExecutionHistoryReverse-by-namespace-execution.workflow_id" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --executionworkflowId: string
  --executionrunId: string
  --maximumPageSize: int # format: int32
  --nextPageToken: string # format: bytes
]: nothing -> record<history: record<events: list<record>>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "execution.workflowId" $executionworkflowId "scalar") (serialize-qp "execution.runId" $executionrunId "scalar") (serialize-qp "maximumPageSize" $maximumPageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($execution.workflow_id)/history-reverse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# QueryWorkflow requests a query be executed for a specified workflow execution.
#
# POST /api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/query/{query.query_type}
# operationId: QueryWorkflow
# --execution shape: {workflowId?: string, runId?: string}
# --query shape: {queryType?: string, queryArgs?: any, header?: any}
export def "namespaces-workflows-query QueryWorkflow-by-namespace-execution.workflow_id-query.query_type" [
  namespace: string
  execution.workflow_id: string
  query.query_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --execution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --body-query: record # See https://docs.temporal.io/docs/concepts/queries/ — shape: {queryType?: string, queryArgs?: any, header?: any}
  --queryRejectCondition: string@queryRejectCondition-completer # QueryRejectCondition can used to reject the query if workflow state does not satisfy condition.  Default: QUERY_REJECT_CONDITION_NONE. (format: enum)
]: any -> record<queryResult: record<payloads: list<any>>, queryRejected: record<status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($execution.workflow_id)/query/($query.query_type)")
  let body = {namespace: $body_namespace, execution: $execution, query: $body_query, queryRejectCondition: $queryRejectCondition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# TriggerWorkflowRule allows to:   * trigger existing rule for a specific workflow execution;   * trigger rule for a specific workflow execution without creating a rule;  This is useful for one-off operations.
#
# POST /api/v1/namespaces/{namespace}/workflows/{execution.workflow_id}/trigger-rule
# operationId: TriggerWorkflowRule
export def "namespaces-workflows-trigger-rule TriggerWorkflowRule-by-namespace-execution.workflow_id" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --execution: any # Execution info of the workflow which scheduled this activity
  --id: string
  --spec: any # Note: Rule ID and expiration date are not used in the trigger request.
  --identity: string # The identity of the client who initiated this request
]: any -> record<applied: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($execution.workflow_id)/trigger-rule")
  let body = {namespace: $body_namespace, execution: $execution, id: $id, spec: $spec, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# StartWorkflowExecution starts a new workflow execution.   It will create the execution with a `WORKFLOW_EXECUTION_STARTED` event in its history and  also schedule the first workflow task. Returns `WorkflowExecutionAlreadyStarted`, if an  instance already exists with same workflow id.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}
# operationId: StartWorkflowExecution
# --workflowType shape: {name?: string}
# --taskQueue shape: {name?: string, kind?: "TASK_QUEUE_KIND_UNSPECIFIED"|"TASK_QUEUE_KIND_NORMAL"|"TASK_QUEUE_KIND_STICKY"|"TASK_QUEUE_KIND_WORKER_COMMANDS", normalName?: string}
# --memo shape: {fields?: record}
# --searchAttributes shape: {indexedFields?: record}
# --header shape: {fields?: record}
# --lastCompletionResult shape: {payloads?: list}
# --completionCallbacks item shape: {nexus?: record, internal?: record, links?: list}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows StartWorkflowExecution-by-namespace-workflowId" [
  namespace: string
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-workflowId: string
  --workflowType: record # Represents the identifier used by a workflow author to define the workflow. Typically, the  name of a function. This is sometimes referred to as the workflow's "name" — shape: {name?: string}
  --taskQueue: record # See https://docs.temporal.io/docs/concepts/task-queues/ — shape: {name?: string, kind?: "TASK_QUEUE_KIND_UNSPECIFIED"|"TASK_QUEUE_KIND_NORMAL"|"TASK_QUEUE_KIND_STICKY"|"TASK_QUEUE_KIND_WORKER_COMMANDS", normalName?: string}
  --input: any # Serialized arguments to the workflow. These are passed as arguments to the workflow function.
  --workflowExecutionTimeout: string # Total workflow execution timeout including retries and continue as new.
  --workflowRunTimeout: string # Timeout of a single workflow run.
  --workflowTaskTimeout: string # Timeout of a single workflow task.
  --identity: string # The identity of the client who initiated this request
  --requestId: string # A unique identifier for this start request. Typically UUIDv4.
  --workflowIdReusePolicy: string@workflowIdReusePolicy-completer # Defines whether to allow re-using the workflow id from a previously *closed* workflow.  The default policy is WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE.   See `workflow_id_conflict_policy` for handling a workflow id duplication with a *running* workflow. (format: enum)
  --workflowIdConflictPolicy: string@workflowIdConflictPolicy-completer # Defines how to resolve a workflow id conflict with a *running* workflow.  The default policy is WORKFLOW_ID_CONFLICT_POLICY_FAIL.   See `workflow_id_reuse_policy` for handling a workflow id duplication with a *closed* workflow. (format: enum)
  --retryPolicy: any # The retry policy for the workflow. Will never exceed `workflow_execution_timeout`.
  --cronSchedule: string # See https://docs.temporal.io/docs/content/what-is-a-temporal-cron-job/
  --memo: record # A user-defined set of *unindexed* fields that are exposed when listing/searching workflows — shape: {fields?: record}
  --searchAttributes: record # A user-defined set of *indexed* fields that are used/exposed when listing/searching workflows.  The payload is not serialized in a user-defined way. — shape: {indexedFields?: record}
  --header: record # Contains metadata that can be attached to a variety of requests, like starting a workflow, and  can be propagated between, for example, workflows and activities. — shape: {fields?: record}
  --requestEagerExecution: oneof<nothing, bool> # Request to get the first workflow task inline in the response bypassing matching service and worker polling.  If set to `true` the caller is expected to have a worker available and capable of processing the task.  The returned task will be marked as started and is expected to be completed by the specified  `workflow_task_timeout`.
  --continuedFailure: any # These values will be available as ContinuedFailure and LastCompletionResult in the  WorkflowExecutionStarted event and through SDKs. The are currently only used by the  server itself (for the schedules feature) and are not intended to be exposed in  StartWorkflowExecution.
  --lastCompletionResult: record # See `Payload` — shape: {payloads?: list}
  --workflowStartDelay: string # Time to wait before dispatching the first workflow task. Cannot be used with `cron_schedule`.  If the workflow gets a signal before the delay, a workflow task will be dispatched and the rest  of the delay will be ignored.
  --completionCallbacks: list # Callbacks to be called by the server when this workflow reaches a terminal state.  If the workflow continues-as-new, these callbacks will be carried over to the new execution.  Callback addresses must be whitelisted in the server's dynamic configuration. — item shape: {nexus?: record, internal?: record, links?: list}
  --userMetadata: any # Metadata on the workflow if it is started. This is carried over to the WorkflowExecutionInfo  for use by user interfaces to display the fixed as-of-start summary and details of the  workflow.
  --links: list # Links to be associated with the workflow. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
  --versioningOverride: any # If set, takes precedence over the Versioning Behavior sent by the SDK on Workflow Task completion.  To unset the override after the workflow is running, use UpdateWorkflowExecutionOptions.
  --onConflictOptions: any # Defines actions to be done to the existing running workflow when the conflict policy  WORKFLOW_ID_CONFLICT_POLICY_USE_EXISTING is used. If not set (ie., nil value) or set to a  empty object (ie., all options with default value), it won't do anything to the existing  running workflow. If set, it will add a history event to the running workflow.
  --priority: any # Priority metadata
  --eagerWorkerDeploymentOptions: any # Deployment Options of the worker who will process the eager task. Passed when `request_eager_execution=true`.
  --timeSkippingConfig: any # Time-skipping configuration. If not set, time skipping is disabled.
]: any -> record<runId: string, started: bool, status: string, eagerWorkflowTask: record<taskToken: string, workflowExecution: record<workflowId: string, runId: string>, workflowType: record<name: string>, previousStartedEventId: string, startedEventId: string, attempt: int, backlogCountHint: string, history: record<events: list>, nextPageToken: string, query: record<queryType: string, queryArgs: record, header: record>, workflowExecutionTaskQueue: record<name: string, kind: string, normalName: string>, scheduledTime: string, startedTime: string, queries: record, messages: list<record>, pollerScalingDecision: record<pollRequestDeltaSuggestion: int>, pollerGroupId: string, pollerGroupInfos: list<record>>, link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, workflowType: $workflowType, taskQueue: $taskQueue, input: $input, workflowExecutionTimeout: $workflowExecutionTimeout, workflowRunTimeout: $workflowRunTimeout, workflowTaskTimeout: $workflowTaskTimeout, identity: $identity, requestId: $requestId, workflowIdReusePolicy: $workflowIdReusePolicy, workflowIdConflictPolicy: $workflowIdConflictPolicy, retryPolicy: $retryPolicy, cronSchedule: $cronSchedule, memo: $memo, searchAttributes: $searchAttributes, header: $header, requestEagerExecution: $requestEagerExecution, continuedFailure: $continuedFailure, lastCompletionResult: $lastCompletionResult, workflowStartDelay: $workflowStartDelay, completionCallbacks: $completionCallbacks, userMetadata: $userMetadata, links: $links, versioningOverride: $versioningOverride, onConflictOptions: $onConflictOptions, priority: $priority, eagerWorkerDeploymentOptions: $eagerWorkerDeploymentOptions, timeSkippingConfig: $timeSkippingConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCompleted`. This version allows clients to record completions by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/complete
# operationId: RespondActivityTaskCompletedById
export def "namespaces-workflows-activities-complete RespondActivityTaskCompletedById-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to complete
  --body-result: any # The serialized result of activity execution
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/complete")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, result: $body_result, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskFailed`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/fail
# operationId: RespondActivityTaskFailedById
export def "namespaces-workflows-activities-fail RespondActivityTaskFailedById-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to fail
  --failure: any # Detailed failure information
  --identity: string # The identity of the worker/client
  --lastHeartbeatDetails: any # Additional details to be stored as last activity heartbeat
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<failures: table<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/fail")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, failure: $failure, identity: $identity, lastHeartbeatDetails: $lastHeartbeatDetails, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskHeartbeat`. This version allows clients to record heartbeats by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/heartbeat
# operationId: RecordActivityTaskHeartbeatById
export def "namespaces-workflows-activities-heartbeat RecordActivityTaskHeartbeatById-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity we're heartbeating
  --details: any # Arbitrary data, of which the most recent call is kept, to store for this activity
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<cancelRequested: bool, activityPaused: bool, activityReset: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/heartbeat")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PauseActivityExecution pauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity   Pausing an activity means:  - If the activity is currently waiting for a retry or is running and subsequently fails,    it will not be rescheduled until it is unpaused.  - If the activity is already paused, calling this method will have no effect.  - If the activity is running and finishes successfully, the activity will be completed.  - If the activity is running and finishes with failure:    * if there is no retry left - the activity will be completed.    * if there are more retries left - the activity will be paused.  For long-running activities:  - activities in paused state will send a cancellation with "activity_paused" set to 'true' in response to 'RecordActivityTaskHeartbeat'.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/pause
# operationId: PauseActivityExecution
export def "namespaces-workflows-activities-pause PauseActivityExecution-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --body-workflowId: string # If provided, pause a workflow activity (or activities) for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to pause the activity.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
  --requestId: string # Used to de-dupe pause requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/pause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, reason: $reason, resourceId: $resourceId, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetActivityExecution resets the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   Resetting an activity means:  * number of attempts will be reset to 0.  * activity timeouts will be reset.  * if the activity is waiting for retry, and it is not paused or 'keep_paused' is not provided:     it will be scheduled immediately (* see 'jitter' flag)   Returns a `NotFound` error if there is no pending activity with the provided ID or type.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/reset
# operationId: ResetActivityExecution
export def "namespaces-workflows-activities-reset ResetActivityExecution-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --body-workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetHeartbeat: oneof<nothing, bool> # Indicates that activity should reset heartbeat details.  This flag will be applied only to the new instance of the activity.
  --keepPaused: oneof<nothing, bool> # If activity is paused, it will remain paused after reset
  --jitter: string # If set, and activity is in backoff, the activity will start at a random time within the specified jitter duration.  (unless it is paused and keep_paused is set)
  --restoreOriginalOptions: oneof<nothing, bool> # If set, the activity options will be restored to the defaults.  Default options are then options activity was created with.  They are part of the first schedule event.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/reset")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetHeartbeat: $resetHeartbeat, keepPaused: $keepPaused, jitter: $jitter, restoreOriginalOptions: $restoreOriginalOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCanceled`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/resolve-as-canceled
# operationId: RespondActivityTaskCanceledById
export def "namespaces-workflows-activities-resolve-as-canceled RespondActivityTaskCanceledById-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to confirm is cancelled
  --details: any # Serialized additional information to attach to the cancellation
  --identity: string # The identity of the worker/client
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/resolve-as-canceled")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, deploymentOptions: $deploymentOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UnpauseActivityExecution unpauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   If activity is not paused, this call will have no effect.  If the activity was paused while waiting for retry, it will be scheduled immediately (* see 'jitter' flag).  Once the activity is unpaused, all timeout timers will be regenerated.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/unpause
# operationId: UnpauseActivityExecution
export def "namespaces-workflows-activities-unpause UnpauseActivityExecution-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --body-workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetAttempts: oneof<nothing, bool> # Providing this flag will also reset the number of attempts.
  --resetHeartbeat: oneof<nothing, bool> # Providing this flag will also reset the heartbeat details.
  --reason: string # Reason to unpause the activity.
  --jitter: string # If set, the activity will start at a random time within the specified jitter duration.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/unpause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetAttempts: $resetAttempts, resetHeartbeat: $resetHeartbeat, reason: $reason, jitter: $jitter, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateActivityExecutionOptions is called by the client to update the options of an activity by its ID.  This API can be used to target a workflow activity or a standalone activity.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/update-options
# operationId: UpdateActivityExecutionOptions
export def "namespaces-workflows-activities-update-options UpdateActivityExecutionOptions-by-namespace-workflowId-activityId" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request
  --activityOptions: any # Activity options. Partial updates are accepted and controlled by update_mask
  --updateMask: string # Controls which fields from `activity_options` will be applied (format: field-mask)
  --restoreOriginal: oneof<nothing, bool> # If set, the activity options will be restored to the default.  Default options are then options activity was created with.  They are part of the first schedule event.  This flag cannot be combined with any other option; if you supply  restore_original together with other options, the request will be rejected.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record<activityOptions: record<taskQueue: record<name: string, kind: string, normalName: string>, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/update-options")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, activityOptions: $activityOptions, updateMask: $updateMask, restoreOriginal: $restoreOriginal, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Note: This is an experimental API and the behavior may change in a future release.  PauseWorkflowExecution pauses the workflow execution specified in the request. Pausing a workflow execution results in  - The workflow execution status changes to `PAUSED` and a new WORKFLOW_EXECUTION_PAUSED event is added to the history  - No new workflow tasks or activity tasks are dispatched.    - Any workflow task currently executing on the worker will be allowed to complete.    - Any activity task currently executing will be paused.  - All server-side events will continue to be processed by the server.  - Queries & Updates on a paused workflow will be rejected.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/pause
# operationId: PauseWorkflowExecution
export def "namespaces-workflows-pause PauseWorkflowExecution-by-namespace-workflowId" [
  namespace: string
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow to pause.
  --body-workflowId: string # ID of the workflow execution to be paused. Required.
  --runId: string # Run ID of the workflow execution to be paused. Optional. If not provided, the current run of the workflow will be paused.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to pause the workflow execution.
  --requestId: string # A unique identifier for this pause request for idempotence. Typically UUIDv4.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/pause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, identity: $identity, reason: $reason, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SignalWithStartWorkflowExecution is used to ensure a signal is sent to a workflow, even if  it isn't yet started.   If the workflow is running, a `WORKFLOW_EXECUTION_SIGNALED` event is recorded in the history  and a workflow task is generated.   If the workflow is not running or not found, then the workflow is created with  `WORKFLOW_EXECUTION_STARTED` and `WORKFLOW_EXECUTION_SIGNALED` events in its history, and a  workflow task is generated.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "With" is used to indicate combined operation. --)
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/signal-with-start/{signalName}
# operationId: SignalWithStartWorkflowExecution
# --workflowType shape: {name?: string}
# --memo shape: {fields?: record}
# --searchAttributes shape: {indexedFields?: record}
# --header shape: {fields?: record}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-signal-with-start SignalWithStartWorkflowExecution-by-namespace-workflowId-signalName" [
  namespace: string
  workflowId: string
  signalName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-workflowId: string
  --workflowType: record # Represents the identifier used by a workflow author to define the workflow. Typically, the  name of a function. This is sometimes referred to as the workflow's "name" — shape: {name?: string}
  --taskQueue: any # The task queue to start this workflow on, if it will be started
  --input: any # Serialized arguments to the workflow. These are passed as arguments to the workflow function.
  --workflowExecutionTimeout: string # Total workflow execution timeout including retries and continue as new
  --workflowRunTimeout: string # Timeout of a single workflow run
  --workflowTaskTimeout: string # Timeout of a single workflow task
  --identity: string # The identity of the worker/client
  --requestId: string # Used to de-dupe signal w/ start requests
  --workflowIdReusePolicy: string@workflowIdReusePolicy-completer # Defines whether to allow re-using the workflow id from a previously *closed* workflow.  The default policy is WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE.   See `workflow_id_reuse_policy` for handling a workflow id duplication with a *running* workflow. (format: enum)
  --workflowIdConflictPolicy: string@workflowIdConflictPolicy-completer # Defines how to resolve a workflow id conflict with a *running* workflow.  The default policy is WORKFLOW_ID_CONFLICT_POLICY_USE_EXISTING.  Note that WORKFLOW_ID_CONFLICT_POLICY_FAIL is an invalid option.   See `workflow_id_reuse_policy` for handling a workflow id duplication with a *closed* workflow. (format: enum)
  --body-signalName: string # The workflow author-defined name of the signal to send to the workflow
  --signalInput: any # Serialized value(s) to provide with the signal
  --control: string # Deprecated.
  --retryPolicy: any # Retry policy for the workflow
  --cronSchedule: string # See https://docs.temporal.io/docs/content/what-is-a-temporal-cron-job/
  --memo: record # A user-defined set of *unindexed* fields that are exposed when listing/searching workflows — shape: {fields?: record}
  --searchAttributes: record # A user-defined set of *indexed* fields that are used/exposed when listing/searching workflows.  The payload is not serialized in a user-defined way. — shape: {indexedFields?: record}
  --header: record # Contains metadata that can be attached to a variety of requests, like starting a workflow, and  can be propagated between, for example, workflows and activities. — shape: {fields?: record}
  --workflowStartDelay: string # Time to wait before dispatching the first workflow task. Cannot be used with `cron_schedule`.  Note that the signal will be delivered with the first workflow task. If the workflow gets  another SignalWithStartWorkflow before the delay a workflow task will be dispatched immediately  and the rest of the delay period will be ignored, even if that request also had a delay.  Signal via SignalWorkflowExecution will not unblock the workflow.
  --userMetadata: any # Metadata on the workflow if it is started. This is carried over to the WorkflowExecutionInfo  for use by user interfaces to display the fixed as-of-start summary and details of the  workflow.
  --links: list # Links to be associated with the WorkflowExecutionStarted and WorkflowExecutionSignaled events. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
  --versioningOverride: any # If set, takes precedence over the Versioning Behavior sent by the SDK on Workflow Task completion.  To unset the override after the workflow is running, use UpdateWorkflowExecutionOptions.
  --priority: any # Priority metadata
  --timeSkippingConfig: any # Time-skipping configuration. If not set, time skipping is disabled.
]: any -> record<runId: string, started: bool, signalLink: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/signal-with-start/($signalName)")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, workflowType: $workflowType, taskQueue: $taskQueue, input: $input, workflowExecutionTimeout: $workflowExecutionTimeout, workflowRunTimeout: $workflowRunTimeout, workflowTaskTimeout: $workflowTaskTimeout, identity: $identity, requestId: $requestId, workflowIdReusePolicy: $workflowIdReusePolicy, workflowIdConflictPolicy: $workflowIdConflictPolicy, signalName: $body_signalName, signalInput: $signalInput, control: $control, retryPolicy: $retryPolicy, cronSchedule: $cronSchedule, memo: $memo, searchAttributes: $searchAttributes, header: $header, workflowStartDelay: $workflowStartDelay, userMetadata: $userMetadata, links: $links, versioningOverride: $versioningOverride, priority: $priority, timeSkippingConfig: $timeSkippingConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Note: This is an experimental API and the behavior may change in a future release.  UnpauseWorkflowExecution unpauses a previously paused workflow execution specified in the request.  Unpausing a workflow execution results in  - The workflow execution status changes to `RUNNING` and a new WORKFLOW_EXECUTION_UNPAUSED event is added to the history  - Workflow tasks and activity tasks are resumed.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflowId}/unpause
# operationId: UnpauseWorkflowExecution
export def "namespaces-workflows-unpause UnpauseWorkflowExecution-by-namespace-workflowId" [
  namespace: string
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow to unpause.
  --body-workflowId: string # ID of the workflow execution to be paused. Required.
  --runId: string # Run ID of the workflow execution to be paused. Optional. If not provided, the current run of the workflow will be paused.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to unpause the workflow execution.
  --requestId: string # A unique identifier for this unpause request for idempotence. Typically UUIDv4.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflowId)/unpause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, identity: $identity, reason: $reason, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RequestCancelWorkflowExecution is called by workers when they want to request cancellation of  a workflow execution.   This results in a new `WORKFLOW_EXECUTION_CANCEL_REQUESTED` event being written to the  workflow history and a new workflow task created for the workflow. It returns success if the requested  workflow is already closed. It fails with 'NotFound' if the requested workflow doesn't exist.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/cancel
# operationId: RequestCancelWorkflowExecution
# --workflowExecution shape: {workflowId?: string, runId?: string}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-cancel RequestCancelWorkflowExecution-by-namespace-workflow_execution.workflow_id" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --identity: string # The identity of the worker/client
  --requestId: string # Used to de-dupe cancellation requests
  --firstExecutionRunId: string # If set, this call will error if the most recent (if no run id is set on  `workflow_execution`), or specified (if it is) workflow execution is not part of the same  execution chain as this id.
  --reason: string # Reason for requesting the cancellation
  --links: list # Links to be associated with the WorkflowExecutionCanceled event. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/cancel")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, identity: $identity, requestId: $requestId, firstExecutionRunId: $firstExecutionRunId, reason: $reason, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetWorkflowExecution will reset an existing workflow execution to a specified  `WORKFLOW_TASK_COMPLETED` event (exclusive). It will immediately terminate the current  execution instance. "Exclusive" means the identified completed event itself is not replayed  in the reset history; the preceding `WORKFLOW_TASK_STARTED` event remains and will be marked as failed  immediately, and a new workflow task will be scheduled to retry it.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/reset
# operationId: ResetWorkflowExecution
# --postResetOperations item shape: {signalWorkflow?: record, updateWorkflowOptions?: record}
export def "namespaces-workflows-reset ResetWorkflowExecution-by-namespace-workflow_execution.workflow_id" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: any # The workflow to reset. If this contains a run ID then the workflow will be reset back to the  provided event ID in that run. Otherwise it will be reset to the provided event ID in the  current run. In all cases the current run will be terminated and a new run started.
  --reason: string
  --workflowTaskFinishEventId: string # The id of a `WORKFLOW_TASK_COMPLETED`,`WORKFLOW_TASK_TIMED_OUT`, `WORKFLOW_TASK_FAILED`, or  `WORKFLOW_TASK_STARTED` event to reset to.
  --requestId: string # Used to de-dupe reset requests
  --resetReapplyType: string@resetReapplyType-completer # Deprecated. Use `options`.  Default: RESET_REAPPLY_TYPE_SIGNAL (format: enum)
  --resetReapplyExcludeTypes: list # Event types not to be reapplied
  --postResetOperations: list # Operations to perform after the workflow has been reset. These operations will be applied  to the *new* run of the workflow execution in the order they are provided.  All operations are applied to the workflow before the first new workflow task is generated — item shape: {signalWorkflow?: record, updateWorkflowOptions?: record}
  --identity: string # The identity of the worker/client
]: any -> record<runId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/reset")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, reason: $reason, workflowTaskFinishEventId: $workflowTaskFinishEventId, requestId: $requestId, resetReapplyType: $resetReapplyType, resetReapplyExcludeTypes: $resetReapplyExcludeTypes, postResetOperations: $postResetOperations, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SignalWorkflowExecution is used to send a signal to a running workflow execution.   This results in a `WORKFLOW_EXECUTION_SIGNALED` event recorded in the history and a workflow  task being created for the execution.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/signal/{signalName}
# operationId: SignalWorkflowExecution
# --workflowExecution shape: {workflowId?: string, runId?: string}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-signal SignalWorkflowExecution-by-namespace-workflow_execution.workflow_id-signalName" [
  namespace: string
  workflow_execution.workflow_id: string
  signalName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --body-signalName: string # The workflow author-defined name of the signal to send to the workflow
  --input: any # Serialized value(s) to provide with the signal
  --identity: string # The identity of the worker/client
  --requestId: string # Used to de-dupe sent signals
  --control: string # Deprecated.
  --header: any # Headers that are passed with the signal to the processing workflow.  These can include things like auth or tracing tokens.
  --links: list # Links to be associated with the WorkflowExecutionSignaled event. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
]: any -> record<link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/signal/($signalName)")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, signalName: $body_signalName, input: $input, identity: $identity, requestId: $requestId, control: $control, header: $header, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# TerminateWorkflowExecution terminates an existing workflow execution by recording a  `WORKFLOW_EXECUTION_TERMINATED` event in the history and immediately terminating the  execution instance.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/terminate
# operationId: TerminateWorkflowExecution
# --workflowExecution shape: {workflowId?: string, runId?: string}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-terminate TerminateWorkflowExecution-by-namespace-workflow_execution.workflow_id" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --reason: string
  --details: any # Serialized additional information to attach to the termination event
  --identity: string # The identity of the worker/client
  --firstExecutionRunId: string # If set, this call will error if the most recent (if no run id is set on  `workflow_execution`), or specified (if it is) workflow execution is not part of the same  execution chain as this id.
  --links: list # Links to be associated with the WorkflowExecutionTerminated event. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/terminate")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, reason: $reason, details: $details, identity: $identity, firstExecutionRunId: $firstExecutionRunId, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateWorkflowExecutionOptions partially updates the WorkflowExecutionOptions of an existing workflow execution.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update-options
# operationId: UpdateWorkflowExecutionOptions
export def "namespaces-workflows-update-options UpdateWorkflowExecutionOptions-by-namespace-workflow_execution.workflow_id" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace name of the target Workflow.
  --workflowExecution: any # The target Workflow Id and (optionally) a specific Run Id thereof.  (-- api-linter: core::0203::optional=disabled      aip.dev/not-precedent: false positive triggered by the word "optional" --)
  --workflowExecutionOptions: any # Workflow Execution options. Partial updates are accepted and controlled by update_mask.
  --updateMask: string # Controls which fields from `workflow_execution_options` will be applied.  To unset a field, set it to null and use the update mask to indicate that it should be mutated. (format: field-mask)
  --identity: string # Optional. The identity of the client who initiated this request.
]: any -> record<workflowExecutionOptions: record<versioningOverride: record<pinned: record, autoUpgrade: bool, behavior: string, deployment: record, pinnedVersion: string>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>, timeSkippingConfig: record<enabled: bool, maxSkippedDuration: string, maxElapsedDuration: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/update-options")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, workflowExecutionOptions: $workflowExecutionOptions, updateMask: $updateMask, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invokes the specified Update function on user Workflow code.
#
# POST /api/v1/namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update/{request.input.name}
# operationId: UpdateWorkflowExecution
export def "namespaces-workflows-update UpdateWorkflowExecution-by-namespace-workflow_execution.workflow_id-request.input.name" [
  namespace: string
  workflow_execution.workflow_id: string
  request.input.name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace name of the target Workflow.
  --workflowExecution: any # The target Workflow Id and (optionally) a specific Run Id thereof.  (-- api-linter: core::0203::optional=disabled      aip.dev/not-precedent: false positive triggered by the word "optional" --)
  --firstExecutionRunId: string # If set, this call will error if the most recent (if no Run Id is set on  `workflow_execution`), or specified (if it is) Workflow Execution is not  part of the same execution chain as this Id.
  --waitPolicy: any # Specifies client's intent to wait for Update results.  NOTE: This field works together with API call timeout which is limited by  server timeout (maximum wait time). If server timeout is expired before  user specified timeout, API call returns even if specified stage is not reached.  Actual reached stage will be included in the response.
  --request: any # The request information that will be delivered all the way down to the  Workflow Execution.
]: any -> record<updateRef: record<workflowExecution: record<workflowId: string, runId: string>, updateId: string>, outcome: record<success: record<payloads: list>, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>>, stage: string, link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/update/($request.input.name)")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, firstExecutionRunId: $firstExecutionRunId, waitPolicy: $waitPolicy, request: $request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Nexus endpoints for the cluster, sorted by ID in ascending order. Set page_token in the request to the  next_page_token field of the previous response to get the next page of results. An empty next_page_token  indicates that there are no more results. During pagination, a newly added service with an ID lexicographically  earlier than the previous page's last endpoint's ID may be missed.
#
# GET /api/v1/nexus/endpoints
# operationId: ListNexusEndpoints
export def "nexus-endpoints ListNexusEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # To get the next page, pass in `ListNexusEndpointsResponse.next_page_token` from the previous page's  response, the token will be empty if there's no other page.  Note: the last page may be empty if the total number of endpoints registered is a multiple of the page size. (format: bytes)
  --name: string # Name of the incoming endpoint to filter on - optional. Specifying this will result in zero or one results.  (-- api-linter: core::203::field-behavior-required=disabled      aip.dev/not-precedent: Not following linter rules. --)
]: nothing -> record<nextPageToken: string, endpoints: table<version: string, id: string, spec: record, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/nexus/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Nexus endpoint. This will fail if an endpoint with the same name is already registered with a status of  ALREADY_EXISTS.  Returns the created endpoint with its initial version. You may use this version for subsequent updates.
#
# POST /api/v1/nexus/endpoints
# operationId: CreateNexusEndpoint
export def "nexus-endpoints CreateNexusEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spec: any # Endpoint definition to create.
]: any -> record<endpoint: record<version: string, id: string, spec: record<name: string, description: record, target: record>, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/nexus/endpoints")
  let body = {spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a registered Nexus endpoint by ID. The returned version can be used for optimistic updates.
#
# GET /api/v1/nexus/endpoints/{id}
# operationId: GetNexusEndpoint
export def "nexus-endpoints GetNexusEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoint: record<version: string, id: string, spec: record<name: string, description: record, target: record>, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/nexus/endpoints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an incoming Nexus service by ID.
#
# DELETE /api/v1/nexus/endpoints/{id}
# operationId: DeleteNexusEndpoint
export def "nexus-endpoints DeleteNexusEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Data version for this endpoint. Must match current version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/nexus/endpoints/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Optimistically update a Nexus endpoint based on provided version as obtained via the `GetNexusEndpoint` or  `ListNexusEndpointResponse` APIs. This will fail with a status of FAILED_PRECONDITION if the version does not  match.  Returns the updated endpoint with its updated version. You may use this version for subsequent updates. You don't  need to increment the version yourself. The server will increment the version for you after each update.
#
# POST /api/v1/nexus/endpoints/{id}/update
# operationId: UpdateNexusEndpoint
# --spec shape: {name?: string, description?: any, target?: any}
export def "nexus-endpoints-update UpdateNexusEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # Server-generated unique endpoint ID.
  --version: string # Data version for this endpoint. Must match current version.
  --spec: record # Contains mutable fields for an Endpoint. — shape: {name?: string, description?: any, target?: any}
]: any -> record<endpoint: record<version: string, id: string, spec: record<name: string, description: record, target: record>, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/nexus/endpoints/($id)/update")
  let body = {id: $body_id, version: $version, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GetSystemInfo returns information about the system.
#
# GET /api/v1/system-info
# operationId: GetSystemInfo
export def "system-info GetSystemInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<serverVersion: string, capabilities: record<signalAndQueryHeader: bool, internalErrorDifferentiation: bool, activityFailureIncludeHeartbeat: bool, supportsSchedules: bool, encodedFailureAttributes: bool, buildIdBasedVersioning: bool, upsertMemo: bool, eagerWorkflowStart: bool, sdkMetadata: bool, countGroupByExecutionStatus: bool, nexus: bool, serverScaledDeployments: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetClusterInfo returns information about temporal cluster
#
# GET /cluster
# operationId: GetClusterInfo
export def "cluster GetClusterInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<supportedClients: record, serverVersion: string, clusterId: string, versionInfo: record<current: record<version: string, releaseTime: string, notes: string>, recommended: record<version: string, releaseTime: string, notes: string>, instructions: string, alerts: list<record>, lastUpdateTime: string>, clusterName: string, historyShardCount: int, persistenceStore: string, visibilityStore: string, initialFailoverVersion: string, failoverVersionIncrement: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListNamespaces returns the information and configuration for all namespaces.
#
# GET /cluster/namespaces
# operationId: ListNamespaces
export def "cluster-namespaces ListNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --namespaceFilterincludeDeleted: oneof<nothing, bool> # By default namespaces in NAMESPACE_STATE_DELETED state are not included.  Setting include_deleted to true will include deleted namespaces.  Note: Namespace is in NAMESPACE_STATE_DELETED state when it was deleted from the system but associated data is not deleted yet.
]: nothing -> record<namespaces: table<namespaceInfo: record, config: record, replicationConfig: record, failoverVersion: string, isGlobalNamespace: bool, failoverHistory: list, pollerGroupInfos: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "namespaceFilter.includeDeleted" $namespaceFilterincludeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cluster/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# RegisterNamespace creates a new namespace which can be used as a container for all resources.   A Namespace is a top level entity within Temporal, and is used as a container for resources  like workflow executions, task queues, etc. A Namespace acts as a sandbox and provides  isolation for all resources within the namespace. All resources belongs to exactly one  namespace.
#
# POST /cluster/namespaces
# operationId: RegisterNamespace
# --clusters item shape: {clusterName?: string}
export def "cluster-namespaces RegisterNamespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string
  --description: string
  --ownerEmail: string
  --workflowExecutionRetentionPeriod: string
  --clusters: list # item shape: {clusterName?: string}
  --activeClusterName: string
  --data: record # A key-value map for any customized purpose.
  --securityToken: string
  --isGlobalNamespace: oneof<nothing, bool>
  --historyArchivalState: string@historyArchivalState-completer # If unspecified (ARCHIVAL_STATE_UNSPECIFIED) then default server configuration is used. (format: enum)
  --historyArchivalUri: string
  --visibilityArchivalState: string@visibilityArchivalState-completer # If unspecified (ARCHIVAL_STATE_UNSPECIFIED) then default server configuration is used. (format: enum)
  --visibilityArchivalUri: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster/namespaces")
  let body = {namespace: $namespace, description: $description, ownerEmail: $ownerEmail, workflowExecutionRetentionPeriod: $workflowExecutionRetentionPeriod, clusters: $clusters, activeClusterName: $activeClusterName, data: $data, securityToken: $securityToken, isGlobalNamespace: $isGlobalNamespace, historyArchivalState: $historyArchivalState, historyArchivalUri: $historyArchivalUri, visibilityArchivalState: $visibilityArchivalState, visibilityArchivalUri: $visibilityArchivalUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DescribeNamespace returns the information and configuration for a registered namespace.
#
# GET /cluster/namespaces/{namespace}
# operationId: DescribeNamespace
export def "cluster-namespaces DescribeNamespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --weakConsistency: oneof<nothing, bool> # If true, the server may serve the response from an eventually-consistent  source instead of reading through to persistence. Defaults to false,  which preserves read-after-write consistency. SDKs should set this when  fetching namespace capabilities on worker/client startup.
]: nothing -> record<namespaceInfo: record<name: string, state: string, description: string, ownerEmail: string, data: record, id: string, capabilities: record<eagerWorkflowStart: bool, syncUpdate: bool, asyncUpdate: bool, workerHeartbeats: bool, reportedProblemsSearchAttribute: bool, workflowPause: bool, standaloneActivities: bool, workerPollCompleteOnShutdown: bool, pollerAutoscaling: bool, workerCommands: bool, standaloneNexusOperation: bool, workflowUpdateCallbacks: bool>, limits: record<blobSizeLimitError: string, memoSizeLimitError: string>, supportsSchedules: bool>, config: record<workflowExecutionRetentionTtl: string, badBinaries: record<binaries: record>, historyArchivalState: string, historyArchivalUri: string, visibilityArchivalState: string, visibilityArchivalUri: string, customSearchAttributeAliases: record>, replicationConfig: record<activeClusterName: string, clusters: list<record>, state: string>, failoverVersion: string, isGlobalNamespace: bool, failoverHistory: table<failoverTime: string, failoverVersion: string>, pollerGroupInfos: table<id: string, weight: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "weakConsistency" $weakConsistency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cluster/namespaces/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListSearchAttributes returns comprehensive information about search attributes.
#
# GET /cluster/namespaces/{namespace}/search-attributes
# operationId: ListSearchAttributes
export def "cluster-namespaces-search-attributes ListSearchAttributes" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customAttributes: record, systemAttributes: record, storageSchema: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cluster/namespaces/($namespace)/search-attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# UpdateNamespace is used to update the information and configuration of a registered  namespace.
#
# POST /cluster/namespaces/{namespace}/update
# operationId: UpdateNamespace
# --updateInfo shape: {description?: string, ownerEmail?: string, data?: record, state?: "NAMESPACE_STATE_UNSPECIFIED"|"NAMESPACE_STATE_REGISTERED"|"NAMESPACE_STATE_DEPRECATED"|"NAMESPACE_STATE_DELETED"}
# --config shape: {workflowExecutionRetentionTtl?: string, badBinaries?: record, historyArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", historyArchivalUri?: string, visibilityArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", visibilityArchivalUri?: string, customSearchAttributeAliases?: record}
# --replicationConfig shape: {activeClusterName?: string, clusters?: list, state?: "REPLICATION_STATE_UNSPECIFIED"|"REPLICATION_STATE_NORMAL"|"REPLICATION_STATE_HANDOVER"}
export def "cluster-namespaces-update UpdateNamespace" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --updateInfo: record # shape: {description?: string, ownerEmail?: string, data?: record, state?: "NAMESPACE_STATE_UNSPECIFIED"|"NAMESPACE_STATE_REGISTERED"|"NAMESPACE_STATE_DEPRECATED"|"NAMESPACE_STATE_DELETED"}
  --config: record # shape: {workflowExecutionRetentionTtl?: string, badBinaries?: record, historyArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", historyArchivalUri?: string, visibilityArchivalState?: "ARCHIVAL_STATE_UNSPECIFIED"|"ARCHIVAL_STATE_DISABLED"|"ARCHIVAL_STATE_ENABLED", visibilityArchivalUri?: string, customSearchAttributeAliases?: record}
  --replicationConfig: record # shape: {activeClusterName?: string, clusters?: list, state?: "REPLICATION_STATE_UNSPECIFIED"|"REPLICATION_STATE_NORMAL"|"REPLICATION_STATE_HANDOVER"}
  --securityToken: string
  --deleteBadBinary: string
  --promoteNamespace: oneof<nothing, bool> # promote local namespace to global namespace. Ignored if namespace is already global namespace.
]: any -> record<namespaceInfo: record<name: string, state: string, description: string, ownerEmail: string, data: record, id: string, capabilities: record<eagerWorkflowStart: bool, syncUpdate: bool, asyncUpdate: bool, workerHeartbeats: bool, reportedProblemsSearchAttribute: bool, workflowPause: bool, standaloneActivities: bool, workerPollCompleteOnShutdown: bool, pollerAutoscaling: bool, workerCommands: bool, standaloneNexusOperation: bool, workflowUpdateCallbacks: bool>, limits: record<blobSizeLimitError: string, memoSizeLimitError: string>, supportsSchedules: bool>, config: record<workflowExecutionRetentionTtl: string, badBinaries: record<binaries: record>, historyArchivalState: string, historyArchivalUri: string, visibilityArchivalState: string, visibilityArchivalUri: string, customSearchAttributeAliases: record>, replicationConfig: record<activeClusterName: string, clusters: list<record>, state: string>, failoverVersion: string, isGlobalNamespace: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cluster/namespaces/($namespace)/update")
  let body = {namespace: $body_namespace, updateInfo: $updateInfo, config: $config, replicationConfig: $replicationConfig, securityToken: $securityToken, deleteBadBinary: $deleteBadBinary, promoteNamespace: $promoteNamespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Nexus endpoints for the cluster, sorted by ID in ascending order. Set page_token in the request to the  next_page_token field of the previous response to get the next page of results. An empty next_page_token  indicates that there are no more results. During pagination, a newly added service with an ID lexicographically  earlier than the previous page's last endpoint's ID may be missed.
#
# GET /cluster/nexus/endpoints
# operationId: ListNexusEndpoints
export def "cluster-nexus-endpoints ListNexusEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # To get the next page, pass in `ListNexusEndpointsResponse.next_page_token` from the previous page's  response, the token will be empty if there's no other page.  Note: the last page may be empty if the total number of endpoints registered is a multiple of the page size. (format: bytes)
  --name: string # Name of the incoming endpoint to filter on - optional. Specifying this will result in zero or one results.  (-- api-linter: core::203::field-behavior-required=disabled      aip.dev/not-precedent: Not following linter rules. --)
]: nothing -> record<nextPageToken: string, endpoints: table<version: string, id: string, spec: record, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cluster/nexus/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Nexus endpoint. This will fail if an endpoint with the same name is already registered with a status of  ALREADY_EXISTS.  Returns the created endpoint with its initial version. You may use this version for subsequent updates.
#
# POST /cluster/nexus/endpoints
# operationId: CreateNexusEndpoint
export def "cluster-nexus-endpoints CreateNexusEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spec: any # Endpoint definition to create.
]: any -> record<endpoint: record<version: string, id: string, spec: record<name: string, description: record, target: record>, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster/nexus/endpoints")
  let body = {spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a registered Nexus endpoint by ID. The returned version can be used for optimistic updates.
#
# GET /cluster/nexus/endpoints/{id}
# operationId: GetNexusEndpoint
export def "cluster-nexus-endpoints GetNexusEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpoint: record<version: string, id: string, spec: record<name: string, description: record, target: record>, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cluster/nexus/endpoints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an incoming Nexus service by ID.
#
# DELETE /cluster/nexus/endpoints/{id}
# operationId: DeleteNexusEndpoint
export def "cluster-nexus-endpoints DeleteNexusEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Data version for this endpoint. Must match current version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cluster/nexus/endpoints/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Optimistically update a Nexus endpoint based on provided version as obtained via the `GetNexusEndpoint` or  `ListNexusEndpointResponse` APIs. This will fail with a status of FAILED_PRECONDITION if the version does not  match.  Returns the updated endpoint with its updated version. You may use this version for subsequent updates. You don't  need to increment the version yourself. The server will increment the version for you after each update.
#
# POST /cluster/nexus/endpoints/{id}/update
# operationId: UpdateNexusEndpoint
# --spec shape: {name?: string, description?: any, target?: any}
export def "cluster-nexus-endpoints-update UpdateNexusEndpoint" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string # Server-generated unique endpoint ID.
  --version: string # Data version for this endpoint. Must match current version.
  --spec: record # Contains mutable fields for an Endpoint. — shape: {name?: string, description?: any, target?: any}
]: any -> record<endpoint: record<version: string, id: string, spec: record<name: string, description: record, target: record>, createdTime: string, lastModifiedTime: string, urlPrefix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cluster/nexus/endpoints/($id)/update")
  let body = {id: $body_id, version: $version, spec: $spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ListActivityExecutions is a visibility API to list activity executions in a specific namespace.
#
# GET /namespaces/{namespace}/activities
# operationId: ListActivityExecutions
export def "namespaces-activities ListActivityExecutions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Max number of executions to return per page. (format: int32)
  --nextPageToken: string # Token returned in ListActivityExecutionsResponse. (format: bytes)
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.
]: nothing -> record<executions: table<activityId: string, runId: string, activityType: record, scheduleTime: string, closeTime: string, status: string, searchAttributes: record, taskQueue: string, stateTransitionCount: string, stateSizeBytes: string, executionDuration: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PauseActivity pauses the execution of an activity specified by its ID or type.  If there are multiple pending activities of the provided type - all of them will be paused   Pausing an activity means:  - If the activity is currently waiting for a retry or is running and subsequently fails,    it will not be rescheduled until it is unpaused.  - If the activity is already paused, calling this method will have no effect.  - If the activity is running and finishes successfully, the activity will be completed.  - If the activity is running and finishes with failure:    * if there is no retry left - the activity will be completed.    * if there are more retries left - the activity will be paused.  For long-running activities:  - activities in paused state will send a cancellation with "activity_paused" set to 'true' in response to 'RecordActivityTaskHeartbeat'.  - The activity should respond to the cancellation accordingly.   Returns a `NotFound` error if there is no pending activity with the provided ID or type  This API will be deprecated soon and replaced with a newer PauseActivityExecution that is better named and  structured to work well for standalone activities.
#
# POST /namespaces/{namespace}/activities-deprecated/pause
# operationId: PauseActivity
export def "namespaces-activities-deprecated-pause PauseActivity-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request.
  --id: string # Only the activity with this ID will be paused.
  --type: string # Pause all running activities of this type.  Note: Experimental - the behavior of pause by activity type might change in a future release.
  --reason: string # Reason to pause the activity.
  --requestId: string # Used to de-dupe pause requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities-deprecated/pause")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, id: $id, type: $type, reason: $reason, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetActivity resets the execution of an activity specified by its ID or type.  If there are multiple pending activities of the provided type - all of them will be reset.   Resetting an activity means:  * number of attempts will be reset to 0.  * activity timeouts will be reset.  * if the activity is waiting for retry, and it is not paused or 'keep_paused' is not provided:     it will be scheduled immediately (* see 'jitter' flag),   Flags:   'jitter': the activity will be scheduled at a random time within the jitter duration.  If the activity currently paused it will be unpaused, unless 'keep_paused' flag is provided.  'reset_heartbeats': the activity heartbeat timer and heartbeats will be reset.  'keep_paused': if the activity is paused, it will remain paused.   Returns a `NotFound` error if there is no pending activity with the provided ID or type.  This API will be deprecated soon and replaced with a newer ResetActivityExecution that is better named and  structured to work well for standalone activities.
#
# POST /namespaces/{namespace}/activities-deprecated/reset
# operationId: ResetActivity
export def "namespaces-activities-deprecated-reset ResetActivity-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request.
  --id: string # Only activity with this ID will be reset.
  --type: string # Reset all running activities with of this type.
  --matchAll: oneof<nothing, bool> # Reset all running activities.
  --resetHeartbeat: oneof<nothing, bool> # Indicates that activity should reset heartbeat details.  This flag will be applied only to the new instance of the activity.
  --keepPaused: oneof<nothing, bool> # If activity is paused, it will remain paused after reset
  --jitter: string # If set, and activity is in backoff, the activity will start at a random time within the specified jitter duration.  (unless it is paused and keep_paused is set)
  --restoreOriginalOptions: oneof<nothing, bool> # If set, the activity options will be restored to the defaults.  Default options are then options activity was created with.  They are part of the first schedule event.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities-deprecated/reset")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, id: $id, type: $type, matchAll: $matchAll, resetHeartbeat: $resetHeartbeat, keepPaused: $keepPaused, jitter: $jitter, restoreOriginalOptions: $restoreOriginalOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UnpauseActivity unpauses the execution of an activity specified by its ID or type.  If there are multiple pending activities of the provided type - all of them will be unpaused.   If activity is not paused, this call will have no effect.  If the activity was paused while waiting for retry, it will be scheduled immediately (* see 'jitter' flag).  Once the activity is unpaused, all timeout timers will be regenerated.   Flags:  'jitter': the activity will be scheduled at a random time within the jitter duration.  'reset_attempts': the number of attempts will be reset.  'reset_heartbeat': the activity heartbeat timer and heartbeats will be reset.   Returns a `NotFound` error if there is no pending activity with the provided ID or type  This API will be deprecated soon and replaced with a newer UnpauseActivityExecution that is better named and  structured to work well for standalone activities.
#
# POST /namespaces/{namespace}/activities-deprecated/unpause
# operationId: UnpauseActivity
export def "namespaces-activities-deprecated-unpause UnpauseActivity-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request.
  --id: string # Only the activity with this ID will be unpaused.
  --type: string # Unpause all running activities with of this type.
  --unpauseAll: oneof<nothing, bool> # Unpause all running activities.
  --resetAttempts: oneof<nothing, bool> # Providing this flag will also reset the number of attempts.
  --resetHeartbeat: oneof<nothing, bool> # Providing this flag will also reset the heartbeat details.
  --jitter: string # If set, the activity will start at a random time within the specified jitter duration.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities-deprecated/unpause")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, id: $id, type: $type, unpauseAll: $unpauseAll, resetAttempts: $resetAttempts, resetHeartbeat: $resetHeartbeat, jitter: $jitter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateActivityOptions is called by the client to update the options of an activity by its ID or type.  If there are multiple pending activities of the provided type - all of them will be updated.  This API will be deprecated soon and replaced with a newer UpdateActivityExecutionOptions that is better named and  structured to work well for standalone activities.
#
# POST /namespaces/{namespace}/activities-deprecated/update-options
# operationId: UpdateActivityOptions
export def "namespaces-activities-deprecated-update-options UpdateActivityOptions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --execution: any # Execution info of the workflow which scheduled this activity
  --identity: string # The identity of the client who initiated this request
  --activityOptions: any # Activity options. Partial updates are accepted and controlled by update_mask
  --updateMask: string # Controls which fields from `activity_options` will be applied (format: field-mask)
  --id: string # Only activity with this ID will be updated.
  --type: string # Update all running activities of this type.
  --matchAll: oneof<nothing, bool> # Update all running activities.
  --restoreOriginal: oneof<nothing, bool> # If set, the activity options will be restored to the default.  Default options are then options activity was created with.  They are part of the first schedule event.  This flag cannot be combined with any other option; if you supply  restore_original together with other options, the request will be rejected.
]: any -> record<activityOptions: record<taskQueue: record<name: string, kind: string, normalName: string>, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities-deprecated/update-options")
  let body = {namespace: $body_namespace, execution: $execution, identity: $identity, activityOptions: $activityOptions, updateMask: $updateMask, id: $id, type: $type, matchAll: $matchAll, restoreOriginal: $restoreOriginal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DescribeActivityExecution returns information about an activity execution.  It can be used to:  - Get current activity info without waiting  - Long-poll for next state change and return new activity info  Response can optionally include activity input or outcome (if the activity has completed).
#
# GET /namespaces/{namespace}/activities/{activityId}
# operationId: DescribeActivityExecution
export def "namespaces-activities DescribeActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Activity run ID. If empty the request targets the latest run.
  --includeInput: oneof<nothing, bool> # Include the input field in the response.
  --includeOutcome: oneof<nothing, bool> # Include the outcome (result/failure) in the response if the activity has completed.
  --longPollToken: string # Token from a previous DescribeActivityExecutionResponse. If present, long-poll until activity  state changes from the state encoded in this token. If absent, return current state immediately.  If present, run_id must also be present.  Note that activity state may change multiple times between requests, therefore it is not  guaranteed that a client making a sequence of long-poll requests will see a complete  sequence of state changes. (format: bytes)
  --includeHeartbeatDetails: oneof<nothing, bool> # Include the heartbeat_details field inside info in the response if available.
  --includeLastFailure: oneof<nothing, bool> # Include the last_failure field inside info in the response if available.
]: nothing -> record<runId: string, info: record<activityId: string, runId: string, activityType: record<name: string>, status: string, runState: string, taskQueue: string, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, heartbeatDetails: record<payloads: list>, lastHeartbeatTime: string, lastStartedTime: string, attempt: int, executionDuration: string, scheduleTime: string, expirationTime: string, closeTime: string, lastFailure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, lastWorkerIdentity: string, currentRetryInterval: string, lastAttemptCompleteTime: string, nextAttemptScheduleTime: string, lastDeploymentVersion: record<buildId: string, deploymentName: string>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>, stateTransitionCount: string, stateSizeBytes: string, searchAttributes: record<indexedFields: record>, header: record<fields: record>, userMetadata: record<summary: record, details: record>, canceledReason: string, links: list<record>, totalHeartbeatCount: string, sdkName: string, sdkVersion: string, startDelay: string>, input: record<payloads: list<any>>, outcome: record<result: record<payloads: list>, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>>, longPollToken: string, callbacks: table<callback: record, registrationTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, blockedReason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar") (serialize-qp "includeInput" $includeInput "scalar") (serialize-qp "includeOutcome" $includeOutcome "scalar") (serialize-qp "longPollToken" $longPollToken "scalar") (serialize-qp "includeHeartbeatDetails" $includeHeartbeatDetails "scalar") (serialize-qp "includeLastFailure" $includeLastFailure "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StartActivityExecution starts a new activity execution.   Returns an `ActivityExecutionAlreadyStarted` error if an instance already exists with same activity ID in this namespace  unless permitted by the specified ID conflict policy.
#
# POST /namespaces/{namespace}/activities/{activityId}
# operationId: StartActivityExecution
# --completionCallbacks item shape: {nexus?: record, internal?: record, links?: list}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-activities StartActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --identity: string # The identity of the client who initiated this request
  --requestId: string # A unique identifier for this start request. Typically UUIDv4.
  --body-activityId: string # Identifier for this activity. Required. This identifier should be meaningful in the user's  own system. It must be unique among activities in the same namespace, subject to the rules  imposed by id_reuse_policy and id_conflict_policy.
  --activityType: any # The type of the activity, a string that corresponds to a registered activity on a worker.
  --taskQueue: any # Task queue to schedule this activity on.
  --scheduleToCloseTimeout: string # Indicates how long the caller is willing to wait for an activity completion. Limits how long  retries will be attempted. Either this or `start_to_close_timeout` must be specified.   (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --scheduleToStartTimeout: string # Limits time an activity task can stay in a task queue before a worker picks it up. This  timeout is always non retryable, as all a retry would achieve is to put it back into the same  queue. Defaults to `schedule_to_close_timeout` if not specified.   (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --startToCloseTimeout: string # Maximum time an activity is allowed to execute after being picked up by a worker. This  timeout is always retryable. Either this or `schedule_to_close_timeout` must be  specified.   (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --heartbeatTimeout: string # Maximum permitted time between successful worker heartbeats.
  --retryPolicy: any # The retry policy for the activity. Will never exceed `schedule_to_close_timeout`.
  --input: any # Serialized arguments to the activity. These are passed as arguments to the activity function.
  --idReusePolicy: string@idReusePolicy-completer # Defines whether to allow re-using the activity id from a previously *closed* activity.  The default policy is ACTIVITY_ID_REUSE_POLICY_ALLOW_DUPLICATE. (format: enum)
  --idConflictPolicy: string@idConflictPolicy-completer # Defines how to resolve an activity id conflict with a *running* activity.  The default policy is ACTIVITY_ID_CONFLICT_POLICY_FAIL. (format: enum)
  --searchAttributes: any # Search attributes for indexing.
  --header: any # Header for context propagation and tracing purposes.
  --userMetadata: any # Metadata for use by user interfaces to display the fixed as-of-start summary and details of the activity.
  --priority: any # Priority metadata.
  --completionCallbacks: list # Callbacks to be called by the server when this activity reaches a terminal state.  Callback addresses must be whitelisted in the server's dynamic configuration. — item shape: {nexus?: record, internal?: record, links?: list}
  --links: list # Links to be associated with the activity. Callbacks may also have associated links;  links already included with a callback should not be duplicated here. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
  --onConflictOptions: any # Options for handling conflicts when using ACTIVITY_ID_CONFLICT_POLICY_USE_EXISTING.
  --startDelay: string # Time to wait before dispatching the first activity task. This delay is not applied to retry attempts.
]: any -> record<runId: string, started: bool, link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)")
  let body = {namespace: $body_namespace, identity: $identity, requestId: $requestId, activityId: $body_activityId, activityType: $activityType, taskQueue: $taskQueue, scheduleToCloseTimeout: $scheduleToCloseTimeout, scheduleToStartTimeout: $scheduleToStartTimeout, startToCloseTimeout: $startToCloseTimeout, heartbeatTimeout: $heartbeatTimeout, retryPolicy: $retryPolicy, input: $input, idReusePolicy: $idReusePolicy, idConflictPolicy: $idConflictPolicy, searchAttributes: $searchAttributes, header: $header, userMetadata: $userMetadata, priority: $priority, completionCallbacks: $completionCallbacks, links: $links, onConflictOptions: $onConflictOptions, startDelay: $startDelay} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RequestCancelActivityExecution requests cancellation of an activity execution.   Cancellation is cooperative: this call records the request, but the activity must detect and  acknowledge it for the activity to reach CANCELED status. The cancellation signal is  delivered via `cancel_requested` in the heartbeat response; SDKs surface this via  language-idiomatic mechanisms (context cancellation, exceptions, abort signals).
#
# POST /namespaces/{namespace}/activities/{activityId}/cancel
# operationId: RequestCancelActivityExecution
export def "namespaces-activities-cancel RequestCancelActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-activityId: string
  --runId: string # Activity run ID, targets the latest run if run_id is empty.
  --identity: string # The identity of the worker/client.
  --requestId: string # Used to de-dupe cancellation requests.
  --reason: string # Reason for requesting the cancellation, recorded and available via the PollActivityExecution API.  Not propagated to a worker if an activity attempt is currently running.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/cancel")
  let body = {namespace: $body_namespace, activityId: $body_activityId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCompleted`. This version allows clients to record completions by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/activities/{activityId}/complete
# operationId: RespondActivityTaskCompletedById
export def "namespaces-activities-complete RespondActivityTaskCompletedById-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to complete
  --body-result: any # The serialized result of activity execution
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/complete")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, result: $body_result, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskFailed`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/activities/{activityId}/fail
# operationId: RespondActivityTaskFailedById
export def "namespaces-activities-fail RespondActivityTaskFailedById-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to fail
  --failure: any # Detailed failure information
  --identity: string # The identity of the worker/client
  --lastHeartbeatDetails: any # Additional details to be stored as last activity heartbeat
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<failures: table<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/fail")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, failure: $failure, identity: $identity, lastHeartbeatDetails: $lastHeartbeatDetails, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskHeartbeat`. This version allows clients to record heartbeats by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/activities/{activityId}/heartbeat
# operationId: RecordActivityTaskHeartbeatById
export def "namespaces-activities-heartbeat RecordActivityTaskHeartbeatById-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity we're heartbeating
  --details: any # Arbitrary data, of which the most recent call is kept, to store for this activity
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<cancelRequested: bool, activityPaused: bool, activityReset: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/heartbeat")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PollActivityExecution long-polls for an activity execution to complete and returns the  outcome (result or failure).
#
# GET /namespaces/{namespace}/activities/{activityId}/outcome
# operationId: PollActivityExecution
export def "namespaces-activities-outcome PollActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Activity run ID. If empty the request targets the latest run.
]: nothing -> record<runId: string, outcome: record<result: record<payloads: list>, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/outcome" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PauseActivityExecution pauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity   Pausing an activity means:  - If the activity is currently waiting for a retry or is running and subsequently fails,    it will not be rescheduled until it is unpaused.  - If the activity is already paused, calling this method will have no effect.  - If the activity is running and finishes successfully, the activity will be completed.  - If the activity is running and finishes with failure:    * if there is no retry left - the activity will be completed.    * if there are more retries left - the activity will be paused.  For long-running activities:  - activities in paused state will send a cancellation with "activity_paused" set to 'true' in response to 'RecordActivityTaskHeartbeat'.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /namespaces/{namespace}/activities/{activityId}/pause
# operationId: PauseActivityExecution
export def "namespaces-activities-pause PauseActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --workflowId: string # If provided, pause a workflow activity (or activities) for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to pause the activity.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
  --requestId: string # Used to de-dupe pause requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/pause")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, reason: $reason, resourceId: $resourceId, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetActivityExecution resets the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   Resetting an activity means:  * number of attempts will be reset to 0.  * activity timeouts will be reset.  * if the activity is waiting for retry, and it is not paused or 'keep_paused' is not provided:     it will be scheduled immediately (* see 'jitter' flag)   Returns a `NotFound` error if there is no pending activity with the provided ID or type.
#
# POST /namespaces/{namespace}/activities/{activityId}/reset
# operationId: ResetActivityExecution
export def "namespaces-activities-reset ResetActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetHeartbeat: oneof<nothing, bool> # Indicates that activity should reset heartbeat details.  This flag will be applied only to the new instance of the activity.
  --keepPaused: oneof<nothing, bool> # If activity is paused, it will remain paused after reset
  --jitter: string # If set, and activity is in backoff, the activity will start at a random time within the specified jitter duration.  (unless it is paused and keep_paused is set)
  --restoreOriginalOptions: oneof<nothing, bool> # If set, the activity options will be restored to the defaults.  Default options are then options activity was created with.  They are part of the first schedule event.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/reset")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetHeartbeat: $resetHeartbeat, keepPaused: $keepPaused, jitter: $jitter, restoreOriginalOptions: $restoreOriginalOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCanceled`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/activities/{activityId}/resolve-as-canceled
# operationId: RespondActivityTaskCanceledById
export def "namespaces-activities-resolve-as-canceled RespondActivityTaskCanceledById-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to confirm is cancelled
  --details: any # Serialized additional information to attach to the cancellation
  --identity: string # The identity of the worker/client
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/resolve-as-canceled")
  let body = {namespace: $body_namespace, workflowId: $workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, deploymentOptions: $deploymentOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# TerminateActivityExecution terminates an existing activity execution immediately.   Termination does not reach the worker and the activity code cannot react to it. A terminated activity may have a  running attempt.
#
# POST /namespaces/{namespace}/activities/{activityId}/terminate
# operationId: TerminateActivityExecution
export def "namespaces-activities-terminate TerminateActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-activityId: string
  --runId: string # Activity run ID, targets the latest run if run_id is empty.
  --identity: string # The identity of the worker/client.
  --requestId: string # Used to de-dupe termination requests.
  --reason: string # Reason for requesting the termination, recorded in in the activity's result failure outcome.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/terminate")
  let body = {namespace: $body_namespace, activityId: $body_activityId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UnpauseActivityExecution unpauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   If activity is not paused, this call will have no effect.  If the activity was paused while waiting for retry, it will be scheduled immediately (* see 'jitter' flag).  Once the activity is unpaused, all timeout timers will be regenerated.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /namespaces/{namespace}/activities/{activityId}/unpause
# operationId: UnpauseActivityExecution
export def "namespaces-activities-unpause UnpauseActivityExecution-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetAttempts: oneof<nothing, bool> # Providing this flag will also reset the number of attempts.
  --resetHeartbeat: oneof<nothing, bool> # Providing this flag will also reset the heartbeat details.
  --reason: string # Reason to unpause the activity.
  --jitter: string # If set, the activity will start at a random time within the specified jitter duration.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/unpause")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetAttempts: $resetAttempts, resetHeartbeat: $resetHeartbeat, reason: $reason, jitter: $jitter, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateActivityExecutionOptions is called by the client to update the options of an activity by its ID.  This API can be used to target a workflow activity or a standalone activity.
#
# POST /namespaces/{namespace}/activities/{activityId}/update-options
# operationId: UpdateActivityExecutionOptions
export def "namespaces-activities-update-options UpdateActivityExecutionOptions-by-namespace-activityId-1" [
  namespace: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request
  --activityOptions: any # Activity options. Partial updates are accepted and controlled by update_mask
  --updateMask: string # Controls which fields from `activity_options` will be applied (format: field-mask)
  --restoreOriginal: oneof<nothing, bool> # If set, the activity options will be restored to the default.  Default options are then options activity was created with.  They are part of the first schedule event.  This flag cannot be combined with any other option; if you supply  restore_original together with other options, the request will be rejected.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record<activityOptions: record<taskQueue: record<name: string, kind: string, normalName: string>, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activities/($activityId)/update-options")
  let body = {namespace: $body_namespace, workflowId: $workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, activityOptions: $activityOptions, updateMask: $updateMask, restoreOriginal: $restoreOriginal, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RespondActivityTaskCompleted is called by workers when they successfully complete an activity  task.   For workflow activities, this results in a new `ACTIVITY_TASK_COMPLETED` event being written to the workflow history  and a new workflow task created for the workflow. Fails with `NotFound` if the task token is  no longer valid due to activity timeout, already being completed, or never having existed.
#
# POST /namespaces/{namespace}/activity-complete
# operationId: RespondActivityTaskCompleted
export def "namespaces-activity-complete RespondActivityTaskCompleted-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --body-result: any # The result of successfully executing the activity
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
  --workerVersion: any # Version info of the worker who processed this task. This message's `build_id` field should  always be set by SDKs. Workers opting into versioning will also set the `use_versioning`  field to true. See message docstrings for more.  Deprecated. Use `deployment_options` instead.
  --deployment: any # Deployment info of the worker that completed this task. Must be present if user has set  `WorkerDeploymentOptions` regardless of versioning being enabled or not.  Deprecated. Replaced with `deployment_options`.
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activity-complete")
  let body = {taskToken: $taskToken, result: $body_result, identity: $identity, namespace: $body_namespace, resourceId: $resourceId, workerVersion: $workerVersion, deployment: $deployment, deploymentOptions: $deploymentOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CountActivityExecutions is a visibility API to count activity executions in a specific namespace.
#
# GET /namespaces/{namespace}/activity-count
# operationId: CountActivityExecutions
export def "namespaces-activity-count CountActivityExecutions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/activity-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# RespondActivityTaskFailed is called by workers when processing an activity task fails.   This results in a new `ACTIVITY_TASK_FAILED` event being written to the workflow history and  a new workflow task created for the workflow. Fails with `NotFound` if the task token is no  longer valid due to activity timeout, already being completed, or never having existed.
#
# POST /namespaces/{namespace}/activity-fail
# operationId: RespondActivityTaskFailed
export def "namespaces-activity-fail RespondActivityTaskFailed-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --failure: any # Detailed failure information
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
  --lastHeartbeatDetails: any # Additional details to be stored as last activity heartbeat
  --workerVersion: any # Version info of the worker who processed this task. This message's `build_id` field should  always be set by SDKs. Workers opting into versioning will also set the `use_versioning`  field to true. See message docstrings for more.  Deprecated. Use `deployment_options` instead.
  --deployment: any # Deployment info of the worker that completed this task. Must be present if user has set  `WorkerDeploymentOptions` regardless of versioning being enabled or not.  Deprecated. Replaced with `deployment_options`.
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
]: any -> record<failures: table<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activity-fail")
  let body = {taskToken: $taskToken, failure: $failure, identity: $identity, namespace: $body_namespace, resourceId: $resourceId, lastHeartbeatDetails: $lastHeartbeatDetails, workerVersion: $workerVersion, deployment: $deployment, deploymentOptions: $deploymentOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RecordActivityTaskHeartbeat is optionally called by workers while they execute activities.   If a worker fails to heartbeat within the `heartbeat_timeout` interval for the activity task,  then the current attempt times out. Depending on RetryPolicy, this may trigger a retry or  time out the activity.   For workflow activities, an `ACTIVITY_TASK_TIMED_OUT` event will be written to the workflow  history. Calling `RecordActivityTaskHeartbeat` will fail with `NotFound` in such situations,  in that event, the SDK should request cancellation of the activity.   The request may contain response `details` which will be persisted by the server and may be  used by the activity to checkpoint progress. The `cancel_requested` field in the response  indicates whether cancellation has been requested for the activity.
#
# POST /namespaces/{namespace}/activity-heartbeat
# operationId: RecordActivityTaskHeartbeat
export def "namespaces-activity-heartbeat RecordActivityTaskHeartbeat-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --details: any # Arbitrary data, of which the most recent call is kept, to store for this activity
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
]: any -> record<cancelRequested: bool, activityPaused: bool, activityReset: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activity-heartbeat")
  let body = {taskToken: $taskToken, details: $details, identity: $identity, namespace: $body_namespace, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RespondActivityTaskFailed is called by workers when processing an activity task fails.   For workflow activities, this results in a new `ACTIVITY_TASK_CANCELED` event being written to the workflow history  and a new workflow task created for the workflow. Fails with `NotFound` if the task token is  no longer valid due to activity timeout, already being completed, or never having existed.
#
# POST /namespaces/{namespace}/activity-resolve-as-canceled
# operationId: RespondActivityTaskCanceled
export def "namespaces-activity-resolve-as-canceled RespondActivityTaskCanceled-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskToken: string # The task token as received in `PollActivityTaskQueueResponse` (format: bytes)
  --details: any # Serialized additional information to attach to the cancellation
  --identity: string # The identity of the worker/client
  --body-namespace: string
  --resourceId: string # Resource ID for routing. Contains the workflow ID or activity ID for standalone activities.
  --workerVersion: any # Version info of the worker who processed this task. This message's `build_id` field should  always be set by SDKs. Workers opting into versioning will also set the `use_versioning`  field to true. See message docstrings for more.  Deprecated. Use `deployment_options` instead.
  --deployment: any # Deployment info of the worker that completed this task. Must be present if user has set  `WorkerDeploymentOptions` regardless of versioning being enabled or not.  Deprecated. Replaced with `deployment_options`.
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/activity-resolve-as-canceled")
  let body = {taskToken: $taskToken, details: $details, identity: $identity, namespace: $body_namespace, resourceId: $resourceId, workerVersion: $workerVersion, deployment: $deployment, deploymentOptions: $deploymentOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ListArchivedWorkflowExecutions is a visibility API to list archived workflow executions in a specific namespace.
#
# GET /namespaces/{namespace}/archived-workflows
# operationId: ListArchivedWorkflowExecutions
export def "namespaces-archived-workflows ListArchivedWorkflowExecutions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --qp-query: string
]: nothing -> record<executions: table<execution: record, type: record, startTime: string, closeTime: string, status: string, historyLength: string, parentNamespaceId: string, parentExecution: record, executionTime: string, memo: record, searchAttributes: record, autoResetPoints: record, taskQueue: string, stateTransitionCount: string, historySizeBytes: string, mostRecentWorkerVersionStamp: record, executionDuration: string, rootExecution: record, assignedBuildId: string, inheritedBuildId: string, firstRunId: string, versioningInfo: record, workerDeploymentName: string, priority: record, externalPayloadSizeBytes: string, externalPayloadCount: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/archived-workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListBatchOperations returns a list of batch operations
#
# GET /namespaces/{namespace}/batch-operations
# operationId: ListBatchOperations
export def "namespaces-batch-operations ListBatchOperations-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # List page size (format: int32)
  --nextPageToken: string # Next page token (format: bytes)
]: nothing -> record<operationInfo: table<jobId: string, state: string, startTime: string, closeTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/batch-operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeBatchOperation returns the information about a batch operation
#
# GET /namespaces/{namespace}/batch-operations/{jobId}
# operationId: DescribeBatchOperation
export def "namespaces-batch-operations DescribeBatchOperation-by-namespace-jobId-1" [
  namespace: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<operationType: string, jobId: string, state: string, startTime: string, closeTime: string, totalOperationCount: string, completeOperationCount: string, failureOperationCount: string, identity: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/batch-operations/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StartBatchOperation starts a new batch operation
#
# POST /namespaces/{namespace}/batch-operations/{jobId}
# operationId: StartBatchOperation
# --executions item shape: {workflowId?: string, runId?: string}
# --terminationOperation shape: {details?: any, identity?: string}
# --signalOperation shape: {signal?: string, input?: any, header?: any, identity?: string}
# --cancellationOperation shape: {identity?: string}
# --deletionOperation shape: {identity?: string}
# --resetOperation shape: {identity?: string, options?: any, resetType?: "RESET_TYPE_UNSPECIFIED"|"RESET_TYPE_FIRST_WORKFLOW_TASK"|"RESET_TYPE_LAST_WORKFLOW_TASK", resetReapplyType?: "RESET_REAPPLY_TYPE_UNSPECIFIED"|"RESET_REAPPLY_TYPE_SIGNAL"|"RESET_REAPPLY_TYPE_NONE"|"RESET_REAPPLY_TYPE_ALL_ELIGIBLE", postResetOperations?: list}
# --updateWorkflowOptionsOperation shape: {identity?: string, workflowExecutionOptions?: any, updateMask?: string}
# --unpauseActivitiesOperation shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, jitter?: string}
# --resetActivitiesOperation shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, keepPaused?: bool, jitter?: string, restoreOriginalOptions?: bool}
# --updateActivityOptionsOperation shape: {identity?: string, type?: string, matchAll?: bool, activityOptions?: any, updateMask?: string, restoreOriginal?: bool}
export def "namespaces-batch-operations StartBatchOperation-by-namespace-jobId-1" [
  namespace: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace that contains the batch operation
  --visibilityQuery: string # Visibility query defines the the group of workflow to apply the batch operation  This field and `executions` are mutually exclusive
  --body-jobId: string # Job ID defines the unique ID for the batch job
  --reason: string # Reason to perform the batch operation
  --executions: list # Executions to apply the batch operation  This field and `visibility_query` are mutually exclusive — item shape: {workflowId?: string, runId?: string}
  --maxOperationsPerSecond: float # Limit for the number of operations processed per second within this batch.  Its purpose is to reduce the stress on the system caused by batch operations, which helps to prevent system  overload and minimize potential delays in executing ongoing tasks for user workers.  Note that when no explicit limit is provided, the server will operate according to its limit defined by the  dynamic configuration key `worker.batcherRPS`. This also applies if the value in this field exceeds the  server's configured limit. (format: float)
  --terminationOperation: record # BatchOperationTermination sends terminate requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.TerminateWorkflowExecutionRequest.  Ignore first_execution_run_id because this is used for single workflow operation. — shape: {details?: any, identity?: string}
  --signalOperation: record # BatchOperationSignal sends signals to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.SignalWorkflowExecutionRequest. — shape: {signal?: string, input?: any, header?: any, identity?: string}
  --cancellationOperation: record # BatchOperationCancellation sends cancel requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.RequestCancelWorkflowExecutionRequest.  Ignore first_execution_run_id because this is used for single workflow operation. — shape: {identity?: string}
  --deletionOperation: record # BatchOperationDeletion sends deletion requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.DeleteWorkflowExecutionRequest. — shape: {identity?: string}
  --resetOperation: record # BatchOperationReset sends reset requests to batch workflows.  Keep the parameter in sync with temporal.api.workflowservice.v1.ResetWorkflowExecutionRequest. — shape: {identity?: string, options?: any, resetType?: "RESET_TYPE_UNSPECIFIED"|"RESET_TYPE_FIRST_WORKFLOW_TASK"|"RESET_TYPE_LAST_WORKFLOW_TASK", resetReapplyType?: "RESET_REAPPLY_TYPE_UNSPECIFIED"|"RESET_REAPPLY_TYPE_SIGNAL"|"RESET_REAPPLY_TYPE_NONE"|"RESET_REAPPLY_TYPE_ALL_ELIGIBLE", postResetOperations?: list}
  --updateWorkflowOptionsOperation: record # BatchOperationUpdateWorkflowExecutionOptions sends UpdateWorkflowExecutionOptions requests to batch workflows.  Keep the parameters in sync with temporal.api.workflowservice.v1.UpdateWorkflowExecutionOptionsRequest. — shape: {identity?: string, workflowExecutionOptions?: any, updateMask?: string}
  --unpauseActivitiesOperation: record # BatchOperationUnpauseActivities sends unpause requests to batch workflows. — shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, jitter?: string}
  --resetActivitiesOperation: record # BatchOperationResetActivities sends activity reset requests in a batch.  NOTE: keep in sync with temporal.api.workflowservice.v1.ResetActivityRequest — shape: {identity?: string, type?: string, matchAll?: bool, resetAttempts?: bool, resetHeartbeat?: bool, keepPaused?: bool, jitter?: string, restoreOriginalOptions?: bool}
  --updateActivityOptionsOperation: record # BatchOperationUpdateActivityOptions sends an update-activity-options requests in a batch.  NOTE: keep in sync with temporal.api.workflowservice.v1.UpdateActivityRequest — shape: {identity?: string, type?: string, matchAll?: bool, activityOptions?: any, updateMask?: string, restoreOriginal?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/batch-operations/($jobId)")
  let body = {namespace: $body_namespace, visibilityQuery: $visibilityQuery, jobId: $body_jobId, reason: $reason, executions: $executions, maxOperationsPerSecond: $maxOperationsPerSecond, terminationOperation: $terminationOperation, signalOperation: $signalOperation, cancellationOperation: $cancellationOperation, deletionOperation: $deletionOperation, resetOperation: $resetOperation, updateWorkflowOptionsOperation: $updateWorkflowOptionsOperation, unpauseActivitiesOperation: $unpauseActivitiesOperation, resetActivitiesOperation: $resetActivitiesOperation, updateActivityOptionsOperation: $updateActivityOptionsOperation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# StopBatchOperation stops a batch operation
#
# POST /namespaces/{namespace}/batch-operations/{jobId}/stop
# operationId: StopBatchOperation
export def "namespaces-batch-operations-stop StopBatchOperation-by-namespace-jobId-1" [
  namespace: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace that contains the batch operation
  --body-jobId: string # Batch job id
  --reason: string # Reason to stop a batch operation
  --identity: string # Identity of the operator
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/batch-operations/($jobId)/stop")
  let body = {namespace: $body_namespace, jobId: $body_jobId, reason: $reason, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets a deployment as the current deployment for its deployment series. Can optionally update  the metadata of the deployment as well.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced by `SetWorkerDeploymentCurrentVersion`.
#
# POST /namespaces/{namespace}/current-deployment/{deployment.series_name}
# operationId: SetCurrentDeployment
# --deployment shape: {seriesName?: string, buildId?: string}
export def "namespaces-current-deployment SetCurrentDeployment-by-namespace-deployment.series_name-1" [
  namespace: string
  deployment.series_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deployment: record # `Deployment` identifies a deployment of Temporal workers. The combination of deployment series  name + build ID serves as the identifier. User can use `WorkerDeploymentOptions` in their worker  programs to specify these values.  Deprecated. — shape: {seriesName?: string, buildId?: string}
  --identity: string # Optional. The identity of the client who initiated this request.
  --updateMetadata: any # Optional. Use to add or remove user-defined metadata entries. Metadata entries are exposed  when describing a deployment. It is a good place for information such as operator name,  links to internal deployment pipelines, etc.
]: any -> record<currentDeploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>, previousDeploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/current-deployment/($deployment.series_name)")
  let body = {namespace: $body_namespace, deployment: $deployment, identity: $identity, updateMetadata: $updateMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the current deployment (and its info) for a given deployment series.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced by `current_version` returned by `DescribeWorkerDeployment`.
#
# GET /namespaces/{namespace}/current-deployment/{seriesName}
# operationId: GetCurrentDeployment
export def "namespaces-current-deployment GetCurrentDeployment-by-namespace-seriesName-1" [
  namespace: string
  seriesName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentDeploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/current-deployment/($seriesName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists worker deployments in the namespace. Optionally can filter based on deployment series  name.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced with `ListWorkerDeployments`.
#
# GET /namespaces/{namespace}/deployments
# operationId: ListDeployments
export def "namespaces-deployments ListDeployments-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --seriesName: string # Optional. Use to filter based on exact series name match.
]: nothing -> record<nextPageToken: string, deployments: table<deployment: record, createTime: string, isCurrent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "seriesName" $seriesName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a worker deployment.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced with `DescribeWorkerDeploymentVersion`.
#
# GET /namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}
# operationId: DescribeDeployment
export def "namespaces-deployments DescribeDeployment-by-namespace-deployment.series_name-deployment.build_id-1" [
  namespace: string
  deployment.series_name: string
  deployment.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploymentseriesName: string # Different versions of the same worker service/application are related together by having a  shared series name.  Out of all deployments of a series, one can be designated as the current deployment, which  receives new workflow executions and new tasks of workflows with  `VERSIONING_BEHAVIOR_AUTO_UPGRADE` versioning behavior.
  --deploymentbuildId: string # Build ID changes with each version of the worker when the worker program code and/or config  changes.
]: nothing -> record<deploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment.seriesName" $deploymentseriesName "scalar") (serialize-qp "deployment.buildId" $deploymentbuildId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/deployments/($deployment.series_name)/($deployment.build_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the reachability level of a worker deployment to help users decide when it is time  to decommission a deployment. Reachability level is calculated based on the deployment's  `status` and existing workflows that depend on the given deployment for their execution.  Calculating reachability is relatively expensive. Therefore, server might return a recently  cached value. In such a case, the `last_update_time` will inform you about the actual  reachability calculation time.  Experimental. This API might significantly change or be removed in a future release.  Deprecated. Replaced with `DrainageInfo` returned by `DescribeWorkerDeploymentVersion`.
#
# GET /namespaces/{namespace}/deployments/{deployment.series_name}/{deployment.build_id}/reachability
# operationId: GetDeploymentReachability
export def "namespaces-deployments-reachability GetDeploymentReachability-by-namespace-deployment.series_name-deployment.build_id-1" [
  namespace: string
  deployment.series_name: string
  deployment.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deploymentseriesName: string # Different versions of the same worker service/application are related together by having a  shared series name.  Out of all deployments of a series, one can be designated as the current deployment, which  receives new workflow executions and new tasks of workflows with  `VERSIONING_BEHAVIOR_AUTO_UPGRADE` versioning behavior.
  --deploymentbuildId: string # Build ID changes with each version of the worker when the worker program code and/or config  changes.
]: nothing -> record<deploymentInfo: record<deployment: record<seriesName: string, buildId: string>, createTime: string, taskQueueInfos: list<record>, metadata: record, isCurrent: bool>, reachability: string, lastUpdateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deployment.seriesName" $deploymentseriesName "scalar") (serialize-qp "deployment.buildId" $deploymentbuildId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/deployments/($deployment.series_name)/($deployment.build_id)/reachability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CountNexusOperationExecutions is a visibility API to count Nexus operations in a specific namespace.
#
# GET /namespaces/{namespace}/nexus-operation-count
# operationId: CountNexusOperationExecutions
export def "namespaces-nexus-operation-count CountNexusOperationExecutions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.  See also ListNexusOperationExecutionsRequest for search attributes available for Nexus operations.
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/nexus-operation-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListNexusOperationExecutions is a visibility API to list Nexus operations in a specific namespace.
#
# GET /namespaces/{namespace}/nexus-operations
# operationId: ListNexusOperationExecutions
export def "namespaces-nexus-operations ListNexusOperationExecutions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Max number of operations to return per page. (format: int32)
  --nextPageToken: string # Token returned in ListNexusOperationExecutionsResponse. (format: bytes)
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.  Search attributes that are avaialble for Nexus operations include:  - OperationId  - RunId  - Endpoint  - Service  - Operation  - RequestId  - StartTime  - ExecutionTime  - CloseTime  - ExecutionStatus  - ExecutionDuration  - StateTransitionCount
]: nothing -> record<operations: table<operationId: string, runId: string, endpoint: string, service: string, operation: string, scheduleTime: string, closeTime: string, status: string, searchAttributes: record, stateTransitionCount: string, executionDuration: string, stateSizeBytes: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/nexus-operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeNexusOperationExecution returns information about a Nexus operation.  Supported use cases include:  - Get current operation info without waiting  - Long-poll for next state change and return new operation info  Response can optionally include operation input or outcome (if the operation has completed).
#
# GET /namespaces/{namespace}/nexus-operations/{operationId}
# operationId: DescribeNexusOperationExecution
export def "namespaces-nexus-operations DescribeNexusOperationExecution-by-namespace-operationId-1" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Operation run ID. If empty the request targets the latest run.
  --includeInput: oneof<nothing, bool> # Include the input field in the response.
  --includeOutcome: oneof<nothing, bool> # Include the outcome (result/failure) in the response if the operation has completed.
  --longPollToken: string # Token from a previous DescribeNexusOperationExecutionResponse. If present, this RPC will long-poll until operation  state changes from the state encoded in this token. If absent, return current state immediately.  If present, run_id must also be present.  Note that operation state may change multiple times between requests, therefore it is not  guaranteed that a client making a sequence of long-poll requests will see a complete  sequence of state changes. (format: bytes)
]: nothing -> record<runId: string, info: record<operationId: string, runId: string, endpoint: string, service: string, operation: string, status: string, state: string, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, attempt: int, scheduleTime: string, expirationTime: string, closeTime: string, lastAttemptCompleteTime: string, lastAttemptFailure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, nextAttemptScheduleTime: string, executionDuration: string, cancellationInfo: record<requestedTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, blockedReason: string, reason: string>, blockedReason: string, requestId: string, operationToken: string, stateTransitionCount: string, searchAttributes: record<indexedFields: record>, nexusHeader: record, userMetadata: record<summary: record, details: record>, links: list<record>, identity: string, stateSizeBytes: string>, input: record, result: record, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, applicationFailureInfo: record<type: string, nonRetryable: bool, details: record, nextRetryDelay: string, category: string>, timeoutFailureInfo: record<timeoutType: string, lastHeartbeatDetails: record>, canceledFailureInfo: record<details: record, identity: string>, terminatedFailureInfo: record<identity: string>, serverFailureInfo: record<nonRetryable: bool>, resetWorkflowFailureInfo: record<lastHeartbeatDetails: record>, activityFailureInfo: record<scheduledEventId: string, startedEventId: string, identity: string, activityType: record, activityId: string, retryState: string>, childWorkflowExecutionFailureInfo: record<namespace: string, workflowExecution: record, workflowType: record, initiatedEventId: string, startedEventId: string, retryState: string>, nexusOperationExecutionFailureInfo: record<scheduledEventId: string, endpoint: string, service: string, operation: string, operationId: string, operationToken: string>, nexusHandlerFailureInfo: record<type: string, retryBehavior: string>>, longPollToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar") (serialize-qp "includeInput" $includeInput "scalar") (serialize-qp "includeOutcome" $includeOutcome "scalar") (serialize-qp "longPollToken" $longPollToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/nexus-operations/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StartNexusOperationExecution starts a new Nexus operation.   Returns a `NexusOperationExecutionAlreadyStarted` error if an instance already exists with same operation ID in this  namespace unless permitted by the specified ID conflict policy.
#
# POST /namespaces/{namespace}/nexus-operations/{operationId}
# operationId: StartNexusOperationExecution
export def "namespaces-nexus-operations StartNexusOperationExecution-by-namespace-operationId-1" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this caller-side start request. Typically UUIDv4.  StartOperation requests sent to the handler will use a server-generated request ID.
  --body-operationId: string # Identifier for this operation. This is a caller-side ID, distinct from any internal  operation identifiers generated by the handler. Must be unique among operations in the  same namespace, subject to the rules imposed by id_reuse_policy and id_conflict_policy.
  --endpoint: string # Endpoint name, resolved to a URL via the cluster's endpoint registry.
  --service: string # Service name.
  --operation: string # Operation name.
  --scheduleToCloseTimeout: string # Schedule-to-close timeout for this operation.  Indicates how long the caller is willing to wait for operation completion.  Calls are retried internally by the server.  (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --scheduleToStartTimeout: string # Schedule-to-start timeout for this operation.  Indicates how long the caller is willing to wait for the operation to be started (or completed if synchronous)  by the handler.  If not set or zero, no schedule-to-start timeout is enforced.  (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --startToCloseTimeout: string # Start-to-close timeout for this operation.  Indicates how long the caller is willing to wait for an asynchronous operation to complete after it has been  started. Synchronous operations ignore this timeout.  If not set or zero, no start-to-close timeout is enforced.  (-- api-linter: core::0140::prepositions=disabled      aip.dev/not-precedent: "to" is used to indicate interval. --)
  --input: any # Serialized input to the operation. Passed as the request payload.
  --idReusePolicy: string@idReusePolicy-completer-1 # Defines whether to allow re-using the operation id from a previously *closed* operation.  The default policy is NEXUS_OPERATION_ID_REUSE_POLICY_ALLOW_DUPLICATE. (format: enum)
  --idConflictPolicy: string@idConflictPolicy-completer-1 # Defines how to resolve an operation id conflict with a *running* operation.  The default policy is NEXUS_OPERATION_ID_CONFLICT_POLICY_FAIL. (format: enum)
  --searchAttributes: any # Search attributes for indexing.
  --nexusHeader: record # Header to attach to the Nexus request.  Users are responsible for encrypting sensitive data in this header as it is stored in workflow history and  transmitted to external services as-is.  This is useful for propagating tracing information.  Note these headers are not the same as Temporal headers on internal activities and child workflows, these are  transmitted to Nexus operations that may be external and are not traditional payloads.
  --userMetadata: any # Metadata for use by user interfaces to display the fixed as-of-start summary and details of the operation.
]: any -> record<runId: string, started: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/nexus-operations/($operationId)")
  let body = {namespace: $body_namespace, identity: $identity, requestId: $requestId, operationId: $body_operationId, endpoint: $endpoint, service: $service, operation: $operation, scheduleToCloseTimeout: $scheduleToCloseTimeout, scheduleToStartTimeout: $scheduleToStartTimeout, startToCloseTimeout: $startToCloseTimeout, input: $input, idReusePolicy: $idReusePolicy, idConflictPolicy: $idConflictPolicy, searchAttributes: $searchAttributes, nexusHeader: $nexusHeader, userMetadata: $userMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RequestCancelNexusOperationExecution requests cancellation of a Nexus operation.   Requesting to cancel an operation does not automatically transition the operation to canceled status.  The operation will only transition to canceled status if it supports cancellation and the handler  processes the cancellation request.
#
# POST /namespaces/{namespace}/nexus-operations/{operationId}/cancel
# operationId: RequestCancelNexusOperationExecution
export def "namespaces-nexus-operations-cancel RequestCancelNexusOperationExecution-by-namespace-operationId-1" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-operationId: string
  --runId: string # Operation run ID, targets the latest run if empty.
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # Used to de-dupe cancellation requests.
  --reason: string # Reason for requesting the cancellation, recorded and available via the DescribeNexusOperationExecution API.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/nexus-operations/($operationId)/cancel")
  let body = {namespace: $body_namespace, operationId: $body_operationId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PollNexusOperationExecution long-polls for a Nexus operation for a given wait stage to complete and returns  the outcome (result or failure).
#
# GET /namespaces/{namespace}/nexus-operations/{operationId}/poll
# operationId: PollNexusOperationExecution
export def "namespaces-nexus-operations-poll PollNexusOperationExecution-by-namespace-operationId-1" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # Operation run ID. If empty the request targets the latest run.
  --waitStage: string@waitStage-completer # Stage to wait for. The operation may be in a more advanced stage when the poll is unblocked. (format: enum)
]: nothing -> record<runId: string, waitStage: string, operationToken: string, result: record, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>, applicationFailureInfo: record<type: string, nonRetryable: bool, details: record, nextRetryDelay: string, category: string>, timeoutFailureInfo: record<timeoutType: string, lastHeartbeatDetails: record>, canceledFailureInfo: record<details: record, identity: string>, terminatedFailureInfo: record<identity: string>, serverFailureInfo: record<nonRetryable: bool>, resetWorkflowFailureInfo: record<lastHeartbeatDetails: record>, activityFailureInfo: record<scheduledEventId: string, startedEventId: string, identity: string, activityType: record, activityId: string, retryState: string>, childWorkflowExecutionFailureInfo: record<namespace: string, workflowExecution: record, workflowType: record, initiatedEventId: string, startedEventId: string, retryState: string>, nexusOperationExecutionFailureInfo: record<scheduledEventId: string, endpoint: string, service: string, operation: string, operationId: string, operationToken: string>, nexusHandlerFailureInfo: record<type: string, retryBehavior: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar") (serialize-qp "waitStage" $waitStage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/nexus-operations/($operationId)/poll" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# TerminateNexusOperationExecution terminates an existing Nexus operation immediately.   Termination happens immediately and the operation handler cannot react to it. A terminated operation will have  its outcome set to a failure with a termination reason.
#
# POST /namespaces/{namespace}/nexus-operations/{operationId}/terminate
# operationId: TerminateNexusOperationExecution
export def "namespaces-nexus-operations-terminate TerminateNexusOperationExecution-by-namespace-operationId-1" [
  namespace: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-operationId: string
  --runId: string # Operation run ID, targets the latest run if empty.
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # Used to de-dupe termination requests.
  --reason: string # Reason for requesting the termination, recorded in the operation's result failure outcome.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/nexus-operations/($operationId)/terminate")
  let body = {namespace: $body_namespace, operationId: $body_operationId, runId: $runId, identity: $identity, requestId: $requestId, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CountSchedules is a visibility API to count schedules in a specific namespace.
#
# GET /namespaces/{namespace}/schedule-count
# operationId: CountSchedules
export def "namespaces-schedule-count CountSchedules-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Visibility query, see https://docs.temporal.io/list-filter for the syntax.
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/schedule-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all schedules in a namespace.
#
# GET /namespaces/{namespace}/schedules
# operationId: ListSchedules
export def "namespaces-schedules ListSchedules-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maximumPageSize: int # How many to return at once. (format: int32)
  --nextPageToken: string # Token to get the next page of results. (format: bytes)
  --qp-query: string # Query to filter schedules.
]: nothing -> record<schedules: table<scheduleId: string, memo: record, searchAttributes: record, info: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maximumPageSize" $maximumPageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the schedule description and current state of an existing schedule.
#
# GET /namespaces/{namespace}/schedules/{scheduleId}
# operationId: DescribeSchedule
export def "namespaces-schedules DescribeSchedule-by-namespace-scheduleId-1" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schedule: record<spec: record<structuredCalendar: list, cronString: list, calendar: list, interval: list, excludeCalendar: list, excludeStructuredCalendar: list, startTime: string, endTime: string, jitter: string, timezoneName: string, timezoneData: string>, action: record<startWorkflow: record>, policies: record<overlapPolicy: string, catchupWindow: string, pauseOnFailure: bool, keepOriginalWorkflowId: bool>, state: record<notes: string, paused: bool, limitedActions: bool, remainingActions: string>>, info: record<actionCount: string, missedCatchupWindow: string, overlapSkipped: string, bufferDropped: string, bufferSize: string, runningWorkflows: list<record>, recentActions: list<record>, futureActionTimes: list<string>, createTime: string, updateTime: string, invalidScheduleError: string, stateSizeBytes: string>, memo: record<fields: record>, searchAttributes: record<indexedFields: record>, conflictToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/schedules/($scheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new schedule.
#
# POST /namespaces/{namespace}/schedules/{scheduleId}
# operationId: CreateSchedule
# --searchAttributes shape: {indexedFields?: record}
export def "namespaces-schedules CreateSchedule-by-namespace-scheduleId-1" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace the schedule should be created in.
  --body-scheduleId: string # The id of the new schedule.
  --schedule: any # The schedule spec, policies, action, and initial state.
  --initialPatch: any # Optional initial patch (e.g. to run the action once immediately).
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.
  --memo: any # Memo and search attributes to attach to the schedule itself.
  --searchAttributes: record # A user-defined set of *indexed* fields that are used/exposed when listing/searching workflows.  The payload is not serialized in a user-defined way. — shape: {indexedFields?: record}
]: any -> record<conflictToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/schedules/($scheduleId)")
  let body = {namespace: $body_namespace, scheduleId: $body_scheduleId, schedule: $schedule, initialPatch: $initialPatch, identity: $identity, requestId: $requestId, memo: $memo, searchAttributes: $searchAttributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a schedule, removing it from the system.
#
# DELETE /namespaces/{namespace}/schedules/{scheduleId}
# operationId: DeleteSchedule
export def "namespaces-schedules DeleteSchedule-by-namespace-scheduleId-1" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # The identity of the client who initiated this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity" $identity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/schedules/($scheduleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists matching times within a range.
#
# GET /namespaces/{namespace}/schedules/{scheduleId}/matching-times
# operationId: ListScheduleMatchingTimes
export def "namespaces-schedules-matching-times ListScheduleMatchingTimes-by-namespace-scheduleId-1" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startTime: string # Time range to query. (format: date-time)
  --endTime: string # format: date-time
]: nothing -> record<startTime: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/schedules/($scheduleId)/matching-times" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Makes a specific change to a schedule or triggers an immediate action.
#
# POST /namespaces/{namespace}/schedules/{scheduleId}/patch
# operationId: PatchSchedule
# --patch shape: {triggerImmediately?: any, backfillRequest?: list, pause?: string, unpause?: string}
export def "namespaces-schedules-patch PatchSchedule-by-namespace-scheduleId-1" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace of the schedule to patch.
  --body-scheduleId: string # The id of the schedule to patch.
  --patch: record # shape: {triggerImmediately?: any, backfillRequest?: list, pause?: string, unpause?: string}
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this update request for idempotence. Typically UUIDv4.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/schedules/($scheduleId)/patch")
  let body = {namespace: $body_namespace, scheduleId: $body_scheduleId, patch: $patch, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Changes the configuration or state of an existing schedule.
#
# POST /namespaces/{namespace}/schedules/{scheduleId}/update
# operationId: UpdateSchedule
export def "namespaces-schedules-update UpdateSchedule-by-namespace-scheduleId-1" [
  namespace: string
  scheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace of the schedule to update.
  --body-scheduleId: string # The id of the schedule to update.
  --schedule: any # The new schedule. The four main fields of the schedule (spec, action,  policies, state) are replaced completely by the values in this message.
  --conflictToken: string # This can be the value of conflict_token from a DescribeScheduleResponse,  which will cause this request to fail if the schedule has been modified  between the Describe and this Update.  If missing, the schedule will be updated unconditionally. (format: bytes)
  --identity: string # The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this update request for idempotence. Typically UUIDv4.
  --searchAttributes: any # Schedule search attributes to be updated.  Do not set this field if you do not want to update the search attributes.  A non-null empty object will set the search attributes to an empty map.  Note: you cannot only update the search attributes with `UpdateScheduleRequest`,  you must also set the `schedule` field; otherwise, it will unset the schedule.
  --memo: any # Schedule memo to replace. If set, replaces the entire memo.  Do not set this field if you do not want to update the memo.  A non-null empty object will clear the memo.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/schedules/($scheduleId)/update")
  let body = {namespace: $body_namespace, scheduleId: $body_scheduleId, schedule: $schedule, conflictToken: $conflictToken, identity: $identity, requestId: $requestId, searchAttributes: $searchAttributes, memo: $memo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates task queue configuration.  For the overall queue rate limit: the rate limit set by this api overrides the worker-set rate limit,  which uncouples the rate limit from the worker lifecycle.  If the overall queue rate limit is unset, the worker-set rate limit takes effect.
#
# POST /namespaces/{namespace}/task-queues/{taskQueue}/update-config
# operationId: UpdateTaskQueueConfig
export def "namespaces-task-queues-update-config UpdateTaskQueueConfig-by-namespace-taskQueue-1" [
  namespace: string
  taskQueue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --identity: string
  --body-taskQueue: string # Selects the task queue to update.
  --taskQueueType: string@taskQueueType-completer # format: enum
  --updateQueueRateLimit: any # Update to queue-wide rate limit.  If not set, this configuration is unchanged.  NOTE: A limit set by the worker is overriden; and restored again when reset.  If the `rate_limit` field in the `RateLimitUpdate` is missing, remove the existing rate limit.
  --updateFairnessKeyRateLimitDefault: any # Update to the default fairness key rate limit.  If not set, this configuration is unchanged.  If the `rate_limit` field in the `RateLimitUpdate` is missing, remove the existing rate limit.
  --setFairnessWeightOverrides: record # If set, overrides the fairness weight for each specified fairness key.  Fairness keys not listed in this map will keep their existing overrides (if any).
  --unsetFairnessWeightOverrides: list # If set, removes any existing fairness weight overrides for each specified fairness key.  Fairness weights for corresponding keys fall back to the values set during task creation (if any),  or to the default weight of 1.0.
]: any -> record<config: record<queueRateLimit: record<rateLimit: record, metadata: record>, fairnessKeysRateLimitDefault: record<rateLimit: record, metadata: record>, fairnessWeightOverrides: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/task-queues/($taskQueue)/update-config")
  let body = {namespace: $body_namespace, identity: $identity, taskQueue: $body_taskQueue, taskQueueType: $taskQueueType, updateQueueRateLimit: $updateQueueRateLimit, updateFairnessKeyRateLimitDefault: $updateFairnessKeyRateLimitDefault, setFairnessWeightOverrides: $setFairnessWeightOverrides, unsetFairnessWeightOverrides: $unsetFairnessWeightOverrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deprecated. Use `GetWorkerVersioningRules`.  Will be removed in server version v1.32.0.  Fetches the worker build id versioning sets for a task queue.
#
# GET /namespaces/{namespace}/task-queues/{taskQueue}/worker-build-id-compatibility
# operationId: GetWorkerBuildIdCompatibility
export def "namespaces-task-queues-worker-build-id-compatibility GetWorkerBuildIdCompatibility-by-namespace-taskQueue-1" [
  namespace: string
  taskQueue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxSets: int # Limits how many compatible sets will be returned. Specify 1 to only return the current  default major version set. 0 returns all sets. (format: int32)
]: nothing -> record<majorVersionSets: table<buildIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxSets" $maxSets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/task-queues/($taskQueue)/worker-build-id-compatibility" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches the Build ID assignment and redirect rules for a Task Queue.  Will be removed in server version v1.32.0.
#
# GET /namespaces/{namespace}/task-queues/{taskQueue}/worker-versioning-rules
# operationId: GetWorkerVersioningRules
export def "namespaces-task-queues-worker-versioning-rules GetWorkerVersioningRules-by-namespace-taskQueue-1" [
  namespace: string
  taskQueue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignmentRules: table<rule: record, createTime: string>, compatibleRedirectRules: table<rule: record, createTime: string>, conflictToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/task-queues/($taskQueue)/worker-versioning-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeTaskQueue returns the following information about the target task queue, broken down by Build ID:    - List of pollers    - Workflow Reachability status    - Backlog info for Workflow and/or Activity tasks
#
# GET /namespaces/{namespace}/task-queues/{task_queue.name}
# operationId: DescribeTaskQueue
export def "namespaces-task-queues DescribeTaskQueue-by-namespace-task_queue.name-1" [
  namespace: string
  task_queue.name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskQueuename: string
  --taskQueuekind: string@taskQueuekind-completer # Default: TASK_QUEUE_KIND_NORMAL. (format: enum)
  --taskQueuenormalName: string # Iff kind == TASK_QUEUE_KIND_STICKY, then this field contains the name of  the normal task queue that the sticky worker is running on.
  --taskQueueType: string@taskQueueType-completer # If unspecified (TASK_QUEUE_TYPE_UNSPECIFIED), then default value (TASK_QUEUE_TYPE_WORKFLOW) will be used.  Only supported in default mode (use `task_queue_types` in ENHANCED mode instead). (format: enum)
  --reportStats: oneof<nothing, bool> # Report stats for the requested task queue type(s).
  --reportConfig: oneof<nothing, bool> # Report Task Queue Config
  --includeTaskQueueStatus: oneof<nothing, bool> # Deprecated, use `report_stats` instead.  If true, the task queue status will be included in the response.
  --apiMode: string@apiMode-completer # Deprecated. ENHANCED mode is also being deprecated.  Select the API mode to use for this request: DEFAULT mode (if unset) or ENHANCED mode.  Consult the documentation for each field to understand which mode it is supported in. (format: enum)
  --versionsbuildIds: list # Include specific Build IDs.
  --versionsunversioned: oneof<nothing, bool> # Include the unversioned queue.
  --versionsallActive: oneof<nothing, bool> # Include all active versions. A version is considered active if, in the last few minutes,  it has had new tasks or polls, or it has been the subject of certain task queue API calls.
  --taskQueueTypes: list # Deprecated (as part of the ENHANCED mode deprecation).  Task queue types to report info about. If not specified, all types are considered.
  --reportPollers: oneof<nothing, bool> # Deprecated (as part of the ENHANCED mode deprecation).  Report list of pollers for requested task queue types and versions.
  --reportTaskReachability: oneof<nothing, bool> # Deprecated (as part of the ENHANCED mode deprecation).  Report task reachability for the requested versions and all task types (task reachability is not reported  per task type).
]: nothing -> record<pollers: table<lastAccessTime: string, identity: string, ratePerSecond: float, workerVersionCapabilities: record, deploymentOptions: record>, stats: record<approximateBacklogCount: string, approximateBacklogAge: string, tasksAddRate: float, tasksDispatchRate: float>, statsByPriorityKey: record, versioningInfo: record<currentDeploymentVersion: record<buildId: string, deploymentName: string>, currentVersion: string, rampingDeploymentVersion: record<buildId: string, deploymentName: string>, rampingVersion: string, rampingVersionPercentage: float, updateTime: string>, config: record<queueRateLimit: record<rateLimit: record, metadata: record>, fairnessKeysRateLimitDefault: record<rateLimit: record, metadata: record>, fairnessWeightOverrides: record>, effectiveRateLimit: record<requestsPerSecond: float, rateLimitSource: string>, taskQueueStatus: record<backlogCountHint: string, readLevel: string, ackLevel: string, ratePerSecond: float, taskIdBlock: record<startId: string, endId: string>>, versionsInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskQueue.name" $taskQueuename "scalar") (serialize-qp "taskQueue.kind" $taskQueuekind "scalar") (serialize-qp "taskQueue.normalName" $taskQueuenormalName "scalar") (serialize-qp "taskQueueType" $taskQueueType "scalar") (serialize-qp "reportStats" $reportStats "scalar") (serialize-qp "reportConfig" $reportConfig "scalar") (serialize-qp "includeTaskQueueStatus" $includeTaskQueueStatus "scalar") (serialize-qp "apiMode" $apiMode "scalar") (serialize-qp "versions.buildIds" $versionsbuildIds "multi") (serialize-qp "versions.unversioned" $versionsunversioned "scalar") (serialize-qp "versions.allActive" $versionsallActive "scalar") (serialize-qp "taskQueueTypes" $taskQueueTypes "multi") (serialize-qp "reportPollers" $reportPollers "scalar") (serialize-qp "reportTaskReachability" $reportTaskReachability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/task-queues/($task_queue.name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CountWorkers counts the number of workers in a specific namespace.
#
# GET /namespaces/{namespace}/worker-count
# operationId: CountWorkers
export def "namespaces-worker-count CountWorkers-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to filter workers before counting.  Supported filter fields are the same as in ListWorkersRequest.
  --includeSystemWorkers: oneof<nothing, bool> # When true, the count will include system workers that are created implicitly  by the server and not by the user. By default, system workers are excluded.
]: nothing -> record<count: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "includeSystemWorkers" $includeSystemWorkers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Worker Deployment Version.   Experimental. This API might significantly change or be removed in a  future release.
#
# POST /namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}
# operationId: CreateWorkerDeploymentVersion
export def "namespaces-worker-deployment-versions CreateWorkerDeploymentVersion-by-namespace-deployment_version.deployment_name-1" [
  namespace: string
  deployment_version.deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deploymentVersion: any # Required.
  --computeConfig: any # Optional. Contains the new worker compute configuration for the Worker  Deployment. Used for worker scale management.
  --identity: string # Optional. The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.  If a second request with the same ID is recieved, it is considered a successful no-op.  Retrying with a different request ID for the same deployment name + build ID is an error.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)")
  let body = {namespace: $body_namespace, deploymentVersion: $deploymentVersion, computeConfig: $computeConfig, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a worker deployment version.  Experimental. This API might significantly change or be removed in a future release.
#
# GET /namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}
# operationId: DescribeWorkerDeploymentVersion
export def "namespaces-worker-deployment-versions DescribeWorkerDeploymentVersion-by-namespace-deployment_version.deployment_name-deployment_version.build_id-1" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Deprecated. Use `deployment_version`.
  --deploymentVersionbuildId: string # A unique identifier for this Version within the Deployment it is a part of.  Not necessarily unique within the namespace.  The combination of `deployment_name` and `build_id` uniquely identifies this  Version within the namespace, because Deployment names are unique within a namespace.
  --deploymentVersiondeploymentName: string # Identifies the Worker Deployment this Version is part of.
  --reportTaskQueueStats: oneof<nothing, bool> # Report stats for task queues which have been polled by this version.
]: nothing -> record<workerDeploymentVersionInfo: record<version: string, status: string, deploymentVersion: record<buildId: string, deploymentName: string>, deploymentName: string, createTime: string, routingChangedTime: string, currentSinceTime: string, rampingSinceTime: string, firstActivationTime: string, lastCurrentTime: string, lastDeactivationTime: string, rampPercentage: float, taskQueueInfos: list<record>, drainageInfo: record<status: string, lastChangedTime: string, lastCheckedTime: string>, metadata: record<entries: record>, computeConfig: record<scalingGroups: record>, lastModifierIdentity: string>, versionTaskQueues: table<name: string, type: string, stats: record, statsByPriorityKey: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "deploymentVersion.buildId" $deploymentVersionbuildId "scalar") (serialize-qp "deploymentVersion.deploymentName" $deploymentVersiondeploymentName "scalar") (serialize-qp "reportTaskQueueStats" $reportTaskQueueStats "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used for manual deletion of Versions. User can delete a Version only when all the  following conditions are met:   - It is not the Current or Ramping Version of its Deployment.   - It has no active pollers (none of the task queues in the Version have pollers)   - It is not draining (see WorkerDeploymentVersionInfo.drainage_info). This condition     can be skipped by passing `skip-drainage=true`.  Experimental. This API might significantly change or be removed in a future release.
#
# DELETE /namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}
# operationId: DeleteWorkerDeploymentVersion
export def "namespaces-worker-deployment-versions DeleteWorkerDeploymentVersion-by-namespace-deployment_version.deployment_name-deployment_version.build_id-1" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Deprecated. Use `deployment_version`.
  --deploymentVersionbuildId: string # A unique identifier for this Version within the Deployment it is a part of.  Not necessarily unique within the namespace.  The combination of `deployment_name` and `build_id` uniquely identifies this  Version within the namespace, because Deployment names are unique within a namespace.
  --deploymentVersiondeploymentName: string # Identifies the Worker Deployment this Version is part of.
  --skipDrainage: oneof<nothing, bool> # Pass to force deletion even if the Version is draining. In this case the open pinned  workflows will be stuck until manually moved to another version by UpdateWorkflowExecutionOptions.
  --identity: string # Optional. The identity of the client who initiated this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "deploymentVersion.buildId" $deploymentVersionbuildId "scalar") (serialize-qp "deploymentVersion.deploymentName" $deploymentVersiondeploymentName "scalar") (serialize-qp "skipDrainage" $skipDrainage "scalar") (serialize-qp "identity" $identity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the compute config attached to a Worker Deployment Version.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/update-compute-config
# operationId: UpdateWorkerDeploymentVersionComputeConfig
export def "namespaces-worker-deployment-versions-update-compute-config UpdateWorkerDeploymentVersionComputeConfig-by-namespace-deployment_version.deployment_name-deployment_version.build_id-1" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deploymentVersion: any # Required.
  --computeConfigScalingGroups: record # Optional. Contains the compute config scaling groups to add or update for the Worker  Deployment.
  --removeComputeConfigScalingGroups: list # Optional. Contains the compute config scaling groups to remove from the Worker Deployment.
  --identity: string # Optional. The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.  If a second request with the same ID is recieved, it is considered a successful no-op.  Retrying with a different request ID for the same deployment name + build ID is an error.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)/update-compute-config")
  let body = {namespace: $body_namespace, deploymentVersion: $deploymentVersion, computeConfigScalingGroups: $computeConfigScalingGroups, removeComputeConfigScalingGroups: $removeComputeConfigScalingGroups, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the user-given metadata attached to a Worker Deployment Version.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/update-metadata
# operationId: UpdateWorkerDeploymentVersionMetadata
export def "namespaces-worker-deployment-versions-update-metadata UpdateWorkerDeploymentVersionMetadata-by-namespace-deployment_version.deployment_name-deployment_version.build_id-1" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --version: string # Deprecated. Use `deployment_version`.
  --deploymentVersion: any # Required.
  --upsertEntries: record
  --removeEntries: list # List of keys to remove from the metadata.
  --identity: string # Optional. The identity of the client who initiated this request.
]: any -> record<metadata: record<entries: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)/update-metadata")
  let body = {namespace: $body_namespace, version: $version, deploymentVersion: $deploymentVersion, upsertEntries: $upsertEntries, removeEntries: $removeEntries, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validates the compute config without attaching it to a Worker Deployment Version.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /namespaces/{namespace}/worker-deployment-versions/{deployment_version.deployment_name}/{deployment_version.build_id}/validate-compute-config
# operationId: ValidateWorkerDeploymentVersionComputeConfig
export def "namespaces-worker-deployment-versions-validate-compute-config ValidateWorkerDeploymentVersionComputeConfig-by-namespace-deployment_version.deployment_name-deployment_version.build_id-1" [
  namespace: string
  deployment_version.deployment_name: string
  deployment_version.build_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --deploymentVersion: any # Required.
  --computeConfigScalingGroups: record # Optional. Contains the compute config scaling groups to add or update for the Worker  Deployment.
  --removeComputeConfigScalingGroups: list # Optional. Contains the compute config scaling groups to remove from the Worker Deployment.
  --identity: string # Optional. The identity of the client who initiated this request.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployment-versions/($deployment_version.deployment_name)/($deployment_version.build_id)/validate-compute-config")
  let body = {namespace: $body_namespace, deploymentVersion: $deploymentVersion, computeConfigScalingGroups: $computeConfigScalingGroups, removeComputeConfigScalingGroups: $removeComputeConfigScalingGroups, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all Worker Deployments that are tracked in the Namespace.  Experimental. This API might significantly change or be removed in a future release.
#
# GET /namespaces/{namespace}/worker-deployments
# operationId: ListWorkerDeployments
export def "namespaces-worker-deployments ListWorkerDeployments-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
]: nothing -> record<nextPageToken: string, workerDeployments: table<name: string, createTime: string, routingConfig: record, latestVersionSummary: record, currentVersionSummary: record, rampingVersionSummary: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Describes a Worker Deployment.  Experimental. This API might significantly change or be removed in a future release.
#
# GET /namespaces/{namespace}/worker-deployments/{deploymentName}
# operationId: DescribeWorkerDeployment
export def "namespaces-worker-deployments DescribeWorkerDeployment-by-namespace-deploymentName-1" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conflictToken: string, workerDeploymentInfo: record<name: string, versionSummaries: list<record>, createTime: string, routingConfig: record<currentDeploymentVersion: record, currentVersion: string, rampingDeploymentVersion: record, rampingVersion: string, rampingVersionPercentage: float, currentVersionChangedTime: string, rampingVersionChangedTime: string, rampingVersionPercentageChangedTime: string, revisionNumber: string>, lastModifierIdentity: string, managerIdentity: string, routingConfigUpdateState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployments/($deploymentName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Worker Deployment.   Experimental. This API might significantly change or be removed in a  future release.
#
# POST /namespaces/{namespace}/worker-deployments/{deploymentName}
# operationId: CreateWorkerDeployment
export def "namespaces-worker-deployments CreateWorkerDeployment-by-namespace-deploymentName-1" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string # The name of the Worker Deployment to create. If a Worker Deployment with  this name already exists, an error will be returned.
  --identity: string # Optional. The identity of the client who initiated this request.
  --requestId: string # A unique identifier for this create request for idempotence. Typically UUIDv4.
]: any -> record<conflictToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployments/($deploymentName)")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, identity: $identity, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes records of (an old) Deployment. A deployment can only be deleted if  it has no Version in it.  Experimental. This API might significantly change or be removed in a future release.
#
# DELETE /namespaces/{namespace}/worker-deployments/{deploymentName}
# operationId: DeleteWorkerDeployment
export def "namespaces-worker-deployments DeleteWorkerDeployment-by-namespace-deploymentName-1" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # Optional. The identity of the client who initiated this request.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity" $identity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set/unset the Current Version of a Worker Deployment. Automatically unsets the Ramping  Version if it is the Version being set as Current.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /namespaces/{namespace}/worker-deployments/{deploymentName}/set-current-version
# operationId: SetWorkerDeploymentCurrentVersion
export def "namespaces-worker-deployments-set-current-version SetWorkerDeploymentCurrentVersion-by-namespace-deploymentName-1" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string
  --version: string # Deprecated. Use `build_id`.
  --buildId: string # The build id of the Version that you want to set as Current.  Pass an empty value to set the Current Version to nil.  A nil Current Version represents all the unversioned workers (those with `UNVERSIONED` (or unspecified) `WorkerVersioningMode`.)
  --conflictToken: string # Optional. This can be the value of conflict_token from a Describe, or another Worker  Deployment API. Passing a non-nil conflict token will cause this request to fail if the  Deployment's configuration has been modified between the API call that generated the  token and this one. (format: bytes)
  --identity: string # Optional. The identity of the client who initiated this request.
  --ignoreMissingTaskQueues: oneof<nothing, bool> # Optional. By default this request would be rejected if not all the expected Task Queues are  being polled by the new Version, to protect against accidental removal of Task Queues, or  worker health issues. Pass `true` here to bypass this protection.  The set of expected Task Queues is the set of all the Task Queues that were ever poller by  the existing Current Version of the Deployment, with the following exclusions:    - Task Queues that are not used anymore (inferred by having empty backlog and a task      add_rate of 0.)    - Task Queues that are moved to another Worker Deployment (inferred by the Task Queue      having a different Current Version than the Current Version of this deployment.)  WARNING: Do not set this flag unless you are sure that the missing task queue pollers are not  needed. If the request is unexpectedly rejected due to missing pollers, then that means the  pollers have not reached to the server yet. Only set this if you expect those pollers to  never arrive.
  --allowNoPollers: oneof<nothing, bool> # Optional. By default this request will be rejected if no pollers have been seen for the proposed  Current Version, in order to protect users from routing tasks to pollers that do not exist, leading  to possible timeouts. Pass `true` here to bypass this protection.
]: any -> record<conflictToken: string, previousVersion: string, previousDeploymentVersion: record<buildId: string, deploymentName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployments/($deploymentName)/set-current-version")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, version: $version, buildId: $buildId, conflictToken: $conflictToken, identity: $identity, ignoreMissingTaskQueues: $ignoreMissingTaskQueues, allowNoPollers: $allowNoPollers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set/unset the ManagerIdentity of a Worker Deployment.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /namespaces/{namespace}/worker-deployments/{deploymentName}/set-manager
# operationId: SetWorkerDeploymentManager
export def "namespaces-worker-deployments-set-manager SetWorkerDeploymentManager-by-namespace-deploymentName-1" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string
  --managerIdentity: string # Arbitrary value for `manager_identity`.  Empty will unset the field.
  --self: oneof<nothing, bool> # True will set `manager_identity` to `identity`.
  --conflictToken: string # Optional. This can be the value of conflict_token from a Describe, or another Worker  Deployment API. Passing a non-nil conflict token will cause this request to fail if the  Deployment's configuration has been modified between the API call that generated the  token and this one. (format: bytes)
  --identity: string # Required. The identity of the client who initiated this request.
]: any -> record<conflictToken: string, previousManagerIdentity: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployments/($deploymentName)/set-manager")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, managerIdentity: $managerIdentity, self: $self, conflictToken: $conflictToken, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set/unset the Ramping Version of a Worker Deployment and its ramp percentage. Can be used for  gradual ramp to unversioned workers too.  Experimental. This API might significantly change or be removed in a future release.
#
# POST /namespaces/{namespace}/worker-deployments/{deploymentName}/set-ramping-version
# operationId: SetWorkerDeploymentRampingVersion
export def "namespaces-worker-deployments-set-ramping-version SetWorkerDeploymentRampingVersion-by-namespace-deploymentName-1" [
  namespace: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-deploymentName: string
  --version: string # Deprecated. Use `build_id`.
  --buildId: string # The build id of the Version that you want to ramp traffic to.  Pass an empty value to set the Ramping Version to nil.  A nil Ramping Version represents all the unversioned workers (those with `UNVERSIONED` (or unspecified) `WorkerVersioningMode`.)
  --percentage: float # Ramp percentage to set. Valid range: [0,100]. (format: float)
  --conflictToken: string # Optional. This can be the value of conflict_token from a Describe, or another Worker  Deployment API. Passing a non-nil conflict token will cause this request to fail if the  Deployment's configuration has been modified between the API call that generated the  token and this one. (format: bytes)
  --identity: string # Optional. The identity of the client who initiated this request.
  --ignoreMissingTaskQueues: oneof<nothing, bool> # Optional. By default this request would be rejected if not all the expected Task Queues are  being polled by the new Version, to protect against accidental removal of Task Queues, or  worker health issues. Pass `true` here to bypass this protection.  The set of expected Task Queues equals to all the Task Queues ever polled from the existing  Current Version of the Deployment, with the following exclusions:    - Task Queues that are not used anymore (inferred by having empty backlog and a task      add_rate of 0.)    - Task Queues that are moved to another Worker Deployment (inferred by the Task Queue      having a different Current Version than the Current Version of this deployment.)  WARNING: Do not set this flag unless you are sure that the missing task queue poller are not  needed. If the request is unexpectedly rejected due to missing pollers, then that means the  pollers have not reached to the server yet. Only set this if you expect those pollers to  never arrive.  Note: this check only happens when the ramping version is about to change, not every time  that the percentage changes. Also note that the check is against the deployment's Current  Version, not the previous Ramping Version.
  --allowNoPollers: oneof<nothing, bool> # Optional. By default this request will be rejected if no pollers have been seen for the proposed  Current Version, in order to protect users from routing tasks to pollers that do not exist, leading  to possible timeouts. Pass `true` here to bypass this protection.
]: any -> record<conflictToken: string, previousVersion: string, previousDeploymentVersion: record<buildId: string, deploymentName: string>, previousPercentage: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-deployments/($deploymentName)/set-ramping-version")
  let body = {namespace: $body_namespace, deploymentName: $body_deploymentName, version: $version, buildId: $buildId, percentage: $percentage, conflictToken: $conflictToken, identity: $identity, ignoreMissingTaskQueues: $ignoreMissingTaskQueues, allowNoPollers: $allowNoPollers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deprecated. Use `DescribeTaskQueue`.  Will be removed in server version v1.32.0.   Fetches task reachability to determine whether a worker may be retired.  The request may specify task queues to query for or let the server fetch all task queues mapped to the given  build IDs.   When requesting a large number of task queues or all task queues associated with the given build ids in a  namespace, all task queues will be listed in the response but some of them may not contain reachability  information due to a server enforced limit. When reaching the limit, task queues that reachability information  could not be retrieved for will be marked with a single TASK_REACHABILITY_UNSPECIFIED entry. The caller may issue  another call to get the reachability for those task queues.   Open source users can adjust this limit by setting the server's dynamic config value for  `limit.reachabilityTaskQueueScan` with the caveat that this call can strain the visibility store.
#
# GET /namespaces/{namespace}/worker-task-reachability
# operationId: GetWorkerTaskReachability
export def "namespaces-worker-task-reachability GetWorkerTaskReachability-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --buildIds: list # Build ids to retrieve reachability for. An empty string will be interpreted as an unversioned worker.  The number of build ids that can be queried in a single API call is limited.  Open source users can adjust this limit by setting the server's dynamic config value for  `limit.reachabilityQueryBuildIds` with the caveat that this call can strain the visibility store.
  --taskQueues: list # Task queues to retrieve reachability for. Leave this empty to query for all task queues associated with given  build ids in the namespace.  Must specify at least one task queue if querying for an unversioned worker.  The number of task queues that the server will fetch reachability information for is limited.  See the `GetWorkerTaskReachabilityResponse` documentation for more information.
  --reachability: string@reachability-completer # Type of reachability to query for.  `TASK_REACHABILITY_NEW_WORKFLOWS` is always returned in the response.  Use `TASK_REACHABILITY_EXISTING_WORKFLOWS` if your application needs to respond to queries on closed workflows.  Otherwise, use `TASK_REACHABILITY_OPEN_WORKFLOWS`. Default is `TASK_REACHABILITY_EXISTING_WORKFLOWS` if left  unspecified.  See the TaskReachability docstring for information about each enum variant. (format: enum)
]: nothing -> record<buildIdReachability: table<buildId: string, taskQueueReachability: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "buildIds" $buildIds "multi") (serialize-qp "taskQueues" $taskQueues "multi") (serialize-qp "reachability" $reachability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/worker-task-reachability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListWorkers is a visibility API to list worker status information in a specific namespace.
#
# GET /namespaces/{namespace}/workers
# operationId: ListWorkers
export def "namespaces-workers ListWorkers-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --qp-query: string # `query` in ListWorkers is used to filter workers based on worker attributes.  Supported attributes: * WorkerInstanceKey * WorkerIdentity * HostName * TaskQueue * DeploymentName * BuildId * SdkName * SdkVersion * StartTime * Status
  --includeSystemWorkers: oneof<nothing, bool> # When true, the response will include system workers that are created implicitly  by the server and not by the user. By default, system workers are excluded.
]: nothing -> record<workersInfo: table<workerHeartbeat: record>, workers: table<workerInstanceKey: string, workerIdentity: string, taskQueue: string, deploymentVersion: record, sdkName: string, sdkVersion: string, status: string, startTime: string, hostName: string, workerGroupingKey: string, processId: string, plugins: list, drivers: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "includeSystemWorkers" $includeSystemWorkers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/workers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeWorker returns information about the specified worker.
#
# GET /namespaces/{namespace}/workers/describe/{workerInstanceKey}
# operationId: DescribeWorker
export def "namespaces-workers-describe DescribeWorker-by-namespace-workerInstanceKey-1" [
  namespace: string
  workerInstanceKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workerInfo: record<workerHeartbeat: record<workerInstanceKey: string, workerIdentity: string, hostInfo: record, taskQueue: string, deploymentVersion: record, sdkName: string, sdkVersion: string, status: string, startTime: string, heartbeatTime: string, elapsedSinceLastHeartbeat: string, workflowTaskSlotsInfo: record, activityTaskSlotsInfo: record, nexusTaskSlotsInfo: record, localActivitySlotsInfo: record, workflowPollerInfo: record, workflowStickyPollerInfo: record, activityPollerInfo: record, nexusPollerInfo: record, totalStickyCacheHit: int, totalStickyCacheMiss: int, currentStickyCacheSize: int, plugins: list, drivers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workers/describe/($workerInstanceKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FetchWorkerConfig returns the worker configuration for a specific worker.
#
# POST /namespaces/{namespace}/workers/fetch-config
# operationId: FetchWorkerConfig
export def "namespaces-workers-fetch-config FetchWorkerConfig-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace this worker belongs to.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason for sending worker command, can be used for audit purpose.
  --selector: any # Defines which workers should receive this command.  only single worker is supported at this time.
  --resourceId: string # Resource ID for routing. Contains the worker grouping key.
]: any -> record<workerConfig: record<workflowCacheSize: int, simplePollerBehavior: record<maxPollers: int>, autoscalingPollerBehavior: record<minPollers: int, maxPollers: int, initialPollers: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workers/fetch-config")
  let body = {namespace: $body_namespace, identity: $identity, reason: $reason, selector: $selector, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# WorkerHeartbeat receive heartbeat request from the worker.
#
# POST /namespaces/{namespace}/workers/heartbeat
# operationId: RecordWorkerHeartbeat
# --workerHeartbeat item shape: {workerInstanceKey?: string, workerIdentity?: string, hostInfo?: any, taskQueue?: string, deploymentVersion?: record, sdkName?: string, sdkVersion?: string, status?: "WORKER_STATUS_UNSPECIFIED"|"WORKER_STATUS_RUNNING"|"WORKER_STATUS_SHUTTING_DOWN"|"WORKER_STATUS_SHUTDOWN", startTime?: string, heartbeatTime?: string, elapsedSinceLastHeartbeat?: string, workflowTaskSlotsInfo?: record, activityTaskSlotsInfo?: record, nexusTaskSlotsInfo?: record, localActivitySlotsInfo?: record, workflowPollerInfo?: record, workflowStickyPollerInfo?: record, activityPollerInfo?: record, nexusPollerInfo?: record, totalStickyCacheHit?: int, totalStickyCacheMiss?: int, currentStickyCacheSize?: int, plugins?: list, drivers?: list}
export def "namespaces-workers-heartbeat RecordWorkerHeartbeat-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace this worker belongs to.
  --identity: string # The identity of the client who initiated this request.
  --workerHeartbeat: list # item shape: {workerInstanceKey?: string, workerIdentity?: string, hostInfo?: any, taskQueue?: string, deploymentVersion?: record, sdkName?: string, sdkVersion?: string, status?: "WORKER_STATUS_UNSPECIFIED"|"WORKER_STATUS_RUNNING"|"WORKER_STATUS_SHUTTING_DOWN"|"WORKER_STATUS_SHUTDOWN", startTime?: string, heartbeatTime?: string, elapsedSinceLastHeartbeat?: string, workflowTaskSlotsInfo?: record, activityTaskSlotsInfo?: record, nexusTaskSlotsInfo?: record, localActivitySlotsInfo?: record, workflowPollerInfo?: record, workflowStickyPollerInfo?: record, activityPollerInfo?: record, nexusPollerInfo?: record, totalStickyCacheHit?: int, totalStickyCacheMiss?: int, currentStickyCacheSize?: int, plugins?: list, drivers?: list}
  --resourceId: string # Resource ID for routing. Contains the worker grouping key.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workers/heartbeat")
  let body = {namespace: $body_namespace, identity: $identity, workerHeartbeat: $workerHeartbeat, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateWorkerConfig updates the worker configuration of one or more workers.  Can be used to partially update the worker configuration.  Can be used to update the configuration of multiple workers.
#
# POST /namespaces/{namespace}/workers/update-config
# operationId: UpdateWorkerConfig
export def "namespaces-workers-update-config UpdateWorkerConfig-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace this worker belongs to.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason for sending worker command, can be used for audit purpose.
  --workerConfig: any # Partial updates are accepted and controlled by update_mask.  The worker configuration to set.
  --updateMask: string # Controls which fields from `worker_config` will be applied (format: field-mask)
  --selector: any # Defines which workers should receive this command.
  --resourceId: string # Resource ID for routing. Contains the worker grouping key.
]: any -> record<workerConfig: record<workflowCacheSize: int, simplePollerBehavior: record<maxPollers: int>, autoscalingPollerBehavior: record<minPollers: int, maxPollers: int, initialPollers: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workers/update-config")
  let body = {namespace: $body_namespace, identity: $identity, reason: $reason, workerConfig: $workerConfig, updateMask: $updateMask, selector: $selector, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CountWorkflowExecutions is a visibility API to count of workflow executions in a specific namespace.
#
# GET /namespaces/{namespace}/workflow-count
# operationId: CountWorkflowExecutions
export def "namespaces-workflow-count CountWorkflowExecutions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string
]: nothing -> record<count: string, groups: table<groupValues: list, count: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/workflow-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return all namespace workflow rules
#
# GET /namespaces/{namespace}/workflow-rules
# operationId: ListWorkflowRules
export def "namespaces-workflow-rules ListWorkflowRules-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nextPageToken: string # format: bytes
]: nothing -> record<rules: table<createTime: string, spec: record, createdByIdentity: string, description: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/workflow-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new workflow rule. The rules are used to control the workflow execution.  The rule will be applied to all running and new workflows in the namespace.  If the rule with such ID already exist this call will fail  Note: the rules are part of namespace configuration and will be stored in the namespace config.  Namespace config is eventually consistent.
#
# POST /namespaces/{namespace}/workflow-rules
# operationId: CreateWorkflowRule
export def "namespaces-workflow-rules CreateWorkflowRule-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --spec: any # The rule specification .
  --forceScan: oneof<nothing, bool> # If true, the rule will be applied to the currently running workflows via batch job.  If not set , the rule will only be applied when triggering condition is satisfied.  visibility_query in the rule will be used to select the workflows to apply the rule to.
  --requestId: string # Used to de-dupe requests. Typically should be UUID.
  --identity: string # Identity of the actor who created the rule. Will be stored with the rule.
  --description: string # Rule description.Will be stored with the rule.
]: any -> record<rule: record<createTime: string, spec: record<id: string, activityStart: record, visibilityQuery: string, actions: list, expirationTime: string>, createdByIdentity: string, description: string>, jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflow-rules")
  let body = {namespace: $body_namespace, spec: $spec, forceScan: $forceScan, requestId: $requestId, identity: $identity, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DescribeWorkflowRule return the rule specification for existing rule id.  If there is no rule with such id - NOT FOUND error will be returned.
#
# GET /namespaces/{namespace}/workflow-rules/{ruleId}
# operationId: DescribeWorkflowRule
export def "namespaces-workflow-rules DescribeWorkflowRule-by-namespace-ruleId-1" [
  namespace: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rule: record<createTime: string, spec: record<id: string, activityStart: record, visibilityQuery: string, actions: list, expirationTime: string>, createdByIdentity: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflow-rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete rule by rule id
#
# DELETE /namespaces/{namespace}/workflow-rules/{ruleId}
# operationId: DeleteWorkflowRule
export def "namespaces-workflow-rules DeleteWorkflowRule-by-namespace-ruleId-1" [
  namespace: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflow-rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListWorkflowExecutions is a visibility API to list workflow executions in a specific namespace.
#
# GET /namespaces/{namespace}/workflows
# operationId: ListWorkflowExecutions
export def "namespaces-workflows ListWorkflowExecutions-by-namespace-1" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # format: int32
  --nextPageToken: string # format: bytes
  --qp-query: string
]: nothing -> record<executions: table<execution: record, type: record, startTime: string, closeTime: string, status: string, historyLength: string, parentNamespaceId: string, parentExecution: record, executionTime: string, memo: record, searchAttributes: record, autoResetPoints: record, taskQueue: string, stateTransitionCount: string, historySizeBytes: string, mostRecentWorkerVersionStamp: record, executionDuration: string, rootExecution: record, assignedBuildId: string, inheritedBuildId: string, firstRunId: string, versioningInfo: record, workerDeploymentName: string, priority: record, externalPayloadSizeBytes: string, externalPayloadCount: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DescribeWorkflowExecution returns information about the specified workflow execution.
#
# GET /namespaces/{namespace}/workflows/{execution.workflow_id}
# operationId: DescribeWorkflowExecution
export def "namespaces-workflows DescribeWorkflowExecution-by-namespace-execution.workflow_id-1" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --executionworkflowId: string
  --executionrunId: string
]: nothing -> record<executionConfig: record<taskQueue: record<name: string, kind: string, normalName: string>, workflowExecutionTimeout: string, workflowRunTimeout: string, defaultWorkflowTaskTimeout: string, userMetadata: record<summary: record, details: record>>, workflowExecutionInfo: record<execution: record<workflowId: string, runId: string>, type: record<name: string>, startTime: string, closeTime: string, status: string, historyLength: string, parentNamespaceId: string, parentExecution: record<workflowId: string, runId: string>, executionTime: string, memo: record<fields: record>, searchAttributes: record<indexedFields: record>, autoResetPoints: record<points: list>, taskQueue: string, stateTransitionCount: string, historySizeBytes: string, mostRecentWorkerVersionStamp: record<buildId: string, useVersioning: bool>, executionDuration: string, rootExecution: record<workflowId: string, runId: string>, assignedBuildId: string, inheritedBuildId: string, firstRunId: string, versioningInfo: record<behavior: string, deployment: record, version: string, deploymentVersion: record, versioningOverride: record, deploymentTransition: record, versionTransition: record, revisionNumber: string, continueAsNewInitialVersioningBehavior: string>, workerDeploymentName: string, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>, externalPayloadSizeBytes: string, externalPayloadCount: string>, pendingActivities: table<activityId: string, activityType: record, state: string, heartbeatDetails: record, lastHeartbeatTime: string, lastStartedTime: string, attempt: int, maximumAttempts: int, scheduledTime: string, expirationTime: string, lastFailure: record, lastWorkerIdentity: string, lastIndependentlyAssignedBuildId: string, lastWorkerVersionStamp: record, currentRetryInterval: string, lastAttemptCompleteTime: string, nextAttemptScheduleTime: string, paused: bool, lastDeployment: record, lastWorkerDeploymentVersion: string, lastDeploymentVersion: record, priority: record, pauseInfo: record, activityOptions: record>, pendingChildren: table<workflowId: string, runId: string, workflowTypeName: string, initiatedId: string, parentClosePolicy: string>, pendingWorkflowTask: record<state: string, scheduledTime: string, originalScheduledTime: string, startedTime: string, attempt: int>, callbacks: table<callback: record, registrationTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, blockedReason: string>, pendingNexusOperations: table<endpoint: string, service: string, operation: string, operationId: string, scheduleToCloseTimeout: string, scheduledTime: string, state: string, attempt: int, lastAttemptCompleteTime: string, lastAttemptFailure: record, nextAttemptScheduleTime: string, cancellationInfo: record, scheduledEventId: string, blockedReason: string, operationToken: string, scheduleToStartTimeout: string, startToCloseTimeout: string>, workflowExtendedInfo: record<executionExpirationTime: string, runExpirationTime: string, cancelRequested: bool, lastResetTime: string, originalStartTime: string, resetRunId: string, requestIdInfos: record, pauseInfo: record<identity: string, pausedTime: string, reason: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "execution.workflowId" $executionworkflowId "scalar") (serialize-qp "execution.runId" $executionrunId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($execution.workflow_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetWorkflowExecutionHistory returns the history of specified workflow execution. Fails with  `NotFound` if the specified workflow execution is unknown to the service.
#
# GET /namespaces/{namespace}/workflows/{execution.workflow_id}/history
# operationId: GetWorkflowExecutionHistory
export def "namespaces-workflows-history GetWorkflowExecutionHistory-by-namespace-execution.workflow_id-1" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --executionworkflowId: string
  --executionrunId: string
  --maximumPageSize: int # format: int32
  --nextPageToken: string # If a `GetWorkflowExecutionHistoryResponse` or a `PollWorkflowTaskQueueResponse` had one of  these, it should be passed here to fetch the next page. (format: bytes)
  --waitNewEvent: oneof<nothing, bool> # If set to true, the RPC call will not resolve until there is a new event which matches  the `history_event_filter_type`, or a timeout is hit.
  --historyEventFilterType: string@historyEventFilterType-completer # Filter returned events such that they match the specified filter type.  Default: HISTORY_EVENT_FILTER_TYPE_ALL_EVENT. (format: enum)
  --skipArchival: oneof<nothing, bool>
]: nothing -> record<history: record<events: list<record>>, rawHistory: table<encodingType: string, data: string>, nextPageToken: string, archived: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "execution.workflowId" $executionworkflowId "scalar") (serialize-qp "execution.runId" $executionrunId "scalar") (serialize-qp "maximumPageSize" $maximumPageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar") (serialize-qp "waitNewEvent" $waitNewEvent "scalar") (serialize-qp "historyEventFilterType" $historyEventFilterType "scalar") (serialize-qp "skipArchival" $skipArchival "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($execution.workflow_id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetWorkflowExecutionHistoryReverse returns the history of specified workflow execution in reverse  order (starting from last event). Fails with`NotFound` if the specified workflow execution is  unknown to the service.
#
# GET /namespaces/{namespace}/workflows/{execution.workflow_id}/history-reverse
# operationId: GetWorkflowExecutionHistoryReverse
export def "namespaces-workflows-history-reverse GetWorkflowExecutionHistoryReverse-by-namespace-execution.workflow_id-1" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --executionworkflowId: string
  --executionrunId: string
  --maximumPageSize: int # format: int32
  --nextPageToken: string # format: bytes
]: nothing -> record<history: record<events: list<record>>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "execution.workflowId" $executionworkflowId "scalar") (serialize-qp "execution.runId" $executionrunId "scalar") (serialize-qp "maximumPageSize" $maximumPageSize "scalar") (serialize-qp "nextPageToken" $nextPageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($execution.workflow_id)/history-reverse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# QueryWorkflow requests a query be executed for a specified workflow execution.
#
# POST /namespaces/{namespace}/workflows/{execution.workflow_id}/query/{query.query_type}
# operationId: QueryWorkflow
# --execution shape: {workflowId?: string, runId?: string}
# --query shape: {queryType?: string, queryArgs?: any, header?: any}
export def "namespaces-workflows-query QueryWorkflow-by-namespace-execution.workflow_id-query.query_type-1" [
  namespace: string
  execution.workflow_id: string
  query.query_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --execution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --body-query: record # See https://docs.temporal.io/docs/concepts/queries/ — shape: {queryType?: string, queryArgs?: any, header?: any}
  --queryRejectCondition: string@queryRejectCondition-completer # QueryRejectCondition can used to reject the query if workflow state does not satisfy condition.  Default: QUERY_REJECT_CONDITION_NONE. (format: enum)
]: any -> record<queryResult: record<payloads: list<any>>, queryRejected: record<status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($execution.workflow_id)/query/($query.query_type)")
  let body = {namespace: $body_namespace, execution: $execution, query: $body_query, queryRejectCondition: $queryRejectCondition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# TriggerWorkflowRule allows to:   * trigger existing rule for a specific workflow execution;   * trigger rule for a specific workflow execution without creating a rule;  This is useful for one-off operations.
#
# POST /namespaces/{namespace}/workflows/{execution.workflow_id}/trigger-rule
# operationId: TriggerWorkflowRule
export def "namespaces-workflows-trigger-rule TriggerWorkflowRule-by-namespace-execution.workflow_id-1" [
  namespace: string
  execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --execution: any # Execution info of the workflow which scheduled this activity
  --id: string
  --spec: any # Note: Rule ID and expiration date are not used in the trigger request.
  --identity: string # The identity of the client who initiated this request
]: any -> record<applied: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($execution.workflow_id)/trigger-rule")
  let body = {namespace: $body_namespace, execution: $execution, id: $id, spec: $spec, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# StartWorkflowExecution starts a new workflow execution.   It will create the execution with a `WORKFLOW_EXECUTION_STARTED` event in its history and  also schedule the first workflow task. Returns `WorkflowExecutionAlreadyStarted`, if an  instance already exists with same workflow id.
#
# POST /namespaces/{namespace}/workflows/{workflowId}
# operationId: StartWorkflowExecution
# --workflowType shape: {name?: string}
# --taskQueue shape: {name?: string, kind?: "TASK_QUEUE_KIND_UNSPECIFIED"|"TASK_QUEUE_KIND_NORMAL"|"TASK_QUEUE_KIND_STICKY"|"TASK_QUEUE_KIND_WORKER_COMMANDS", normalName?: string}
# --memo shape: {fields?: record}
# --searchAttributes shape: {indexedFields?: record}
# --header shape: {fields?: record}
# --lastCompletionResult shape: {payloads?: list}
# --completionCallbacks item shape: {nexus?: record, internal?: record, links?: list}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows StartWorkflowExecution-by-namespace-workflowId-1" [
  namespace: string
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-workflowId: string
  --workflowType: record # Represents the identifier used by a workflow author to define the workflow. Typically, the  name of a function. This is sometimes referred to as the workflow's "name" — shape: {name?: string}
  --taskQueue: record # See https://docs.temporal.io/docs/concepts/task-queues/ — shape: {name?: string, kind?: "TASK_QUEUE_KIND_UNSPECIFIED"|"TASK_QUEUE_KIND_NORMAL"|"TASK_QUEUE_KIND_STICKY"|"TASK_QUEUE_KIND_WORKER_COMMANDS", normalName?: string}
  --input: any # Serialized arguments to the workflow. These are passed as arguments to the workflow function.
  --workflowExecutionTimeout: string # Total workflow execution timeout including retries and continue as new.
  --workflowRunTimeout: string # Timeout of a single workflow run.
  --workflowTaskTimeout: string # Timeout of a single workflow task.
  --identity: string # The identity of the client who initiated this request
  --requestId: string # A unique identifier for this start request. Typically UUIDv4.
  --workflowIdReusePolicy: string@workflowIdReusePolicy-completer # Defines whether to allow re-using the workflow id from a previously *closed* workflow.  The default policy is WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE.   See `workflow_id_conflict_policy` for handling a workflow id duplication with a *running* workflow. (format: enum)
  --workflowIdConflictPolicy: string@workflowIdConflictPolicy-completer # Defines how to resolve a workflow id conflict with a *running* workflow.  The default policy is WORKFLOW_ID_CONFLICT_POLICY_FAIL.   See `workflow_id_reuse_policy` for handling a workflow id duplication with a *closed* workflow. (format: enum)
  --retryPolicy: any # The retry policy for the workflow. Will never exceed `workflow_execution_timeout`.
  --cronSchedule: string # See https://docs.temporal.io/docs/content/what-is-a-temporal-cron-job/
  --memo: record # A user-defined set of *unindexed* fields that are exposed when listing/searching workflows — shape: {fields?: record}
  --searchAttributes: record # A user-defined set of *indexed* fields that are used/exposed when listing/searching workflows.  The payload is not serialized in a user-defined way. — shape: {indexedFields?: record}
  --header: record # Contains metadata that can be attached to a variety of requests, like starting a workflow, and  can be propagated between, for example, workflows and activities. — shape: {fields?: record}
  --requestEagerExecution: oneof<nothing, bool> # Request to get the first workflow task inline in the response bypassing matching service and worker polling.  If set to `true` the caller is expected to have a worker available and capable of processing the task.  The returned task will be marked as started and is expected to be completed by the specified  `workflow_task_timeout`.
  --continuedFailure: any # These values will be available as ContinuedFailure and LastCompletionResult in the  WorkflowExecutionStarted event and through SDKs. The are currently only used by the  server itself (for the schedules feature) and are not intended to be exposed in  StartWorkflowExecution.
  --lastCompletionResult: record # See `Payload` — shape: {payloads?: list}
  --workflowStartDelay: string # Time to wait before dispatching the first workflow task. Cannot be used with `cron_schedule`.  If the workflow gets a signal before the delay, a workflow task will be dispatched and the rest  of the delay will be ignored.
  --completionCallbacks: list # Callbacks to be called by the server when this workflow reaches a terminal state.  If the workflow continues-as-new, these callbacks will be carried over to the new execution.  Callback addresses must be whitelisted in the server's dynamic configuration. — item shape: {nexus?: record, internal?: record, links?: list}
  --userMetadata: any # Metadata on the workflow if it is started. This is carried over to the WorkflowExecutionInfo  for use by user interfaces to display the fixed as-of-start summary and details of the  workflow.
  --links: list # Links to be associated with the workflow. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
  --versioningOverride: any # If set, takes precedence over the Versioning Behavior sent by the SDK on Workflow Task completion.  To unset the override after the workflow is running, use UpdateWorkflowExecutionOptions.
  --onConflictOptions: any # Defines actions to be done to the existing running workflow when the conflict policy  WORKFLOW_ID_CONFLICT_POLICY_USE_EXISTING is used. If not set (ie., nil value) or set to a  empty object (ie., all options with default value), it won't do anything to the existing  running workflow. If set, it will add a history event to the running workflow.
  --priority: any # Priority metadata
  --eagerWorkerDeploymentOptions: any # Deployment Options of the worker who will process the eager task. Passed when `request_eager_execution=true`.
  --timeSkippingConfig: any # Time-skipping configuration. If not set, time skipping is disabled.
]: any -> record<runId: string, started: bool, status: string, eagerWorkflowTask: record<taskToken: string, workflowExecution: record<workflowId: string, runId: string>, workflowType: record<name: string>, previousStartedEventId: string, startedEventId: string, attempt: int, backlogCountHint: string, history: record<events: list>, nextPageToken: string, query: record<queryType: string, queryArgs: record, header: record>, workflowExecutionTaskQueue: record<name: string, kind: string, normalName: string>, scheduledTime: string, startedTime: string, queries: record, messages: list<record>, pollerScalingDecision: record<pollRequestDeltaSuggestion: int>, pollerGroupId: string, pollerGroupInfos: list<record>>, link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, workflowType: $workflowType, taskQueue: $taskQueue, input: $input, workflowExecutionTimeout: $workflowExecutionTimeout, workflowRunTimeout: $workflowRunTimeout, workflowTaskTimeout: $workflowTaskTimeout, identity: $identity, requestId: $requestId, workflowIdReusePolicy: $workflowIdReusePolicy, workflowIdConflictPolicy: $workflowIdConflictPolicy, retryPolicy: $retryPolicy, cronSchedule: $cronSchedule, memo: $memo, searchAttributes: $searchAttributes, header: $header, requestEagerExecution: $requestEagerExecution, continuedFailure: $continuedFailure, lastCompletionResult: $lastCompletionResult, workflowStartDelay: $workflowStartDelay, completionCallbacks: $completionCallbacks, userMetadata: $userMetadata, links: $links, versioningOverride: $versioningOverride, onConflictOptions: $onConflictOptions, priority: $priority, eagerWorkerDeploymentOptions: $eagerWorkerDeploymentOptions, timeSkippingConfig: $timeSkippingConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCompleted`. This version allows clients to record completions by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/complete
# operationId: RespondActivityTaskCompletedById
export def "namespaces-workflows-activities-complete RespondActivityTaskCompletedById-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to complete
  --body-result: any # The serialized result of activity execution
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/complete")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, result: $body_result, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskFailed`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/fail
# operationId: RespondActivityTaskFailedById
export def "namespaces-workflows-activities-fail RespondActivityTaskFailedById-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to fail
  --failure: any # Detailed failure information
  --identity: string # The identity of the worker/client
  --lastHeartbeatDetails: any # Additional details to be stored as last activity heartbeat
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<failures: table<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/fail")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, failure: $failure, identity: $identity, lastHeartbeatDetails: $lastHeartbeatDetails, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RecordActivityTaskHeartbeat`. This version allows clients to record heartbeats by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/heartbeat
# operationId: RecordActivityTaskHeartbeatById
export def "namespaces-workflows-activities-heartbeat RecordActivityTaskHeartbeatById-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity we're heartbeating
  --details: any # Arbitrary data, of which the most recent call is kept, to store for this activity
  --identity: string # The identity of the worker/client
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record<cancelRequested: bool, activityPaused: bool, activityReset: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/heartbeat")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PauseActivityExecution pauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity   Pausing an activity means:  - If the activity is currently waiting for a retry or is running and subsequently fails,    it will not be rescheduled until it is unpaused.  - If the activity is already paused, calling this method will have no effect.  - If the activity is running and finishes successfully, the activity will be completed.  - If the activity is running and finishes with failure:    * if there is no retry left - the activity will be completed.    * if there are more retries left - the activity will be paused.  For long-running activities:  - activities in paused state will send a cancellation with "activity_paused" set to 'true' in response to 'RecordActivityTaskHeartbeat'.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/pause
# operationId: PauseActivityExecution
export def "namespaces-workflows-activities-pause PauseActivityExecution-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --body-workflowId: string # If provided, pause a workflow activity (or activities) for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to pause the activity.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
  --requestId: string # Used to de-dupe pause requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/pause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, reason: $reason, resourceId: $resourceId, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetActivityExecution resets the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   Resetting an activity means:  * number of attempts will be reset to 0.  * activity timeouts will be reset.  * if the activity is waiting for retry, and it is not paused or 'keep_paused' is not provided:     it will be scheduled immediately (* see 'jitter' flag)   Returns a `NotFound` error if there is no pending activity with the provided ID or type.
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/reset
# operationId: ResetActivityExecution
export def "namespaces-workflows-activities-reset ResetActivityExecution-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --body-workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetHeartbeat: oneof<nothing, bool> # Indicates that activity should reset heartbeat details.  This flag will be applied only to the new instance of the activity.
  --keepPaused: oneof<nothing, bool> # If activity is paused, it will remain paused after reset
  --jitter: string # If set, and activity is in backoff, the activity will start at a random time within the specified jitter duration.  (unless it is paused and keep_paused is set)
  --restoreOriginalOptions: oneof<nothing, bool> # If set, the activity options will be restored to the defaults.  Default options are then options activity was created with.  They are part of the first schedule event.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/reset")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetHeartbeat: $resetHeartbeat, keepPaused: $keepPaused, jitter: $jitter, restoreOriginalOptions: $restoreOriginalOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# See `RespondActivityTaskCanceled`. This version allows clients to record failures by  namespace/workflow id/activity id instead of task token.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "By" is used to indicate request type. --)
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/resolve-as-canceled
# operationId: RespondActivityTaskCanceledById
export def "namespaces-workflows-activities-resolve-as-canceled RespondActivityTaskCanceledById-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # Id of the workflow which scheduled this activity, leave empty to target a standalone activity
  --runId: string # For a workflow activity - the run ID of the workflow which scheduled this activity.  For a standalone activity - the run ID of the activity.
  --body-activityId: string # Id of the activity to confirm is cancelled
  --details: any # Serialized additional information to attach to the cancellation
  --identity: string # The identity of the worker/client
  --deploymentOptions: any # Worker deployment options that user has set in the worker.
  --resourceId: string # Resource ID for routing. Contains "workflow:workflow_id" or "activity:activity_id" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/resolve-as-canceled")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, activityId: $body_activityId, details: $details, identity: $identity, deploymentOptions: $deploymentOptions, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UnpauseActivityExecution unpauses the execution of an activity specified by its ID.  This API can be used to target a workflow activity or a standalone activity.   If activity is not paused, this call will have no effect.  If the activity was paused while waiting for retry, it will be scheduled immediately (* see 'jitter' flag).  Once the activity is unpaused, all timeout timers will be regenerated.   Returns a `NotFound` error if there is no pending activity with the provided ID
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/unpause
# operationId: UnpauseActivityExecution
export def "namespaces-workflows-activities-unpause UnpauseActivityExecution-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity.
  --body-workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request.
  --resetAttempts: oneof<nothing, bool> # Providing this flag will also reset the number of attempts.
  --resetHeartbeat: oneof<nothing, bool> # Providing this flag will also reset the heartbeat details.
  --reason: string # Reason to unpause the activity.
  --jitter: string # If set, the activity will start at a random time within the specified jitter duration.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/unpause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, resetAttempts: $resetAttempts, resetHeartbeat: $resetHeartbeat, reason: $reason, jitter: $jitter, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateActivityExecutionOptions is called by the client to update the options of an activity by its ID.  This API can be used to target a workflow activity or a standalone activity.
#
# POST /namespaces/{namespace}/workflows/{workflowId}/activities/{activityId}/update-options
# operationId: UpdateActivityExecutionOptions
export def "namespaces-workflows-activities-update-options UpdateActivityExecutionOptions-by-namespace-workflowId-activityId-1" [
  namespace: string
  workflowId: string
  activityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow which scheduled this activity
  --body-workflowId: string # If provided, targets a workflow activity for the given workflow ID.  If empty, targets a standalone activity.
  --body-activityId: string # The ID of the activity to target.
  --runId: string # Run ID of the workflow or standalone activity.
  --identity: string # The identity of the client who initiated this request
  --activityOptions: any # Activity options. Partial updates are accepted and controlled by update_mask
  --updateMask: string # Controls which fields from `activity_options` will be applied (format: field-mask)
  --restoreOriginal: oneof<nothing, bool> # If set, the activity options will be restored to the default.  Default options are then options activity was created with.  They are part of the first schedule event.  This flag cannot be combined with any other option; if you supply  restore_original together with other options, the request will be rejected.
  --resourceId: string # Resource ID for routing. Contains "workflow:{workflow_id}" for workflow activities or "activity:{activity_id}" for standalone activities.
]: any -> record<activityOptions: record<taskQueue: record<name: string, kind: string, normalName: string>, scheduleToCloseTimeout: string, scheduleToStartTimeout: string, startToCloseTimeout: string, heartbeatTimeout: string, retryPolicy: record<initialInterval: string, backoffCoefficient: float, maximumInterval: string, maximumAttempts: int, nonRetryableErrorTypes: list>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/activities/($activityId)/update-options")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, activityId: $body_activityId, runId: $runId, identity: $identity, activityOptions: $activityOptions, updateMask: $updateMask, restoreOriginal: $restoreOriginal, resourceId: $resourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Note: This is an experimental API and the behavior may change in a future release.  PauseWorkflowExecution pauses the workflow execution specified in the request. Pausing a workflow execution results in  - The workflow execution status changes to `PAUSED` and a new WORKFLOW_EXECUTION_PAUSED event is added to the history  - No new workflow tasks or activity tasks are dispatched.    - Any workflow task currently executing on the worker will be allowed to complete.    - Any activity task currently executing will be paused.  - All server-side events will continue to be processed by the server.  - Queries & Updates on a paused workflow will be rejected.
#
# POST /namespaces/{namespace}/workflows/{workflowId}/pause
# operationId: PauseWorkflowExecution
export def "namespaces-workflows-pause PauseWorkflowExecution-by-namespace-workflowId-1" [
  namespace: string
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow to pause.
  --body-workflowId: string # ID of the workflow execution to be paused. Required.
  --runId: string # Run ID of the workflow execution to be paused. Optional. If not provided, the current run of the workflow will be paused.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to pause the workflow execution.
  --requestId: string # A unique identifier for this pause request for idempotence. Typically UUIDv4.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/pause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, identity: $identity, reason: $reason, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SignalWithStartWorkflowExecution is used to ensure a signal is sent to a workflow, even if  it isn't yet started.   If the workflow is running, a `WORKFLOW_EXECUTION_SIGNALED` event is recorded in the history  and a workflow task is generated.   If the workflow is not running or not found, then the workflow is created with  `WORKFLOW_EXECUTION_STARTED` and `WORKFLOW_EXECUTION_SIGNALED` events in its history, and a  workflow task is generated.   (-- api-linter: core::0136::prepositions=disabled      aip.dev/not-precedent: "With" is used to indicate combined operation. --)
#
# POST /namespaces/{namespace}/workflows/{workflowId}/signal-with-start/{signalName}
# operationId: SignalWithStartWorkflowExecution
# --workflowType shape: {name?: string}
# --memo shape: {fields?: record}
# --searchAttributes shape: {indexedFields?: record}
# --header shape: {fields?: record}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-signal-with-start SignalWithStartWorkflowExecution-by-namespace-workflowId-signalName-1" [
  namespace: string
  workflowId: string
  signalName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --body-workflowId: string
  --workflowType: record # Represents the identifier used by a workflow author to define the workflow. Typically, the  name of a function. This is sometimes referred to as the workflow's "name" — shape: {name?: string}
  --taskQueue: any # The task queue to start this workflow on, if it will be started
  --input: any # Serialized arguments to the workflow. These are passed as arguments to the workflow function.
  --workflowExecutionTimeout: string # Total workflow execution timeout including retries and continue as new
  --workflowRunTimeout: string # Timeout of a single workflow run
  --workflowTaskTimeout: string # Timeout of a single workflow task
  --identity: string # The identity of the worker/client
  --requestId: string # Used to de-dupe signal w/ start requests
  --workflowIdReusePolicy: string@workflowIdReusePolicy-completer # Defines whether to allow re-using the workflow id from a previously *closed* workflow.  The default policy is WORKFLOW_ID_REUSE_POLICY_ALLOW_DUPLICATE.   See `workflow_id_reuse_policy` for handling a workflow id duplication with a *running* workflow. (format: enum)
  --workflowIdConflictPolicy: string@workflowIdConflictPolicy-completer # Defines how to resolve a workflow id conflict with a *running* workflow.  The default policy is WORKFLOW_ID_CONFLICT_POLICY_USE_EXISTING.  Note that WORKFLOW_ID_CONFLICT_POLICY_FAIL is an invalid option.   See `workflow_id_reuse_policy` for handling a workflow id duplication with a *closed* workflow. (format: enum)
  --body-signalName: string # The workflow author-defined name of the signal to send to the workflow
  --signalInput: any # Serialized value(s) to provide with the signal
  --control: string # Deprecated.
  --retryPolicy: any # Retry policy for the workflow
  --cronSchedule: string # See https://docs.temporal.io/docs/content/what-is-a-temporal-cron-job/
  --memo: record # A user-defined set of *unindexed* fields that are exposed when listing/searching workflows — shape: {fields?: record}
  --searchAttributes: record # A user-defined set of *indexed* fields that are used/exposed when listing/searching workflows.  The payload is not serialized in a user-defined way. — shape: {indexedFields?: record}
  --header: record # Contains metadata that can be attached to a variety of requests, like starting a workflow, and  can be propagated between, for example, workflows and activities. — shape: {fields?: record}
  --workflowStartDelay: string # Time to wait before dispatching the first workflow task. Cannot be used with `cron_schedule`.  Note that the signal will be delivered with the first workflow task. If the workflow gets  another SignalWithStartWorkflow before the delay a workflow task will be dispatched immediately  and the rest of the delay period will be ignored, even if that request also had a delay.  Signal via SignalWorkflowExecution will not unblock the workflow.
  --userMetadata: any # Metadata on the workflow if it is started. This is carried over to the WorkflowExecutionInfo  for use by user interfaces to display the fixed as-of-start summary and details of the  workflow.
  --links: list # Links to be associated with the WorkflowExecutionStarted and WorkflowExecutionSignaled events. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
  --versioningOverride: any # If set, takes precedence over the Versioning Behavior sent by the SDK on Workflow Task completion.  To unset the override after the workflow is running, use UpdateWorkflowExecutionOptions.
  --priority: any # Priority metadata
  --timeSkippingConfig: any # Time-skipping configuration. If not set, time skipping is disabled.
]: any -> record<runId: string, started: bool, signalLink: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/signal-with-start/($signalName)")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, workflowType: $workflowType, taskQueue: $taskQueue, input: $input, workflowExecutionTimeout: $workflowExecutionTimeout, workflowRunTimeout: $workflowRunTimeout, workflowTaskTimeout: $workflowTaskTimeout, identity: $identity, requestId: $requestId, workflowIdReusePolicy: $workflowIdReusePolicy, workflowIdConflictPolicy: $workflowIdConflictPolicy, signalName: $body_signalName, signalInput: $signalInput, control: $control, retryPolicy: $retryPolicy, cronSchedule: $cronSchedule, memo: $memo, searchAttributes: $searchAttributes, header: $header, workflowStartDelay: $workflowStartDelay, userMetadata: $userMetadata, links: $links, versioningOverride: $versioningOverride, priority: $priority, timeSkippingConfig: $timeSkippingConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Note: This is an experimental API and the behavior may change in a future release.  UnpauseWorkflowExecution unpauses a previously paused workflow execution specified in the request.  Unpausing a workflow execution results in  - The workflow execution status changes to `RUNNING` and a new WORKFLOW_EXECUTION_UNPAUSED event is added to the history  - Workflow tasks and activity tasks are resumed.
#
# POST /namespaces/{namespace}/workflows/{workflowId}/unpause
# operationId: UnpauseWorkflowExecution
export def "namespaces-workflows-unpause UnpauseWorkflowExecution-by-namespace-workflowId-1" [
  namespace: string
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # Namespace of the workflow to unpause.
  --body-workflowId: string # ID of the workflow execution to be paused. Required.
  --runId: string # Run ID of the workflow execution to be paused. Optional. If not provided, the current run of the workflow will be paused.
  --identity: string # The identity of the client who initiated this request.
  --reason: string # Reason to unpause the workflow execution.
  --requestId: string # A unique identifier for this unpause request for idempotence. Typically UUIDv4.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflowId)/unpause")
  let body = {namespace: $body_namespace, workflowId: $body_workflowId, runId: $runId, identity: $identity, reason: $reason, requestId: $requestId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# RequestCancelWorkflowExecution is called by workers when they want to request cancellation of  a workflow execution.   This results in a new `WORKFLOW_EXECUTION_CANCEL_REQUESTED` event being written to the  workflow history and a new workflow task created for the workflow. It returns success if the requested  workflow is already closed. It fails with 'NotFound' if the requested workflow doesn't exist.
#
# POST /namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/cancel
# operationId: RequestCancelWorkflowExecution
# --workflowExecution shape: {workflowId?: string, runId?: string}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-cancel RequestCancelWorkflowExecution-by-namespace-workflow_execution.workflow_id-1" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --identity: string # The identity of the worker/client
  --requestId: string # Used to de-dupe cancellation requests
  --firstExecutionRunId: string # If set, this call will error if the most recent (if no run id is set on  `workflow_execution`), or specified (if it is) workflow execution is not part of the same  execution chain as this id.
  --reason: string # Reason for requesting the cancellation
  --links: list # Links to be associated with the WorkflowExecutionCanceled event. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/cancel")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, identity: $identity, requestId: $requestId, firstExecutionRunId: $firstExecutionRunId, reason: $reason, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ResetWorkflowExecution will reset an existing workflow execution to a specified  `WORKFLOW_TASK_COMPLETED` event (exclusive). It will immediately terminate the current  execution instance. "Exclusive" means the identified completed event itself is not replayed  in the reset history; the preceding `WORKFLOW_TASK_STARTED` event remains and will be marked as failed  immediately, and a new workflow task will be scheduled to retry it.
#
# POST /namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/reset
# operationId: ResetWorkflowExecution
# --postResetOperations item shape: {signalWorkflow?: record, updateWorkflowOptions?: record}
export def "namespaces-workflows-reset ResetWorkflowExecution-by-namespace-workflow_execution.workflow_id-1" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: any # The workflow to reset. If this contains a run ID then the workflow will be reset back to the  provided event ID in that run. Otherwise it will be reset to the provided event ID in the  current run. In all cases the current run will be terminated and a new run started.
  --reason: string
  --workflowTaskFinishEventId: string # The id of a `WORKFLOW_TASK_COMPLETED`,`WORKFLOW_TASK_TIMED_OUT`, `WORKFLOW_TASK_FAILED`, or  `WORKFLOW_TASK_STARTED` event to reset to.
  --requestId: string # Used to de-dupe reset requests
  --resetReapplyType: string@resetReapplyType-completer # Deprecated. Use `options`.  Default: RESET_REAPPLY_TYPE_SIGNAL (format: enum)
  --resetReapplyExcludeTypes: list # Event types not to be reapplied
  --postResetOperations: list # Operations to perform after the workflow has been reset. These operations will be applied  to the *new* run of the workflow execution in the order they are provided.  All operations are applied to the workflow before the first new workflow task is generated — item shape: {signalWorkflow?: record, updateWorkflowOptions?: record}
  --identity: string # The identity of the worker/client
]: any -> record<runId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/reset")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, reason: $reason, workflowTaskFinishEventId: $workflowTaskFinishEventId, requestId: $requestId, resetReapplyType: $resetReapplyType, resetReapplyExcludeTypes: $resetReapplyExcludeTypes, postResetOperations: $postResetOperations, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SignalWorkflowExecution is used to send a signal to a running workflow execution.   This results in a `WORKFLOW_EXECUTION_SIGNALED` event recorded in the history and a workflow  task being created for the execution.
#
# POST /namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/signal/{signalName}
# operationId: SignalWorkflowExecution
# --workflowExecution shape: {workflowId?: string, runId?: string}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-signal SignalWorkflowExecution-by-namespace-workflow_execution.workflow_id-signalName-1" [
  namespace: string
  workflow_execution.workflow_id: string
  signalName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --body-signalName: string # The workflow author-defined name of the signal to send to the workflow
  --input: any # Serialized value(s) to provide with the signal
  --identity: string # The identity of the worker/client
  --requestId: string # Used to de-dupe sent signals
  --control: string # Deprecated.
  --header: any # Headers that are passed with the signal to the processing workflow.  These can include things like auth or tracing tokens.
  --links: list # Links to be associated with the WorkflowExecutionSignaled event. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
]: any -> record<link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/signal/($signalName)")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, signalName: $body_signalName, input: $input, identity: $identity, requestId: $requestId, control: $control, header: $header, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# TerminateWorkflowExecution terminates an existing workflow execution by recording a  `WORKFLOW_EXECUTION_TERMINATED` event in the history and immediately terminating the  execution instance.
#
# POST /namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/terminate
# operationId: TerminateWorkflowExecution
# --workflowExecution shape: {workflowId?: string, runId?: string}
# --links item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
export def "namespaces-workflows-terminate TerminateWorkflowExecution-by-namespace-workflow_execution.workflow_id-1" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string
  --workflowExecution: record # Identifies a specific workflow within a namespace. Practically speaking, because run_id is a  uuid, a workflow execution is globally unique. Note that many commands allow specifying an empty  run id as a way of saying "target the latest run of the workflow". — shape: {workflowId?: string, runId?: string}
  --reason: string
  --details: any # Serialized additional information to attach to the termination event
  --identity: string # The identity of the worker/client
  --firstExecutionRunId: string # If set, this call will error if the most recent (if no run id is set on  `workflow_execution`), or specified (if it is) workflow execution is not part of the same  execution chain as this id.
  --links: list # Links to be associated with the WorkflowExecutionTerminated event. — item shape: {workflowEvent?: record, batchJob?: record, activity?: record, nexusOperation?: record, workflow?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/terminate")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, reason: $reason, details: $details, identity: $identity, firstExecutionRunId: $firstExecutionRunId, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# UpdateWorkflowExecutionOptions partially updates the WorkflowExecutionOptions of an existing workflow execution.
#
# POST /namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update-options
# operationId: UpdateWorkflowExecutionOptions
export def "namespaces-workflows-update-options UpdateWorkflowExecutionOptions-by-namespace-workflow_execution.workflow_id-1" [
  namespace: string
  workflow_execution.workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace name of the target Workflow.
  --workflowExecution: any # The target Workflow Id and (optionally) a specific Run Id thereof.  (-- api-linter: core::0203::optional=disabled      aip.dev/not-precedent: false positive triggered by the word "optional" --)
  --workflowExecutionOptions: any # Workflow Execution options. Partial updates are accepted and controlled by update_mask.
  --updateMask: string # Controls which fields from `workflow_execution_options` will be applied.  To unset a field, set it to null and use the update mask to indicate that it should be mutated. (format: field-mask)
  --identity: string # Optional. The identity of the client who initiated this request.
]: any -> record<workflowExecutionOptions: record<versioningOverride: record<pinned: record, autoUpgrade: bool, behavior: string, deployment: record, pinnedVersion: string>, priority: record<priorityKey: int, fairnessKey: string, fairnessWeight: float>, timeSkippingConfig: record<enabled: bool, maxSkippedDuration: string, maxElapsedDuration: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/update-options")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, workflowExecutionOptions: $workflowExecutionOptions, updateMask: $updateMask, identity: $identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invokes the specified Update function on user Workflow code.
#
# POST /namespaces/{namespace}/workflows/{workflow_execution.workflow_id}/update/{request.input.name}
# operationId: UpdateWorkflowExecution
export def "namespaces-workflows-update UpdateWorkflowExecution-by-namespace-workflow_execution.workflow_id-request.input.name-1" [
  namespace: string
  workflow_execution.workflow_id: string
  request.input.name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-namespace: string # The namespace name of the target Workflow.
  --workflowExecution: any # The target Workflow Id and (optionally) a specific Run Id thereof.  (-- api-linter: core::0203::optional=disabled      aip.dev/not-precedent: false positive triggered by the word "optional" --)
  --firstExecutionRunId: string # If set, this call will error if the most recent (if no Run Id is set on  `workflow_execution`), or specified (if it is) Workflow Execution is not  part of the same execution chain as this Id.
  --waitPolicy: any # Specifies client's intent to wait for Update results.  NOTE: This field works together with API call timeout which is limited by  server timeout (maximum wait time). If server timeout is expired before  user specified timeout, API call returns even if specified stage is not reached.  Actual reached stage will be included in the response.
  --request: any # The request information that will be delivered all the way down to the  Workflow Execution.
]: any -> record<updateRef: record<workflowExecution: record<workflowId: string, runId: string>, updateId: string>, outcome: record<success: record<payloads: list>, failure: record<message: string, source: string, stackTrace: string, encodedAttributes: record, cause: any, applicationFailureInfo: record, timeoutFailureInfo: record, canceledFailureInfo: record, terminatedFailureInfo: record, serverFailureInfo: record, resetWorkflowFailureInfo: record, activityFailureInfo: record, childWorkflowExecutionFailureInfo: record, nexusOperationExecutionFailureInfo: record, nexusHandlerFailureInfo: record>>, stage: string, link: record<workflowEvent: record<namespace: string, workflowId: string, runId: string, eventRef: record, requestIdRef: record>, batchJob: record<jobId: string>, activity: record<namespace: string, activityId: string, runId: string>, nexusOperation: record<namespace: string, operationId: string, runId: string>, workflow: record<namespace: string, workflowId: string, runId: string, reason: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/namespaces/($namespace)/workflows/($workflow_execution.workflow_id)/update/($request.input.name)")
  let body = {namespace: $body_namespace, workflowExecution: $workflowExecution, firstExecutionRunId: $firstExecutionRunId, waitPolicy: $waitPolicy, request: $request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GetSystemInfo returns information about the system.
#
# GET /system-info
# operationId: GetSystemInfo
export def "system-info GetSystemInfo-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<serverVersion: string, capabilities: record<signalAndQueryHeader: bool, internalErrorDifferentiation: bool, activityFailureIncludeHeartbeat: bool, supportsSchedules: bool, encodedFailureAttributes: bool, buildIdBasedVersioning: bool, upsertMemo: bool, eagerWorkflowStart: bool, sdkMetadata: bool, countGroupByExecutionStatus: bool, nexus: bool, serverScaledDeployments: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
