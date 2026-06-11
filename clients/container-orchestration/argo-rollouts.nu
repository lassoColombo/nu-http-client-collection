# Auto-generated client for pkg/apiclient/rollout/rollout.proto vversion not set
# Source: https://raw.githubusercontent.com/argoproj/argo-rollouts/master/pkg/apiclient/rollout/rollout.swagger.json
# Auth: --token flag or $env.PKG_APICLIENT_ROLLOUT_ROLLOUT_PROTO_TOKEN

const BASE_URL = "https://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PKG_APICLIENT_ROLLOUT_ROLLOUT_PROTO_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "namespace GetNamespace" } } | get name | first)
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

# GET /api/v1/namespace
#
# operationId: RolloutService_GetNamespace
export def "namespace GetNamespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<namespace: string, availableNamespaces: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/namespace")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/rollouts/{namespace}/info
#
# operationId: RolloutService_ListRolloutInfos
export def "rollouts-info ListRolloutInfos" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rollouts: table<objectMeta: record, status: string, message: string, icon: string, strategy: string, step: string, setWeight: string, actualWeight: string, ready: int, current: int, desired: int, updated: int, available: int, restartedAt: string, generation: string, replicaSets: list, experiments: list, analysisRuns: list, containers: list, steps: list, initContainers: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/rollouts/{namespace}/info/watch
#
# operationId: RolloutService_WatchRolloutInfos
export def "rollouts-info-watch WatchRolloutInfos" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: record<type: string, rolloutInfo: record<objectMeta: record, status: string, message: string, icon: string, strategy: string, step: string, setWeight: string, actualWeight: string, ready: int, current: int, desired: int, updated: int, available: int, restartedAt: string, generation: string, replicaSets: list, experiments: list, analysisRuns: list, containers: list, steps: list, initContainers: list>>, error: record<grpc_code: int, http_code: int, message: string, http_status: string, details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/info/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/rollouts/{namespace}/{name}/abort
#
# operationId: RolloutService_AbortRollout
export def "rollouts-abort AbortRollout" [
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
]: any -> record<metadata: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record<seconds: string, nanos: int>, deletionTimestamp: record<seconds: string, nanos: int>, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list<record>, finalizers: list<string>, managedFields: list<record>>, spec: record<replicas: int, selector: record<matchLabels: record, matchExpressions: list>, template: record<metadata: record, spec: record>, workloadRef: record<apiVersion: string, kind: string, name: string, scaleDown: string>, minReadySeconds: int, rollbackWindow: record<revisions: int>, strategy: record<blueGreen: record, canary: record>, revisionHistoryLimit: int, paused: bool, progressDeadlineSeconds: int, progressDeadlineAbort: bool, restartAt: record<seconds: string, nanos: int>, analysis: record<successfulRunHistoryLimit: int, unsuccessfulRunHistoryLimit: int>>, status: record<abort: bool, pauseConditions: list<record>, controllerPause: bool, abortedAt: record<seconds: string, nanos: int>, currentPodHash: string, currentStepHash: string, replicas: int, updatedReplicas: int, readyReplicas: int, availableReplicas: int, currentStepIndex: int, collisionCount: int, observedGeneration: string, conditions: list<record>, canary: record<currentStepAnalysisRunStatus: record, currentBackgroundAnalysisRunStatus: record, currentExperiment: string, weights: record, stablePingPong: string, stepPluginStatuses: list>, blueGreen: record<previewSelector: string, activeSelector: string, scaleUpPreviewCheckPoint: bool, prePromotionAnalysisRunStatus: record, postPromotionAnalysisRunStatus: record>, HPAReplicas: int, selector: string, stableRS: string, restartedAt: record<seconds: string, nanos: int>, promoteFull: bool, phase: string, message: string, workloadObservedGeneration: string, alb: record<loadBalancer: record, canaryTargetGroup: record, stableTargetGroup: record, ingress: string>, albs: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($name)/abort")
  let body = {name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/rollouts/{namespace}/{name}/info
#
# operationId: RolloutService_GetRolloutInfo
export def "rollouts-info GetRolloutInfo" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<objectMeta: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record<seconds: string, nanos: int>, deletionTimestamp: record<seconds: string, nanos: int>, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list<record>, finalizers: list<string>, managedFields: list<record>>, status: string, message: string, icon: string, strategy: string, step: string, setWeight: string, actualWeight: string, ready: int, current: int, desired: int, updated: int, available: int, restartedAt: string, generation: string, replicaSets: table<objectMeta: record, status: string, icon: string, revision: string, stable: bool, canary: bool, active: bool, preview: bool, replicas: int, available: int, template: string, scaleDownDeadline: string, images: list, pods: list, ping: bool, pong: bool, initContainerImages: list>, experiments: table<objectMeta: record, icon: string, revision: string, status: string, message: string, replicaSets: list, analysisRuns: list>, analysisRuns: table<objectMeta: record, icon: string, revision: string, status: string, successful: int, failed: int, inconclusive: int, error: int, jobs: list, nonJobInfo: list, metrics: list, specAndStatus: record>, containers: table<name: string, image: string>, steps: table<setWeight: int, pause: record, experiment: record, analysis: record, setCanaryScale: record, setHeaderRoute: record, setMirrorRoute: record, plugin: record>, initContainers: table<name: string, image: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($name)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/rollouts/{namespace}/{name}/info/watch
#
# operationId: RolloutService_WatchRolloutInfo
export def "rollouts-info-watch WatchRolloutInfo" [
  namespace: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: record<objectMeta: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record, deletionTimestamp: record, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list, finalizers: list, managedFields: list>, status: string, message: string, icon: string, strategy: string, step: string, setWeight: string, actualWeight: string, ready: int, current: int, desired: int, updated: int, available: int, restartedAt: string, generation: string, replicaSets: list<record>, experiments: list<record>, analysisRuns: list<record>, containers: list<record>, steps: list<record>, initContainers: list<record>>, error: record<grpc_code: int, http_code: int, message: string, http_status: string, details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($name)/info/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/rollouts/{namespace}/{name}/promote
#
# operationId: RolloutService_PromoteRollout
export def "rollouts-promote PromoteRollout" [
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
  --full: string@bool-completer
]: any -> record<metadata: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record<seconds: string, nanos: int>, deletionTimestamp: record<seconds: string, nanos: int>, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list<record>, finalizers: list<string>, managedFields: list<record>>, spec: record<replicas: int, selector: record<matchLabels: record, matchExpressions: list>, template: record<metadata: record, spec: record>, workloadRef: record<apiVersion: string, kind: string, name: string, scaleDown: string>, minReadySeconds: int, rollbackWindow: record<revisions: int>, strategy: record<blueGreen: record, canary: record>, revisionHistoryLimit: int, paused: bool, progressDeadlineSeconds: int, progressDeadlineAbort: bool, restartAt: record<seconds: string, nanos: int>, analysis: record<successfulRunHistoryLimit: int, unsuccessfulRunHistoryLimit: int>>, status: record<abort: bool, pauseConditions: list<record>, controllerPause: bool, abortedAt: record<seconds: string, nanos: int>, currentPodHash: string, currentStepHash: string, replicas: int, updatedReplicas: int, readyReplicas: int, availableReplicas: int, currentStepIndex: int, collisionCount: int, observedGeneration: string, conditions: list<record>, canary: record<currentStepAnalysisRunStatus: record, currentBackgroundAnalysisRunStatus: record, currentExperiment: string, weights: record, stablePingPong: string, stepPluginStatuses: list>, blueGreen: record<previewSelector: string, activeSelector: string, scaleUpPreviewCheckPoint: bool, prePromotionAnalysisRunStatus: record, postPromotionAnalysisRunStatus: record>, HPAReplicas: int, selector: string, stableRS: string, restartedAt: record<seconds: string, nanos: int>, promoteFull: bool, phase: string, message: string, workloadObservedGeneration: string, alb: record<loadBalancer: record, canaryTargetGroup: record, stableTargetGroup: record, ingress: string>, albs: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($name)/promote")
  let body = {name: $body_name, namespace: $body_namespace, full: $full} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/rollouts/{namespace}/{name}/restart
#
# operationId: RolloutService_RestartRollout
export def "rollouts-restart RestartRollout" [
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
]: any -> record<metadata: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record<seconds: string, nanos: int>, deletionTimestamp: record<seconds: string, nanos: int>, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list<record>, finalizers: list<string>, managedFields: list<record>>, spec: record<replicas: int, selector: record<matchLabels: record, matchExpressions: list>, template: record<metadata: record, spec: record>, workloadRef: record<apiVersion: string, kind: string, name: string, scaleDown: string>, minReadySeconds: int, rollbackWindow: record<revisions: int>, strategy: record<blueGreen: record, canary: record>, revisionHistoryLimit: int, paused: bool, progressDeadlineSeconds: int, progressDeadlineAbort: bool, restartAt: record<seconds: string, nanos: int>, analysis: record<successfulRunHistoryLimit: int, unsuccessfulRunHistoryLimit: int>>, status: record<abort: bool, pauseConditions: list<record>, controllerPause: bool, abortedAt: record<seconds: string, nanos: int>, currentPodHash: string, currentStepHash: string, replicas: int, updatedReplicas: int, readyReplicas: int, availableReplicas: int, currentStepIndex: int, collisionCount: int, observedGeneration: string, conditions: list<record>, canary: record<currentStepAnalysisRunStatus: record, currentBackgroundAnalysisRunStatus: record, currentExperiment: string, weights: record, stablePingPong: string, stepPluginStatuses: list>, blueGreen: record<previewSelector: string, activeSelector: string, scaleUpPreviewCheckPoint: bool, prePromotionAnalysisRunStatus: record, postPromotionAnalysisRunStatus: record>, HPAReplicas: int, selector: string, stableRS: string, restartedAt: record<seconds: string, nanos: int>, promoteFull: bool, phase: string, message: string, workloadObservedGeneration: string, alb: record<loadBalancer: record, canaryTargetGroup: record, stableTargetGroup: record, ingress: string>, albs: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($name)/restart")
  let body = {name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/rollouts/{namespace}/{name}/retry
#
# operationId: RolloutService_RetryRollout
export def "rollouts-retry RetryRollout" [
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
]: any -> record<metadata: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record<seconds: string, nanos: int>, deletionTimestamp: record<seconds: string, nanos: int>, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list<record>, finalizers: list<string>, managedFields: list<record>>, spec: record<replicas: int, selector: record<matchLabels: record, matchExpressions: list>, template: record<metadata: record, spec: record>, workloadRef: record<apiVersion: string, kind: string, name: string, scaleDown: string>, minReadySeconds: int, rollbackWindow: record<revisions: int>, strategy: record<blueGreen: record, canary: record>, revisionHistoryLimit: int, paused: bool, progressDeadlineSeconds: int, progressDeadlineAbort: bool, restartAt: record<seconds: string, nanos: int>, analysis: record<successfulRunHistoryLimit: int, unsuccessfulRunHistoryLimit: int>>, status: record<abort: bool, pauseConditions: list<record>, controllerPause: bool, abortedAt: record<seconds: string, nanos: int>, currentPodHash: string, currentStepHash: string, replicas: int, updatedReplicas: int, readyReplicas: int, availableReplicas: int, currentStepIndex: int, collisionCount: int, observedGeneration: string, conditions: list<record>, canary: record<currentStepAnalysisRunStatus: record, currentBackgroundAnalysisRunStatus: record, currentExperiment: string, weights: record, stablePingPong: string, stepPluginStatuses: list>, blueGreen: record<previewSelector: string, activeSelector: string, scaleUpPreviewCheckPoint: bool, prePromotionAnalysisRunStatus: record, postPromotionAnalysisRunStatus: record>, HPAReplicas: int, selector: string, stableRS: string, restartedAt: record<seconds: string, nanos: int>, promoteFull: bool, phase: string, message: string, workloadObservedGeneration: string, alb: record<loadBalancer: record, canaryTargetGroup: record, stableTargetGroup: record, ingress: string>, albs: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($name)/retry")
  let body = {name: $body_name, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/rollouts/{namespace}/{rollout}/set/{container}/{image}/{tag}
#
# operationId: RolloutService_SetRolloutImage
export def "rollouts-set SetRolloutImage" [
  namespace: string
  rollout: string
  container: string
  image: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-rollout: string
  --body-container: string
  --body-image: string
  --body-tag: string
  --body-namespace: string
]: any -> record<metadata: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record<seconds: string, nanos: int>, deletionTimestamp: record<seconds: string, nanos: int>, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list<record>, finalizers: list<string>, managedFields: list<record>>, spec: record<replicas: int, selector: record<matchLabels: record, matchExpressions: list>, template: record<metadata: record, spec: record>, workloadRef: record<apiVersion: string, kind: string, name: string, scaleDown: string>, minReadySeconds: int, rollbackWindow: record<revisions: int>, strategy: record<blueGreen: record, canary: record>, revisionHistoryLimit: int, paused: bool, progressDeadlineSeconds: int, progressDeadlineAbort: bool, restartAt: record<seconds: string, nanos: int>, analysis: record<successfulRunHistoryLimit: int, unsuccessfulRunHistoryLimit: int>>, status: record<abort: bool, pauseConditions: list<record>, controllerPause: bool, abortedAt: record<seconds: string, nanos: int>, currentPodHash: string, currentStepHash: string, replicas: int, updatedReplicas: int, readyReplicas: int, availableReplicas: int, currentStepIndex: int, collisionCount: int, observedGeneration: string, conditions: list<record>, canary: record<currentStepAnalysisRunStatus: record, currentBackgroundAnalysisRunStatus: record, currentExperiment: string, weights: record, stablePingPong: string, stepPluginStatuses: list>, blueGreen: record<previewSelector: string, activeSelector: string, scaleUpPreviewCheckPoint: bool, prePromotionAnalysisRunStatus: record, postPromotionAnalysisRunStatus: record>, HPAReplicas: int, selector: string, stableRS: string, restartedAt: record<seconds: string, nanos: int>, promoteFull: bool, phase: string, message: string, workloadObservedGeneration: string, alb: record<loadBalancer: record, canaryTargetGroup: record, stableTargetGroup: record, ingress: string>, albs: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($rollout)/set/($container)/($image)/($tag)")
  let body = {rollout: $body_rollout, container: $body_container, image: $body_image, tag: $body_tag, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/rollouts/{namespace}/{rollout}/undo/{revision}
#
# operationId: RolloutService_UndoRollout
export def "rollouts-undo UndoRollout" [
  namespace: string
  rollout: string
  revision: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-rollout: string
  --body-revision: string # format: int64
  --body-namespace: string
]: any -> record<metadata: record<name: string, generateName: string, namespace: string, selfLink: string, uid: string, resourceVersion: string, generation: string, creationTimestamp: record<seconds: string, nanos: int>, deletionTimestamp: record<seconds: string, nanos: int>, deletionGracePeriodSeconds: string, labels: record, annotations: record, ownerReferences: list<record>, finalizers: list<string>, managedFields: list<record>>, spec: record<replicas: int, selector: record<matchLabels: record, matchExpressions: list>, template: record<metadata: record, spec: record>, workloadRef: record<apiVersion: string, kind: string, name: string, scaleDown: string>, minReadySeconds: int, rollbackWindow: record<revisions: int>, strategy: record<blueGreen: record, canary: record>, revisionHistoryLimit: int, paused: bool, progressDeadlineSeconds: int, progressDeadlineAbort: bool, restartAt: record<seconds: string, nanos: int>, analysis: record<successfulRunHistoryLimit: int, unsuccessfulRunHistoryLimit: int>>, status: record<abort: bool, pauseConditions: list<record>, controllerPause: bool, abortedAt: record<seconds: string, nanos: int>, currentPodHash: string, currentStepHash: string, replicas: int, updatedReplicas: int, readyReplicas: int, availableReplicas: int, currentStepIndex: int, collisionCount: int, observedGeneration: string, conditions: list<record>, canary: record<currentStepAnalysisRunStatus: record, currentBackgroundAnalysisRunStatus: record, currentExperiment: string, weights: record, stablePingPong: string, stepPluginStatuses: list>, blueGreen: record<previewSelector: string, activeSelector: string, scaleUpPreviewCheckPoint: bool, prePromotionAnalysisRunStatus: record, postPromotionAnalysisRunStatus: record>, HPAReplicas: int, selector: string, stableRS: string, restartedAt: record<seconds: string, nanos: int>, promoteFull: bool, phase: string, message: string, workloadObservedGeneration: string, alb: record<loadBalancer: record, canaryTargetGroup: record, stableTargetGroup: record, ingress: string>, albs: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/rollouts/($namespace)/($rollout)/undo/($revision)")
  let body = {rollout: $body_rollout, revision: $body_revision, namespace: $body_namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/version
#
# operationId: RolloutService_Version
export def "version Version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rolloutsVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
