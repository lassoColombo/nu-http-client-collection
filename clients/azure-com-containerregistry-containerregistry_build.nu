# Auto-generated client for ContainerRegistryManagementClient v2019-06-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/containerregistry-containerregistry_build/2019-06-01-preview/swagger.json
# Auth: --token flag or $env.CONTAINERREGISTRYMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTAINERREGISTRYMANAGEMENTCLIENT_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-container-registry-registries-list-build-source-upload-url get" } } | get name | first)
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

# Get the upload location for the user to be able to upload the source.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/listBuildSourceUploadUrl
# operationId: Registries_GetBuildSourceUploadUrl
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-list-build-source-upload-url get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<relativePath: string, uploadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/listBuildSourceUploadUrl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the runs for a registry.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs
# operationId: Runs_List
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs list" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --filter: string # The runs filter to apply on the operation. Arithmetic operators are not supported. The allowed string function is 'contains'. All logical operators except 'Not', 'Has', 'All' are allowed.
  --top: int # $top is supported for get list of runs, which limits the maximum number of runs to return. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the detailed information for a given run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}
# operationId: Runs_Get
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<properties: record<agentConfiguration: record<cpu: int>, createTime: string, customRegistries: list<string>, finishTime: string, imageUpdateTrigger: record<id: string, images: list, timestamp: string>, isArchiveEnabled: bool, lastUpdatedTime: string, outputImages: list<record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, runErrorMessage: string, runId: string, runType: string, sourceRegistryAuth: string, sourceTrigger: record<branchName: string, commitId: string, eventType: string, id: string, providerType: string, pullRequestId: string, repositoryUrl: string>, startTime: string, status: string, task: string, timerTrigger: record<scheduleOccurrence: string, timerTriggerName: string>, updateTriggerToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch the run properties.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}
# operationId: Runs_Update
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs update" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --is-archive-enabled: oneof<nothing, bool> # The value that indicates whether archiving is enabled or not.
]: any -> record<properties: record<agentConfiguration: record<cpu: int>, createTime: string, customRegistries: list<string>, finishTime: string, imageUpdateTrigger: record<id: string, images: list, timestamp: string>, isArchiveEnabled: bool, lastUpdatedTime: string, outputImages: list<record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, runErrorMessage: string, runId: string, runType: string, sourceRegistryAuth: string, sourceTrigger: record<branchName: string, commitId: string, eventType: string, id: string, providerType: string, pullRequestId: string, repositoryUrl: string>, startTime: string, status: string, task: string, timerTrigger: record<scheduleOccurrence: string, timerTriggerName: string>, updateTriggerToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}") $qp)
  let req_body = {"isArchiveEnabled": $is_archive_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancel an existing run.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}/cancel
# operationId: Runs_Cancel
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs-cancel cancel" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a link to download the run logs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}/listLogSasUrl
# operationId: Runs_GetLogSasUrl
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs-list-log-sas-url get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<logLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}/listLogSasUrl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedules a new run based on the request parameters and add it to the run queue.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/scheduleRun
# Discriminator (request): type
# operationId: Registries_ScheduleRun
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-schedule-run create" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --is-archive-enabled: oneof<nothing, bool> # The value that indicates whether archiving is enabled for the run or not. (default: false)
  type: string # The type of the run request.
]: any -> record<properties: record<agentConfiguration: record<cpu: int>, createTime: string, customRegistries: list<string>, finishTime: string, imageUpdateTrigger: record<id: string, images: list, timestamp: string>, isArchiveEnabled: bool, lastUpdatedTime: string, outputImages: list<record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, runErrorMessage: string, runId: string, runType: string, sourceRegistryAuth: string, sourceTrigger: record<branchName: string, commitId: string, eventType: string, id: string, providerType: string, pullRequestId: string, repositoryUrl: string>, startTime: string, status: string, task: string, timerTrigger: record<scheduleOccurrence: string, timerTriggerName: string>, updateTriggerToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/scheduleRun") $qp)
  let req_body = {"isArchiveEnabled": $is_archive_enabled, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all the task runs for a specified container registry.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns
# operationId: TaskRuns_List
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs list" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a specified task run resource.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Delete
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs delete" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the detailed information for a given task run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Get
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<forceUpdateTag: string, provisioningState: string, runRequest: record<isArchiveEnabled: bool, type: string>, runResult: record<properties: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a task run with the specified parameters.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Update
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {forceUpdateTag?: string, runRequest?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs update" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties of a task run update parameters. — shape: {forceUpdateTag?: string, runRequest?: record}
  --tags: record # The ARM resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<forceUpdateTag: string, provisioningState: string, runRequest: record<isArchiveEnabled: bool, type: string>, runResult: record<properties: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp)
  let req_body = {"identity": $identity, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a task run for a container registry with the specified parameters.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Create
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {forceUpdateTag?: string, runRequest?: record, runResult?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs create" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties of task run. — shape: {forceUpdateTag?: string, runRequest?: record, runResult?: record}
  location: string # The location of the resource. This cannot be changed after the resource is created.
  --tags: record # The tags of the resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<forceUpdateTag: string, provisioningState: string, runRequest: record<isArchiveEnabled: bool, type: string>, runResult: record<properties: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp)
  let req_body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all the tasks for a specified container registry.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks
# operationId: Tasks_List
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks list" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a specified task.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Delete
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks delete" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the properties of a specified task.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Get
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a task with the specified parameters.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Update
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {agentConfiguration?: record, credentials?: record, platform?: record, status?: "Disabled"|"Enabled", step?: record, timeout?: int, trigger?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks update" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties for updating a task. — shape: {agentConfiguration?: record, credentials?: record, platform?: record, status?: "Disabled"|"Enabled", step?: record, timeout?: int, trigger?: record}
  --tags: record # The ARM resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp)
  let req_body = {"identity": $identity, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a task for a container registry with the specified parameters.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Create
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {agentConfiguration?: record, credentials?: record, platform: record, status?: "Disabled"|"Enabled", step: record, timeout?: int, trigger?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks create" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties of a task. — shape: {agentConfiguration?: record, credentials?: record, platform: record, status?: "Disabled"|"Enabled", step: record, timeout?: int, trigger?: record}
  location: string # The location of the resource. This cannot be changed after the resource is created.
  --tags: record # The tags of the resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp)
  let req_body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a task with extended information that includes all secrets.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}/listDetails
# operationId: Tasks_GetDetails
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks-list-details get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}/listDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
