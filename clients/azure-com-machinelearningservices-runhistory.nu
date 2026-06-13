# Auto-generated client for Run History APIs v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-runHistory/2019-09-30/swagger.json
# Auth: --token flag or $env.RUN_HISTORY_APIS_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RUN_HISTORY_APIS_TOKEN | default "" }
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def MergeStrategyType-completer [] { ["Default" "MergeToVector" "None"] }
def MergeStrategyOptions-completer [] { ["None" "ReportUnmergedMetricsValues"] }
def MergeStrategySettingsSelectMetrics-completer [] { ["SelectAll" "SelectByFirstValueSchema" "SelectByFirstValueSchemaMergeNumericValues"] }
def sortorder-completer [] { ["Asc" "Desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experimentids GetById" } } | get name | first)
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

# Get details of an Experiment.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}
# operationId: Experiments_GetById
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experimentids GetById" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experimentids/($experimentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update details of an Experiment.
#
# PATCH /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}
# operationId: Experiments_Update
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experimentids Update" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archive: oneof<nothing, bool>
  --description: string
  --tags: record
]: any -> record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experimentids/($experimentId)")
  let body = {archive: $archive, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete list of Tags in an Experiment.
#
# DELETE /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}/tags
# operationId: Experiments_DeleteTags
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experimentids-tags DeleteTags" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list
]: any -> record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experimentids/($experimentId)/tags")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details of an Experiment.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Get
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments Get" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Experiment.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Create
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments Create" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch post event data.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/batch/events
# operationId: Events_BatchPost
# --events item shape: {data?: record, name?: string, timestamp?: string}
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-batch-events BatchPost" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: list # item shape: {data?: record, name?: string, timestamp?: string}
]: any -> record<errors: table<key: record, value: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/batch/events")
  let body = {events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add or Modify a batch of Runs.
#
# PATCH /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/batch/runs
# operationId: Runs_BatchAddOrModify
# --runs item shape: {cancelUri?: string, createdFrom?: record, dataContainerId?: string, description?: string, diagnosticsUri?: string, endTimeUtc?: string, heartbeatEnabled?: bool, hidden?: bool, name?: string, options?: record, parentRunId?: string, properties?: record, runDefinition?: record, runId?: string, runType?: string, scriptName?: string, startTimeUtc?: string, status?: string, tags?: record, target?: string}
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-batch-runs BatchAddOrModify" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runs: list # item shape: {cancelUri?: string, createdFrom?: record, dataContainerId?: string, description?: string, diagnosticsUri?: string, endTimeUtc?: string, heartbeatEnabled?: bool, hidden?: bool, name?: string, options?: record, parentRunId?: string, properties?: record, runDefinition?: record, runId?: string, runType?: string, scriptName?: string, startTimeUtc?: string, status?: string, tags?: record, target?: string}
]: any -> record<errors: record, runs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/batch/runs")
  let body = {runs: $runs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Metric details.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/metrics/{metricId}
# operationId: RunMetrics_Get
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-metrics Get" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  metricId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cells: list<record>, createdUtc: string, dataContainerId: string, dataLocation: string, description: string, label: string, metricId: string, metricType: string, name: string, numCells: int, runId: string, schema: record<numProperties: int, properties: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/metrics/($metricId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Run Metrics for the specific Experiment.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/metrics:query
# operationId: RunMetrics_GetByQuery
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-metrics-query GetByQuery" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MergeStrategyType: string@MergeStrategyType-completer # The type of merge strategy. Currently supported strategies are: None - all logged values are returned as individual metrics. MergeToVector - merges multiple values into a vector of values. Default - the system determines the behavior.
  --MergeStrategyOptions: string@MergeStrategyOptions-completer # Controls behavior of the merge strategy in certain cases; e.g. when a metric is not merged.
  --MergeStrategySettingsVersion: string # The strategy settings version.
  --MergeStrategySettingsSelectMetrics: string@MergeStrategySettingsSelectMetrics-completer # Defines how to select metrics when merging them together.
  --continuationToken: string # The continuation token to use for getting the next set of resources.
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response. See https://docs.microsoft.com/en-us/azure/search/query-odata-filter-orderby-syntax for details on the expression syntax.
  --orderBy: string # The comma separated list of resource properties to use for sorting the requested resources. Optionally, can be followed by either 'asc' or 'desc' (e.g. Color, Size desc)
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
]: any -> record<continuationToken: string, nextLink: string, value: table<cells: list, createdUtc: string, dataContainerId: string, dataLocation: string, description: string, label: string, metricId: string, metricType: string, name: string, numCells: int, runId: string, schema: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MergeStrategyType" $MergeStrategyType "scalar") (serialize-qp "MergeStrategyOptions" $MergeStrategyOptions "scalar") (serialize-qp "MergeStrategySettings.Version" $MergeStrategySettingsVersion "scalar") (serialize-qp "MergeStrategySettings.SelectMetrics" $MergeStrategySettingsSelectMetrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/metrics:query" $qp)
  let body = {continuationToken: $continuationToken, filter: $filter, orderBy: $orderBy, top: $top} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Run details.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}
