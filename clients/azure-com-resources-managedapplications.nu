# Auto-generated client for ApplicationClient v2018-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/resources-managedapplications/2018-06-01/swagger.json
# Auth: --token flag or $env.APPLICATIONCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APPLICATIONCLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-solutions-applications list-by" } } | get name | first)
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

# Gets all the applications within a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Solutions/applications
# operationId: Applications_ListBySubscription
export def "subscriptions-providers-microsoft-solutions-applications list-by" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<kind: string, plan: record, properties: record, identity: record, managedBy: string, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Solutions/applications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the managed application definitions in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applicationDefinitions
# operationId: ApplicationDefinitions_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-solutions-application-definitions list-by" [
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
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<properties: record, identity: record, managedBy: string, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applicationDefinitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the managed application definition.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applicationDefinitions/{applicationDefinitionName}
# operationId: ApplicationDefinitions_Delete
export def "subscriptions-resource-groups-providers-microsoft-solutions-application-definitions delete" [
  subscription_id: string
  resource_group_name: string
  application_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<errorCode: string, errorMessage: string, httpStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_definition_name: $application_definition_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applicationDefinitions/{application_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the managed application definition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applicationDefinitions/{applicationDefinitionName}
# operationId: ApplicationDefinitions_Get
export def "subscriptions-resource-groups-providers-microsoft-solutions-application-definitions get" [
  subscription_id: string
  resource_group_name: string
  application_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<artifacts: list<record>, authorizations: list<record>, createUiDefinition: record, description: string, displayName: string, isEnabled: string, lockLevel: string, mainTemplate: record, packageFileUri: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_definition_name: $application_definition_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applicationDefinitions/{application_definition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new managed application definition.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applicationDefinitions/{applicationDefinitionName}
# operationId: ApplicationDefinitions_CreateOrUpdate
# --properties shape: {artifacts?: list, authorizations: list, createUiDefinition?: record, description?: string, displayName?: string, isEnabled?: string, lockLevel: "CanNotDelete"|"ReadOnly"|"None", mainTemplate?: record, packageFileUri?: string}
# --identity shape: {type?: "SystemAssigned"}
# --sku shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-solutions-application-definitions create-or-update" [
  subscription_id: string
  resource_group_name: string
  application_definition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  properties: any # The managed application definition properties. — shape: {artifacts?: list, authorizations: list, createUiDefinition?: record, description?: string, displayName?: string, isEnabled?: string, lockLevel: "CanNotDelete"|"ReadOnly"|"None", mainTemplate?: record, packageFileUri?: string}
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"}
  --managed-by: string # ID of the resource that manages this resource.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
]: any -> record<properties: record<artifacts: list<record>, authorizations: list<record>, createUiDefinition: record, description: string, displayName: string, isEnabled: string, lockLevel: string, mainTemplate: record, packageFileUri: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_definition_name: $application_definition_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applicationDefinitions/{application_definition_name}") $qp)
  let body = {"properties": $properties, "identity": $identity, "managedBy": $managed_by, "sku": $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all the applications within a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applications
# operationId: Applications_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-solutions-applications list-by" [
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
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<kind: string, plan: record, properties: record, identity: record, managedBy: string, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the managed application.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applications/{applicationName}
# operationId: Applications_Delete
export def "subscriptions-resource-groups-providers-microsoft-solutions-applications delete" [
  subscription_id: string
  resource_group_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<errorCode: string, errorMessage: string, httpStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_name: $application_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applications/{application_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the managed application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applications/{applicationName}
# operationId: Applications_Get
export def "subscriptions-resource-groups-providers-microsoft-solutions-applications get" [
  subscription_id: string
  resource_group_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<kind: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record<applicationDefinitionId: string, managedResourceGroupId: string, outputs: record, parameters: record, provisioningState: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_name: $application_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applications/{application_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing managed application. The only value that can be updated via PATCH currently is the tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applications/{applicationName}
# operationId: Applications_Update
# --plan shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
# --properties shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
# --identity shape: {type?: "SystemAssigned"}
# --sku shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-solutions-applications update" [
  subscription_id: string
  resource_group_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  kind: string # The kind of the managed application. Allowed values are MarketPlace and ServiceCatalog.
  --plan: any # Plan for the managed application. — shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
  properties: any # The managed application properties. — shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"}
  --managed-by: string # ID of the resource that manages this resource.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
]: any -> record<kind: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record<applicationDefinitionId: string, managedResourceGroupId: string, outputs: record, parameters: record, provisioningState: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_name: $application_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applications/{application_name}") $qp)
  let body = {"kind": $kind, "plan": $plan, "properties": $properties, "identity": $identity, "managedBy": $managed_by, "sku": $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new managed application.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Solutions/applications/{applicationName}
# operationId: Applications_CreateOrUpdate
# --plan shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
# --properties shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
# --identity shape: {type?: "SystemAssigned"}
# --sku shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-solutions-applications create-or-update" [
  subscription_id: string
  resource_group_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  kind: string # The kind of the managed application. Allowed values are MarketPlace and ServiceCatalog.
  --plan: any # Plan for the managed application. — shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
  properties: any # The managed application properties. — shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"}
  --managed-by: string # ID of the resource that manages this resource.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
]: any -> record<kind: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record<applicationDefinitionId: string, managedResourceGroupId: string, outputs: record, parameters: record, provisioningState: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_name: $application_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Solutions/applications/{application_name}") $qp)
  let body = {"kind": $kind, "plan": $plan, "properties": $properties, "identity": $identity, "managedBy": $managed_by, "sku": $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the managed application.
#
# DELETE /{applicationId}
# operationId: Applications_DeleteById
export def "applications delete-by" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<errorCode: string, errorMessage: string, httpStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: $application_id} | format pattern "/{application_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the managed application.
#
# GET /{applicationId}
# operationId: Applications_GetById
export def "applications get-by" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<kind: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record<applicationDefinitionId: string, managedResourceGroupId: string, outputs: record, parameters: record, provisioningState: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: $application_id} | format pattern "/{application_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing managed application. The only value that can be updated via PATCH currently is the tags.
#
# PATCH /{applicationId}
# operationId: Applications_UpdateById
# --plan shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
# --properties shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
# --identity shape: {type?: "SystemAssigned"}
# --sku shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
export def "applications update-by" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  kind: string # The kind of the managed application. Allowed values are MarketPlace and ServiceCatalog.
  --plan: any # Plan for the managed application. — shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
  properties: any # The managed application properties. — shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"}
  --managed-by: string # ID of the resource that manages this resource.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
]: any -> record<kind: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record<applicationDefinitionId: string, managedResourceGroupId: string, outputs: record, parameters: record, provisioningState: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: $application_id} | format pattern "/{application_id}") $qp)
  let body = {"kind": $kind, "plan": $plan, "properties": $properties, "identity": $identity, "managedBy": $managed_by, "sku": $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new managed application.
#
# PUT /{applicationId}
# operationId: Applications_CreateOrUpdateById
# --plan shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
# --properties shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
# --identity shape: {type?: "SystemAssigned"}
# --sku shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
export def "applications create-or-update" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  kind: string # The kind of the managed application. Allowed values are MarketPlace and ServiceCatalog.
  --plan: any # Plan for the managed application. — shape: {name: string, product: string, promotionCode?: string, publisher: string, version: string}
  properties: any # The managed application properties. — shape: {applicationDefinitionId?: string, managedResourceGroupId: string, parameters?: record}
  --identity: any # Identity for the resource. — shape: {type?: "SystemAssigned"}
  --managed-by: string # ID of the resource that manages this resource.
  --sku: any # SKU for the resource. — shape: {capacity?: int, family?: string, model?: string, name: string, size?: string, tier?: string}
]: any -> record<kind: string, plan: record<name: string, product: string, promotionCode: string, publisher: string, version: string>, properties: record<applicationDefinitionId: string, managedResourceGroupId: string, outputs: record, parameters: record, provisioningState: string>, identity: record<principalId: string, tenantId: string, type: string>, managedBy: string, sku: record<capacity: int, family: string, model: string, name: string, size: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: $application_id} | format pattern "/{application_id}") $qp)
  let body = {"kind": $kind, "plan": $plan, "properties": $properties, "identity": $identity, "managedBy": $managed_by, "sku": $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
