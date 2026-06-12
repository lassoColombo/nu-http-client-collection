# Auto-generated client for DataFactoryManagementClient v2018-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/datafactory/2018-06-01/swagger.json
# Auth: --token flag or $env.DATAFACTORYMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATAFACTORYMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def command-completer [] { ["executeExpressionQuery" "executePreviewQuery" "executeStatisticsQuery"] }
def autoUpdate-completer [] { ["Off" "On"] }
def keyName-completer [] { ["authKey1" "authKey2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-data-factory-operations List" } } | get name | first)
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

# Lists the available Azure Data Factory API operations.
#
# GET /providers/Microsoft.DataFactory/operations
# operationId: Operations_List
export def "providers-microsoft-data-factory-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DataFactory/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists factories under the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DataFactory/factories
# operationId: Factories_List
export def "subscriptions-providers-microsoft-data-factory-factories List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataFactory/factories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a factory's repo information.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataFactory/locations/{locationId}/configureFactoryRepo
# operationId: Factories_ConfigureFactoryRepo
# --repoConfiguration shape: {accountName: string, collaborationBranch: string, lastCommitId?: string, repositoryName: string, rootFolder: string, type: string}
export def "subscriptions-providers-microsoft-data-factory-locations-configure-factory-repo ConfigureFactoryRepo" [
  subscriptionId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --factoryResourceId: string # The factory resource id.
  --repoConfiguration: record # Factory's git repo information. — shape: {accountName: string, collaborationBranch: string, lastCommitId?: string, repositoryName: string, rootFolder: string, type: string}
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataFactory/locations/($locationId)/configureFactoryRepo" $qp)
  let body = {factoryResourceId: $factoryResourceId, repoConfiguration: $repoConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get exposure control feature for specific location.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataFactory/locations/{locationId}/getFeatureValue
# operationId: ExposureControl_GetFeatureValue
export def "subscriptions-providers-microsoft-data-factory-locations-get-feature-value GetFeatureValue" [
  subscriptionId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --featureName: string # The feature name.
  --featureType: string # The feature type.
]: any -> record<featureName: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataFactory/locations/($locationId)/getFeatureValue" $qp)
  let body = {featureName: $featureName, featureType: $featureType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists factories.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories
# operationId: Factories_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories ListByResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a factory.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a factory.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-None-Match: string # ETag of the factory entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a factory.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_Update
# --identity shape: {type: "SystemAssigned"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories Update" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --identity: any # Identity properties of the factory resource. — shape: {type: "SystemAssigned"}
  --tags: record # The resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)" $qp)
  let body = {identity: $identity, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a factory.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}
# operationId: Factories_CreateOrUpdate
# --identity shape: {type: "SystemAssigned"}
# --properties shape: {repoConfiguration?: record}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-Match: string # ETag of the factory entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  --identity: any # Identity properties of the factory resource. — shape: {type: "SystemAssigned"}
  --properties: any # Factory resource properties. — shape: {repoConfiguration?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<createTime: string, provisioningState: string, repoConfiguration: record<accountName: string, collaborationBranch: string, lastCommitId: string, repositoryName: string, rootFolder: string, type: string>, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)" $qp)
  let body = {identity: $identity, properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a data flow into debug session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/addDataFlowToDebugSession
# operationId: DataFlowDebugSession_AddDataFlow
# --dataFlow shape: {properties: record, name?: string}
# --datasets item shape: {properties: record, name?: string}
# --debugSettings shape: {datasetParameters?: record, parameters?: record, sourceSettings?: list}
# --linkedServices item shape: {properties: record, name?: string}
# --staging shape: {folderPath?: string, linkedService?: any}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-add-data-flow-to-debug-session AddDataFlow" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --dataFlow: any # Data flow debug resource. — shape: {properties: record, name?: string}
  --datasets: list # List of datasets. — item shape: {properties: record, name?: string}
  --debugSettings: record # Data flow debug settings. — shape: {datasetParameters?: record, parameters?: record, sourceSettings?: list}
  --linkedServices: list # List of linked services. — item shape: {properties: record, name?: string}
  --sessionId: string # The ID of data flow debug session.
  --staging: any # Staging info for execute data flow activity. — shape: {folderPath?: string, linkedService?: any}
]: any -> record<jobVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/addDataFlowToDebugSession" $qp)
  let body = {dataFlow: $dataFlow, datasets: $datasets, debugSettings: $debugSettings, linkedServices: $linkedServices, sessionId: $sessionId, staging: $staging} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a data flow debug session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/createDataFlowDebugSession
# operationId: DataFlowDebugSession_Create
# --integrationRuntime shape: {properties: record, name?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-create-data-flow-debug-session Create" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --computeType: string # Compute type of the cluster. The value will be overwritten by the same setting in integration runtime if provided.
  --coreCount: int # Core count of the cluster. The value will be overwritten by the same setting in integration runtime if provided.
  --integrationRuntime: any # Integration runtime debug resource. — shape: {properties: record, name?: string}
  --timeToLive: int # Time to live setting of the cluster in minutes.
]: any -> record<sessionId: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/createDataFlowDebugSession" $qp)
  let body = {computeType: $computeType, coreCount: $coreCount, integrationRuntime: $integrationRuntime, timeToLive: $timeToLive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists data flows.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows
# operationId: DataFlows_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows ListByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/dataflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a data flow.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows/{dataFlowName}
# operationId: DataFlows_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  dataFlowName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/dataflows/($dataFlowName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a data flow.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows/{dataFlowName}
# operationId: DataFlows_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  dataFlowName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-None-Match: string # ETag of the data flow entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/dataflows/($dataFlowName)" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a data flow.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/dataflows/{dataFlowName}
# operationId: DataFlows_CreateOrUpdate
# --properties shape: {annotations?: list, description?: string, folder?: record, type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-dataflows CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  dataFlowName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-Match: string # ETag of the data flow entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # Azure Data Factory nested object which contains a flow with data movements and transformations. — shape: {annotations?: list, description?: string, folder?: record, type: string}
]: any -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/dataflows/($dataFlowName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists datasets.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets
# operationId: Datasets_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets ListByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a dataset.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets/{datasetName}
# operationId: Datasets_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  datasetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/datasets/($datasetName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a dataset.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets/{datasetName}
# operationId: Datasets_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  datasetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-None-Match: string # ETag of the dataset entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, linkedServiceName: record<parameters: record, referenceName: string, type: string>, parameters: record, schema: record, structure: record, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/datasets/($datasetName)" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a dataset.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/datasets/{datasetName}
# operationId: Datasets_CreateOrUpdate
# --properties shape: {annotations?: list, description?: string, folder?: record, linkedServiceName: any, parameters?: record, schema?: record, structure?: record, type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-datasets CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  datasetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-Match: string # ETag of the dataset entity.  Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # The Azure Data Factory nested object which identifies data within different data stores, such as tables, files, folders, and documents. — shape: {annotations?: list, description?: string, folder?: record, linkedServiceName: any, parameters?: record, schema?: record, structure?: record, type: string}
]: any -> record<properties: record<annotations: list<record>, description: string, folder: record<name: string>, linkedServiceName: record<parameters: record, referenceName: string, type: string>, parameters: record, schema: record, structure: record, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/datasets/($datasetName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a data flow debug session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/deleteDataFlowDebugSession
# operationId: DataFlowDebugSession_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-delete-data-flow-debug-session Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --sessionId: string # The ID of data flow debug session.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/deleteDataFlowDebugSession" $qp)
  let body = {sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute a data flow debug command.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/executeDataFlowDebugCommand
# operationId: DataFlowDebugSession_ExecuteCommand
# --commandPayload shape: {columns?: list, expression?: string, rowLimits?: int, streamName: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-execute-data-flow-debug-command ExecuteCommand" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --command: string@command-completer # The command type.
  --commandPayload: record # Structure of command payload. — shape: {columns?: list, expression?: string, rowLimits?: int, streamName: string}
  --sessionId: string # The ID of data flow debug session.
]: any -> record<data: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/executeDataFlowDebugCommand" $qp)
  let body = {command: $command, commandPayload: $commandPayload, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Data Plane access.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/getDataPlaneAccess
# operationId: Factories_GetDataPlaneAccess
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-get-data-plane-access GetDataPlaneAccess" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --accessResourcePath: string # The resource path to get access relative to factory. Currently only empty string is supported which corresponds to the factory resource.
  --expireTime: string # Expiration time for the token. Maximum duration for the token is eight hours and by default the token will expire in eight hours.
  --permissions: string # The string with permissions for Data Plane access. Currently only 'r' is supported which grants read only access.
  --profileName: string # The name of the profile. Currently only the default is supported. The default value is DefaultProfile.
  --startTime: string # Start time for the token. If not specified the current time will be used.
]: any -> record<accessToken: string, dataPlaneUrl: string, policy: record<accessResourcePath: string, expireTime: string, permissions: string, profileName: string, startTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/getDataPlaneAccess" $qp)
  let body = {accessResourcePath: $accessResourcePath, expireTime: $expireTime, permissions: $permissions, profileName: $profileName, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get exposure control feature for specific factory.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/getFeatureValue
# operationId: ExposureControl_GetFeatureValueByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-get-feature-value GetFeatureValueByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --featureName: string # The feature name.
  --featureType: string # The feature type.
]: any -> record<featureName: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/getFeatureValue" $qp)
  let body = {featureName: $featureName, featureType: $featureType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get GitHub Access Token.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/getGitHubAccessToken
# operationId: Factories_GetGitHubAccessToken
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-get-git-hub-access-token GetGitHubAccessToken" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  gitHubAccessCode: string # GitHub access code.
  gitHubAccessTokenBaseUrl: string # GitHub access token base URL.
  --gitHubClientId: string # GitHub application client ID.
]: any -> record<gitHubAccessToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/getGitHubAccessToken" $qp)
  let body = {gitHubAccessCode: $gitHubAccessCode, gitHubAccessTokenBaseUrl: $gitHubAccessTokenBaseUrl, gitHubClientId: $gitHubClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists integration runtimes.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes
# operationId: IntegrationRuntimes_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes ListByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration runtime.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration runtime.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-None-Match: string # ETag of the integration runtime entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<description: string, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an integration runtime.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_Update
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes Update" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --autoUpdate: string@autoUpdate-completer # The state of integration runtime auto update.
  --updateDelayOffset: string # The time offset (in hours) in the day, e.g., PT03H is 3 hours. The integration runtime auto update will happen on that time.
]: any -> record<properties: record<description: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)" $qp)
  let body = {autoUpdate: $autoUpdate, updateDelayOffset: $updateDelayOffset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates an integration runtime.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}
# operationId: IntegrationRuntimes_CreateOrUpdate
# --properties shape: {description?: string, type: "Managed"|"SelfHosted"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-Match: string # ETag of the integration runtime entity. Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # Azure Data Factory nested object which serves as a compute resource for activities. — shape: {description?: string, type: "Managed"|"SelfHosted"}
]: any -> record<properties: record<description: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the on-premises integration runtime connection information for encrypting the on-premises data source credentials.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/getConnectionInfo
# operationId: IntegrationRuntimes_GetConnectionInfo
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-get-connection-info GetConnectionInfo" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<hostServiceUri: string, identityCertThumbprint: string, isIdentityCertExprired: bool, publicKey: string, serviceToken: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/getConnectionInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a SSIS integration runtime object metadata by specified path. The return is pageable metadata list.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/getObjectMetadata
# operationId: IntegrationRuntimeObjectMetadata_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-get-object-metadata Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --metadataPath: string # Metadata path.
]: any -> record<nextLink: string, value: table<description: string, id: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/getObjectMetadata" $qp)
  let body = {metadataPath: $metadataPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets detailed status information for an integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/getStatus
# operationId: IntegrationRuntimes_GetStatus
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-get-status GetStatus" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<dataFactoryName: string, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/getStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a linked integration runtime entry in a shared integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/linkedIntegrationRuntime
# operationId: IntegrationRuntimes_CreateLinkedIntegrationRuntime
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-linked-integration-runtime CreateLinkedIntegrationRuntime" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --dataFactoryLocation: string # The location of the data factory that the linked integration runtime belongs to.
  --dataFactoryName: string # The name of the data factory that the linked integration runtime belongs to.
  --name: string # The name of the linked integration runtime.
  --body-subscriptionId: string # The ID of the subscription that the linked integration runtime belongs to.
]: any -> record<name: string, properties: record<dataFactoryName: string, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/linkedIntegrationRuntime" $qp)
  let body = {dataFactoryLocation: $dataFactoryLocation, dataFactoryName: $dataFactoryName, name: $name, subscriptionId: $body_subscriptionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the authentication keys for an integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/listAuthKeys
# operationId: IntegrationRuntimes_ListAuthKeys
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-list-auth-keys ListAuthKeys" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<authKey1: string, authKey2: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/listAuthKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the integration runtime monitoring data, which includes the monitor data for all the nodes under this integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/monitoringData
# operationId: IntegrationRuntimes_GetMonitoringData
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-monitoring-data GetMonitoringData" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, nodes: table<availableMemoryInMB: int, concurrentJobsLimit: int, concurrentJobsRunning: int, cpuUtilization: int, maxConcurrentJobs: int, nodeName: string, receivedBytes: float, sentBytes: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/monitoringData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a self-hosted integration runtime node.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}
# operationId: IntegrationRuntimeNodes_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/nodes/($nodeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a self-hosted integration runtime node.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}
# operationId: IntegrationRuntimeNodes_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<capabilities: record, concurrentJobsLimit: int, expiryTime: string, hostServiceUri: string, isActiveDispatcher: bool, lastConnectTime: string, lastEndUpdateTime: string, lastStartTime: string, lastStartUpdateTime: string, lastStopTime: string, lastUpdateResult: string, machineName: string, maxConcurrentJobs: int, nodeName: string, registerTime: string, status: string, version: string, versionStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/nodes/($nodeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a self-hosted integration runtime node.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}
# operationId: IntegrationRuntimeNodes_Update
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes Update" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --concurrentJobsLimit: int # The number of concurrent jobs permitted to run on the integration runtime node. Values between 1 and maxConcurrentJobs(inclusive) are allowed.
]: any -> record<capabilities: record, concurrentJobsLimit: int, expiryTime: string, hostServiceUri: string, isActiveDispatcher: bool, lastConnectTime: string, lastEndUpdateTime: string, lastStartTime: string, lastStartUpdateTime: string, lastStopTime: string, lastUpdateResult: string, machineName: string, maxConcurrentJobs: int, nodeName: string, registerTime: string, status: string, version: string, versionStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/nodes/($nodeName)" $qp)
  let body = {concurrentJobsLimit: $concurrentJobsLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the IP address of self-hosted integration runtime node.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/nodes/{nodeName}/ipAddress
# operationId: IntegrationRuntimeNodes_GetIpAddress
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-nodes-ip-address GetIpAddress" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<ipAddress: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/nodes/($nodeName)/ipAddress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh a SSIS integration runtime object metadata.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/refreshObjectMetadata
# operationId: IntegrationRuntimeObjectMetadata_Refresh
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-refresh-object-metadata Refresh" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: string, name: string, properties: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/refreshObjectMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerates the authentication key for an integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/regenerateAuthKey
# operationId: IntegrationRuntimes_RegenerateAuthKey
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-regenerate-auth-key RegenerateAuthKey" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --keyName: string@keyName-completer # The name of the authentication key to regenerate.
]: any -> record<authKey1: string, authKey2: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/regenerateAuthKey" $qp)
  let body = {keyName: $keyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove all linked integration runtimes under specific data factory in a self-hosted integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/removeLinks
# operationId: IntegrationRuntimes_RemoveLinks
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-remove-links RemoveLinks" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --body-factoryName: string # The data factory name for linked integration runtime.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/removeLinks" $qp)
  let body = {factoryName: $body_factoryName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts a ManagedReserved type integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/start
# operationId: IntegrationRuntimes_Start
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-start Start" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<dataFactoryName: string, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops a ManagedReserved type integration runtime.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/stop
# operationId: IntegrationRuntimes_Stop
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-stop Stop" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force the integration runtime to synchronize credentials across integration runtime nodes, and this will override the credentials across all worker nodes with those available on the dispatcher node. If you already have the latest credential backup file, you should manually import it (preferred) on any self-hosted integration runtime node than using this API directly.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/syncCredentials
# operationId: IntegrationRuntimes_SyncCredentials
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-sync-credentials SyncCredentials" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/syncCredentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upgrade self-hosted integration runtime to latest version if availability.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/integrationRuntimes/{integrationRuntimeName}/upgrade
# operationId: IntegrationRuntimes_Upgrade
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-integration-runtimes-upgrade Upgrade" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  integrationRuntimeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/integrationRuntimes/($integrationRuntimeName)/upgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists linked services.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices
# operationId: LinkedServices_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices ListByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/linkedservices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a linked service.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices/{linkedServiceName}
# operationId: LinkedServices_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  linkedServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/linkedservices/($linkedServiceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a linked service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices/{linkedServiceName}
# operationId: LinkedServices_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  linkedServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-None-Match: string # ETag of the linked service entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, connectVia: record<parameters: record, referenceName: string, type: string>, description: string, parameters: record, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/linkedservices/($linkedServiceName)" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a linked service.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/linkedservices/{linkedServiceName}
# operationId: LinkedServices_CreateOrUpdate
# --properties shape: {annotations?: list, connectVia?: any, description?: string, parameters?: record, type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-linkedservices CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  linkedServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-Match: string # ETag of the linkedService entity.  Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # The Azure Data Factory nested object which contains the information and credential which can be used to connect with related store or compute resource. — shape: {annotations?: list, connectVia?: any, description?: string, parameters?: record, type: string}
]: any -> record<properties: record<annotations: list<record>, connectVia: record<parameters: record, referenceName: string, type: string>, description: string, parameters: record, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/linkedservices/($linkedServiceName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a pipeline run by its run ID.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelineruns/{runId}
# operationId: PipelineRuns_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelineruns Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<durationInMs: int, invokedBy: record<id: string, invokedByType: string, name: string>, isLatest: bool, lastUpdated: string, message: string, parameters: record, pipelineName: string, runDimensions: record, runEnd: string, runGroupId: string, runId: string, runStart: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelineruns/($runId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a pipeline run by its run ID.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelineruns/{runId}/cancel
# operationId: PipelineRuns_Cancel
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelineruns-cancel Cancel" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isRecursive: oneof<nothing, bool> # If true, cancel all the Child pipelines that are triggered by the current pipeline.
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isRecursive" $isRecursive "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelineruns/($runId)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query activity runs based on input filter conditions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelineruns/{runId}/queryActivityruns
# operationId: ActivityRuns_QueryByPipelineRun
# --filters item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list}
# --orderBy item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelineruns-query-activityruns QueryByPipelineRun" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --continuationToken: string # The continuation token for getting the next page of results. Null for first page.
  --filters: list # List of filters. — item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list}
  lastUpdatedAfter: string # The time at or after which the run event was updated in 'ISO 8601' format. (format: date-time)
  lastUpdatedBefore: string # The time at or before which the run event was updated in 'ISO 8601' format. (format: date-time)
  --orderBy: list # List of OrderBy option. — item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
]: any -> record<continuationToken: string, value: table<activityName: string, activityRunEnd: string, activityRunId: string, activityRunStart: string, activityType: string, durationInMs: int, error: record, input: record, linkedServiceName: string, output: record, pipelineName: string, pipelineRunId: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelineruns/($runId)/queryActivityruns" $qp)
  let body = {continuationToken: $continuationToken, filters: $filters, lastUpdatedAfter: $lastUpdatedAfter, lastUpdatedBefore: $lastUpdatedBefore, orderBy: $orderBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists pipelines.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines
# operationId: Pipelines_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines ListByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pipeline.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}
# operationId: Pipelines_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  pipelineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelines/($pipelineName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a pipeline.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}
# operationId: Pipelines_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  pipelineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-None-Match: string # ETag of the pipeline entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<activities: list<record>, annotations: list<record>, concurrency: int, description: string, folder: record<name: string>, parameters: record, runDimensions: record, variables: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelines/($pipelineName)" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a pipeline.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}
# operationId: Pipelines_CreateOrUpdate
# --properties shape: {activities?: list, annotations?: list, concurrency?: int, description?: string, folder?: record, parameters?: record, runDimensions?: record, variables?: record}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  pipelineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-Match: string # ETag of the pipeline entity.  Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # A data factory pipeline. — shape: {activities?: list, annotations?: list, concurrency?: int, description?: string, folder?: record, parameters?: record, runDimensions?: record, variables?: record}
]: any -> record<properties: record<activities: list<record>, annotations: list<record>, concurrency: int, description: string, folder: record<name: string>, parameters: record, runDimensions: record, variables: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelines/($pipelineName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a run of a pipeline.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/pipelines/{pipelineName}/createRun
# operationId: Pipelines_CreateRun
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-pipelines-create-run CreateRun" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  pipelineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --referencePipelineRunId: string # The pipeline run identifier. If run ID is specified the parameters of the specified run will be used to create a new run.
  --isRecovery: oneof<nothing, bool> # Recovery mode flag. If recovery mode is set to true, the specified referenced pipeline run and the new run will be grouped under the same groupId.
  --startActivityName: string # In recovery mode, the rerun will start from this activity. If not specified, all activities will run.
  --body: record
]: any -> record<runId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "referencePipelineRunId" $referencePipelineRunId "scalar") (serialize-qp "isRecovery" $isRecovery "scalar") (serialize-qp "startActivityName" $startActivityName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/pipelines/($pipelineName)/createRun" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query all active data flow debug sessions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/queryDataFlowDebugSessions
# operationId: DataFlowDebugSession_QueryByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-query-data-flow-debug-sessions QueryByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<computeType: string, coreCount: int, dataFlowName: string, integrationRuntimeName: string, lastActivityTime: string, nodeCount: int, sessionId: string, startTime: string, timeToLiveInMinutes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/queryDataFlowDebugSessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query pipeline runs in the factory based on input filter conditions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/queryPipelineRuns
# operationId: PipelineRuns_QueryByFactory
# --filters item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list}
# --orderBy item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-query-pipeline-runs QueryByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --continuationToken: string # The continuation token for getting the next page of results. Null for first page.
  --filters: list # List of filters. — item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list}
  lastUpdatedAfter: string # The time at or after which the run event was updated in 'ISO 8601' format. (format: date-time)
  lastUpdatedBefore: string # The time at or before which the run event was updated in 'ISO 8601' format. (format: date-time)
  --orderBy: list # List of OrderBy option. — item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
]: any -> record<continuationToken: string, value: table<durationInMs: int, invokedBy: record, isLatest: bool, lastUpdated: string, message: string, parameters: record, pipelineName: string, runDimensions: record, runEnd: string, runGroupId: string, runId: string, runStart: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/queryPipelineRuns" $qp)
  let body = {continuationToken: $continuationToken, filters: $filters, lastUpdatedAfter: $lastUpdatedAfter, lastUpdatedBefore: $lastUpdatedBefore, orderBy: $orderBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query trigger runs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/queryTriggerRuns
# operationId: TriggerRuns_QueryByFactory
# --filters item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list}
# --orderBy item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-query-trigger-runs QueryByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --continuationToken: string # The continuation token for getting the next page of results. Null for first page.
  --filters: list # List of filters. — item shape: {operand: "PipelineName"|"Status"|"RunStart"|"RunEnd"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"ActivityType"|"TriggerName"|"TriggerRunTimestamp"|"RunGroupId"|"LatestOnly", operator: "Equals"|"NotEquals"|"In"|"NotIn", values: list}
  lastUpdatedAfter: string # The time at or after which the run event was updated in 'ISO 8601' format. (format: date-time)
  lastUpdatedBefore: string # The time at or before which the run event was updated in 'ISO 8601' format. (format: date-time)
  --orderBy: list # List of OrderBy option. — item shape: {order: "ASC"|"DESC", orderBy: "RunStart"|"RunEnd"|"PipelineName"|"Status"|"ActivityName"|"ActivityRunStart"|"ActivityRunEnd"|"TriggerName"|"TriggerRunTimestamp"}
]: any -> record<continuationToken: string, value: table<dependencyStatus: record, message: string, properties: record, runDimension: record, status: string, triggerName: string, triggerRunId: string, triggerRunTimestamp: string, triggerType: string, triggeredPipelines: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/queryTriggerRuns" $qp)
  let body = {continuationToken: $continuationToken, filters: $filters, lastUpdatedAfter: $lastUpdatedAfter, lastUpdatedBefore: $lastUpdatedBefore, orderBy: $orderBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists triggers.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers
# operationId: Triggers_ListByFactory
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers ListByFactory" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a trigger.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}
# operationId: Triggers_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers Delete" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a trigger.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}
# operationId: Triggers_Get
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers Get" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-None-Match: string # ETag of the trigger entity. Should only be specified for get. If the ETag matches the existing entity tag, or if * was provided, then no content will be returned.
]: nothing -> record<properties: record<annotations: list<record>, description: string, runtimeState: string, type: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a trigger.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}
# operationId: Triggers_CreateOrUpdate
# --properties shape: {annotations?: list, description?: string, runtimeState?: "Started"|"Stopped"|"Disabled", type: string}
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --If-Match: string # ETag of the trigger entity.  Should only be specified for update, for which it should match existing entity or can be * for unconditional update.
  properties: record # Azure data factory nested object which contains information about creating pipeline run — shape: {annotations?: list, description?: string, runtimeState?: "Started"|"Stopped"|"Disabled", type: string}
]: any -> record<properties: record<annotations: list<record>, description: string, runtimeState: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a trigger's event subscription status.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/getEventSubscriptionStatus
# operationId: Triggers_GetEventSubscriptionStatus
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-get-event-subscription-status GetEventSubscriptionStatus" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<status: string, triggerName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/getEventSubscriptionStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists rerun triggers by an original trigger name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers
# operationId: RerunTriggers_ListByTrigger
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers ListByTrigger" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/rerunTriggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a rerun trigger.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}
# operationId: RerunTriggers_Create
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers Create" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  rerunTriggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  endTime: string # The end time for the time period for which restatement is initiated. Only UTC time is currently supported. (format: date-time)
  maxConcurrency: int # The max number of parallel time windows (ready for execution) for which a rerun is triggered.
  startTime: string # The start time for the time period for which restatement is initiated. Only UTC time is currently supported. (format: date-time)
]: any -> record<properties: record<annotations: list<record>, description: string, runtimeState: string, type: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/rerunTriggers/($rerunTriggerName)" $qp)
  let body = {endTime: $endTime, maxConcurrency: $maxConcurrency, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}/cancel
