# Auto-generated client for ApiManagementClient v2019-01-01
# Source: https://api.apis.guru/v2/specs/azure.com/apimanagement-apimdeployment/2019-01-01/swagger.json
# Auth: --token flag or $env.APIMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APIMANAGEMENTCLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-api-management-operations list" } } | get name | first)
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

# Lists all of the available REST API operations of the Microsoft.ApiManagement provider.
#
# GET /providers/Microsoft.ApiManagement/operations
# operationId: ApiManagementOperations_List
export def "providers-microsoft-api-management-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ApiManagement/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks availability and correctness of a name for an API Management service.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.ApiManagement/checkNameAvailability
# operationId: ApiManagementService_CheckNameAvailability
export def "subscriptions-providers-microsoft-api-management-check-name-availability check" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  name: string # The name to check for availability.
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.ApiManagement/checkNameAvailability") $qp)
  let body = {"name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all API Management services within an Azure subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.ApiManagement/service
# operationId: ApiManagementService_List
export def "subscriptions-providers-microsoft-api-management-service list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<etag: string, identity: record, location: string, properties: record, sku: record, id: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.ApiManagement/service") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all API Management services within a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service
# operationId: ApiManagementService_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-api-management-service list-by" [
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
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<etag: string, identity: record, location: string, properties: record, sku: record, id: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing API Management service.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}
# operationId: ApiManagementService_Delete
export def "subscriptions-resource-groups-providers-microsoft-api-management-service delete" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string>, location: string, properties: record<publisherEmail: string, publisherName: string, additionalLocations: list<record>, certificates: list<record>, createdAtUtc: string, customProperties: record, enableClientCertificate: bool, gatewayRegionalUrl: string, gatewayUrl: string, hostnameConfigurations: list<record>, managementApiUrl: string, notificationSenderEmail: string, portalUrl: string, privateIPAddresses: list<string>, provisioningState: string, publicIPAddresses: list<string>, scmUrl: string, targetProvisioningState: string, virtualNetworkConfiguration: record<subnetResourceId: string, subnetname: string, vnetid: string>, virtualNetworkType: string>, sku: record<capacity: int, name: string>, id: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an API Management service resource description.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}
# operationId: ApiManagementService_Get
export def "subscriptions-resource-groups-providers-microsoft-api-management-service get" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string>, location: string, properties: record<publisherEmail: string, publisherName: string, additionalLocations: list<record>, certificates: list<record>, createdAtUtc: string, customProperties: record, enableClientCertificate: bool, gatewayRegionalUrl: string, gatewayUrl: string, hostnameConfigurations: list<record>, managementApiUrl: string, notificationSenderEmail: string, portalUrl: string, privateIPAddresses: list<string>, provisioningState: string, publicIPAddresses: list<string>, scmUrl: string, targetProvisioningState: string, virtualNetworkConfiguration: record<subnetResourceId: string, subnetname: string, vnetid: string>, virtualNetworkType: string>, sku: record<capacity: int, name: string>, id: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing API Management service.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}
# operationId: ApiManagementService_Update
# --identity shape: {type: "SystemAssigned"}
# --properties shape: {publisherEmail?: string, publisherName?: string, additionalLocations?: list, certificates?: list, customProperties?: record, enableClientCertificate?: bool, hostnameConfigurations?: list, notificationSenderEmail?: string, virtualNetworkConfiguration?: any, virtualNetworkType?: "None"|"External"|"Internal"}
# --sku shape: {capacity?: int, name: "Developer"|"Standard"|"Premium"|"Basic"|"Consumption"}
export def "subscriptions-resource-groups-providers-microsoft-api-management-service update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  --identity: any # Identity properties of the Api Management service resource. — shape: {type: "SystemAssigned"}
  --properties: any # Properties of an API Management service resource description. — shape: {publisherEmail?: string, publisherName?: string, additionalLocations?: list, certificates?: list, customProperties?: record, enableClientCertificate?: bool, hostnameConfigurations?: list, notificationSenderEmail?: string, virtualNetworkConfiguration?: any, virtualNetworkType?: "None"|"External"|"Internal"}
  --sku: any # API Management service resource SKU properties. — shape: {capacity?: int, name: "Developer"|"Standard"|"Premium"|"Basic"|"Consumption"}
  --tags: record # Resource tags.
]: any -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string>, location: string, properties: record<publisherEmail: string, publisherName: string, additionalLocations: list<record>, certificates: list<record>, createdAtUtc: string, customProperties: record, enableClientCertificate: bool, gatewayRegionalUrl: string, gatewayUrl: string, hostnameConfigurations: list<record>, managementApiUrl: string, notificationSenderEmail: string, portalUrl: string, privateIPAddresses: list<string>, provisioningState: string, publicIPAddresses: list<string>, scmUrl: string, targetProvisioningState: string, virtualNetworkConfiguration: record<subnetResourceId: string, subnetname: string, vnetid: string>, virtualNetworkType: string>, sku: record<capacity: int, name: string>, id: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}") $qp)
  let body = {"identity": $identity, "properties": $properties, "sku": $sku, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates an API Management service. This is long running operation and could take several minutes to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}
