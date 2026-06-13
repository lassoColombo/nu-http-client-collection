# Auto-generated client for ResourceManagementClient v2019-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/resources/2019-08-01/swagger.json
# Auth: --token flag or $env.RESOURCEMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RESOURCEMANAGEMENTCLIENT_TOKEN | default "" }
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers ListAtTenantScope" } } | get name | first)
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

# Gets all resource providers for the tenant.
#
# GET /providers
# operationId: Providers_ListAtTenantScope
export def "providers ListAtTenantScope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. If null is passed returns all providers. (format: int32)
  --expand: string # The properties to include in the results. For example, use &$expand=metadata in the query string to retrieve resource provider metadata. To include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the deployments for a management group.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/
# operationId: Deployments_ListAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments ListAtManagementGroupScope" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a deployment from the deployment history.
#
# DELETE /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments DeleteAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployment.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_GetAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments GetAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the deployment exists.
#
# HEAD /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CheckExistenceAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments CheckExistenceAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deploys resources at management group scope.
#
# PUT /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CreateOrUpdateAtManagementGroupScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments CreateOrUpdateAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a currently running template deployment.
#
# POST /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments-cancel CancelAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the template used for specified deployment.
#
# POST /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# operationId: Deployments_ExportTemplateAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments-export-template ExportTemplateAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<template: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)/exportTemplate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments operations for a deployment.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations
# operationId: DeploymentOperations_ListAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments-operations ListAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, operationId: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployments operation.
#
# GET /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# operationId: DeploymentOperations_GetAtManagementGroupScope
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments-operations GetAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)/operations/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# operationId: Deployments_ValidateAtManagementGroupScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "providers-microsoft-management-management-groups-providers-microsoft-resources-deployments-validate ValidateAtManagementGroupScope" [
  groupId: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Management/managementGroups/($groupId)/providers/Microsoft.Resources/deployments/($deploymentName)/validate" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Calculate the hash of the given template.
#
# POST /providers/Microsoft.Resources/calculateTemplateHash
# operationId: Deployments_CalculateTemplateHash
export def "providers-microsoft-resources-calculate-template-hash CalculateTemplateHash" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --body: record
]: any -> record<minifiedTemplate: string, templateHash: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Resources/calculateTemplateHash" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the deployments at the tenant scope.
#
# GET /providers/Microsoft.Resources/deployments/
# operationId: Deployments_ListAtTenantScope
export def "providers-microsoft-resources-deployments ListAtTenantScope" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Resources/deployments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a deployment from the deployment history.
#
# DELETE /providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtTenantScope
export def "providers-microsoft-resources-deployments DeleteAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployment.
#
# GET /providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_GetAtTenantScope
export def "providers-microsoft-resources-deployments GetAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the deployment exists.
#
# HEAD /providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CheckExistenceAtTenantScope
export def "providers-microsoft-resources-deployments CheckExistenceAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deploys resources at tenant scope.
#
# PUT /providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CreateOrUpdateAtTenantScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "providers-microsoft-resources-deployments CreateOrUpdateAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a currently running template deployment.
#
# POST /providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtTenantScope
export def "providers-microsoft-resources-deployments-cancel CancelAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the template used for specified deployment.
#
# POST /providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# operationId: Deployments_ExportTemplateAtTenantScope
export def "providers-microsoft-resources-deployments-export-template ExportTemplateAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<template: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)/exportTemplate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments operations for a deployment.
#
# GET /providers/Microsoft.Resources/deployments/{deploymentName}/operations
# operationId: DeploymentOperations_ListAtTenantScope
export def "providers-microsoft-resources-deployments-operations ListAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, operationId: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployments operation.
#
# GET /providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# operationId: DeploymentOperations_GetAtTenantScope
export def "providers-microsoft-resources-deployments-operations GetAtTenantScope" [
  deploymentName: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)/operations/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /providers/Microsoft.Resources/deployments/{deploymentName}/validate
