# Auto-generated client for BatchAI v2018-05-01
# Source: https://api.apis.guru/v2/specs/azure.com/batchai-BatchAI/2018-05-01/swagger.json
# Auth: --token flag or $env.BATCHAI_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BATCHAI_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-batch-ai-operations list" } } | get name | first)
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

# Lists available operations for the Microsoft.BatchAI provider.
#
# GET /providers/Microsoft.BatchAI/operations
# operationId: Operations_List
export def "providers-microsoft-batch-ai-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.BatchAI/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the current usage information as well as limits for Batch AI resources for given subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.BatchAI/locations/{location}/usages
# operationId: Usages_List
export def "subscriptions-providers-microsoft-batch-ai-locations-usages list" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location: (encode-path-segment $location)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.BatchAI/locations/{location}/usages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of Workspaces associated with the given subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.BatchAI/workspaces
# operationId: Workspaces_List
export def "subscriptions-providers-microsoft-batch-ai-workspaces list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.BatchAI/workspaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of Workspaces within the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces
# operationId: Workspaces_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Workspace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a Workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates properties of a Workspace.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Update
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces update" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  --tags: record # The user specified tags associated with the Workspace.
]: any -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a Workspace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Create
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  location: string # The region in which to create the Workspace.
  --tags: record # The user specified tags associated with the Workspace.
]: any -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp)
  let req_body = {"location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets information about Clusters associated with the given Workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters
# operationId: Clusters_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Cluster.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  cluster_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a Cluster.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  cluster_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, creationTime: string, currentNodeCount: int, errors: list<record>, nodeSetup: record<mountVolumes: record, performanceCountersSettings: record, setupTask: record>, nodeStateCounts: record<idleNodeCount: int, leavingNodeCount: int, preparingNodeCount: int, runningNodeCount: int, unusableNodeCount: int>, provisioningState: string, provisioningStateTransitionTime: string, scaleSettings: record<autoScale: record, manual: record>, subnet: record<id: string>, userAccountSettings: record<adminUserName: string, adminUserPassword: string, adminUserSshPublicKey: string>, virtualMachineConfiguration: record<imageReference: record>, vmPriority: string, vmSize: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates properties of a Cluster.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Update
# --properties shape: {scaleSettings?: any}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters update" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  cluster_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a Cluster that need to be updated. — shape: {scaleSettings?: any}
]: any -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, creationTime: string, currentNodeCount: int, errors: list<record>, nodeSetup: record<mountVolumes: record, performanceCountersSettings: record, setupTask: record>, nodeStateCounts: record<idleNodeCount: int, leavingNodeCount: int, preparingNodeCount: int, runningNodeCount: int, unusableNodeCount: int>, provisioningState: string, provisioningStateTransitionTime: string, scaleSettings: record<autoScale: record, manual: record>, subnet: record<id: string>, userAccountSettings: record<adminUserName: string, adminUserPassword: string, adminUserSshPublicKey: string>, virtualMachineConfiguration: record<imageReference: record>, vmPriority: string, vmSize: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a Cluster in the given Workspace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Create
# --properties shape: {nodeSetup?: any, scaleSettings?: any, subnet?: any, userAccountSettings: any, virtualMachineConfiguration?: any, vmPriority?: "dedicated"|"lowpriority", vmSize: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  cluster_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a Cluster. — shape: {nodeSetup?: any, scaleSettings?: any, subnet?: any, userAccountSettings: any, virtualMachineConfiguration?: any, vmPriority?: "dedicated"|"lowpriority", vmSize: string}
]: any -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, creationTime: string, currentNodeCount: int, errors: list<record>, nodeSetup: record<mountVolumes: record, performanceCountersSettings: record, setupTask: record>, nodeStateCounts: record<idleNodeCount: int, leavingNodeCount: int, preparingNodeCount: int, runningNodeCount: int, unusableNodeCount: int>, provisioningState: string, provisioningStateTransitionTime: string, scaleSettings: record<autoScale: record, manual: record>, subnet: record<id: string>, userAccountSettings: record<adminUserName: string, adminUserPassword: string, adminUserSshPublicKey: string>, virtualMachineConfiguration: record<imageReference: record>, vmPriority: string, vmSize: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the IP address, port of all the compute nodes in the Cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}/listRemoteLoginInformation
# operationId: Clusters_ListRemoteLoginInformation
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters-list-remote-login-information list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  cluster_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<ipAddress: string, nodeId: string, port: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}/listRemoteLoginInformation") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of Experiments within the specified Workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments
# operationId: Experiments_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an Experiment.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about an Experiment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an Experiment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Create
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of Jobs within the specified Experiment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs
# operationId: Jobs_ListByExperiment
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Job.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}
# operationId: Jobs_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a Job.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}
# operationId: Jobs_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<caffe2Settings: record<commandLineArgs: string, pythonInterpreterPath: string, pythonScriptFilePath: string>, caffeSettings: record<commandLineArgs: string, configFilePath: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, chainerSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, cluster: record<id: string>, cntkSettings: record<commandLineArgs: string, configFilePath: string, languageType: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, constraints: record<maxWallClockTime: string>, containerSettings: record<imageSourceRegistry: record, shmSize: string>, creationTime: string, customMpiSettings: record<commandLine: string, processCount: int>, customToolkitSettings: record<commandLine: string>, environmentVariables: list<record>, executionInfo: record<endTime: string, errors: list, exitCode: int, startTime: string>, executionState: string, executionStateTransitionTime: string, horovodSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, inputDirectories: list<record>, jobOutputDirectoryPathSegment: string, jobPreparation: record<commandLine: string>, mountVolumes: record<azureBlobFileSystems: list, azureFileShares: list, fileServers: list, unmanagedFileSystems: list>, nodeCount: int, outputDirectories: list<record>, provisioningState: string, provisioningStateTransitionTime: string, pyTorchSettings: record<commandLineArgs: string, communicationBackend: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, schedulingPriority: string, secrets: list<record>, stdOutErrPathPrefix: string, tensorFlowSettings: record<masterCommandLineArgs: string, parameterServerCommandLineArgs: string, parameterServerCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string, workerCommandLineArgs: string, workerCount: int>, toolType: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Job in the given Experiment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}
# operationId: Jobs_Create
# --properties shape: {caffe2Settings?: any, caffeSettings?: any, chainerSettings?: any, cluster: any, cntkSettings?: any, constraints?: any, containerSettings?: any, customMpiSettings?: any, customToolkitSettings?: any, environmentVariables?: list, horovodSettings?: any, inputDirectories?: list, jobPreparation?: any, mountVolumes?: any, nodeCount: int, outputDirectories?: list, pyTorchSettings?: any, schedulingPriority?: "low"|"normal"|"high", secrets?: list, stdOutErrPathPrefix: string, tensorFlowSettings?: any}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a Batch AI Job. — shape: {caffe2Settings?: any, caffeSettings?: any, chainerSettings?: any, cluster: any, cntkSettings?: any, constraints?: any, containerSettings?: any, customMpiSettings?: any, customToolkitSettings?: any, environmentVariables?: list, horovodSettings?: any, inputDirectories?: list, jobPreparation?: any, mountVolumes?: any, nodeCount: int, outputDirectories?: list, pyTorchSettings?: any, schedulingPriority?: "low"|"normal"|"high", secrets?: list, stdOutErrPathPrefix: string, tensorFlowSettings?: any}
]: any -> record<properties: record<caffe2Settings: record<commandLineArgs: string, pythonInterpreterPath: string, pythonScriptFilePath: string>, caffeSettings: record<commandLineArgs: string, configFilePath: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, chainerSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, cluster: record<id: string>, cntkSettings: record<commandLineArgs: string, configFilePath: string, languageType: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, constraints: record<maxWallClockTime: string>, containerSettings: record<imageSourceRegistry: record, shmSize: string>, creationTime: string, customMpiSettings: record<commandLine: string, processCount: int>, customToolkitSettings: record<commandLine: string>, environmentVariables: list<record>, executionInfo: record<endTime: string, errors: list, exitCode: int, startTime: string>, executionState: string, executionStateTransitionTime: string, horovodSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, inputDirectories: list<record>, jobOutputDirectoryPathSegment: string, jobPreparation: record<commandLine: string>, mountVolumes: record<azureBlobFileSystems: list, azureFileShares: list, fileServers: list, unmanagedFileSystems: list>, nodeCount: int, outputDirectories: list<record>, provisioningState: string, provisioningStateTransitionTime: string, pyTorchSettings: record<commandLineArgs: string, communicationBackend: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, schedulingPriority: string, secrets: list<record>, stdOutErrPathPrefix: string, tensorFlowSettings: record<masterCommandLineArgs: string, parameterServerCommandLineArgs: string, parameterServerCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string, workerCommandLineArgs: string, workerCount: int>, toolType: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all directories and files inside the given directory of the Job's output directory (if the output directory is on Azure File Share or Azure Storage Container).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}/listOutputFiles
# operationId: Jobs_ListOutputFiles
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs-list-output-files list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputdirectoryid: string # Id of the job output directory. This is the OutputDirectory-->id parameter that is given by the user during Create Job.
  --directory: string # The path to the directory. (default: .)
  --linkexpiryinminutes: int # The number of minutes after which the download link will expire. (format: int32, default: 60)
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<downloadUrl: string, fileType: string, name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputdirectoryid" $outputdirectoryid "scalar") (serialize-qp "directory" $directory "scalar") (serialize-qp "linkexpiryinminutes" $linkexpiryinminutes "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}/listOutputFiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of currently existing nodes which were used for the Job execution. The returned information contains the node ID, its public IP and SSH port.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}/listRemoteLoginInformation
# operationId: Jobs_ListRemoteLoginInformation
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs-list-remote-login-information list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<ipAddress: string, nodeId: string, port: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}/listRemoteLoginInformation") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Terminates a job.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}/terminate
# operationId: Jobs_Terminate
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs-terminate create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}/terminate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of File Servers associated with the specified workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers
# operationId: FileServers_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a File Server.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers/{fileServerName}
# operationId: FileServers_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  file_server_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), file_server_name: (encode-path-segment $file_server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers/{file_server_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a File Server.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers/{fileServerName}
# operationId: FileServers_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  file_server_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, dataDisks: record<cachingType: string, diskCount: int, diskSizeInGB: int, storageAccountType: string>, mountSettings: record<fileServerInternalIP: string, fileServerPublicIP: string, mountPoint: string>, provisioningState: string, provisioningStateTransitionTime: string, sshConfiguration: record<publicIPsToAllow: list, userAccountSettings: record>, subnet: record<id: string>, vmSize: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), file_server_name: (encode-path-segment $file_server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers/{file_server_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a File Server in the given workspace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers/{fileServerName}
# operationId: FileServers_Create
# --properties shape: {dataDisks: any, sshConfiguration: any, subnet?: any, vmSize: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  file_server_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a file server. — shape: {dataDisks: any, sshConfiguration: any, subnet?: any, vmSize: string}
]: any -> record<properties: record<creationTime: string, dataDisks: record<cachingType: string, diskCount: int, diskSizeInGB: int, storageAccountType: string>, mountSettings: record<fileServerInternalIP: string, fileServerPublicIP: string, mountPoint: string>, provisioningState: string, provisioningStateTransitionTime: string, sshConfiguration: record<publicIPsToAllow: list, userAccountSettings: record>, subnet: record<id: string>, vmSize: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), file_server_name: (encode-path-segment $file_server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers/{file_server_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
