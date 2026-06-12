# Auto-generated client for Argo Workflows API vVERSION
# Source: https://raw.githubusercontent.com/argoproj/argo-workflows/main/api/openapi-spec/swagger.json
# Auth: --token flag or $env.ARGO_WORKFLOWS_API_TOKEN

const BASE_URL = "http://localhost:2746"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ARGO_WORKFLOWS_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost:2746" "https://localhost:2746"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["CONFIGMAP" "DATABASE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "archived-workflows ListArchivedWorkflows" } } | get name | first)
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

# GET /api/v1/archived-workflows
#
# operationId: ArchivedWorkflowService_ListArchivedWorkflows
export def "archived-workflows ListArchivedWorkflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
  --namePrefix: string
  --namespace: string
  --nameFilter: string # Filter type used for name filtering. Exact | Contains | Prefix. Default to Exact.
]: nothing -> record<apiVersion: string, items: table<apiVersion: string, kind: string, metadata: record, spec: record, status: record>, kind: string, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "nameFilter" $nameFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/archived-workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/archived-workflows-label-keys
#
# operationId: ArchivedWorkflowService_ListArchivedWorkflowLabelKeys
export def "archived-workflows-label-keys ListArchivedWorkflowLabelKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/archived-workflows-label-keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/archived-workflows-label-values
#
# operationId: ArchivedWorkflowService_ListArchivedWorkflowLabelValues
export def "archived-workflows-label-values ListArchivedWorkflowLabelValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
  --namespace: string
]: nothing -> record<items: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar") (serialize-qp "namespace" $namespace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/archived-workflows-label-values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/archived-workflows/{uid}
#
# operationId: ArchivedWorkflowService_GetArchivedWorkflow
export def "archived-workflows GetArchivedWorkflow" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string
  --name: string
]: nothing -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/archived-workflows/($uid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/archived-workflows/{uid}
#
# operationId: ArchivedWorkflowService_DeleteArchivedWorkflow
export def "archived-workflows DeleteArchivedWorkflow" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namespace: string
  --name: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namespace" $namespace "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/archived-workflows/($uid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/archived-workflows/{uid}/resubmit
#
# operationId: ArchivedWorkflowService_ResubmitArchivedWorkflow
export def "archived-workflows-resubmit ResubmitArchivedWorkflow" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --memoized: oneof<nothing, bool>
  --name: string
  --namespace: string
  --parameters: list
  --body-uid: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/archived-workflows/($uid)/resubmit")
  let body = {memoized: $memoized, name: $name, namespace: $namespace, parameters: $parameters, uid: $body_uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/archived-workflows/{uid}/retry
#
# operationId: ArchivedWorkflowService_RetryArchivedWorkflow
export def "archived-workflows-retry RetryArchivedWorkflow" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --namespace: string
  --nodeFieldSelector: string
  --parameters: list
  --restartSuccessful: oneof<nothing, bool>
  --body-uid: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/archived-workflows/($uid)/retry")
  let body = {name: $name, namespace: $namespace, nodeFieldSelector: $nodeFieldSelector, parameters: $parameters, restartSuccessful: $restartSuccessful, uid: $body_uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/cluster-workflow-templates
#
# operationId: ClusterWorkflowTemplateService_ListClusterWorkflowTemplates
export def "cluster-workflow-templates ListClusterWorkflowTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<apiVersion: string, items: table<apiVersion: string, kind: string, metadata: record, spec: record>, kind: string, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/cluster-workflow-templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/cluster-workflow-templates
#
# operationId: ClusterWorkflowTemplateService_CreateClusterWorkflowTemplate
# --createOptions shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
# --template shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
export def "cluster-workflow-templates CreateClusterWorkflowTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOptions: record # CreateOptions may be provided when creating an API object. — shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
  --template: record # ClusterWorkflowTemplate is the definition of a workflow template resource in cluster scope — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/cluster-workflow-templates")
  let body = {createOptions: $createOptions, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/cluster-workflow-templates/lint
#
# operationId: ClusterWorkflowTemplateService_LintClusterWorkflowTemplate
# --createOptions shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
# --template shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
export def "cluster-workflow-templates-lint LintClusterWorkflowTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOptions: record # CreateOptions may be provided when creating an API object. — shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
  --template: record # ClusterWorkflowTemplate is the definition of a workflow template resource in cluster scope — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/cluster-workflow-templates/lint")
  let body = {createOptions: $createOptions, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/cluster-workflow-templates/{name}
#
# operationId: ClusterWorkflowTemplateService_GetClusterWorkflowTemplate
export def "cluster-workflow-templates GetClusterWorkflowTemplate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --getOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
]: nothing -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getOptions.resourceVersion" $getOptionsresourceVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/cluster-workflow-templates/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/cluster-workflow-templates/{name}
#
# operationId: ClusterWorkflowTemplateService_UpdateClusterWorkflowTemplate
# --template shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
export def "cluster-workflow-templates UpdateClusterWorkflowTemplate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string # DEPRECATED: This field is ignored.
  --template: record # ClusterWorkflowTemplate is the definition of a workflow template resource in cluster scope — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cluster-workflow-templates/($name)")
  let body = {name: $body_name, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/cluster-workflow-templates/{name}
#
# operationId: ClusterWorkflowTemplateService_DeleteClusterWorkflowTemplate
export def "cluster-workflow-templates DeleteClusterWorkflowTemplate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteOptionsgracePeriodSeconds: string # The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately. +optional. (format: int64)
  --deleteOptionspreconditionsuid: string # Specifies the target UID. +optional.
  --deleteOptionspreconditionsresourceVersion: string # Specifies the target ResourceVersion +optional.
  --deleteOptionsorphanDependents: oneof<nothing, bool> # Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the "orphan" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both. +optional.
  --deleteOptionspropagationPolicy: string # Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground. +optional.
  --deleteOptionsdryRun: list # When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed +optional +listType=atomic.
  --deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential: oneof<nothing, bool> # if set to true, it will trigger an unsafe deletion of the resource in case the normal deletion flow fails with a corrupt object error. A resource is considered corrupt if it can not be retrieved from the underlying storage successfully because of a) its data can not be transformed e.g. decryption failure, or b) it fails to decode into an object. NOTE: unsafe deletion ignores finalizer constraints, skips precondition checks, and removes the object from the storage. WARNING: This may potentially break the cluster if the workload associated with the resource being unsafe-deleted relies on normal deletion flow. Use only if you REALLY know what you are doing. The default value is false, and the user must opt in to enable it +optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOptions.gracePeriodSeconds" $deleteOptionsgracePeriodSeconds "scalar") (serialize-qp "deleteOptions.preconditions.uid" $deleteOptionspreconditionsuid "scalar") (serialize-qp "deleteOptions.preconditions.resourceVersion" $deleteOptionspreconditionsresourceVersion "scalar") (serialize-qp "deleteOptions.orphanDependents" $deleteOptionsorphanDependents "scalar") (serialize-qp "deleteOptions.propagationPolicy" $deleteOptionspropagationPolicy "scalar") (serialize-qp "deleteOptions.dryRun" $deleteOptionsdryRun "multi") (serialize-qp "deleteOptions.ignoreStoreReadErrorWithClusterBreakingPotential" $deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/cluster-workflow-templates/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/cron-workflows/{namespace}
#
# operationId: CronWorkflowService_ListCronWorkflows
export def "cron-workflows ListCronWorkflows" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<apiVersion: string, items: table<apiVersion: string, kind: string, metadata: record, spec: record, status: record>, kind: string, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/cron-workflows/{namespace}
#
# operationId: CronWorkflowService_CreateCronWorkflow
# --createOptions shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
# --cronWorkflow shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
export def "cron-workflows CreateCronWorkflow" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOptions: record # CreateOptions may be provided when creating an API object. — shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
  --cronWorkflow: record # CronWorkflow is the definition of a scheduled workflow resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
  --body-namespace: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<concurrencyPolicy: string, failedJobsHistoryLimit: int, schedules: list<string>, startingDeadlineSeconds: int, stopStrategy: record<expression: string>, successfulJobsHistoryLimit: int, suspend: bool, timezone: string, when: string, workflowMetadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, workflowSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>>, status: record<active: list<record>, conditions: list<record>, failed: int, lastScheduledTime: string, phase: string, succeeded: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)")
  let body = {createOptions: $createOptions, cronWorkflow: $cronWorkflow, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/cron-workflows/{namespace}/lint
#
# operationId: CronWorkflowService_LintCronWorkflow
# --cronWorkflow shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
export def "cron-workflows-lint LintCronWorkflow" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cronWorkflow: record # CronWorkflow is the definition of a scheduled workflow resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
  --body-namespace: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<concurrencyPolicy: string, failedJobsHistoryLimit: int, schedules: list<string>, startingDeadlineSeconds: int, stopStrategy: record<expression: string>, successfulJobsHistoryLimit: int, suspend: bool, timezone: string, when: string, workflowMetadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, workflowSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>>, status: record<active: list<record>, conditions: list<record>, failed: int, lastScheduledTime: string, phase: string, succeeded: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)/lint")
  let body = {cronWorkflow: $cronWorkflow, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/cron-workflows/{namespace}/{name}
#
# operationId: CronWorkflowService_GetCronWorkflow
export def "cron-workflows GetCronWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --getOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
]: nothing -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<concurrencyPolicy: string, failedJobsHistoryLimit: int, schedules: list<string>, startingDeadlineSeconds: int, stopStrategy: record<expression: string>, successfulJobsHistoryLimit: int, suspend: bool, timezone: string, when: string, workflowMetadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, workflowSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>>, status: record<active: list<record>, conditions: list<record>, failed: int, lastScheduledTime: string, phase: string, succeeded: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getOptions.resourceVersion" $getOptionsresourceVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/cron-workflows/{namespace}/{name}
#
# operationId: CronWorkflowService_UpdateCronWorkflow
# --cronWorkflow shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
export def "cron-workflows UpdateCronWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cronWorkflow: record # CronWorkflow is the definition of a scheduled workflow resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
  --body-name: string # DEPRECATED: This field is ignored.
  --body-namespace: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<concurrencyPolicy: string, failedJobsHistoryLimit: int, schedules: list<string>, startingDeadlineSeconds: int, stopStrategy: record<expression: string>, successfulJobsHistoryLimit: int, suspend: bool, timezone: string, when: string, workflowMetadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, workflowSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>>, status: record<active: list<record>, conditions: list<record>, failed: int, lastScheduledTime: string, phase: string, succeeded: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)/($name)")
  let body = {cronWorkflow: $cronWorkflow, name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/cron-workflows/{namespace}/{name}
#
# operationId: CronWorkflowService_DeleteCronWorkflow
export def "cron-workflows DeleteCronWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteOptionsgracePeriodSeconds: string # The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately. +optional. (format: int64)
  --deleteOptionspreconditionsuid: string # Specifies the target UID. +optional.
  --deleteOptionspreconditionsresourceVersion: string # Specifies the target ResourceVersion +optional.
  --deleteOptionsorphanDependents: oneof<nothing, bool> # Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the "orphan" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both. +optional.
  --deleteOptionspropagationPolicy: string # Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground. +optional.
  --deleteOptionsdryRun: list # When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed +optional +listType=atomic.
  --deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential: oneof<nothing, bool> # if set to true, it will trigger an unsafe deletion of the resource in case the normal deletion flow fails with a corrupt object error. A resource is considered corrupt if it can not be retrieved from the underlying storage successfully because of a) its data can not be transformed e.g. decryption failure, or b) it fails to decode into an object. NOTE: unsafe deletion ignores finalizer constraints, skips precondition checks, and removes the object from the storage. WARNING: This may potentially break the cluster if the workload associated with the resource being unsafe-deleted relies on normal deletion flow. Use only if you REALLY know what you are doing. The default value is false, and the user must opt in to enable it +optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOptions.gracePeriodSeconds" $deleteOptionsgracePeriodSeconds "scalar") (serialize-qp "deleteOptions.preconditions.uid" $deleteOptionspreconditionsuid "scalar") (serialize-qp "deleteOptions.preconditions.resourceVersion" $deleteOptionspreconditionsresourceVersion "scalar") (serialize-qp "deleteOptions.orphanDependents" $deleteOptionsorphanDependents "scalar") (serialize-qp "deleteOptions.propagationPolicy" $deleteOptionspropagationPolicy "scalar") (serialize-qp "deleteOptions.dryRun" $deleteOptionsdryRun "multi") (serialize-qp "deleteOptions.ignoreStoreReadErrorWithClusterBreakingPotential" $deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/cron-workflows/{namespace}/{name}/resume
#
# operationId: CronWorkflowService_ResumeCronWorkflow
export def "cron-workflows-resume ResumeCronWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string
  --body-namespace: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<concurrencyPolicy: string, failedJobsHistoryLimit: int, schedules: list<string>, startingDeadlineSeconds: int, stopStrategy: record<expression: string>, successfulJobsHistoryLimit: int, suspend: bool, timezone: string, when: string, workflowMetadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, workflowSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>>, status: record<active: list<record>, conditions: list<record>, failed: int, lastScheduledTime: string, phase: string, succeeded: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)/($name)/resume")
  let body = {name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/cron-workflows/{namespace}/{name}/suspend
#
# operationId: CronWorkflowService_SuspendCronWorkflow
export def "cron-workflows-suspend SuspendCronWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string
  --body-namespace: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<concurrencyPolicy: string, failedJobsHistoryLimit: int, schedules: list<string>, startingDeadlineSeconds: int, stopStrategy: record<expression: string>, successfulJobsHistoryLimit: int, suspend: bool, timezone: string, when: string, workflowMetadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, workflowSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>>, status: record<active: list<record>, conditions: list<record>, failed: int, lastScheduledTime: string, phase: string, succeeded: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cron-workflows/($namespace)/($name)/suspend")
  let body = {name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/event-sources/{namespace}
#
# operationId: EventSourceService_ListEventSources
export def "event-sources ListEventSources" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<items: table<metadata: record, spec: record, status: record>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/event-sources/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/event-sources/{namespace}
#
# operationId: EventSourceService_CreateEventSource
# --eventSource shape: {metadata?: record, spec?: record, status?: record}
export def "event-sources CreateEventSource" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventSource: record # shape: {metadata?: record, spec?: record, status?: record}
  --body-namespace: string
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<amqp: record, azureEventsHub: record, azureQueueStorage: record, azureServiceBus: record, bitbucket: record, bitbucketserver: record, calendar: record, emitter: record, eventBusName: string, file: record, generic: record, gerrit: record, github: record, gitlab: record, hdfs: record, kafka: record, minio: record, mns: record, mqtt: record, nats: record, nsq: record, pubSub: record, pulsar: record, redis: record, redisStream: record, replicas: int, resource: record, service: record<clusterIP: string, metadata: record, ports: list>, sftp: record, slack: record, sns: record, sqs: record, storageGrid: record, stripe: record, template: record<affinity: record, container: record, imagePullSecrets: list, metadata: record, nodeSelector: record, priority: int, priorityClassName: string, securityContext: record, serviceAccountName: string, tolerations: list, volumes: list>, webhook: record>, status: record<status: record<conditions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-sources/($namespace)")
  let body = {eventSource: $eventSource, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/event-sources/{namespace}/{name}
#
# operationId: EventSourceService_GetEventSource
export def "event-sources GetEventSource" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<amqp: record, azureEventsHub: record, azureQueueStorage: record, azureServiceBus: record, bitbucket: record, bitbucketserver: record, calendar: record, emitter: record, eventBusName: string, file: record, generic: record, gerrit: record, github: record, gitlab: record, hdfs: record, kafka: record, minio: record, mns: record, mqtt: record, nats: record, nsq: record, pubSub: record, pulsar: record, redis: record, redisStream: record, replicas: int, resource: record, service: record<clusterIP: string, metadata: record, ports: list>, sftp: record, slack: record, sns: record, sqs: record, storageGrid: record, stripe: record, template: record<affinity: record, container: record, imagePullSecrets: list, metadata: record, nodeSelector: record, priority: int, priorityClassName: string, securityContext: record, serviceAccountName: string, tolerations: list, volumes: list>, webhook: record>, status: record<status: record<conditions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-sources/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/event-sources/{namespace}/{name}
#
# operationId: EventSourceService_UpdateEventSource
# --eventSource shape: {metadata?: record, spec?: record, status?: record}
export def "event-sources UpdateEventSource" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventSource: record # shape: {metadata?: record, spec?: record, status?: record}
  --body-name: string
  --body-namespace: string
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<amqp: record, azureEventsHub: record, azureQueueStorage: record, azureServiceBus: record, bitbucket: record, bitbucketserver: record, calendar: record, emitter: record, eventBusName: string, file: record, generic: record, gerrit: record, github: record, gitlab: record, hdfs: record, kafka: record, minio: record, mns: record, mqtt: record, nats: record, nsq: record, pubSub: record, pulsar: record, redis: record, redisStream: record, replicas: int, resource: record, service: record<clusterIP: string, metadata: record, ports: list>, sftp: record, slack: record, sns: record, sqs: record, storageGrid: record, stripe: record, template: record<affinity: record, container: record, imagePullSecrets: list, metadata: record, nodeSelector: record, priority: int, priorityClassName: string, securityContext: record, serviceAccountName: string, tolerations: list, volumes: list>, webhook: record>, status: record<status: record<conditions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/event-sources/($namespace)/($name)")
  let body = {eventSource: $eventSource, name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/event-sources/{namespace}/{name}
#
# operationId: EventSourceService_DeleteEventSource
export def "event-sources DeleteEventSource" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteOptionsgracePeriodSeconds: string # The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately. +optional. (format: int64)
  --deleteOptionspreconditionsuid: string # Specifies the target UID. +optional.
  --deleteOptionspreconditionsresourceVersion: string # Specifies the target ResourceVersion +optional.
  --deleteOptionsorphanDependents: oneof<nothing, bool> # Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the "orphan" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both. +optional.
  --deleteOptionspropagationPolicy: string # Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground. +optional.
  --deleteOptionsdryRun: list # When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed +optional +listType=atomic.
  --deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential: oneof<nothing, bool> # if set to true, it will trigger an unsafe deletion of the resource in case the normal deletion flow fails with a corrupt object error. A resource is considered corrupt if it can not be retrieved from the underlying storage successfully because of a) its data can not be transformed e.g. decryption failure, or b) it fails to decode into an object. NOTE: unsafe deletion ignores finalizer constraints, skips precondition checks, and removes the object from the storage. WARNING: This may potentially break the cluster if the workload associated with the resource being unsafe-deleted relies on normal deletion flow. Use only if you REALLY know what you are doing. The default value is false, and the user must opt in to enable it +optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOptions.gracePeriodSeconds" $deleteOptionsgracePeriodSeconds "scalar") (serialize-qp "deleteOptions.preconditions.uid" $deleteOptionspreconditionsuid "scalar") (serialize-qp "deleteOptions.preconditions.resourceVersion" $deleteOptionspreconditionsresourceVersion "scalar") (serialize-qp "deleteOptions.orphanDependents" $deleteOptionsorphanDependents "scalar") (serialize-qp "deleteOptions.propagationPolicy" $deleteOptionspropagationPolicy "scalar") (serialize-qp "deleteOptions.dryRun" $deleteOptionsdryRun "multi") (serialize-qp "deleteOptions.ignoreStoreReadErrorWithClusterBreakingPotential" $deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/event-sources/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/events/{namespace}/{discriminator}
#
# operationId: EventService_ReceiveEvent
export def "events ReceiveEvent" [
  namespace: string
  discriminator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/events/($namespace)/($discriminator)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/info
#
# operationId: InfoService_GetInfo
export def "info GetInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<columns: table<key: string, name: string, type: string>, links: table<name: string, scope: string, target: string, url: string>, managedNamespace: string, modals: record, navColor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/sensors/{namespace}
#
# operationId: SensorService_ListSensors
export def "sensors ListSensors" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<items: table<metadata: record, spec: record, status: record>, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sensors/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/sensors/{namespace}
#
# operationId: SensorService_CreateSensor
# --createOptions shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
# --sensor shape: {metadata?: record, spec?: record, status?: record}
export def "sensors CreateSensor" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOptions: record # CreateOptions may be provided when creating an API object. — shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
  --body-namespace: string
  --sensor: record # shape: {metadata?: record, spec?: record, status?: record}
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<dependencies: list<record>, errorOnFailedRound: bool, eventBusName: string, loggingFields: record, replicas: int, revisionHistoryLimit: int, template: record<affinity: record, container: record, imagePullSecrets: list, metadata: record, nodeSelector: record, priority: int, priorityClassName: string, securityContext: record, serviceAccountName: string, tolerations: list, volumes: list>, triggers: list<record>>, status: record<status: record<conditions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sensors/($namespace)")
  let body = {createOptions: $createOptions, namespace: $body_namespace, sensor: $sensor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/sensors/{namespace}/{name}
#
# operationId: SensorService_GetSensor
export def "sensors GetSensor" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --getOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
]: nothing -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<dependencies: list<record>, errorOnFailedRound: bool, eventBusName: string, loggingFields: record, replicas: int, revisionHistoryLimit: int, template: record<affinity: record, container: record, imagePullSecrets: list, metadata: record, nodeSelector: record, priority: int, priorityClassName: string, securityContext: record, serviceAccountName: string, tolerations: list, volumes: list>, triggers: list<record>>, status: record<status: record<conditions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getOptions.resourceVersion" $getOptionsresourceVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sensors/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/sensors/{namespace}/{name}
#
# operationId: SensorService_UpdateSensor
# --sensor shape: {metadata?: record, spec?: record, status?: record}
export def "sensors UpdateSensor" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string
  --body-namespace: string
  --sensor: record # shape: {metadata?: record, spec?: record, status?: record}
]: any -> record<metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<dependencies: list<record>, errorOnFailedRound: bool, eventBusName: string, loggingFields: record, replicas: int, revisionHistoryLimit: int, template: record<affinity: record, container: record, imagePullSecrets: list, metadata: record, nodeSelector: record, priority: int, priorityClassName: string, securityContext: record, serviceAccountName: string, tolerations: list, volumes: list>, triggers: list<record>>, status: record<status: record<conditions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sensors/($namespace)/($name)")
  let body = {name: $body_name, namespace: $body_namespace, sensor: $sensor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/sensors/{namespace}/{name}
#
# operationId: SensorService_DeleteSensor
export def "sensors DeleteSensor" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteOptionsgracePeriodSeconds: string # The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately. +optional. (format: int64)
  --deleteOptionspreconditionsuid: string # Specifies the target UID. +optional.
  --deleteOptionspreconditionsresourceVersion: string # Specifies the target ResourceVersion +optional.
  --deleteOptionsorphanDependents: oneof<nothing, bool> # Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the "orphan" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both. +optional.
  --deleteOptionspropagationPolicy: string # Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground. +optional.
  --deleteOptionsdryRun: list # When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed +optional +listType=atomic.
  --deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential: oneof<nothing, bool> # if set to true, it will trigger an unsafe deletion of the resource in case the normal deletion flow fails with a corrupt object error. A resource is considered corrupt if it can not be retrieved from the underlying storage successfully because of a) its data can not be transformed e.g. decryption failure, or b) it fails to decode into an object. NOTE: unsafe deletion ignores finalizer constraints, skips precondition checks, and removes the object from the storage. WARNING: This may potentially break the cluster if the workload associated with the resource being unsafe-deleted relies on normal deletion flow. Use only if you REALLY know what you are doing. The default value is false, and the user must opt in to enable it +optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOptions.gracePeriodSeconds" $deleteOptionsgracePeriodSeconds "scalar") (serialize-qp "deleteOptions.preconditions.uid" $deleteOptionspreconditionsuid "scalar") (serialize-qp "deleteOptions.preconditions.resourceVersion" $deleteOptionspreconditionsresourceVersion "scalar") (serialize-qp "deleteOptions.orphanDependents" $deleteOptionsorphanDependents "scalar") (serialize-qp "deleteOptions.propagationPolicy" $deleteOptionspropagationPolicy "scalar") (serialize-qp "deleteOptions.dryRun" $deleteOptionsdryRun "multi") (serialize-qp "deleteOptions.ignoreStoreReadErrorWithClusterBreakingPotential" $deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sensors/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/stream/event-sources/{namespace}
#
# operationId: EventSourceService_WatchEventSources
export def "stream-event-sources WatchEventSources" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<object: record<metadata: record, spec: record, status: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/event-sources/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/stream/event-sources/{namespace}/logs
#
# operationId: EventSourceService_EventSourcesLogs
export def "stream-event-sources-logs EventSourcesLogs" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # optional - only return entries for this event source.
  --eventSourceType: string # optional - only return entries for this event source type (e.g. `webhook`).
  --eventName: string # optional - only return entries for this event name (e.g. `example`).
  --grep: string # optional - only return entries where `msg` matches this regular expression.
  --podLogOptionscontainer: string # The container for which to stream logs. Defaults to only container if there is one container in the pod. +optional.
  --podLogOptionsfollow: oneof<nothing, bool> # Follow the log stream of the pod. Defaults to false. +optional.
  --podLogOptionsprevious: oneof<nothing, bool> # Return previous terminated container logs. Defaults to false. +optional.
  --podLogOptionssinceSeconds: string # A relative time in seconds before the current time from which to show logs. If this value precedes the time a pod was started, only logs since the pod start will be returned. If this value is in the future, no logs will be returned. Only one of sinceSeconds or sinceTime may be specified. +optional. (format: int64)
  --podLogOptionssinceTimeseconds: string # Represents seconds of UTC time since Unix epoch 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z inclusive. (format: int64)
  --podLogOptionssinceTimenanos: int # Non-negative fractions of a second at nanosecond resolution. Negative second values with fractions must still have non-negative nanos values that count forward in time. Must be from 0 to 999,999,999 inclusive. This field may be limited in precision depending on context. (format: int32)
  --podLogOptionstimestamps: oneof<nothing, bool> # If true, add an RFC3339 or RFC3339Nano timestamp at the beginning of every line of log output. Defaults to false. +optional.
  --podLogOptionstailLines: string # If set, the number of lines from the end of the logs to show. If not specified, logs are shown from the creation of the container or sinceSeconds or sinceTime. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +optional. (format: int64)
  --podLogOptionslimitBytes: string # If set, the number of bytes to read from the server before terminating the log output. This may not display a complete final line of logging, and may return slightly more or slightly less than the specified limit. +optional. (format: int64)
  --podLogOptionsinsecureSkipTLSVerifyBackend: oneof<nothing, bool> # insecureSkipTLSVerifyBackend indicates that the apiserver should not confirm the validity of the serving certificate of the backend it is connecting to.  This will make the HTTPS connection between the apiserver and the backend insecure. This means the apiserver cannot verify the log data it is receiving came from the real kubelet.  If the kubelet is configured to verify the apiserver's TLS credentials, it does not mean the connection to the real kubelet is vulnerable to a man in the middle attack (e.g. an attacker could not intercept the actual log data coming from the real kubelet). +optional.
  --podLogOptionsstream: string # Specify which container log stream to return to the client. Acceptable values are "All", "Stdout" and "Stderr". If not specified, "All" is used, and both stdout and stderr are returned interleaved. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +featureGate=PodLogsQuerySplitStreams +optional.
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<eventName: string, eventSourceName: string, eventSourceType: string, level: string, msg: string, namespace: string, time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "eventSourceType" $eventSourceType "scalar") (serialize-qp "eventName" $eventName "scalar") (serialize-qp "grep" $grep "scalar") (serialize-qp "podLogOptions.container" $podLogOptionscontainer "scalar") (serialize-qp "podLogOptions.follow" $podLogOptionsfollow "scalar") (serialize-qp "podLogOptions.previous" $podLogOptionsprevious "scalar") (serialize-qp "podLogOptions.sinceSeconds" $podLogOptionssinceSeconds "scalar") (serialize-qp "podLogOptions.sinceTime.seconds" $podLogOptionssinceTimeseconds "scalar") (serialize-qp "podLogOptions.sinceTime.nanos" $podLogOptionssinceTimenanos "scalar") (serialize-qp "podLogOptions.timestamps" $podLogOptionstimestamps "scalar") (serialize-qp "podLogOptions.tailLines" $podLogOptionstailLines "scalar") (serialize-qp "podLogOptions.limitBytes" $podLogOptionslimitBytes "scalar") (serialize-qp "podLogOptions.insecureSkipTLSVerifyBackend" $podLogOptionsinsecureSkipTLSVerifyBackend "scalar") (serialize-qp "podLogOptions.stream" $podLogOptionsstream "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/event-sources/($namespace)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/stream/events/{namespace}
#
# operationId: WorkflowService_WatchEvents
export def "stream-events WatchEvents" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<action: string, apiVersion: string, count: int, eventTime: string, firstTimestamp: string, involvedObject: record<apiVersion: string, fieldPath: string, kind: string, name: string, namespace: string, resourceVersion: string, uid: string>, kind: string, lastTimestamp: string, message: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list, generateName: string, generation: int, labels: record, managedFields: list, name: string, namespace: string, ownerReferences: list, resourceVersion: string, selfLink: string, uid: string>, reason: string, related: record<apiVersion: string, fieldPath: string, kind: string, name: string, namespace: string, resourceVersion: string, uid: string>, reportingComponent: string, reportingInstance: string, series: record<count: int, lastObservedTime: string>, source: record<component: string, host: string>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/events/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/stream/sensors/{namespace}
#
# operationId: SensorService_WatchSensors
export def "stream-sensors WatchSensors" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<object: record<metadata: record, spec: record, status: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/sensors/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/stream/sensors/{namespace}/logs
#
# operationId: SensorService_SensorsLogs
export def "stream-sensors-logs SensorsLogs" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # optional - only return entries for this sensor name.
  --triggerName: string # optional - only return entries for this trigger.
  --grep: string # option - only return entries where `msg` contains this regular expressions.
  --podLogOptionscontainer: string # The container for which to stream logs. Defaults to only container if there is one container in the pod. +optional.
  --podLogOptionsfollow: oneof<nothing, bool> # Follow the log stream of the pod. Defaults to false. +optional.
  --podLogOptionsprevious: oneof<nothing, bool> # Return previous terminated container logs. Defaults to false. +optional.
  --podLogOptionssinceSeconds: string # A relative time in seconds before the current time from which to show logs. If this value precedes the time a pod was started, only logs since the pod start will be returned. If this value is in the future, no logs will be returned. Only one of sinceSeconds or sinceTime may be specified. +optional. (format: int64)
  --podLogOptionssinceTimeseconds: string # Represents seconds of UTC time since Unix epoch 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z inclusive. (format: int64)
  --podLogOptionssinceTimenanos: int # Non-negative fractions of a second at nanosecond resolution. Negative second values with fractions must still have non-negative nanos values that count forward in time. Must be from 0 to 999,999,999 inclusive. This field may be limited in precision depending on context. (format: int32)
  --podLogOptionstimestamps: oneof<nothing, bool> # If true, add an RFC3339 or RFC3339Nano timestamp at the beginning of every line of log output. Defaults to false. +optional.
  --podLogOptionstailLines: string # If set, the number of lines from the end of the logs to show. If not specified, logs are shown from the creation of the container or sinceSeconds or sinceTime. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +optional. (format: int64)
  --podLogOptionslimitBytes: string # If set, the number of bytes to read from the server before terminating the log output. This may not display a complete final line of logging, and may return slightly more or slightly less than the specified limit. +optional. (format: int64)
  --podLogOptionsinsecureSkipTLSVerifyBackend: oneof<nothing, bool> # insecureSkipTLSVerifyBackend indicates that the apiserver should not confirm the validity of the serving certificate of the backend it is connecting to.  This will make the HTTPS connection between the apiserver and the backend insecure. This means the apiserver cannot verify the log data it is receiving came from the real kubelet.  If the kubelet is configured to verify the apiserver's TLS credentials, it does not mean the connection to the real kubelet is vulnerable to a man in the middle attack (e.g. an attacker could not intercept the actual log data coming from the real kubelet). +optional.
  --podLogOptionsstream: string # Specify which container log stream to return to the client. Acceptable values are "All", "Stdout" and "Stderr". If not specified, "All" is used, and both stdout and stderr are returned interleaved. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +featureGate=PodLogsQuerySplitStreams +optional.
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<dependencyName: string, eventContext: string, level: string, msg: string, namespace: string, sensorName: string, time: string, triggerName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "triggerName" $triggerName "scalar") (serialize-qp "grep" $grep "scalar") (serialize-qp "podLogOptions.container" $podLogOptionscontainer "scalar") (serialize-qp "podLogOptions.follow" $podLogOptionsfollow "scalar") (serialize-qp "podLogOptions.previous" $podLogOptionsprevious "scalar") (serialize-qp "podLogOptions.sinceSeconds" $podLogOptionssinceSeconds "scalar") (serialize-qp "podLogOptions.sinceTime.seconds" $podLogOptionssinceTimeseconds "scalar") (serialize-qp "podLogOptions.sinceTime.nanos" $podLogOptionssinceTimenanos "scalar") (serialize-qp "podLogOptions.timestamps" $podLogOptionstimestamps "scalar") (serialize-qp "podLogOptions.tailLines" $podLogOptionstailLines "scalar") (serialize-qp "podLogOptions.limitBytes" $podLogOptionslimitBytes "scalar") (serialize-qp "podLogOptions.insecureSkipTLSVerifyBackend" $podLogOptionsinsecureSkipTLSVerifyBackend "scalar") (serialize-qp "podLogOptions.stream" $podLogOptionsstream "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/stream/sensors/($namespace)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/sync/{namespace}
#
# operationId: SyncService_CreateSyncLimit
export def "sync CreateSyncLimit" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cmName: string
  --key: string
  --limit: int
  --body-namespace: string
  --type: string@type-completer # default: CONFIGMAP
]: any -> record<cmName: string, key: string, limit: int, namespace: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sync/($namespace)")
  let body = {cmName: $cmName, key: $key, limit: $limit, namespace: $body_namespace, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/sync/{namespace}/{key}
#
# operationId: SyncService_GetSyncLimit
export def "sync GetSyncLimit" [
  namespace: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # default: CONFIGMAP
  --cmName: string
]: nothing -> record<cmName: string, key: string, limit: int, namespace: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "cmName" $cmName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sync/($namespace)/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/sync/{namespace}/{key}
#
# operationId: SyncService_UpdateSyncLimit
export def "sync UpdateSyncLimit" [
  namespace: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cmName: string
  --body-key: string
  --limit: int
  --body-namespace: string
  --type: string@type-completer # default: CONFIGMAP
]: any -> record<cmName: string, key: string, limit: int, namespace: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sync/($namespace)/($key)")
  let body = {cmName: $cmName, key: $body_key, limit: $limit, namespace: $body_namespace, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/sync/{namespace}/{key}
#
# operationId: SyncService_DeleteSyncLimit
export def "sync DeleteSyncLimit" [
  namespace: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # default: CONFIGMAP
  --cmName: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "cmName" $cmName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sync/($namespace)/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/tracking/event
#
# operationId: InfoService_CollectEvent
export def "tracking-event CollectEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tracking/event")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/userinfo
#
# operationId: InfoService_GetUserInfo
export def "userinfo GetUserInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, emailVerified: bool, groups: list<string>, issuer: string, name: string, serviceAccountName: string, serviceAccountNamespace: string, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/version
#
# operationId: InfoService_GetVersion
export def "version GetVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<buildDate: string, compiler: string, gitCommit: string, gitTag: string, gitTreeState: string, goVersion: string, platform: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/workflow-event-bindings/{namespace}
#
# operationId: EventService_ListWorkflowEventBindings
export def "workflow-event-bindings ListWorkflowEventBindings" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<apiVersion: string, items: table<apiVersion: string, kind: string, metadata: record, spec: record>, kind: string, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflow-event-bindings/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/workflow-events/{namespace}
#
# operationId: WorkflowService_WatchWorkflows
export def "workflow-events WatchWorkflows" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
  --qp-fields: string
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<object: record<apiVersion: string, kind: string, metadata: record, spec: record, status: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflow-events/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/workflow-templates/{namespace}
#
# operationId: WorkflowTemplateService_ListWorkflowTemplates
export def "workflow-templates ListWorkflowTemplates" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namePattern: string
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
]: nothing -> record<apiVersion: string, items: table<apiVersion: string, kind: string, metadata: record, spec: record>, kind: string, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namePattern" $namePattern "scalar") (serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflow-templates/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/workflow-templates/{namespace}
#
# operationId: WorkflowTemplateService_CreateWorkflowTemplate
# --createOptions shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
# --template shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
export def "workflow-templates CreateWorkflowTemplate" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOptions: record # CreateOptions may be provided when creating an API object. — shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
  --body-namespace: string
  --template: record # WorkflowTemplate is the definition of a workflow template resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflow-templates/($namespace)")
  let body = {createOptions: $createOptions, namespace: $body_namespace, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/workflow-templates/{namespace}/lint
#
# operationId: WorkflowTemplateService_LintWorkflowTemplate
# --createOptions shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
# --template shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
export def "workflow-templates-lint LintWorkflowTemplate" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOptions: record # CreateOptions may be provided when creating an API object. — shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
  --body-namespace: string
  --template: record # WorkflowTemplate is the definition of a workflow template resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflow-templates/($namespace)/lint")
  let body = {createOptions: $createOptions, namespace: $body_namespace, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/workflow-templates/{namespace}/{name}
#
# operationId: WorkflowTemplateService_GetWorkflowTemplate
export def "workflow-templates GetWorkflowTemplate" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --getOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
]: nothing -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getOptions.resourceVersion" $getOptionsresourceVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflow-templates/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/workflow-templates/{namespace}/{name}
#
# operationId: WorkflowTemplateService_UpdateWorkflowTemplate
# --template shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
export def "workflow-templates UpdateWorkflowTemplate" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string # DEPRECATED: This field is ignored.
  --body-namespace: string
  --template: record # WorkflowTemplate is the definition of a workflow template resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflow-templates/($namespace)/($name)")
  let body = {name: $body_name, namespace: $body_namespace, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/workflow-templates/{namespace}/{name}
#
# operationId: WorkflowTemplateService_DeleteWorkflowTemplate
export def "workflow-templates DeleteWorkflowTemplate" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteOptionsgracePeriodSeconds: string # The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately. +optional. (format: int64)
  --deleteOptionspreconditionsuid: string # Specifies the target UID. +optional.
  --deleteOptionspreconditionsresourceVersion: string # Specifies the target ResourceVersion +optional.
  --deleteOptionsorphanDependents: oneof<nothing, bool> # Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the "orphan" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both. +optional.
  --deleteOptionspropagationPolicy: string # Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground. +optional.
  --deleteOptionsdryRun: list # When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed +optional +listType=atomic.
  --deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential: oneof<nothing, bool> # if set to true, it will trigger an unsafe deletion of the resource in case the normal deletion flow fails with a corrupt object error. A resource is considered corrupt if it can not be retrieved from the underlying storage successfully because of a) its data can not be transformed e.g. decryption failure, or b) it fails to decode into an object. NOTE: unsafe deletion ignores finalizer constraints, skips precondition checks, and removes the object from the storage. WARNING: This may potentially break the cluster if the workload associated with the resource being unsafe-deleted relies on normal deletion flow. Use only if you REALLY know what you are doing. The default value is false, and the user must opt in to enable it +optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOptions.gracePeriodSeconds" $deleteOptionsgracePeriodSeconds "scalar") (serialize-qp "deleteOptions.preconditions.uid" $deleteOptionspreconditionsuid "scalar") (serialize-qp "deleteOptions.preconditions.resourceVersion" $deleteOptionspreconditionsresourceVersion "scalar") (serialize-qp "deleteOptions.orphanDependents" $deleteOptionsorphanDependents "scalar") (serialize-qp "deleteOptions.propagationPolicy" $deleteOptionspropagationPolicy "scalar") (serialize-qp "deleteOptions.dryRun" $deleteOptionsdryRun "multi") (serialize-qp "deleteOptions.ignoreStoreReadErrorWithClusterBreakingPotential" $deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflow-templates/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/workflows/{namespace}
#
# operationId: WorkflowService_ListWorkflows
export def "workflows ListWorkflows" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listOptionslabelSelector: string # A selector to restrict the list of returned objects by their labels. Defaults to everything. +optional.
  --listOptionsfieldSelector: string # A selector to restrict the list of returned objects by their fields. Defaults to everything. +optional.
  --listOptionswatch: oneof<nothing, bool> # Watch for changes to the described resources and return them as a stream of add, update, and remove notifications. Specify resourceVersion. +optional.
  --listOptionsallowWatchBookmarks: oneof<nothing, bool> # allowWatchBookmarks requests watch events with type "BOOKMARK". Servers that do not implement bookmarks may ignore this flag and bookmarks are sent at the server's discretion. Clients should not assume bookmarks are returned at any specific interval, nor may they assume the server will send any BOOKMARK event during a session. If this is not a watch, this field is ignored. +optional.
  --listOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionsresourceVersionMatch: string # resourceVersionMatch determines how resourceVersion is applied to list calls. It is highly recommended that resourceVersionMatch be set for list calls where resourceVersion is set See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --listOptionstimeoutSeconds: string # Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. +optional. (format: int64)
  --listOptionslimit: string # limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (format: int64)
  --listOptionscontinue: string # The continue option should be set when retrieving more results from the server. Since this value is server defined, clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the client needs a consistent list, it must restart their list without the continue field. Otherwise, the client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the "next key".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications.
  --listOptionssendInitialEvents: oneof<nothing, bool> # `sendInitialEvents=true` may be set together with `watch=true`. In that case, the watch stream will begin with synthetic events to produce the current state of objects in the collection. Once all such events have been sent, a synthetic "Bookmark" event  will be sent. The bookmark will report the ResourceVersion (RV) corresponding to the set of objects, and be marked with `"io.k8s.initial-events-end": "true"` annotation. Afterwards, the watch stream will proceed as usual, sending watch events corresponding to changes (subsequent to the RV) to objects watched.  When `sendInitialEvents` option is set, we require `resourceVersionMatch` option to also be set. The semantic of the watch request is as following: - `resourceVersionMatch` = NotOlderThan   is interpreted as "data at least as new as the provided `resourceVersion`"   and the bookmark event is send when the state is synced   to a `resourceVersion` at least as fresh as the one provided by the ListOptions.   If `resourceVersion` is unset, this is interpreted as "consistent read" and the   bookmark event is send when the state is synced at least to the moment   when request started being processed. - `resourceVersionMatch` set to any other value or unset   Invalid error is returned.  Defaults to true if `resourceVersion=""` or `resourceVersion="0"` (for backward compatibility reasons) and to false otherwise. +optional
  --qp-fields: string # Fields to be included or excluded in the response. e.g. "items.spec,items.status.phase", "-items.status.nodes".
  --nameFilter: string # Filter type used for name filtering. Exact | Contains | Prefix. Default to Exact.
  --createdAfter: string
  --finishedBefore: string
]: nothing -> record<apiVersion: string, items: table<apiVersion: string, kind: string, metadata: record, spec: record, status: record>, kind: string, metadata: record<continue: string, remainingItemCount: int, resourceVersion: string, selfLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listOptions.labelSelector" $listOptionslabelSelector "scalar") (serialize-qp "listOptions.fieldSelector" $listOptionsfieldSelector "scalar") (serialize-qp "listOptions.watch" $listOptionswatch "scalar") (serialize-qp "listOptions.allowWatchBookmarks" $listOptionsallowWatchBookmarks "scalar") (serialize-qp "listOptions.resourceVersion" $listOptionsresourceVersion "scalar") (serialize-qp "listOptions.resourceVersionMatch" $listOptionsresourceVersionMatch "scalar") (serialize-qp "listOptions.timeoutSeconds" $listOptionstimeoutSeconds "scalar") (serialize-qp "listOptions.limit" $listOptionslimit "scalar") (serialize-qp "listOptions.continue" $listOptionscontinue "scalar") (serialize-qp "listOptions.sendInitialEvents" $listOptionssendInitialEvents "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "nameFilter" $nameFilter "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "finishedBefore" $finishedBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/workflows/{namespace}
#
# operationId: WorkflowService_CreateWorkflow
# --createOptions shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
# --workflow shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
export def "workflows CreateWorkflow" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createOptions: record # CreateOptions may be provided when creating an API object. — shape: {dryRun?: list, fieldManager?: string, fieldValidation?: string}
  --instanceID: string # This field is no longer used.
  --body-namespace: string
  --serverDryRun: oneof<nothing, bool>
  --workflow: record # Workflow is the definition of a workflow resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)")
  let body = {createOptions: $createOptions, instanceID: $instanceID, namespace: $body_namespace, serverDryRun: $serverDryRun, workflow: $workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/workflows/{namespace}/lint
#
# operationId: WorkflowService_LintWorkflow
# --workflow shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
export def "workflows-lint LintWorkflow" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-namespace: string
  --workflow: record # Workflow is the definition of a workflow resource — shape: {apiVersion?: string, kind?: string, metadata: record, spec: record, status?: record}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/lint")
  let body = {namespace: $body_namespace, workflow: $workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/workflows/{namespace}/submit
#
# operationId: WorkflowService_SubmitWorkflow
# --submitOptions shape: {annotations?: string, dryRun?: bool, entryPoint?: string, generateName?: string, labels?: string, name?: string, ownerReference?: record, parameters?: list, podPriorityClassName?: string, priority?: int, serverDryRun?: bool, serviceAccount?: string}
export def "workflows-submit SubmitWorkflow" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-namespace: string
  --resourceKind: string
  --resourceName: string
  --submitOptions: record # SubmitOpts are workflow submission options — shape: {annotations?: string, dryRun?: bool, entryPoint?: string, generateName?: string, labels?: string, name?: string, ownerReference?: record, parameters?: list, podPriorityClassName?: string, priority?: int, serverDryRun?: bool, serviceAccount?: string}
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/submit")
  let body = {namespace: $body_namespace, resourceKind: $resourceKind, resourceName: $resourceName, submitOptions: $submitOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/workflows/{namespace}/{name}
#
# operationId: WorkflowService_GetWorkflow
export def "workflows GetWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --getOptionsresourceVersion: string # resourceVersion sets a constraint on what resource versions a request may be served from. See https://kubernetes.io/docs/reference/using-api/api-concepts/#resource-versions for details.  Defaults to unset +optional
  --qp-fields: string # Fields to be included or excluded in the response. e.g. "spec,status.phase", "-status.nodes".
  --uid: string # Optional UID to retrieve a specific workflow (useful for archived workflows with the same name).
]: nothing -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getOptions.resourceVersion" $getOptionsresourceVersion "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uid" $uid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/workflows/{namespace}/{name}
#
# operationId: WorkflowService_DeleteWorkflow
export def "workflows DeleteWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteOptionsgracePeriodSeconds: string # The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately. +optional. (format: int64)
  --deleteOptionspreconditionsuid: string # Specifies the target UID. +optional.
  --deleteOptionspreconditionsresourceVersion: string # Specifies the target ResourceVersion +optional.
  --deleteOptionsorphanDependents: oneof<nothing, bool> # Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the "orphan" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both. +optional.
  --deleteOptionspropagationPolicy: string # Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground. +optional.
  --deleteOptionsdryRun: list # When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed +optional +listType=atomic.
  --deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential: oneof<nothing, bool> # if set to true, it will trigger an unsafe deletion of the resource in case the normal deletion flow fails with a corrupt object error. A resource is considered corrupt if it can not be retrieved from the underlying storage successfully because of a) its data can not be transformed e.g. decryption failure, or b) it fails to decode into an object. NOTE: unsafe deletion ignores finalizer constraints, skips precondition checks, and removes the object from the storage. WARNING: This may potentially break the cluster if the workload associated with the resource being unsafe-deleted relies on normal deletion flow. Use only if you REALLY know what you are doing. The default value is false, and the user must opt in to enable it +optional.
  --force: oneof<nothing, bool>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteOptions.gracePeriodSeconds" $deleteOptionsgracePeriodSeconds "scalar") (serialize-qp "deleteOptions.preconditions.uid" $deleteOptionspreconditionsuid "scalar") (serialize-qp "deleteOptions.preconditions.resourceVersion" $deleteOptionspreconditionsresourceVersion "scalar") (serialize-qp "deleteOptions.orphanDependents" $deleteOptionsorphanDependents "scalar") (serialize-qp "deleteOptions.propagationPolicy" $deleteOptionspropagationPolicy "scalar") (serialize-qp "deleteOptions.dryRun" $deleteOptionsdryRun "multi") (serialize-qp "deleteOptions.ignoreStoreReadErrorWithClusterBreakingPotential" $deleteOptionsignoreStoreReadErrorWithClusterBreakingPotential "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/workflows/{namespace}/{name}/log
#
# operationId: WorkflowService_WorkflowLogs
export def "workflows-log WorkflowLogs" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --podName: string
  --logOptionscontainer: string # The container for which to stream logs. Defaults to only container if there is one container in the pod. +optional.
  --logOptionsfollow: oneof<nothing, bool> # Follow the log stream of the pod. Defaults to false. +optional.
  --logOptionsprevious: oneof<nothing, bool> # Return previous terminated container logs. Defaults to false. +optional.
  --logOptionssinceSeconds: string # A relative time in seconds before the current time from which to show logs. If this value precedes the time a pod was started, only logs since the pod start will be returned. If this value is in the future, no logs will be returned. Only one of sinceSeconds or sinceTime may be specified. +optional. (format: int64)
  --logOptionssinceTimeseconds: string # Represents seconds of UTC time since Unix epoch 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z inclusive. (format: int64)
  --logOptionssinceTimenanos: int # Non-negative fractions of a second at nanosecond resolution. Negative second values with fractions must still have non-negative nanos values that count forward in time. Must be from 0 to 999,999,999 inclusive. This field may be limited in precision depending on context. (format: int32)
  --logOptionstimestamps: oneof<nothing, bool> # If true, add an RFC3339 or RFC3339Nano timestamp at the beginning of every line of log output. Defaults to false. +optional.
  --logOptionstailLines: string # If set, the number of lines from the end of the logs to show. If not specified, logs are shown from the creation of the container or sinceSeconds or sinceTime. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +optional. (format: int64)
  --logOptionslimitBytes: string # If set, the number of bytes to read from the server before terminating the log output. This may not display a complete final line of logging, and may return slightly more or slightly less than the specified limit. +optional. (format: int64)
  --logOptionsinsecureSkipTLSVerifyBackend: oneof<nothing, bool> # insecureSkipTLSVerifyBackend indicates that the apiserver should not confirm the validity of the serving certificate of the backend it is connecting to.  This will make the HTTPS connection between the apiserver and the backend insecure. This means the apiserver cannot verify the log data it is receiving came from the real kubelet.  If the kubelet is configured to verify the apiserver's TLS credentials, it does not mean the connection to the real kubelet is vulnerable to a man in the middle attack (e.g. an attacker could not intercept the actual log data coming from the real kubelet). +optional.
  --logOptionsstream: string # Specify which container log stream to return to the client. Acceptable values are "All", "Stdout" and "Stderr". If not specified, "All" is used, and both stdout and stderr are returned interleaved. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +featureGate=PodLogsQuerySplitStreams +optional.
  --grep: string
  --selector: string
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<content: string, podName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "podName" $podName "scalar") (serialize-qp "logOptions.container" $logOptionscontainer "scalar") (serialize-qp "logOptions.follow" $logOptionsfollow "scalar") (serialize-qp "logOptions.previous" $logOptionsprevious "scalar") (serialize-qp "logOptions.sinceSeconds" $logOptionssinceSeconds "scalar") (serialize-qp "logOptions.sinceTime.seconds" $logOptionssinceTimeseconds "scalar") (serialize-qp "logOptions.sinceTime.nanos" $logOptionssinceTimenanos "scalar") (serialize-qp "logOptions.timestamps" $logOptionstimestamps "scalar") (serialize-qp "logOptions.tailLines" $logOptionstailLines "scalar") (serialize-qp "logOptions.limitBytes" $logOptionslimitBytes "scalar") (serialize-qp "logOptions.insecureSkipTLSVerifyBackend" $logOptionsinsecureSkipTLSVerifyBackend "scalar") (serialize-qp "logOptions.stream" $logOptionsstream "scalar") (serialize-qp "grep" $grep "scalar") (serialize-qp "selector" $selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/workflows/{namespace}/{name}/resubmit
#
# operationId: WorkflowService_ResubmitWorkflow
export def "workflows-resubmit ResubmitWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --memoized: oneof<nothing, bool>
  --body-name: string
  --body-namespace: string
  --parameters: list
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/resubmit")
  let body = {memoized: $memoized, name: $body_name, namespace: $body_namespace, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/workflows/{namespace}/{name}/resume
#
# operationId: WorkflowService_ResumeWorkflow
export def "workflows-resume ResumeWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string
  --body-namespace: string
  --nodeFieldSelector: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/resume")
  let body = {name: $body_name, namespace: $body_namespace, nodeFieldSelector: $nodeFieldSelector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/workflows/{namespace}/{name}/retry
#
# operationId: WorkflowService_RetryWorkflow
export def "workflows-retry RetryWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string
  --body-namespace: string
  --nodeFieldSelector: string
  --parameters: list
  --restartSuccessful: oneof<nothing, bool>
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/retry")
  let body = {name: $body_name, namespace: $body_namespace, nodeFieldSelector: $nodeFieldSelector, parameters: $parameters, restartSuccessful: $restartSuccessful} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/workflows/{namespace}/{name}/set
#
# operationId: WorkflowService_SetWorkflow
export def "workflows-set SetWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
  --body-name: string
  --body-namespace: string
  --nodeFieldSelector: string
  --outputParameters: string
  --phase: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/set")
  let body = {message: $message, name: $body_name, namespace: $body_namespace, nodeFieldSelector: $nodeFieldSelector, outputParameters: $outputParameters, phase: $phase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/workflows/{namespace}/{name}/stop
#
# operationId: WorkflowService_StopWorkflow
export def "workflows-stop StopWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
  --body-name: string
  --body-namespace: string
  --nodeFieldSelector: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/stop")
  let body = {message: $message, name: $body_name, namespace: $body_namespace, nodeFieldSelector: $nodeFieldSelector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/workflows/{namespace}/{name}/suspend
#
# operationId: WorkflowService_SuspendWorkflow
export def "workflows-suspend SuspendWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string
  --body-namespace: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/suspend")
  let body = {name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/workflows/{namespace}/{name}/terminate
#
# operationId: WorkflowService_TerminateWorkflow
export def "workflows-terminate TerminateWorkflow" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-name: string
  --body-namespace: string
]: any -> record<apiVersion: string, kind: string, metadata: record<annotations: record, creationTimestamp: string, deletionGracePeriodSeconds: int, deletionTimestamp: string, finalizers: list<string>, generateName: string, generation: int, labels: record, managedFields: list<record>, name: string, namespace: string, ownerReferences: list<record>, resourceVersion: string, selfLink: string, uid: string>, spec: record<activeDeadlineSeconds: int, affinity: record<nodeAffinity: record, podAffinity: record, podAntiAffinity: record>, archiveLogs: bool, arguments: record<artifacts: list, parameters: list>, artifactGC: record<forceFinalizerRemoval: bool, podMetadata: record, podSpecPatch: string, serviceAccountName: string, strategy: string>, artifactRepositoryRef: record<configMap: string, key: string>, automountServiceAccountToken: bool, dnsConfig: record<nameservers: list, options: list, searches: list>, dnsPolicy: string, entrypoint: string, executor: record<serviceAccountName: string>, hooks: record, hostAliases: list<record>, hostNetwork: bool, imagePullSecrets: list<record>, metrics: record<prometheus: list>, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record<maxUnavailable: string, minAvailable: string, selector: record, unhealthyPodEvictionPolicy: string>, podGC: record<deleteDelayDuration: string, labelSelector: record, strategy: string>, podMetadata: record<annotations: record, labels: record>, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record<affinity: record, backoff: record, expression: string, limit: string, retryPolicy: string>, schedulerName: string, securityContext: record<appArmorProfile: record, fsGroup: int, fsGroupChangePolicy: string, runAsGroup: int, runAsNonRoot: bool, runAsUser: int, seLinuxChangePolicy: string, seLinuxOptions: record, seccompProfile: record, supplementalGroups: list, supplementalGroupsPolicy: string, sysctls: list, windowsOptions: record>, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record<mutexes: list, semaphores: list>, templateDefaults: record<activeDeadlineSeconds: string, affinity: record, annotations: record, archiveLocation: record, automountServiceAccountToken: bool, container: record, containerSet: record, daemon: bool, dag: record, data: record, executor: record, failFast: bool, hostAliases: list, http: record, initContainers: list, inputs: record, memoize: record, metadata: record, metrics: record, name: string, nodeSelector: record, outputs: record, parallelism: int, plugin: record, podSpecPatch: string, priorityClassName: string, resource: record, retryStrategy: record, schedulerName: string, script: record, securityContext: record, serviceAccountName: string, sidecars: list, steps: list, suspend: record, synchronization: record, timeout: string, tolerations: list, volumes: list>, templates: list<record>, tolerations: list<record>, ttlStrategy: record<secondsAfterCompletion: int, secondsAfterFailure: int, secondsAfterSuccess: int>, volumeClaimGC: record<strategy: string>, volumeClaimTemplates: list<record>, volumes: list<record>, workflowMetadata: record<annotations: record, labels: record, labelsFrom: record>, workflowTemplateRef: record<clusterScope: bool, name: string>>, status: record<artifactGCStatus: record<notSpecified: bool, podsRecouped: record, strategiesProcessed: record>, artifactRepositoryRef: record<artifactRepository: record, configMap: string, default: bool, key: string, namespace: string>, compressedNodes: string, conditions: list<record>, estimatedDuration: int, finishedAt: string, message: string, nodes: record, offloadNodeStatusVersion: string, outputs: record<artifacts: list, exitCode: string, parameters: list, result: string>, persistentVolumeClaims: list<record>, phase: string, progress: string, resourcesDuration: record, startedAt: string, storedTemplates: record, storedWorkflowTemplateSpec: record<activeDeadlineSeconds: int, affinity: record, archiveLogs: bool, arguments: record, artifactGC: record, artifactRepositoryRef: record, automountServiceAccountToken: bool, dnsConfig: record, dnsPolicy: string, entrypoint: string, executor: record, hooks: record, hostAliases: list, hostNetwork: bool, imagePullSecrets: list, metrics: record, nodeSelector: record, onExit: string, parallelism: int, podDisruptionBudget: record, podGC: record, podMetadata: record, podPriorityClassName: string, podSpecPatch: string, priority: int, retryStrategy: record, schedulerName: string, securityContext: record, serviceAccountName: string, shutdown: string, suspend: bool, synchronization: record, templateDefaults: record, templates: list, tolerations: list, ttlStrategy: record, volumeClaimGC: record, volumeClaimTemplates: list, volumes: list, workflowMetadata: record, workflowTemplateRef: record>, synchronization: record<mutex: record, semaphore: record>, taskResultsCompletionStatus: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/terminate")
  let body = {name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DEPRECATED: Cannot work via HTTP if podName is an empty string. Use WorkflowLogs.
#
# GET /api/v1/workflows/{namespace}/{name}/{podName}/log
# operationId: WorkflowService_PodLogs
export def "workflows-log PodLogs" [
  namespace: string
  name: string
  podName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logOptionscontainer: string # The container for which to stream logs. Defaults to only container if there is one container in the pod. +optional.
  --logOptionsfollow: oneof<nothing, bool> # Follow the log stream of the pod. Defaults to false. +optional.
  --logOptionsprevious: oneof<nothing, bool> # Return previous terminated container logs. Defaults to false. +optional.
  --logOptionssinceSeconds: string # A relative time in seconds before the current time from which to show logs. If this value precedes the time a pod was started, only logs since the pod start will be returned. If this value is in the future, no logs will be returned. Only one of sinceSeconds or sinceTime may be specified. +optional. (format: int64)
  --logOptionssinceTimeseconds: string # Represents seconds of UTC time since Unix epoch 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z inclusive. (format: int64)
  --logOptionssinceTimenanos: int # Non-negative fractions of a second at nanosecond resolution. Negative second values with fractions must still have non-negative nanos values that count forward in time. Must be from 0 to 999,999,999 inclusive. This field may be limited in precision depending on context. (format: int32)
  --logOptionstimestamps: oneof<nothing, bool> # If true, add an RFC3339 or RFC3339Nano timestamp at the beginning of every line of log output. Defaults to false. +optional.
  --logOptionstailLines: string # If set, the number of lines from the end of the logs to show. If not specified, logs are shown from the creation of the container or sinceSeconds or sinceTime. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +optional. (format: int64)
  --logOptionslimitBytes: string # If set, the number of bytes to read from the server before terminating the log output. This may not display a complete final line of logging, and may return slightly more or slightly less than the specified limit. +optional. (format: int64)
  --logOptionsinsecureSkipTLSVerifyBackend: oneof<nothing, bool> # insecureSkipTLSVerifyBackend indicates that the apiserver should not confirm the validity of the serving certificate of the backend it is connecting to.  This will make the HTTPS connection between the apiserver and the backend insecure. This means the apiserver cannot verify the log data it is receiving came from the real kubelet.  If the kubelet is configured to verify the apiserver's TLS credentials, it does not mean the connection to the real kubelet is vulnerable to a man in the middle attack (e.g. an attacker could not intercept the actual log data coming from the real kubelet). +optional.
  --logOptionsstream: string # Specify which container log stream to return to the client. Acceptable values are "All", "Stdout" and "Stderr". If not specified, "All" is used, and both stdout and stderr are returned interleaved. Note that when "TailLines" is specified, "Stream" can only be set to nil or "All". +featureGate=PodLogsQuerySplitStreams +optional.
  --grep: string
  --selector: string
]: nothing -> record<error: record<details: list<record>, grpc_code: int, http_code: int, http_status: string, message: string>, result: record<content: string, podName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logOptions.container" $logOptionscontainer "scalar") (serialize-qp "logOptions.follow" $logOptionsfollow "scalar") (serialize-qp "logOptions.previous" $logOptionsprevious "scalar") (serialize-qp "logOptions.sinceSeconds" $logOptionssinceSeconds "scalar") (serialize-qp "logOptions.sinceTime.seconds" $logOptionssinceTimeseconds "scalar") (serialize-qp "logOptions.sinceTime.nanos" $logOptionssinceTimenanos "scalar") (serialize-qp "logOptions.timestamps" $logOptionstimestamps "scalar") (serialize-qp "logOptions.tailLines" $logOptionstailLines "scalar") (serialize-qp "logOptions.limitBytes" $logOptionslimitBytes "scalar") (serialize-qp "logOptions.insecureSkipTLSVerifyBackend" $logOptionsinsecureSkipTLSVerifyBackend "scalar") (serialize-qp "logOptions.stream" $logOptionsstream "scalar") (serialize-qp "grep" $grep "scalar") (serialize-qp "selector" $selector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/workflows/($namespace)/($name)/($podName)/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an artifact.
#
# GET /artifact-files/{namespace}/{idDiscriminator}/{id}/{nodeId}/{artifactDiscriminator}/{artifactName}
# operationId: ArtifactService_GetArtifactFile
export def "artifact-files GetArtifactFile" [
  namespace: string
  idDiscriminator: string
  id: string
  nodeId: string
  artifactName: string
  artifactDiscriminator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifact-files/($namespace)/($idDiscriminator)/($id)/($nodeId)/($artifactDiscriminator)/($artifactName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an output artifact by UID.
#
# GET /artifacts-by-uid/{uid}/{nodeId}/{artifactName}
# operationId: ArtifactService_GetOutputArtifactByUID
export def "artifacts-by-uid GetOutputArtifactByUID" [
  uid: string
  nodeId: string
  artifactName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifacts-by-uid/($uid)/($nodeId)/($artifactName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an output artifact.
#
# GET /artifacts/{namespace}/{name}/{nodeId}/{artifactName}
# operationId: ArtifactService_GetOutputArtifact
export def "artifacts GetOutputArtifact" [
  namespace: string
  name: string
  nodeId: string
  artifactName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/artifacts/($namespace)/($name)/($nodeId)/($artifactName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an input artifact by UID.
#
# GET /input-artifacts-by-uid/{uid}/{nodeId}/{artifactName}
# operationId: ArtifactService_GetInputArtifactByUID
export def "input-artifacts-by-uid GetInputArtifactByUID" [
  uid: string
  nodeId: string
  artifactName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/input-artifacts-by-uid/($uid)/($nodeId)/($artifactName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an input artifact.
#
# GET /input-artifacts/{namespace}/{name}/{nodeId}/{artifactName}
# operationId: ArtifactService_GetInputArtifact
export def "input-artifacts GetInputArtifact" [
  namespace: string
  name: string
  nodeId: string
  artifactName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/input-artifacts/($namespace)/($name)/($nodeId)/($artifactName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