# operationId: ApiManagementService_CreateOrUpdate
# --identity shape: {type: "SystemAssigned"}
# --properties shape: {publisherEmail: string, publisherName: string, additionalLocations?: list, certificates?: list, customProperties?: record, enableClientCertificate?: bool, hostnameConfigurations?: list, notificationSenderEmail?: string, virtualNetworkConfiguration?: any, virtualNetworkType?: "None"|"External"|"Internal"}
# --sku shape: {capacity?: int, name: "Developer"|"Standard"|"Premium"|"Basic"|"Consumption"}
export def "subscriptions-resource-groups-providers-microsoft-api-management-service create-or-update" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  --identity: any # Identity properties of the Api Management service resource. — shape: {type: "SystemAssigned"}
  location: string # Resource location.
  properties: any # Properties of an API Management service resource description. — shape: {publisherEmail: string, publisherName: string, additionalLocations?: list, certificates?: list, customProperties?: record, enableClientCertificate?: bool, hostnameConfigurations?: list, notificationSenderEmail?: string, virtualNetworkConfiguration?: any, virtualNetworkType?: "None"|"External"|"Internal"}
  sku: any # API Management service resource SKU properties. — shape: {capacity?: int, name: "Developer"|"Standard"|"Premium"|"Basic"|"Consumption"}
  --tags: record # Resource tags.
]: any -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string>, location: string, properties: record<publisherEmail: string, publisherName: string, additionalLocations: list<record>, certificates: list<record>, createdAtUtc: string, customProperties: record, enableClientCertificate: bool, gatewayRegionalUrl: string, gatewayUrl: string, hostnameConfigurations: list<record>, managementApiUrl: string, notificationSenderEmail: string, portalUrl: string, privateIPAddresses: list<string>, provisioningState: string, publicIPAddresses: list<string>, scmUrl: string, targetProvisioningState: string, virtualNetworkConfiguration: record<subnetResourceId: string, subnetname: string, vnetid: string>, virtualNetworkType: string>, sku: record<capacity: int, name: string>, id: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}") $qp)
  let body = {"identity": $identity, "location": $location, "properties": $properties, "sku": $sku, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the Microsoft.ApiManagement resource running in the Virtual network to pick the updated network settings.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/applynetworkconfigurationupdates
# operationId: ApiManagementService_ApplyNetworkConfigurationUpdates
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-applynetworkconfigurationupdates post" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  --location: string # Location of the Api Management service to update for a multi-region service. For a service deployed in a single region, this parameter is not required.
]: any -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string>, location: string, properties: record<publisherEmail: string, publisherName: string, additionalLocations: list<record>, certificates: list<record>, createdAtUtc: string, customProperties: record, enableClientCertificate: bool, gatewayRegionalUrl: string, gatewayUrl: string, hostnameConfigurations: list<record>, managementApiUrl: string, notificationSenderEmail: string, portalUrl: string, privateIPAddresses: list<string>, provisioningState: string, publicIPAddresses: list<string>, scmUrl: string, targetProvisioningState: string, virtualNetworkConfiguration: record<subnetResourceId: string, subnetname: string, vnetid: string>, virtualNetworkType: string>, sku: record<capacity: int, name: string>, id: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/applynetworkconfigurationupdates") $qp)
  let body = {"location": $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a backup of the API Management service to the given Azure Storage Account. This is long running operation and could take several minutes to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/backup
# operationId: ApiManagementService_Backup
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-backup post" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  access_key: string # Azure Cloud Storage account (used to place/retrieve the backup) access key.
  backup_name: string # The name of the backup file to create.
  container_name: string # Azure Cloud Storage blob container name used to place/retrieve the backup.
  storage_account: string # Azure Cloud Storage account (used to place/retrieve the backup) name.
]: any -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string>, location: string, properties: record<publisherEmail: string, publisherName: string, additionalLocations: list<record>, certificates: list<record>, createdAtUtc: string, customProperties: record, enableClientCertificate: bool, gatewayRegionalUrl: string, gatewayUrl: string, hostnameConfigurations: list<record>, managementApiUrl: string, notificationSenderEmail: string, portalUrl: string, privateIPAddresses: list<string>, provisioningState: string, publicIPAddresses: list<string>, scmUrl: string, targetProvisioningState: string, virtualNetworkConfiguration: record<subnetResourceId: string, subnetname: string, vnetid: string>, virtualNetworkType: string>, sku: record<capacity: int, name: string>, id: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/backup") $qp)
  let body = {"accessKey": $access_key, "backupName": $backup_name, "containerName": $container_name, "storageAccount": $storage_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Single-Sign-On token for the API Management Service which is valid for 5 Minutes.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/getssotoken
# operationId: ApiManagementService_GetSsoToken
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-getssotoken get-sso-token" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<redirectUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/getssotoken") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores a backup of an API Management service created using the ApiManagementService_Backup operation on the current service. This is a long running operation and could take several minutes to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/restore
# operationId: ApiManagementService_Restore
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-restore post" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
  access_key: string # Azure Cloud Storage account (used to place/retrieve the backup) access key.
  backup_name: string # The name of the backup file to create.
  container_name: string # Azure Cloud Storage blob container name used to place/retrieve the backup.
  storage_account: string # Azure Cloud Storage account (used to place/retrieve the backup) name.
]: any -> record<etag: string, identity: record<principalId: string, tenantId: string, type: string>, location: string, properties: record<publisherEmail: string, publisherName: string, additionalLocations: list<record>, certificates: list<record>, createdAtUtc: string, customProperties: record, enableClientCertificate: bool, gatewayRegionalUrl: string, gatewayUrl: string, hostnameConfigurations: list<record>, managementApiUrl: string, notificationSenderEmail: string, portalUrl: string, privateIPAddresses: list<string>, provisioningState: string, publicIPAddresses: list<string>, scmUrl: string, targetProvisioningState: string, virtualNetworkConfiguration: record<subnetResourceId: string, subnetname: string, vnetid: string>, virtualNetworkType: string>, sku: record<capacity: int, name: string>, id: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/restore") $qp)
  let body = {"accessKey": $access_key, "backupName": $backup_name, "containerName": $container_name, "storageAccount": $storage_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets available SKUs for API Management service
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/skus
# operationId: ApiManagementServiceSkus_ListAvailableServiceSkus
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-skus list-available" [
  subscription_id: string
  resource_group_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, service_name: $service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/skus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