# operationId: Deployments_ValidateAtTenantScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "providers-microsoft-resources-deployments-validate ValidateAtTenantScope" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/Microsoft.Resources/deployments/($deploymentName)/validate" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all of the available Microsoft.Resources REST API operations.
#
# GET /providers/Microsoft.Resources/operations
# operationId: Operations_List
export def "providers-microsoft-resources-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Resources/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified resource provider at the tenant level.
#
# GET /providers/{resourceProviderNamespace}
# operationId: Providers_GetAtTenantScope
export def "providers GetAtTenantScope" [
  resourceProviderNamespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The $expand query parameter. For example, to include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($resourceProviderNamespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all resource providers for a subscription.
#
# GET /subscriptions/{subscriptionId}/providers
# operationId: Providers_List
export def "subscriptions-providers List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. If null is passed returns all deployments. (format: int32)
  --expand: string # The properties to include in the results. For example, use &$expand=metadata in the query string to retrieve resource provider metadata. To include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the deployments for a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/
# operationId: Deployments_ListAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments ListAtSubscriptionScope" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a deployment from the deployment history.
#
# DELETE /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments DeleteAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployment.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_GetAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments GetAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the deployment exists.
#
# HEAD /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CheckExistenceAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments CheckExistenceAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deploys resources at subscription scope.
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CreateOrUpdateAtSubscriptionScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "subscriptions-providers-microsoft-resources-deployments CreateOrUpdateAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a currently running template deployment.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments-cancel CancelAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the template used for specified deployment.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# operationId: Deployments_ExportTemplateAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments-export-template ExportTemplateAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<template: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)/exportTemplate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments operations for a deployment.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations
# operationId: DeploymentOperations_ListAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments-operations ListAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, operationId: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployments operation.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# operationId: DeploymentOperations_GetAtSubscriptionScope
export def "subscriptions-providers-microsoft-resources-deployments-operations GetAtSubscriptionScope" [
  deploymentName: string
  operationId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)/operations/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# operationId: Deployments_ValidateAtSubscriptionScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "subscriptions-providers-microsoft-resources-deployments-validate ValidateAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)/validate" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns changes that will be made by the deployment if executed at the scope of the subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}/whatIf
# operationId: Deployments_WhatIfAtSubscriptionScope
# --properties shape: {whatIfSettings?: any, debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "subscriptions-providers-microsoft-resources-deployments-what-if WhatIfAtSubscriptionScope" [
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment What-if properties. — shape: {whatIfSettings?: any, debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<changes: list<record>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Resources/deployments/($deploymentName)/whatIf" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the specified resource provider.
#
# GET /subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}
# operationId: Providers_Get
export def "subscriptions-providers Get" [
  resourceProviderNamespace: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The $expand query parameter. For example, to include property aliases in response, use $expand=resourceTypes/aliases.
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/($resourceProviderNamespace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Registers a subscription with a resource provider.
#
# POST /subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/register
# operationId: Providers_Register
export def "subscriptions-providers-register Register" [
  resourceProviderNamespace: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/($resourceProviderNamespace)/register" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unregisters a subscription from a resource provider.
#
# POST /subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/unregister
# operationId: Providers_Unregister
export def "subscriptions-providers-unregister Unregister" [
  resourceProviderNamespace: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, namespace: string, registrationPolicy: string, registrationState: string, resourceTypes: table<aliases: list, apiVersions: list, capabilities: string, locations: list, properties: record, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/($resourceProviderNamespace)/unregister" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the resources for a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/resources
# operationId: Resources_ListByResourceGroup
export def "subscriptions-resource-groups-resources ListByResourceGroup" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation.<br><br>The properties you can use for eq (equals) or ne (not equals) are: location, resourceType, name, resourceGroup, identity, identity/principalId, plan, plan/publisher, plan/product, plan/name, plan/version, and plan/promotionCode.<br><br>For example, to filter by a resource type, use: $filter=resourceType eq 'Microsoft.Network/virtualNetworks'<br><br>You can use substringof(value, property) in the filter. The properties you can use for substring are: name and resourceGroup.<br><br>For example, to get all resources with 'demo' anywhere in the name, use: $filter=substringof('demo', name)<br><br>You can link more than one substringof together by adding and/or operators.<br><br>You can filter by tag names and values. For example, to filter for a tag name and value, use $filter=tagName eq 'tag1' and tagValue eq 'Value1'. When you filter by a tag name and value, the tags for each resource are not returned in the results.<br><br>You can use some properties together when filtering. The combinations you can use are: substringof and/or resourceType, plan and plan/publisher and plan/name, identity and identity/principalId.
  --expand: string # The $expand query parameter. You can expand createdTime and changedTime. For example, to expand both properties, use $expand=changedTime,createdTime
  --top: int # The number of results to return. If null is passed, returns all resources. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<identity: record, kind: string, managedBy: string, plan: record, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Moves resources from one resource group to another resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{sourceResourceGroupName}/moveResources
# operationId: Resources_MoveResources
export def "subscriptions-resource-groups-move-resources MoveResources" [
  sourceResourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --resources: list # The IDs of the resources.
  --targetResourceGroup: string # The target resource group.
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($sourceResourceGroupName)/moveResources" $qp)
  let body = {resources: $resources, targetResourceGroup: $targetResourceGroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validates whether resources can be moved from one resource group to another resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{sourceResourceGroupName}/validateMoveResources
# operationId: Resources_ValidateMoveResources
export def "subscriptions-resource-groups-validate-move-resources ValidateMoveResources" [
  sourceResourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --resources: list # The IDs of the resources.
  --targetResourceGroup: string # The target resource group.
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($sourceResourceGroupName)/validateMoveResources" $qp)
  let body = {resources: $resources, targetResourceGroup: $targetResourceGroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all the resource groups for a subscription.
#
# GET /subscriptions/{subscriptionId}/resourcegroups
# operationId: ResourceGroups_List
export def "subscriptions-resourcegroups List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation.<br><br>You can filter by tag names and values. For example, to filter for a tag name and value, use $filter=tagName eq 'tag1' and tagValue eq 'Value1'
  --top: int # The number of results to return. If null is passed, returns all resource groups. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, managedBy: string, name: string, properties: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a resource group.
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# operationId: ResourceGroups_Delete
export def "subscriptions-resourcegroups Delete" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a resource group.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# operationId: ResourceGroups_Get
export def "subscriptions-resourcegroups Get" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether a resource group exists.
#
# HEAD /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# operationId: ResourceGroups_CheckExistence
export def "subscriptions-resourcegroups CheckExistence" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a resource group.
#
# PATCH /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# operationId: ResourceGroups_Update
export def "subscriptions-resourcegroups Update" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --managedBy: string # The ID of the resource that manages this resource group.
  --name: string # The name of the resource group.
  --properties: any # The resource group properties.
  --tags: record # The tags attached to the resource group.
]: any -> record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)" $qp)
  let body = {managedBy: $managedBy, name: $name, properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a resource group.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}
# operationId: ResourceGroups_CreateOrUpdate
export def "subscriptions-resourcegroups CreateOrUpdate" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  location: string # The location of the resource group. It cannot be changed after the resource group has been created. It must be one of the supported Azure locations.
  --managedBy: string # The ID of the resource that manages this resource group.
  --properties: any # The resource group properties.
  --tags: record # The tags attached to the resource group.
]: any -> record<id: string, location: string, managedBy: string, name: string, properties: record<provisioningState: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)" $qp)
  let body = {location: $location, managedBy: $managedBy, properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all deployments operations for a deployment.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/deployments/{deploymentName}/operations
# operationId: DeploymentOperations_List
export def "subscriptions-resourcegroups-deployments-operations List" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, operationId: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/deployments/($deploymentName)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployments operation.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/deployments/{deploymentName}/operations/{operationId}
# operationId: DeploymentOperations_Get
export def "subscriptions-resourcegroups-deployments-operations Get" [
  resourceGroupName: string
  deploymentName: string
  operationId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/deployments/($deploymentName)/operations/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Captures the specified resource group as a template.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/exportTemplate
# operationId: ResourceGroups_ExportTemplate
export def "subscriptions-resourcegroups-export-template ExportTemplate" [
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
  --api-version: string # The API version to use for this operation.
  --options: string # The export template options. A CSV-formatted list containing zero or more of the following: 'IncludeParameterDefaultValue', 'IncludeComments', 'SkipResourceNameParameterization', 'SkipAllParameterization'
  --resources: list # The IDs of the resources to filter the export by. To export all resources, supply an array with single entry '*'.
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, template: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/exportTemplate" $qp)
  let body = {options: $options, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the deployments for a resource group.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/
# operationId: Deployments_ListByResourceGroup
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments ListByResourceGroup" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a deployment from the deployment history.
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_Delete
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments Delete" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployment.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_Get
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments Get" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the deployment exists.
#
# HEAD /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CheckExistence
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments CheckExistence" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deploys resources to a resource group.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CreateOrUpdate
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments CreateOrUpdate" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a currently running template deployment.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_Cancel
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments-cancel Cancel" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the template used for specified deployment.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# operationId: Deployments_ExportTemplate
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments-export-template ExportTemplate" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<template: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)/exportTemplate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# operationId: Deployments_Validate
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments-validate Validate" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)/validate" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns changes that will be made by the deployment if executed at the scope of the resource group.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}/whatIf
# operationId: Deployments_WhatIf
# --properties shape: {whatIfSettings?: any, debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "subscriptions-resourcegroups-providers-microsoft-resources-deployments-what-if WhatIf" [
  resourceGroupName: string
  deploymentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment What-if properties. — shape: {whatIfSettings?: any, debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<changes: list<record>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Resources/deployments/($deploymentName)/whatIf" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a resource.
#
# DELETE /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# operationId: Resources_Delete
export def "subscriptions-resourcegroups-providers Delete" [
  resourceGroupName: string
  resourceProviderNamespace: string
  parentResourcePath: string
  resourceType: string
  resourceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/($resourceProviderNamespace)/($parentResourcePath)/($resourceType)/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a resource.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# operationId: Resources_Get
export def "subscriptions-resourcegroups-providers Get" [
  resourceGroupName: string
  resourceProviderNamespace: string
  parentResourcePath: string
  resourceType: string
  resourceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/($resourceProviderNamespace)/($parentResourcePath)/($resourceType)/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether a resource exists.
#
# HEAD /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# operationId: Resources_CheckExistence
export def "subscriptions-resourcegroups-providers CheckExistence" [
  resourceGroupName: string
  resourceProviderNamespace: string
  parentResourcePath: string
  resourceType: string
  resourceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/($resourceProviderNamespace)/($parentResourcePath)/($resourceType)/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a resource.
#
# PATCH /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# operationId: Resources_Update
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --plan shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
# --sku shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
export def "subscriptions-resourcegroups-providers Update" [
  resourceGroupName: string
  resourceProviderNamespace: string
  parentResourcePath: string
  resourceType: string
  resourceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managedBy: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/($resourceProviderNamespace)/($parentResourcePath)/($resourceType)/($resourceName)" $qp)
  let body = {identity: $identity, kind: $kind, managedBy: $managedBy, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a resource.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{parentResourcePath}/{resourceType}/{resourceName}
# operationId: Resources_CreateOrUpdate
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --plan shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
# --sku shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
export def "subscriptions-resourcegroups-providers CreateOrUpdate" [
  resourceGroupName: string
  resourceProviderNamespace: string
  parentResourcePath: string
  resourceType: string
  resourceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managedBy: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/($resourceProviderNamespace)/($parentResourcePath)/($resourceType)/($resourceName)" $qp)
  let body = {identity: $identity, kind: $kind, managedBy: $managedBy, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the resources in a subscription.
#
# GET /subscriptions/{subscriptionId}/resources
# operationId: Resources_List
export def "subscriptions-resources List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation.<br><br>The properties you can use for eq (equals) or ne (not equals) are: location, resourceType, name, resourceGroup, identity, identity/principalId, plan, plan/publisher, plan/product, plan/name, plan/version, and plan/promotionCode.<br><br>For example, to filter by a resource type, use: $filter=resourceType eq 'Microsoft.Network/virtualNetworks'<br><br>You can use substringof(value, property) in the filter. The properties you can use for substring are: name and resourceGroup.<br><br>For example, to get all resources with 'demo' anywhere in the name, use: $filter=substringof('demo', name)<br><br>You can link more than one substringof together by adding and/or operators.<br><br>You can filter by tag names and values. For example, to filter for a tag name and value, use $filter=tagName eq 'tag1' and tagValue eq 'Value1'. When you filter by a tag name and value, the tags for each resource are not returned in the results.<br><br>You can use some properties together when filtering. The combinations you can use are: substringof and/or resourceType, plan and plan/publisher and plan/name, identity and identity/principalId.
  --expand: string # The $expand query parameter. You can expand createdTime and changedTime. For example, to expand both properties, use $expand=changedTime,createdTime
  --top: int # The number of results to return. If null is passed, returns all resource groups. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<identity: record, kind: string, managedBy: string, plan: record, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the names and values of all resource tags that are defined in a subscription.
#
# GET /subscriptions/{subscriptionId}/tagNames
# operationId: Tags_List
export def "subscriptions-tag-names List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<count: record, id: string, tagName: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/tagNames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a tag from the subscription.
#
# DELETE /subscriptions/{subscriptionId}/tagNames/{tagName}
# operationId: Tags_Delete
export def "subscriptions-tag-names Delete" [
  tagName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/tagNames/($tagName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a tag in the subscription.
#
# PUT /subscriptions/{subscriptionId}/tagNames/{tagName}
# operationId: Tags_CreateOrUpdate
export def "subscriptions-tag-names CreateOrUpdate" [
  tagName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<count: record<type: string, value: int>, id: string, tagName: string, values: table<count: record, id: string, tagValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/tagNames/($tagName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a tag value.
#
# DELETE /subscriptions/{subscriptionId}/tagNames/{tagName}/tagValues/{tagValue}
# operationId: Tags_DeleteValue
export def "subscriptions-tag-names-tag-values DeleteValue" [
  tagName: string
  tagValue: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/tagNames/($tagName)/tagValues/($tagValue)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a tag value. The name of the tag must already exist.
#
# PUT /subscriptions/{subscriptionId}/tagNames/{tagName}/tagValues/{tagValue}
# operationId: Tags_CreateOrUpdateValue
export def "subscriptions-tag-names-tag-values CreateOrUpdateValue" [
  tagName: string
  tagValue: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<count: record<type: string, value: int>, id: string, tagValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/tagNames/($tagName)/tagValues/($tagValue)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a resource by ID.
#
# DELETE /{resourceId}
# operationId: Resources_DeleteById
export def "resources DeleteById" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a resource by ID.
#
# GET /{resourceId}
# operationId: Resources_GetById
export def "resources GetById" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks by ID whether a resource exists.
#
# HEAD /{resourceId}
# operationId: Resources_CheckExistenceById
export def "resources CheckExistenceById" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a resource by ID.
#
# PATCH /{resourceId}
# operationId: Resources_UpdateById
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --plan shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
# --sku shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
export def "resources UpdateById" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managedBy: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)" $qp)
  let body = {identity: $identity, kind: $kind, managedBy: $managedBy, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a resource by ID.
#
# PUT /{resourceId}
# operationId: Resources_CreateOrUpdateById
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --plan shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
# --sku shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
export def "resources CreateOrUpdateById" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --kind: string # The kind of the resource.
  --managedBy: string # ID of the resource that manages this resource.
  --plan: any # Plan for the resource. — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record # The resource properties.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name?: string, size?: string, tier?: string}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, kind: string, managedBy: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)" $qp)
  let body = {identity: $identity, kind: $kind, managedBy: $managedBy, plan: $plan, properties: $properties, sku: $sku, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the deployments at the given scope.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/
# operationId: Deployments_ListAtScope
export def "providers-microsoft-resources-deployments ListAtScope" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the operation. For example, you can use $filter=provisioningState eq '{state}'.
  --top: int # The number of results to get. If null is passed, returns all deployments. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a deployment from the deployment history.
#
# DELETE /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_DeleteAtScope
export def "providers-microsoft-resources-deployments DeleteAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployment.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_GetAtScope
export def "providers-microsoft-resources-deployments GetAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the deployment exists.
#
# HEAD /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CheckExistenceAtScope
export def "providers-microsoft-resources-deployments CheckExistenceAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deploys resources at a given scope.
#
# PUT /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}
# operationId: Deployments_CreateOrUpdateAtScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "providers-microsoft-resources-deployments CreateOrUpdateAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<id: string, location: string, name: string, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a currently running template deployment.
#
# POST /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/cancel
# operationId: Deployments_CancelAtScope
export def "providers-microsoft-resources-deployments-cancel CancelAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the template used for specified deployment.
#
# POST /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/exportTemplate
# operationId: Deployments_ExportTemplateAtScope
export def "providers-microsoft-resources-deployments-export-template ExportTemplateAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<template: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)/exportTemplate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments operations for a deployment.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/operations
# operationId: DeploymentOperations_ListAtScope
export def "providers-microsoft-resources-deployments-operations ListAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of results to return. (format: int32)
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<id: string, operationId: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a deployments operation.
#
# GET /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/operations/{operationId}
# operationId: DeploymentOperations_GetAtScope
export def "providers-microsoft-resources-deployments-operations GetAtScope" [
  scope: string
  deploymentName: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<id: string, operationId: string, properties: record<duration: string, provisioningState: string, request: record<content: record>, response: record<content: record>, serviceRequestId: string, statusCode: string, statusMessage: record, targetResource: record<id: string, resourceName: string, resourceType: string>, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)/operations/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validates whether the specified template is syntactically correct and will be accepted by Azure Resource Manager..
#
# POST /{scope}/providers/Microsoft.Resources/deployments/{deploymentName}/validate
# operationId: Deployments_ValidateAtScope
# --properties shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
export def "providers-microsoft-resources-deployments-validate ValidateAtScope" [
  scope: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --location: string # The location to store the deployment data.
  properties: any # Deployment properties. — shape: {debugSetting?: any, mode: "Incremental"|"Complete", onErrorDeployment?: any, parameters?: record, parametersLink?: any, template?: record, templateLink?: any}
]: any -> record<error: record<additionalInfo: list<record>, code: string, details: list<any>, message: string, target: string>, properties: record<correlationId: string, debugSetting: record<detailLevel: string>, dependencies: list<record>, duration: string, mode: string, onErrorDeployment: record<deploymentName: string, provisioningState: string, type: string>, outputs: record, parameters: record, parametersLink: record<contentVersion: string, uri: string>, providers: list<record>, provisioningState: string, template: record, templateLink: record<contentVersion: string, uri: string>, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.Resources/deployments/($deploymentName)/validate" $qp)
  let body = {location: $location, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