# operationId: RerunTriggers_Cancel
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers-cancel Cancel" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  rerunTriggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/rerunTriggers/($rerunTriggerName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}/start
# operationId: RerunTriggers_Start
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers-start Start" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  rerunTriggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/rerunTriggers/($rerunTriggerName)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/rerunTriggers/{rerunTriggerName}/stop
# operationId: RerunTriggers_Stop
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-rerun-triggers-stop Stop" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  rerunTriggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/rerunTriggers/($rerunTriggerName)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/start
# operationId: Triggers_Start
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-start Start" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops a trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/stop
# operationId: Triggers_Stop
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-stop Stop" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe event trigger to events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/subscribeToEvents
# operationId: Triggers_SubscribeToEvents
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-subscribe-to-events SubscribeToEvents" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<status: string, triggerName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/subscribeToEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rerun single trigger instance by runId.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/triggerRuns/{runId}/rerun
# operationId: TriggerRuns_Rerun
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-trigger-runs-rerun Rerun" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  runId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/triggerRuns/($runId)/rerun" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe event trigger from events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataFactory/factories/{factoryName}/triggers/{triggerName}/unsubscribeFromEvents
# operationId: Triggers_UnsubscribeFromEvents
export def "subscriptions-resource-groups-providers-microsoft-data-factory-factories-triggers-unsubscribe-from-events UnsubscribeFromEvents" [
  subscriptionId: string
  resourceGroupName: string
  factoryName: string
  triggerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<status: string, triggerName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataFactory/factories/($factoryName)/triggers/($triggerName)/unsubscribeFromEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
