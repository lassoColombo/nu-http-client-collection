# Auto-generated client for Azure Machine Learning Model Management Service v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-modelManagement/2019-09-30/swagger.json
# Auth: --token flag or $env.AZURE_MACHINE_LEARNING_MODEL_MANAGEMENT_SERVICE_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_MACHINE_LEARNING_MODEL_MANAGEMENT_SERVICE_TOKEN | default "" }
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
def orderby-completer [] { ["CreatedAtAsc" "CreatedAtDesc" "UpdatedAtAsc" "UpdatedAtDesc"] }
def orderBy-completer [] { ["CreatedAtAsc" "CreatedAtDesc" "UpdatedAtAsc" "UpdatedAtDesc"] }
def computeType-completer [] { ["ACI" "AKS" "AKSENDPOINT" "AMLCOMPUTE" "IOT" "UNKNOWN"] }
def deploymentType-completer [] { ["Batch" "GRPCRealtimeEndpoint" "HttpRealtimeEndpoint"] }
def keyType-completer [] { ["Primary" "Secondary"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets ListQuery" } } | get name | first)
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

# Query the list of Assets in a workspace.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets
# operationId: Assets_ListQuery
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets ListQuery" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --runId: string # The run Id associated with the Assets.
  --name: string # The object name.
  --count: int # The number of items to retrieve in a page. (format: int32)
  --skipToken: string # The continuation token to retrieve the next page.
  --tags: string # A set of tags with which to filter the returned models.             It is a comma separated string of tags key or tags key=value             Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models.             It is a comma separated string of properties key and/or properties key=value             Example: propKey1,propKey2,propKey3=value3
  --orderby: string@orderby-completer # An option for specifying how to order the list. (default: CreatedAtDesc)
]: nothing -> record<nextLink: string, value: table<artifacts: list, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "runId" $runId "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "$skipToken" $skipToken "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Asset.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets
# operationId: Assets_Create
# --artifacts item shape: {id?: string, prefix?: string}
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets Create" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --artifacts: list # A list of child artifacts. — item shape: {id?: string, prefix?: string}
  --description: string # The Asset description.
  --id: string # The Asset Id.
  --kvTags: record # The Asset tag dictionary. Tags are mutable.
  --meta: record # A dictionary containing metadata about the Asset.
  name: string # The name of the Asset.
  --properties: record # The Asset property dictionary. Properties are immutable.
  --runid: string # The RunId associated with this Asset.
]: any -> record<artifacts: table<id: string, prefix: string>, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/assets")
  let body = {artifacts: $artifacts, description: $description, id: $id, kvTags: $kvTags, meta: $meta, name: $name, properties: $properties, runid: $runid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Asset.
#
# DELETE /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}
# operationId: Assets_Delete
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets Delete" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/assets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Asset.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}
# operationId: Assets_QueryById
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets QueryById" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifacts: table<id: string, prefix: string>, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/assets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Asset.
#
# PATCH /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/assets/{id}
# operationId: Assets_Patch
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-assets Patch" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<artifacts: table<id: string, prefix: string>, createdTime: string, description: string, id: string, kvTags: record, meta: record, name: string, properties: record, runid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/assets/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of Image Profiles.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{imageId}/profiles
# operationId: Profiles_ListQuery
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-images-profiles ListQuery" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The Profile name.
  --description: string # The Profile description.
  --tags: string # A set of tags with which to filter the returned models.             It is a comma separated string of tags key or tags key=value             Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models.             It is a comma separated string of properties key and/or properties key=value             Example: propKey1,propKey2,propKey3=value3
  --count: int # The number of items to retrieve in a page. (format: int32)
  --skipToken: string # The continuation token to retrieve the next page.
  --orderBy: string@orderBy-completer # The option to order the response. (default: CreatedAtDesc)
]: nothing -> record<nextLink: string, value: table<createdTime: string, description: string, error: record, imageId: string, inputData: string, kvTags: record, name: string, profileRunResult: string, profilingErrorLogs: string, properties: record, recommendationLatencyInMs: float, recommendedCpu: float, recommendedMemoryInGB: float, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "$skipToken" $skipToken "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/images/($imageId)/profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Profile.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{imageId}/profiles
# operationId: Profiles_Create
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-images-profiles Create" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The profile description.
  --inputData: string # The profile input data.
  --kvTags: record # The tags dictionary.
  name: string # The profile name.
  --properties: record # The properties dictionary.
]: any -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/images/($imageId)/profiles")
  let body = {description: $description, inputData: $inputData, kvTags: $kvTags, name: $name, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Profile.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/images/{imageId}/profiles/{id}
# operationId: Profiles_QueryById
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-images-profiles QueryById" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  imageId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdTime: string, description: string, error: record<code: string, details: list<record>, message: string, statusCode: int>, imageId: string, inputData: string, kvTags: record, name: string, profileRunResult: string, profilingErrorLogs: string, properties: record, recommendationLatencyInMs: float, recommendedCpu: float, recommendedMemoryInGB: float, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/images/($imageId)/profiles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query the list of Models in a workspace.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models
# operationId: MLModels_ListQuery
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models ListQuery" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The object name.
  --framework: string # The framework.
  --description: string # The object description.
  --count: int # The number of items to retrieve in a page. (format: int32)
  --skipToken: string # The continuation token to retrieve the next page.
  --tags: string # A set of tags with which to filter the returned models.             It is a comma separated string of tags key or tags key=value             Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models.             It is a comma separated string of properties key and/or properties key=value             Example: propKey1,propKey2,propKey3=value3
  --runId: string # The runId which created the model.
  --orderBy: string@orderBy-completer # An option to specify how the models are ordered in the response. (default: CreatedAtDesc)
]: nothing -> record<nextLink: string, value: table<createdTime: string, datasets: list, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "framework" $framework "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "$skipToken" $skipToken "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "runId" $runId "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a model.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models
# operationId: MLModels_Register
# --datasets item shape: {id?: string, name?: string}
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models Register" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasets: list # The list of datasets associated with the model. — item shape: {id?: string, name?: string}
  --description: string # The Model description text. (e.g. A mnist model, first version.)
  --experimentName: string # The name of the experiment where this model was created.
  --framework: string # The Model framework.
  --frameworkVersion: string # The Model framework version.
  --id: string # The Model Id. (e.g. sklearn_mnist:1)
  --kvTags: record # The Model tag dictionary. Items are mutable.
  mimeType: string # The MIME type of Model content. For more details about MIME type, please open https://www.iana.org/assignments/media-types/media-types.xhtml
  name: string # The Model name. (e.g. sklearn_mnist)
  --parentModelId: string # The Parent Model Id. (e.g. sklearn_mnist_root:1)
  --properties: record # The Model property dictionary. Properties are immutable.
  --runId: string # The RunId that created this model.
  --unpack: oneof<nothing, bool> # Indicates whether we need to unpack the Model during docker Image creation.
  --body-url: string # The URL of the Model. Usually a SAS URL.
  --version: int # The Model version assigned by Model Management Service. (format: int64, e.g. 1)
]: any -> record<createdTime: string, datasets: table<id: string, name: string>, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/models")
  let body = {datasets: $datasets, description: $description, experimentName: $experimentName, framework: $framework, frameworkVersion: $frameworkVersion, id: $id, kvTags: $kvTags, mimeType: $mimeType, name: $name, parentModelId: $parentModelId, properties: $properties, runId: $runId, unpack: $unpack, url: $body_url, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the specified Model.
#
# DELETE /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}
# operationId: MLModels_Delete
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models Delete" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/models/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a model.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}
# operationId: MLModels_QueryById
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models QueryById" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdTime: string, datasets: table<id: string, name: string>, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/models/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a specific model.
#
# PATCH /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}
# operationId: MLModels_Patch
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models Patch" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<createdTime: string, datasets: table<id: string, name: string>, description: string, experimentName: string, framework: string, frameworkVersion: string, id: string, kvTags: record, mimeType: string, modifiedTime: string, name: string, parentModelId: string, properties: record, runId: string, unpack: bool, url: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/models/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the metrics for a Model.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/models/{id}/metrics
# operationId: MLModels_GetMetrics
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-models-metrics GetMetrics" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # The start date from which to retrieve metrics, ISO 8601 literal format.
  --endDate: string # The end date from which to retrieve metrics, ISO 8601 literal format.
]: nothing -> record<deploymentSummary: record<successfulDeployments: int, unsuccessfulDeployments: int>, endTime: string, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/models/($id)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the status of an async operation.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/operations/{id}
# operationId: Operations_Get
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-operations Get" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdTime: string, endTime: string, error: record<code: string, details: list<record>, message: string, statusCode: int>, id: string, operationDetails: record<subOperationState: string, subOperationType: string>, operationLog: string, operationType: string, parentRequestId: string, resourceLocation: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/operations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query the list of Services in a Workspace.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services
# operationId: Services_ListQuery
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services ListQuery" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --imageId: string # The Image Id.
  --imageName: string # The Image name.
  --modelId: string # The Model Id.
  --modelName: string # The Model name.
  --name: string # The object name.
  --count: int # The number of items to retrieve in a page. (format: int32)
  --computeType: string # The compute environment type.
  --skipToken: string # The continuation token to retrieve the next page.
  --tags: string # A set of tags with which to filter the returned models.             It is a comma separated string of tags key or tags key=value             Example: tagKey1,tagKey2,tagKey3=value3
  --properties: string # A set of properties with which to filter the returned models.             It is a comma separated string of properties key and/or properties key=value             Example: propKey1,propKey2,propKey3=value3
  --expand: oneof<nothing, bool> # Set to True to include Model details. (default: false)
  --orderby: string@orderby-completer # The option to order the response. (default: UpdatedAtDesc)
]: nothing -> record<nextLink: string, value: table<computeType: string, createdTime: string, deploymentType: string, description: string, error: record, id: string, kvTags: record, name: string, operationId: string, properties: record, state: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "imageId" $imageId "scalar") (serialize-qp "imageName" $imageName "scalar") (serialize-qp "modelId" $modelId "scalar") (serialize-qp "modelName" $modelName "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "computeType" $computeType "scalar") (serialize-qp "$skipToken" $skipToken "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "properties" $properties "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Service.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services
# Discriminator (request): computeType
# operationId: Services_Create
# --environmentImageRequest shape: {assets?: list, driverProgram?: string, environment?: record, modelIds?: list}
# --keys shape: {primaryKey?: string, secondaryKey?: string}
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services Create" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  computeType: string@computeType-completer # The compute environment type for the service. (e.g. AKS)
  --deploymentType: string@deploymentType-completer # The deployment type for the service. (e.g. HttpRealtimeEndpoint)
  --description: string # The description of the service.
  --environmentImageRequest: record # Request to create a Docker image based on Environment. — shape: {assets?: list, driverProgram?: string, environment?: record, modelIds?: list}
  --imageId: string # The Image Id.
  --keys: record # shape: {primaryKey?: string, secondaryKey?: string}
  --kvTags: record # The service tag dictionary. Tags are mutable.
  --location: string # The location of the service.
  name: string # The service name.
  --properties: record # The service properties dictionary. Properties are immutable.
]: any -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services")
  let body = {computeType: $computeType, deploymentType: $deploymentType, description: $description, environmentImageRequest: $environmentImageRequest, imageId: $imageId, keys: $keys, kvTags: $kvTags, location: $location, name: $name, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Service.
#
# DELETE /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}
# operationId: Services_Delete
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services Delete" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Service.
#
# GET /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}
# operationId: Services_QueryById
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services QueryById" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: oneof<nothing, bool> # Set to True to include Model details. (default: false)
]: nothing -> record<computeType: string, createdTime: string, deploymentType: string, description: string, error: record<code: string, details: list<record>, message: string, statusCode: int>, id: string, kvTags: record, name: string, operationId: string, properties: record, state: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a Service.
#
# PATCH /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}
# operationId: Services_Patch
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services Patch" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: string, details: table<code: string, message: string, target: string>, message: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists Service keys.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/listkeys
# operationId: Services_ListServiceKeys
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services-listkeys ListServiceKeys" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<primaryKey: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services/($id)/listkeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate Service Keys.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/regenerateKeys
# operationId: Services_RegenerateServiceKeys
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services-regenerate-keys RegenerateServiceKeys" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyType: int@keyType-completer # Specification for which type of key to generate. (format: int32, e.g. Primary)
  --keyValue: string # The value the key is set to.
]: any -> record<primaryKey: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services/($id)/regenerateKeys")
  let body = {keyType: $keyType, keyValue: $keyValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate Service Access Token.
#
# POST /modelmanagement/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.MachineLearningServices/workspaces/{workspace}/services/{id}/token
# operationId: Services_GetServiceToken
export def "modelmanagement-v10-subscriptions-resource-groups-providers-microsoft-machine-learning-services-workspaces-services-token GetServiceToken" [
  subscriptionId: string
  resourceGroup: string
  workspace: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessToken: string, expiryOn: int, refreshAfter: int, tokenType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/modelmanagement/v1.0/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.MachineLearningServices/workspaces/($workspace)/services/($id)/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