# operationId: Runs_Get
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs Get" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or Modify a Run.
#
# PATCH /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}
# operationId: Runs_Patch
# --createdFrom shape: {location?: string, locationType?: "ArtifactId", type?: "Notebook"}
# --options shape: {generateDataContainerIdIfNotSpecified?: bool}
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs Patch" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cancelUri: string
  --createdFrom: record # shape: {location?: string, locationType?: "ArtifactId", type?: "Notebook"}
  --dataContainerId: string
  --description: string
  --diagnosticsUri: string
  --endTimeUtc: string # The end time of the run in UTC. (format: date-time)
  --heartbeatEnabled: oneof<nothing, bool>
  --hidden: oneof<nothing, bool>
  --name: string
  --options: record # shape: {generateDataContainerIdIfNotSpecified?: bool}
  --parentRunId: string # The parent of the run if the run is hierarchical; otherwise, Null.
  --properties: record
  --runDefinition: record
  --body-runId: string # The identifier for the run. Run IDs must be less than 256 characters and contain only alphanumeric characters with dashes and underscores.
  --runType: string
  --scriptName: string
  --startTimeUtc: string # The start time of the run in UTC. (format: date-time)
  --status: string # The status of the run. The Status string value maps to the RunStatus Enum.
  --tags: record
  --target: string
]: any -> record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)")
  let body = {cancelUri: $cancelUri, createdFrom: $createdFrom, dataContainerId: $dataContainerId, description: $description, diagnosticsUri: $diagnosticsUri, endTimeUtc: $endTimeUtc, heartbeatEnabled: $heartbeatEnabled, hidden: $hidden, name: $name, options: $options, parentRunId: $parentRunId, properties: $properties, runDefinition: $runDefinition, runId: $body_runId, runType: $runType, scriptName: $scriptName, startTimeUtc: $startTimeUtc, status: $status, tags: $tags, target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Artifacts in a container.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts
# operationId: RunArtifacts_ListInContainer
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-artifacts ListInContainer" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --continuationToken: string # The Continuation Token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/artifacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get URI of an Artifact.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/artifacturi
# operationId: RunArtifacts_GetSasUri
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-artifacts-artifacturi GetSasUri" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/artifacts/artifacturi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a batch of empty Artifacts.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/batch/metadata
# operationId: RunArtifacts_BatchCreateEmptyArtifacts
# --paths item shape: {path: string}
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-artifacts-batch-metadata BatchCreateEmptyArtifacts" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  paths: list # List of Artifact Paths. — item shape: {path: string}
]: any -> record<artifactContentInformation: record, artifacts: record, errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/artifacts/batch/metadata")
  let body = {paths: $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Artifact content information.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/contentinfo
# operationId: RunArtifacts_GetContentInformation
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-artifacts-contentinfo GetContentInformation" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<container: string, contentUri: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/artifacts/contentinfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Artifact by Id.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/metadata
# operationId: RunArtifacts_GetById
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-artifacts-metadata GetById" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/artifacts/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Artifacts in the provided path.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/path
# operationId: RunArtifacts_ListInPath
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-artifacts-path ListInPath" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuationToken: string # The Continuation Token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/artifacts/path" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SAS of an Artifact.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/prefix/contentinfo
# operationId: RunArtifacts_ListSasByPrefix
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-artifacts-prefix-contentinfo ListSasByPrefix" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuationToken: string # The Continuation Token.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<container: string, contentUri: string, origin: string, path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/artifacts/prefix/contentinfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post Metrics to a Run.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/batch/metrics
# operationId: RunMetrics_BatchPost
# --values item shape: {cells?: list, createdUtc?: string, dataContainerId?: string, dataLocation?: string, description?: string, label?: string, metricId?: string, metricType?: string, name?: string, numCells?: int, schema?: record}
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-batch-metrics BatchPost" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --values: list # item shape: {cells?: list, createdUtc?: string, dataContainerId?: string, dataLocation?: string, description?: string, label?: string, metricId?: string, metricType?: string, name?: string, numCells?: int, schema?: record}
]: any -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/batch/metrics")
  let body = {values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details of all child runs.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/children
# operationId: Runs_GetChild
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-children GetChild" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response.
  --continuationtoken: string # The continuation token to use for getting the next set of resources.
  --orderby: list # The list of resource properties to use for sorting the requested resources.
  --sortorder: string@sortorder-completer # The sort order of the returned resources. Not used, specify asc or desc after each property name in the OrderBy parameter.
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
  --count: oneof<nothing, bool> # Whether to include a count of the matching resources along with the resources returned in the response.
]: nothing -> record<continuationToken: string, nextLink: string, value: table<cancelUri: string, createdBy: record, createdFrom: record, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$continuationtoken" $continuationtoken "scalar") (serialize-qp "$orderby" $orderby "multi") (serialize-qp "$sortorder" $sortorder "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/children" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Run Details.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/details
# operationId: Runs_GetDetails
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-details GetDetails" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, logFiles: record, parentRunId: string, properties: record, revision: int, runDefinition: record, runId: string, startTimeUtc: string, status: string, tags: record, target: string, warnings: table<message: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post event data.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/events
# operationId: Events_Post
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-events Post" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --name: string
  --timestamp: string # format: date-time
]: any -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/events")
  let body = {data: $data, name: $name, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Post Metric to a Run.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/metrics
# operationId: RunMetrics_Post
# --schema shape: {numProperties?: int, properties?: list}
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-metrics Post" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cells: list
  --createdUtc: string # format: date-time
  --dataContainerId: string
  --dataLocation: string
  --description: string
  --label: string
  --metricId: string # format: uuid
  --metricType: string
  --name: string
  --numCells: int # format: int32
  --schema: record # shape: {numProperties?: int, properties?: list}
]: any -> record<correlation: record, environment: string, error: record<code: string, details: list<record>, innerError: record<code: string, innerError: any>, message: string, target: string>, location: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/metrics")
  let body = {cells: $cells, createdUtc: $createdUtc, dataContainerId: $dataContainerId, dataLocation: $dataLocation, description: $description, label: $label, metricId: $metricId, metricType: $metricType, name: $name, numCells: $numCells, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete list of Tags in a Run.
#
# DELETE /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/tags
# operationId: Runs_DeleteTags
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-tags DeleteTags" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs/($runId)/tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all Runs for a specific Experiment.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs:query
# operationId: Runs_GetByQuery
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-runs-query GetByQuery" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  experimentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --continuationToken: string # The continuation token to use for getting the next set of resources.
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response. See https://docs.microsoft.com/en-us/azure/search/query-odata-filter-orderby-syntax for details on the expression syntax.
  --orderBy: string # The comma separated list of resource properties to use for sorting the requested resources. Optionally, can be followed by either 'asc' or 'desc' (e.g. Color, Size desc)
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
]: any -> record<continuationToken: string, nextLink: string, value: table<cancelUri: string, createdBy: record, createdFrom: record, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments/($experimentName)/runs:query")
  let body = {continuationToken: $continuationToken, filter: $filter, orderBy: $orderBy, top: $top} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all Experiments in a specific workspace.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments:query
# operationId: Experiments_GetByQuery
export def "history-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-experiments-query GetByQuery" [
  subscriptionId: string
  resourceGroupName: string
  workspaceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --continuationToken: string # The continuation token to use for getting the next set of resources.
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response. See https://docs.microsoft.com/en-us/azure/search/query-odata-filter-orderby-syntax for details on the expression syntax.
  --orderBy: string # The comma separated list of resource properties to use for sorting the requested resources. Optionally, can be followed by either 'asc' or 'desc' (e.g. Color, Size desc)
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
]: any -> record<continuationToken: string, nextLink: string, value: table<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearningServices/workspaces/($workspaceName)/experiments:query")
  let body = {continuationToken: $continuationToken, filter: $filter, orderBy: $orderBy, top: $top} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
