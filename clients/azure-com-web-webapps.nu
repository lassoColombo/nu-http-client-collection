# Auto-generated client for WebApps API Client v2018-11-01
# Source: https://api.apis.guru/v2/specs/azure.com/web-WebApps/2018-11-01/swagger.json
# Auth: --token flag or $env.WEBAPPS_API_CLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEBAPPS_API_CLIENT_TOKEN | default "" }
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
def format-completer [] { ["FileZilla3" "Ftp" "WebDeploy"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-web-sites List" } } | get name | first)
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

# Get all apps for a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/sites
# operationId: WebApps_List
export def "subscriptions-providers-microsoft-web-sites List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Web/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all web, mobile, and API apps in the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites
# operationId: WebApps_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-web-sites ListByResourceGroup" [
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
  --includeSlots: oneof<nothing, bool> # Specify <strong>true</strong> to include deployment slots in results. The default is false, which only gives you the production slot of all apps.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeSlots" $includeSlots "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a web, mobile, or API app, or one of the deployment slots.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# operationId: WebApps_Delete
export def "subscriptions-resource-groups-providers-microsoft-web-sites Delete" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteMetrics: oneof<nothing, bool> # If true, web app metrics are also deleted.
  --deleteEmptyServerFarm: oneof<nothing, bool> # Specify false if you want to keep empty App Service plan. By default, empty App Service plan is deleted.
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteMetrics" $deleteMetrics "scalar") (serialize-qp "deleteEmptyServerFarm" $deleteEmptyServerFarm "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a web, mobile, or API app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# operationId: WebApps_Get
export def "subscriptions-resource-groups-providers-microsoft-web-sites Get" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, clientCertExclusionPaths: string, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, sourceWebAppLocation: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, dailyMemoryTimeQuota: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, geoDistributions: list<record>, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, httpsOnly: bool, hyperV: bool, inProgressOperationId: string, isDefaultContainer: bool, isXenon: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, outboundIpAddresses: string, possibleOutboundIpAddresses: string, redundancyMode: string, repositorySiteName: string, reserved: bool, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<alwaysOn: bool, apiDefinition: record, appCommandLine: string, appSettings: list, autoHealEnabled: bool, autoHealRules: record, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list, cors: record, defaultDocuments: list, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record, ftpsState: string, handlerMappings: list, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>, slotSwapStatus: record<destinationSlotName: string, sourceSlotName: string, timestampUtc: string>, state: string, suspendedTill: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new web, mobile, or API app in an existing resource group, or updates an existing app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# operationId: WebApps_Update
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites Update" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --identity: record # Managed service identity. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: any # SitePatchResource resource specific properties — shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
  --kind: string # Kind of resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, clientCertExclusionPaths: string, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, sourceWebAppLocation: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, dailyMemoryTimeQuota: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, geoDistributions: list<record>, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, httpsOnly: bool, hyperV: bool, inProgressOperationId: string, isDefaultContainer: bool, isXenon: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, outboundIpAddresses: string, possibleOutboundIpAddresses: string, redundancyMode: string, repositorySiteName: string, reserved: bool, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<alwaysOn: bool, apiDefinition: record, appCommandLine: string, appSettings: list, autoHealEnabled: bool, autoHealRules: record, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list, cors: record, defaultDocuments: list, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record, ftpsState: string, handlerMappings: list, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>, slotSwapStatus: record<destinationSlotName: string, sourceSlotName: string, timestampUtc: string>, state: string, suspendedTill: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)" $qp)
  let body = {identity: $identity, properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new web, mobile, or API app in an existing resource group, or updates an existing app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# operationId: WebApps_CreateOrUpdate
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites CreateOrUpdate" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --identity: record # Managed service identity. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: any # Site resource specific properties — shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
  --kind: string # Kind of resource.
  location: string # Resource Location.
  --tags: record # Resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, clientCertExclusionPaths: string, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, sourceWebAppLocation: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, dailyMemoryTimeQuota: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, geoDistributions: list<record>, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, httpsOnly: bool, hyperV: bool, inProgressOperationId: string, isDefaultContainer: bool, isXenon: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, outboundIpAddresses: string, possibleOutboundIpAddresses: string, redundancyMode: string, repositorySiteName: string, reserved: bool, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<alwaysOn: bool, apiDefinition: record, appCommandLine: string, appSettings: list, autoHealEnabled: bool, autoHealRules: record, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list, cors: record, defaultDocuments: list, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record, ftpsState: string, handlerMappings: list, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>, slotSwapStatus: record<destinationSlotName: string, sourceSlotName: string, timestampUtc: string>, state: string, suspendedTill: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)" $qp)
  let body = {identity: $identity, properties: $properties, kind: $kind, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Analyze a custom hostname.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/analyzeCustomHostname
# operationId: WebApps_AnalyzeCustomHostname
export def "subscriptions-resource-groups-providers-microsoft-web-sites-analyze-custom-hostname AnalyzeCustomHostname" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hostName: string # Custom hostname.
  --api-version: string # API Version
]: nothing -> record<properties: record<aRecords: list<string>, alternateCNameRecords: list<string>, alternateTxtRecords: list<string>, cNameRecords: list<string>, conflictingAppResourceId: string, customDomainVerificationFailureInfo: record<code: string, extendedCode: string, innerErrors: list, message: string, messageTemplate: string, parameters: list>, customDomainVerificationTest: string, hasConflictAcrossSubscription: bool, hasConflictOnScaleUnit: bool, isHostnameAlreadyVerified: bool, txtRecords: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostName" $hostName "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/analyzeCustomHostname" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Applies the configuration settings from the target slot onto the current slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/applySlotConfig
# operationId: WebApps_ApplySlotConfigToProduction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-apply-slot-config ApplySlotConfigToProduction" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --preserveVnet: oneof<nothing, bool> # <code>true</code> to preserve Virtual Network to the slot during swap; otherwise, <code>false</code>.
  targetSlot: string # Destination deployment slot during swap operation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/applySlotConfig" $qp)
  let body = {preserveVnet: $preserveVnet, targetSlot: $targetSlot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a backup of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backup
# operationId: WebApps_Backup
# --properties shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backup Backup" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # BackupRequest resource specific properties — shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/backup" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets existing backups of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups
# operationId: WebApps_ListBackups
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups ListBackups" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/backups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a backup of an app by its ID.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}
# operationId: WebApps_DeleteBackup
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups DeleteBackup" [
  resourceGroupName: string
  name: string
  backupId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/backups/($backupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a backup of an app by its ID.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}
# operationId: WebApps_GetBackupStatus
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups GetBackupStatus" [
  resourceGroupName: string
  name: string
  backupId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/backups/($backupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets status of a web app backup that may be in progress, including secrets associated with the backup, such as the Azure Storage SAS URL. Also can be used to update the SAS URL for the backup if a new URL is passed in the request body.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/list
# operationId: WebApps_ListBackupStatusSecrets
# --properties shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups-list ListBackupStatusSecrets" [
  resourceGroupName: string
  name: string
  backupId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # BackupRequest resource specific properties — shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/backups/($backupId)/list" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a specific backup to another app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/restore
# operationId: WebApps_Restore
# --properties shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-backups-restore Restore" [
  resourceGroupName: string
  name: string
  backupId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RestoreRequest resource specific properties — shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/backups/($backupId)/restore" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the configurations of an app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config
# operationId: WebApps_ListConfigurations
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config ListConfigurations" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the application settings of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings
# operationId: WebApps_UpdateApplicationSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-appsettings UpdateApplicationSettings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Settings.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/appsettings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the application settings of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings/list
# operationId: WebApps_ListApplicationSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-appsettings-list ListApplicationSettings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/appsettings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Authentication / Authorization settings associated with web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings
# operationId: WebApps_UpdateAuthSettings
# --properties shape: {additionalLoginParams?: list, allowedAudiences?: list, allowedExternalRedirectUrls?: list, clientId?: string, clientSecret?: string, clientSecretCertificateThumbprint?: string, defaultProvider?: "AzureActiveDirectory"|"Facebook"|"Google"|"MicrosoftAccount"|"Twitter", enabled?: bool, facebookAppId?: string, facebookAppSecret?: string, facebookOAuthScopes?: list, googleClientId?: string, googleClientSecret?: string, googleOAuthScopes?: list, issuer?: string, microsoftAccountClientId?: string, microsoftAccountClientSecret?: string, microsoftAccountOAuthScopes?: list, runtimeVersion?: string, tokenRefreshExtensionHours?: float, tokenStoreEnabled?: bool, twitterConsumerKey?: string, twitterConsumerSecret?: string, unauthenticatedClientAction?: "RedirectToLoginPage"|"AllowAnonymous", validateIssuer?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-authsettings UpdateAuthSettings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteAuthSettings resource specific properties — shape: {additionalLoginParams?: list, allowedAudiences?: list, allowedExternalRedirectUrls?: list, clientId?: string, clientSecret?: string, clientSecretCertificateThumbprint?: string, defaultProvider?: "AzureActiveDirectory"|"Facebook"|"Google"|"MicrosoftAccount"|"Twitter", enabled?: bool, facebookAppId?: string, facebookAppSecret?: string, facebookOAuthScopes?: list, googleClientId?: string, googleClientSecret?: string, googleOAuthScopes?: list, issuer?: string, microsoftAccountClientId?: string, microsoftAccountClientSecret?: string, microsoftAccountOAuthScopes?: list, runtimeVersion?: string, tokenRefreshExtensionHours?: float, tokenStoreEnabled?: bool, twitterConsumerKey?: string, twitterConsumerSecret?: string, unauthenticatedClientAction?: "RedirectToLoginPage"|"AllowAnonymous", validateIssuer?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, clientSecretCertificateThumbprint: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, runtimeVersion: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string, validateIssuer: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/authsettings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Authentication/Authorization settings of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings/list
# operationId: WebApps_GetAuthSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-authsettings-list GetAuthSettings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, clientSecretCertificateThumbprint: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, runtimeVersion: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string, validateIssuer: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/authsettings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Azure storage account configurations of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/azurestorageaccounts
# operationId: WebApps_UpdateAzureStorageAccounts
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-azurestorageaccounts UpdateAzureStorageAccounts" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Azure storage accounts.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/azurestorageaccounts" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Azure storage account configurations of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/azurestorageaccounts/list
# operationId: WebApps_ListAzureStorageAccounts
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-azurestorageaccounts-list ListAzureStorageAccounts" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/azurestorageaccounts/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the backup configuration of an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup
# operationId: WebApps_DeleteBackupConfiguration
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-backup DeleteBackupConfiguration" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/backup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the backup configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup
# operationId: WebApps_UpdateBackupConfiguration
# --properties shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-backup UpdateBackupConfiguration" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # BackupRequest resource specific properties — shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<backupName: string, backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, storageAccountUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/backup" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the backup configuration of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup/list
# operationId: WebApps_GetBackupConfiguration
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-backup-list GetBackupConfiguration" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<backupName: string, backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, storageAccountUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/backup/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the connection strings of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings
# operationId: WebApps_UpdateConnectionStrings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-connectionstrings UpdateConnectionStrings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Connection strings.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/connectionstrings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the connection strings of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings/list
# operationId: WebApps_ListConnectionStrings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-connectionstrings-list ListConnectionStrings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/connectionstrings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the logging configuration of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs
# operationId: WebApps_GetDiagnosticLogsConfiguration
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-logs GetDiagnosticLogsConfiguration" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the logging configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs
# operationId: WebApps_UpdateDiagnosticLogsConfig
# --properties shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-logs UpdateDiagnosticLogsConfig" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteLogsConfig resource specific properties — shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
  --kind: string # Kind of resource.
]: any -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/logs" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replaces the metadata of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata
# operationId: WebApps_UpdateMetadata
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-metadata UpdateMetadata" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Settings.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/metadata" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the metadata of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata/list
# operationId: WebApps_ListMetadata
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-metadata-list ListMetadata" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/metadata/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Git/FTP publishing credentials of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/publishingcredentials/list
# operationId: WebApps_ListPublishingCredentials
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-publishingcredentials-list ListPublishingCredentials" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<publishingPassword: string, publishingPasswordHash: string, publishingPasswordHashSalt: string, publishingUserName: string, scmUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/publishingcredentials/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Push settings associated with web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/pushsettings
# operationId: WebApps_UpdateSitePushSettings
# --properties shape: {dynamicTagsJson?: string, isPushEnabled: bool, tagWhitelistJson?: string, tagsRequiringAuth?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-pushsettings UpdateSitePushSettings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PushSettings resource specific properties — shape: {dynamicTagsJson?: string, isPushEnabled: bool, tagWhitelistJson?: string, tagsRequiringAuth?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<dynamicTagsJson: string, isPushEnabled: bool, tagWhitelistJson: string, tagsRequiringAuth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/pushsettings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Push settings associated with web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/pushsettings/list
# operationId: WebApps_ListSitePushSettings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-pushsettings-list ListSitePushSettings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<dynamicTagsJson: string, isPushEnabled: bool, tagWhitelistJson: string, tagsRequiringAuth: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/pushsettings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the names of app settings and connection strings that stick to the slot (not swapped).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames
# operationId: WebApps_ListSlotConfigurationNames
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-slot-config-names ListSlotConfigurationNames" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<appSettingNames: list<string>, azureStorageConfigNames: list<string>, connectionStringNames: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/slotConfigNames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the names of application settings and connection string that remain with the slot during swap operation.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames
# operationId: WebApps_UpdateSlotConfigurationNames
# --properties shape: {appSettingNames?: list, azureStorageConfigNames?: list, connectionStringNames?: list}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-slot-config-names UpdateSlotConfigurationNames" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Names for connection strings, application settings, and external Azure storage account configuration identifiers to be marked as sticky to the deployment slot and not moved during a swap operation. This is valid for all deployment slots in an app. — shape: {appSettingNames?: list, azureStorageConfigNames?: list, connectionStringNames?: list}
  --kind: string # Kind of resource.
]: any -> record<properties: record<appSettingNames: list<string>, azureStorageConfigNames: list<string>, connectionStringNames: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/slotConfigNames" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the configuration of an app, such as platform version and bitness, default documents, virtual applications, Always On, etc.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# operationId: WebApps_GetConfiguration
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web GetConfiguration" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/web" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the configuration of an app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# operationId: WebApps_UpdateConfiguration
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web UpdateConfiguration" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Configuration of an App Service app. — shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
  --kind: string # Kind of resource.
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# operationId: WebApps_CreateOrUpdateConfiguration
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web CreateOrUpdateConfiguration" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Configuration of an App Service app. — shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
  --kind: string # Kind of resource.
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of web app configuration snapshots identifiers. Each element of the list contains a timestamp and the ID of the snapshot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web/snapshots
# operationId: WebApps_ListConfigurationSnapshotInfo
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web-snapshots ListConfigurationSnapshotInfo" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/web/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a snapshot of the configuration of an app at a previous point in time.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web/snapshots/{snapshotId}
# operationId: WebApps_GetConfigurationSnapshot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web-snapshots GetConfigurationSnapshot" [
  resourceGroupName: string
  name: string
  snapshotId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/web/snapshots/($snapshotId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reverts the configuration of an app to a previous snapshot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web/snapshots/{snapshotId}/recover
# operationId: WebApps_RecoverSiteConfigurationSnapshot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-config-web-snapshots-recover RecoverSiteConfigurationSnapshot" [
  resourceGroupName: string
  name: string
  snapshotId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/config/web/snapshots/($snapshotId)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the last lines of docker logs for the given site
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/containerlogs
# operationId: WebApps_GetWebSiteContainerLogs
export def "subscriptions-resource-groups-providers-microsoft-web-sites-containerlogs GetWebSiteContainerLogs" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/containerlogs" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the ZIP archived docker log files for the given site
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/containerlogs/zip/download
# operationId: WebApps_GetContainerLogsZip
export def "subscriptions-resource-groups-providers-microsoft-web-sites-containerlogs-zip-download GetContainerLogsZip" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/containerlogs/zip/download" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List continuous web jobs for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/continuouswebjobs
# operationId: WebApps_ListContinuousWebJobs
export def "subscriptions-resource-groups-providers-microsoft-web-sites-continuouswebjobs ListContinuousWebJobs" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/continuouswebjobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a continuous web job by its ID for an app, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/continuouswebjobs/{webJobName}
# operationId: WebApps_DeleteContinuousWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-continuouswebjobs DeleteContinuousWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/continuouswebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a continuous web job by its ID for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/continuouswebjobs/{webJobName}
# operationId: WebApps_GetContinuousWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-continuouswebjobs GetContinuousWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<detailed_status: string, error: string, extra_info_url: string, log_url: string, run_command: string, settings: record, status: string, url: string, using_sdk: bool, web_job_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/continuouswebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a continuous web job for an app, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/continuouswebjobs/{webJobName}/start
# operationId: WebApps_StartContinuousWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-continuouswebjobs-start StartContinuousWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/continuouswebjobs/($webJobName)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a continuous web job for an app, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/continuouswebjobs/{webJobName}/stop
# operationId: WebApps_StopContinuousWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-continuouswebjobs-stop StopContinuousWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/continuouswebjobs/($webJobName)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deployments for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments
# operationId: WebApps_ListDeployments
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments ListDeployments" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a deployment by its ID for an app, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# operationId: WebApps_DeleteDeployment
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments DeleteDeployment" [
  resourceGroupName: string
  name: string
  id: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/deployments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a deployment by its ID for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# operationId: WebApps_GetDeployment
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments GetDeployment" [
  resourceGroupName: string
  name: string
  id: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/deployments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deployment for an app, or a deployment slot.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# operationId: WebApps_CreateDeployment
# --properties shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, message?: string, start_time?: string, status?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments CreateDeployment" [
  resourceGroupName: string
  name: string
  id: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # Deployment resource specific properties — shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, message?: string, start_time?: string, status?: int}
  --kind: string # Kind of resource.
]: any -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, message: string, start_time: string, status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/deployments/($id)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List deployment log for specific deployment for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}/log
# operationId: WebApps_ListDeploymentLog
export def "subscriptions-resource-groups-providers-microsoft-web-sites-deployments-log ListDeploymentLog" [
  resourceGroupName: string
  name: string
  id: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/deployments/($id)/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Discovers an existing app backup that can be restored from a blob in Azure storage. Use this to get information about the databases stored in a backup.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/discoverbackup
# operationId: WebApps_DiscoverBackup
# --properties shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-discoverbackup DiscoverBackup" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RestoreRequest resource specific properties — shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<adjustConnectionStrings: bool, appServicePlan: string, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, ignoreDatabases: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/discoverbackup" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists ownership identifiers for domain associated with web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/domainOwnershipIdentifiers
# operationId: WebApps_ListDomainOwnershipIdentifiers
export def "subscriptions-resource-groups-providers-microsoft-web-sites-domain-ownership-identifiers ListDomainOwnershipIdentifiers" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/domainOwnershipIdentifiers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a domain ownership identifier for a web app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_DeleteDomainOwnershipIdentifier
export def "subscriptions-resource-groups-providers-microsoft-web-sites-domain-ownership-identifiers DeleteDomainOwnershipIdentifier" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get domain ownership identifier for web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_GetDomainOwnershipIdentifier
export def "subscriptions-resource-groups-providers-microsoft-web-sites-domain-ownership-identifiers GetDomainOwnershipIdentifier" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a domain ownership identifier for web app, or updates an existing ownership identifier.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_UpdateDomainOwnershipIdentifier
# --properties shape: {id?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-domain-ownership-identifiers UpdateDomainOwnershipIdentifier" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # Identifier resource specific properties — shape: {id?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a domain ownership identifier for web app, or updates an existing ownership identifier.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_CreateOrUpdateDomainOwnershipIdentifier
# --properties shape: {id?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-domain-ownership-identifiers CreateOrUpdateDomainOwnershipIdentifier" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # Identifier resource specific properties — shape: {id?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the status of the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/extensions/MSDeploy
# operationId: WebApps_GetMSDeployStatus
export def "subscriptions-resource-groups-providers-microsoft-web-sites-extensions-ms-deploy GetMSDeployStatus" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/extensions/MSDeploy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke the MSDeploy web app extension.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/extensions/MSDeploy
# operationId: WebApps_CreateMSDeployOperation
# --properties shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-extensions-ms-deploy CreateMSDeployOperation" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # MSDeploy ARM PUT core information — shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/extensions/MSDeploy" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the MSDeploy Log for the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/extensions/MSDeploy/log
# operationId: WebApps_GetMSDeployLog
export def "subscriptions-resource-groups-providers-microsoft-web-sites-extensions-ms-deploy-log GetMSDeployLog" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<entries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/extensions/MSDeploy/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the functions for a web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/functions
# operationId: WebApps_ListFunctions
export def "subscriptions-resource-groups-providers-microsoft-web-sites-functions ListFunctions" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a short lived token that can be exchanged for a master key.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/functions/admin/token
# operationId: WebApps_GetFunctionsAdminToken
export def "subscriptions-resource-groups-providers-microsoft-web-sites-functions-admin-token GetFunctionsAdminToken" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/functions/admin/token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a function for web site, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/functions/{functionName}
# operationId: WebApps_DeleteFunction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-functions DeleteFunction" [
  resourceGroupName: string
  name: string
  functionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/functions/($functionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get function information by its ID for web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/functions/{functionName}
# operationId: WebApps_GetFunction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-functions GetFunction" [
  resourceGroupName: string
  name: string
  functionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<config: record, config_href: string, files: record, function_app_id: string, href: string, script_href: string, script_root_path_href: string, secrets_file_href: string, test_data: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/functions/($functionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create function for web site, or a deployment slot.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/functions/{functionName}
# operationId: WebApps_CreateFunction
# --properties shape: {config?: record, config_href?: string, files?: record, function_app_id?: string, href?: string, script_href?: string, script_root_path_href?: string, secrets_file_href?: string, test_data?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-functions CreateFunction" [
  resourceGroupName: string
  name: string
  functionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # FunctionEnvelope resource specific properties — shape: {config?: record, config_href?: string, files?: record, function_app_id?: string, href?: string, script_href?: string, script_root_path_href?: string, secrets_file_href?: string, test_data?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<config: record, config_href: string, files: record, function_app_id: string, href: string, script_href: string, script_root_path_href: string, secrets_file_href: string, test_data: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/functions/($functionName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get function secrets for a function in a web site, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/functions/{functionName}/listsecrets
# operationId: WebApps_ListFunctionSecrets
export def "subscriptions-resource-groups-providers-microsoft-web-sites-functions-listsecrets ListFunctionSecrets" [
  resourceGroupName: string
  name: string
  functionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<key: string, trigger_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/functions/($functionName)/listsecrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get hostname bindings for an app or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings
# operationId: WebApps_ListHostNameBindings
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings ListHostNameBindings" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hostNameBindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a hostname binding for an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# operationId: WebApps_DeleteHostNameBinding
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings DeleteHostNameBinding" [
  resourceGroupName: string
  name: string
  hostName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hostNameBindings/($hostName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the named hostname binding for an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# operationId: WebApps_GetHostNameBinding
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings GetHostNameBinding" [
  resourceGroupName: string
  name: string
  hostName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, siteName: string, sslState: string, thumbprint: string, virtualIP: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hostNameBindings/($hostName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a hostname binding for an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# operationId: WebApps_CreateOrUpdateHostNameBinding
# --properties shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", siteName?: string, sslState?: "Disabled"|"SniEnabled"|"IpBasedEnabled", thumbprint?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-host-name-bindings CreateOrUpdateHostNameBinding" [
  resourceGroupName: string
  name: string
  hostName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # HostNameBinding resource specific properties — shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", siteName?: string, sslState?: "Disabled"|"SniEnabled"|"IpBasedEnabled", thumbprint?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, siteName: string, sslState: string, thumbprint: string, virtualIP: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hostNameBindings/($hostName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a Hybrid Connection from this site.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_DeleteHybridConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybrid-connection-namespaces-relays DeleteHybridConnection" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific Service Bus Hybrid Connection used by this Web App.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_GetHybridConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybrid-connection-namespaces-relays GetHybridConnection" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Hybrid Connection using a Service Bus relay.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_UpdateHybridConnection
# --properties shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybrid-connection-namespaces-relays UpdateHybridConnection" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # HybridConnection resource specific properties — shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new Hybrid Connection using a Service Bus relay.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_CreateOrUpdateHybridConnection
# --properties shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybrid-connection-namespaces-relays CreateOrUpdateHybridConnection" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # HybridConnection resource specific properties — shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the send key name and value for a Hybrid Connection.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}/listKeys
# operationId: WebApps_ListHybridConnectionKeys
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybrid-connection-namespaces-relays-list-keys ListHybridConnectionKeys" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<sendKeyName: string, sendKeyValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all Service Bus Hybrid Connections used by this Web App.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridConnectionRelays
# operationId: WebApps_ListHybridConnections
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybrid-connection-relays ListHybridConnections" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridConnectionRelays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets hybrid connections configured for an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection
# operationId: WebApps_ListRelayServiceConnections
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection ListRelayServiceConnections" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridconnection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a relay service connection by its name.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: WebApps_DeleteRelayServiceConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection DeleteRelayServiceConnection" [
  resourceGroupName: string
  name: string
  entityName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridconnection/($entityName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a hybrid connection configuration by its name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: WebApps_GetRelayServiceConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection GetRelayServiceConnection" [
  resourceGroupName: string
  name: string
  entityName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridconnection/($entityName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new hybrid connection configuration (PUT), or updates an existing one (PATCH).
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: WebApps_UpdateRelayServiceConnection
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection UpdateRelayServiceConnection" [
  resourceGroupName: string
  name: string
  entityName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RelayServiceConnectionEntity resource specific properties — shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridconnection/($entityName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new hybrid connection configuration (PUT), or updates an existing one (PATCH).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# operationId: WebApps_CreateOrUpdateRelayServiceConnection
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-hybridconnection CreateOrUpdateRelayServiceConnection" [
  resourceGroupName: string
  name: string
  entityName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RelayServiceConnectionEntity resource specific properties — shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/hybridconnection/($entityName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all scale-out instances of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances
# operationId: WebApps_ListInstanceIdentifiers
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances ListInstanceIdentifiers" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the status of the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/extensions/MSDeploy
# operationId: WebApps_GetInstanceMsDeployStatus
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-extensions-ms-deploy GetInstanceMsDeployStatus" [
  resourceGroupName: string
  name: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/extensions/MSDeploy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke the MSDeploy web app extension.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/extensions/MSDeploy
# operationId: WebApps_CreateInstanceMSDeployOperation
# --properties shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-extensions-ms-deploy CreateInstanceMSDeployOperation" [
  resourceGroupName: string
  name: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # MSDeploy ARM PUT core information — shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/extensions/MSDeploy" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the MSDeploy Log for the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/extensions/MSDeploy/log
# operationId: WebApps_GetInstanceMSDeployLog
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-extensions-ms-deploy-log GetInstanceMSDeployLog" [
  resourceGroupName: string
  name: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<entries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/extensions/MSDeploy/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of processes for a web site, or a deployment slot, or for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes
# operationId: WebApps_ListInstanceProcesses
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes ListInstanceProcesses" [
  resourceGroupName: string
  name: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Terminate a process by its ID for a web site, or a deployment slot, or specific scaled-out instance in a web site.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes/{processId}
# operationId: WebApps_DeleteInstanceProcess
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes DeleteInstanceProcess" [
  resourceGroupName: string
  name: string
  processId: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes/{processId}
# operationId: WebApps_GetInstanceProcess
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes GetInstanceProcess" [
  resourceGroupName: string
  name: string
  processId: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<children: list<string>, command_line: string, deployment_name: string, description: string, environment_variables: record, file_name: string, handle_count: int, href: string, identifier: int, iis_profile_timeout_in_seconds: float, is_iis_profile_running: bool, is_profile_running: bool, is_scm_site: bool, is_webjob: bool, minidump: string, module_count: int, modules: list<record>, non_paged_system_memory: int, open_file_handles: list<string>, paged_memory: int, paged_system_memory: int, parent: string, peak_paged_memory: int, peak_virtual_memory: int, peak_working_set: int, private_memory: int, privileged_cpu_time: string, start_time: string, thread_count: int, threads: list<record>, time_stamp: string, total_cpu_time: string, user_cpu_time: string, user_name: string, virtual_memory: int, working_set: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a memory dump of a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes/{processId}/dump
# operationId: WebApps_GetInstanceProcessDump
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes-dump GetInstanceProcessDump" [
  resourceGroupName: string
  name: string
  processId: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes/($processId)/dump" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List module information for a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes/{processId}/modules
# operationId: WebApps_ListInstanceProcessModules
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes-modules ListInstanceProcessModules" [
  resourceGroupName: string
  name: string
  processId: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes/($processId)/modules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes/{processId}/modules/{baseAddress}
# operationId: WebApps_GetInstanceProcessModule
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes-modules GetInstanceProcessModule" [
  resourceGroupName: string
  name: string
  processId: string
  baseAddress: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_address: string, file_description: string, file_name: string, file_path: string, file_version: string, href: string, is_debug: bool, language: string, module_memory_size: int, product: string, product_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes/($processId)/modules/($baseAddress)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the threads in a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes/{processId}/threads
# operationId: WebApps_ListInstanceProcessThreads
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes-threads ListInstanceProcessThreads" [
  resourceGroupName: string
  name: string
  processId: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes/($processId)/threads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get thread information by Thread ID for a specific process, in a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/processes/{processId}/threads/{threadId}
# operationId: WebApps_GetInstanceProcessThread
export def "subscriptions-resource-groups-providers-microsoft-web-sites-instances-processes-threads GetInstanceProcessThread" [
  resourceGroupName: string
  name: string
  processId: string
  threadId: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_priority: int, current_priority: int, href: string, identifier: int, priority_level: string, priviledged_processor_time: string, process: string, start_address: string, start_time: string, state: string, total_processor_time: string, user_processor_time: string, wait_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/instances/($instanceId)/processes/($processId)/threads/($threadId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shows whether an app can be cloned to another resource group or subscription.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/iscloneable
# operationId: WebApps_IsCloneable
export def "subscriptions-resource-groups-providers-microsoft-web-sites-iscloneable IsCloneable" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/iscloneable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This is to allow calling via powershell and ARM template.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/listsyncfunctiontriggerstatus
# operationId: WebApps_ListSyncFunctionTriggers
export def "subscriptions-resource-groups-providers-microsoft-web-sites-listsyncfunctiontriggerstatus ListSyncFunctionTriggers" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<key: string, trigger_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/listsyncfunctiontriggerstatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all metric definitions of an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metricdefinitions
# operationId: WebApps_ListMetricDefinitions
export def "subscriptions-resource-groups-providers-microsoft-web-sites-metricdefinitions ListMetricDefinitions" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/metricdefinitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets performance metrics of an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metrics
# operationId: WebApps_ListMetrics
export def "subscriptions-resource-groups-providers-microsoft-web-sites-metrics ListMetrics" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: oneof<nothing, bool> # Specify "true" to include metric details in the response. It is "false" by default.
  --filter: string # Return only metrics specified in the filter (using OData syntax). For example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq 2014-01-01T00:00:00Z and endTime eq 2014-12-31T23:59:59Z and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, id: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores a web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/migrate
# operationId: WebApps_MigrateStorage
# --properties shape: {azurefilesConnectionString: string, azurefilesShare: string, blockWriteAccessToSite?: bool, switchSiteAfterMigration?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-migrate MigrateStorage" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscriptionName: string # Azure subscription.
  --api-version: string # API Version
  --properties: any # StorageMigrationOptions resource specific properties — shape: {azurefilesConnectionString: string, azurefilesShare: string, blockWriteAccessToSite?: bool, switchSiteAfterMigration?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<operationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscriptionName" $subscriptionName "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/migrate" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Migrates a local (in-app) MySql database to a remote MySql database.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/migratemysql
# operationId: WebApps_MigrateMySql
# --properties shape: {connectionString: string, migrationType: "LocalToRemote"|"RemoteToLocal"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-migratemysql MigrateMySql" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # MigrateMySqlRequest resource specific properties — shape: {connectionString: string, migrationType: "LocalToRemote"|"RemoteToLocal"}
  --kind: string # Kind of resource.
]: any -> record<createdTime: string, errors: table<code: string, extendedCode: string, innerErrors: list, message: string, messageTemplate: string, parameters: list>, expirationTime: string, geoMasterOperationId: string, id: string, modifiedTime: string, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/migratemysql" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the status of MySql in app migration, if one is active, and whether or not MySql in app is enabled
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/migratemysql/status
# operationId: WebApps_GetMigrateMySqlStatus
export def "subscriptions-resource-groups-providers-microsoft-web-sites-migratemysql-status GetMigrateMySqlStatus" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<localMySqlEnabled: bool, migrationOperationStatus: string, operationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/migratemysql/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Swift Virtual Network connection from an app (or deployment slot).
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkConfig/virtualNetwork
# operationId: WebApps_DeleteSwiftVirtualNetwork
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-config-virtual-network DeleteSwiftVirtualNetwork" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkConfig/virtualNetwork" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Swift Virtual Network connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkConfig/virtualNetwork
# operationId: WebApps_GetSwiftVirtualNetworkConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-config-virtual-network GetSwiftVirtualNetworkConnection" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<subnetResourceId: string, swiftSupported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkConfig/virtualNetwork" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Integrates this Web App with a Virtual Network. This requires that 1) "swiftSupported" is true when doing a GET against this resource, and 2) that the target Subnet has already been delegated, and is not in use by another App Service Plan other than the one this App is in.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkConfig/virtualNetwork
# operationId: WebApps_UpdateSwiftVirtualNetworkConnection
# --properties shape: {subnetResourceId?: string, swiftSupported?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-config-virtual-network UpdateSwiftVirtualNetworkConnection" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SwiftVirtualNetwork resource specific properties — shape: {subnetResourceId?: string, swiftSupported?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<subnetResourceId: string, swiftSupported: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkConfig/virtualNetwork" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Integrates this Web App with a Virtual Network. This requires that 1) "swiftSupported" is true when doing a GET against this resource, and 2) that the target Subnet has already been delegated, and is not in use by another App Service Plan other than the one this App is in.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkConfig/virtualNetwork
# operationId: WebApps_CreateOrUpdateSwiftVirtualNetworkConnection
# --properties shape: {subnetResourceId?: string, swiftSupported?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-config-virtual-network CreateOrUpdateSwiftVirtualNetworkConnection" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SwiftVirtualNetwork resource specific properties — shape: {subnetResourceId?: string, swiftSupported?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<subnetResourceId: string, swiftSupported: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkConfig/virtualNetwork" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all network features used by the app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkFeatures/{view}
# operationId: WebApps_ListNetworkFeatures
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-features ListNetworkFeatures" [
  resourceGroupName: string
  name: string
  view: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<hybridConnections: list<record>, hybridConnectionsV2: list<record>, virtualNetworkConnection: record<properties: record>, virtualNetworkName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkFeatures/($view)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkTrace/operationresults/{operationId}
# operationId: WebApps_GetNetworkTraceOperation
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-trace-operationresults GetNetworkTraceOperation" [
  resourceGroupName: string
  name: string
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
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkTrace/operationresults/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start capturing network packets for the site (To be deprecated).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkTrace/start
# operationId: WebApps_StartWebSiteNetworkTrace
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-trace-start StartWebSiteNetworkTrace" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --durationInSeconds: int # The duration to keep capturing in seconds. (format: int32)
  --maxFrameLength: int # The maximum frame length in bytes (Optional). (format: int32)
  --sasUrl: string # The Blob URL to store capture file.
  --api-version: string # API Version
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationInSeconds" $durationInSeconds "scalar") (serialize-qp "maxFrameLength" $maxFrameLength "scalar") (serialize-qp "sasUrl" $sasUrl "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkTrace/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkTrace/startOperation
# operationId: WebApps_StartWebSiteNetworkTraceOperation
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-trace-start-operation StartWebSiteNetworkTraceOperation" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --durationInSeconds: int # The duration to keep capturing in seconds. (format: int32)
  --maxFrameLength: int # The maximum frame length in bytes (Optional). (format: int32)
  --sasUrl: string # The Blob URL to store capture file.
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationInSeconds" $durationInSeconds "scalar") (serialize-qp "maxFrameLength" $maxFrameLength "scalar") (serialize-qp "sasUrl" $sasUrl "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkTrace/startOperation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop ongoing capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkTrace/stop
# operationId: WebApps_StopWebSiteNetworkTrace
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-trace-stop StopWebSiteNetworkTrace" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkTrace/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkTrace/{operationId}
# operationId: WebApps_GetNetworkTraces
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-trace GetNetworkTraces" [
  resourceGroupName: string
  name: string
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
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkTrace/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkTraces/current/operationresults/{operationId}
# operationId: WebApps_GetNetworkTraceOperationV2
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-traces-current-operationresults GetNetworkTraceOperationV2" [
  resourceGroupName: string
  name: string
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
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkTraces/current/operationresults/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkTraces/{operationId}
# operationId: WebApps_GetNetworkTracesV2
export def "subscriptions-resource-groups-providers-microsoft-web-sites-network-traces GetNetworkTracesV2" [
  resourceGroupName: string
  name: string
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
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/networkTraces/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates a new publishing password for an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/newpassword
# operationId: WebApps_GenerateNewSitePublishingPassword
export def "subscriptions-resource-groups-providers-microsoft-web-sites-newpassword GenerateNewSitePublishingPassword" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/newpassword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets perfmon counters for web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/perfcounters
# operationId: WebApps_ListPerfMonCounters
export def "subscriptions-resource-groups-providers-microsoft-web-sites-perfcounters ListPerfMonCounters" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(startTime eq 2014-01-01T00:00:00Z and endTime eq 2014-12-31T23:59:59Z and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/perfcounters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets web app's event logs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/phplogging
# operationId: WebApps_GetSitePhpErrorLogFlag
export def "subscriptions-resource-groups-providers-microsoft-web-sites-phplogging GetSitePhpErrorLogFlag" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<localLogErrors: string, localLogErrorsMaxLength: string, masterLogErrors: string, masterLogErrorsMaxLength: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/phplogging" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the premier add-ons of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons
# operationId: WebApps_ListPremierAddOns
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons ListPremierAddOns" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/premieraddons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a premier add-on from an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
# operationId: WebApps_DeletePremierAddOn
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons DeletePremierAddOn" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/premieraddons/($premierAddOnName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named add-on of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
# operationId: WebApps_GetPremierAddOn
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons GetPremierAddOn" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/premieraddons/($premierAddOnName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a named add-on of an app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
# operationId: WebApps_UpdatePremierAddOn
# --properties shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons UpdatePremierAddOn" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PremierAddOnPatchResource resource specific properties — shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/premieraddons/($premierAddOnName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a named add-on of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
# operationId: WebApps_AddPremierAddOn
# --properties shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-premieraddons AddPremierAddOn" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PremierAddOn resource specific properties — shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
  --kind: string # Kind of resource.
  location: string # Resource Location.
  --tags: record # Resource tags.
]: any -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/premieraddons/($premierAddOnName)" $qp)
  let body = {properties: $properties, kind: $kind, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets data around private site access enablement and authorized Virtual Networks that can access the site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/privateAccess/virtualNetworks
# operationId: WebApps_GetPrivateAccess
export def "subscriptions-resource-groups-providers-microsoft-web-sites-private-access-virtual-networks GetPrivateAccess" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<enabled: bool, virtualNetworks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/privateAccess/virtualNetworks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets data around private site access enablement and authorized Virtual Networks that can access the site.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/privateAccess/virtualNetworks
# operationId: WebApps_PutPrivateAccessVnet
# --properties shape: {enabled?: bool, virtualNetworks?: list}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-private-access-virtual-networks PutPrivateAccessVnet" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PrivateAccess resource specific properties — shape: {enabled?: bool, virtualNetworks?: list}
  --kind: string # Kind of resource.
]: any -> record<properties: record<enabled: bool, virtualNetworks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/privateAccess/virtualNetworks" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of processes for a web site, or a deployment slot, or for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes
# operationId: WebApps_ListProcesses
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes ListProcesses" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Terminate a process by its ID for a web site, or a deployment slot, or specific scaled-out instance in a web site.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes/{processId}
# operationId: WebApps_DeleteProcess
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes DeleteProcess" [
  resourceGroupName: string
  name: string
  processId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes/{processId}
# operationId: WebApps_GetProcess
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes GetProcess" [
  resourceGroupName: string
  name: string
  processId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<children: list<string>, command_line: string, deployment_name: string, description: string, environment_variables: record, file_name: string, handle_count: int, href: string, identifier: int, iis_profile_timeout_in_seconds: float, is_iis_profile_running: bool, is_profile_running: bool, is_scm_site: bool, is_webjob: bool, minidump: string, module_count: int, modules: list<record>, non_paged_system_memory: int, open_file_handles: list<string>, paged_memory: int, paged_system_memory: int, parent: string, peak_paged_memory: int, peak_virtual_memory: int, peak_working_set: int, private_memory: int, privileged_cpu_time: string, start_time: string, thread_count: int, threads: list<record>, time_stamp: string, total_cpu_time: string, user_cpu_time: string, user_name: string, virtual_memory: int, working_set: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a memory dump of a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes/{processId}/dump
# operationId: WebApps_GetProcessDump
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes-dump GetProcessDump" [
  resourceGroupName: string
  name: string
  processId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes/($processId)/dump" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List module information for a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes/{processId}/modules
# operationId: WebApps_ListProcessModules
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes-modules ListProcessModules" [
  resourceGroupName: string
  name: string
  processId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes/($processId)/modules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes/{processId}/modules/{baseAddress}
# operationId: WebApps_GetProcessModule
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes-modules GetProcessModule" [
  resourceGroupName: string
  name: string
  processId: string
  baseAddress: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_address: string, file_description: string, file_name: string, file_path: string, file_version: string, href: string, is_debug: bool, language: string, module_memory_size: int, product: string, product_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes/($processId)/modules/($baseAddress)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the threads in a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes/{processId}/threads
# operationId: WebApps_ListProcessThreads
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes-threads ListProcessThreads" [
  resourceGroupName: string
  name: string
  processId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes/($processId)/threads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get thread information by Thread ID for a specific process, in a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/processes/{processId}/threads/{threadId}
# operationId: WebApps_GetProcessThread
export def "subscriptions-resource-groups-providers-microsoft-web-sites-processes-threads GetProcessThread" [
  resourceGroupName: string
  name: string
  processId: string
  threadId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_priority: int, current_priority: int, href: string, identifier: int, priority_level: string, priviledged_processor_time: string, process: string, start_address: string, start_time: string, state: string, total_processor_time: string, user_processor_time: string, wait_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/processes/($processId)/threads/($threadId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public certificates for an app or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publicCertificates
# operationId: WebApps_ListPublicCertificates
export def "subscriptions-resource-groups-providers-microsoft-web-sites-public-certificates ListPublicCertificates" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/publicCertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a hostname binding for an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publicCertificates/{publicCertificateName}
# operationId: WebApps_DeletePublicCertificate
export def "subscriptions-resource-groups-providers-microsoft-web-sites-public-certificates DeletePublicCertificate" [
  resourceGroupName: string
  name: string
  publicCertificateName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/publicCertificates/($publicCertificateName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the named public certificate for an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publicCertificates/{publicCertificateName}
# operationId: WebApps_GetPublicCertificate
export def "subscriptions-resource-groups-providers-microsoft-web-sites-public-certificates GetPublicCertificate" [
  resourceGroupName: string
  name: string
  publicCertificateName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<blob: string, publicCertificateLocation: string, thumbprint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/publicCertificates/($publicCertificateName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a hostname binding for an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publicCertificates/{publicCertificateName}
# operationId: WebApps_CreateOrUpdatePublicCertificate
# --properties shape: {blob?: string, publicCertificateLocation?: "CurrentUserMy"|"LocalMachineMy"|"Unknown"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-public-certificates CreateOrUpdatePublicCertificate" [
  resourceGroupName: string
  name: string
  publicCertificateName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PublicCertificate resource specific properties — shape: {blob?: string, publicCertificateLocation?: "CurrentUserMy"|"LocalMachineMy"|"Unknown"}
  --kind: string # Kind of resource.
]: any -> record<properties: record<blob: string, publicCertificateLocation: string, thumbprint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/publicCertificates/($publicCertificateName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the publishing profile for an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publishxml
# operationId: WebApps_ListPublishingProfileXmlWithSecrets
export def "subscriptions-resource-groups-providers-microsoft-web-sites-publishxml ListPublishingProfileXmlWithSecrets" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --format: string@format-completer # Name of the format. Valid values are:  FileZilla3 WebDeploy -- default Ftp
  --includeDisasterRecoveryEndpoints: oneof<nothing, bool> # Include the DisasterRecover endpoint if true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/publishxml" $qp)
  let body = {format: $format, includeDisasterRecoveryEndpoints: $includeDisasterRecoveryEndpoints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resets the configuration settings of the current slot if they were previously modified by calling the API with POST.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/resetSlotConfig
# operationId: WebApps_ResetProductionSlotConfig
export def "subscriptions-resource-groups-providers-microsoft-web-sites-reset-slot-config ResetProductionSlotConfig" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/resetSlotConfig" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/restart
# operationId: WebApps_Restart
export def "subscriptions-resource-groups-providers-microsoft-web-sites-restart Restart" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --softRestart: oneof<nothing, bool> # Specify true to apply the configuration settings and restarts the app only if necessary. By default, the API always restarts and reprovisions the app.
  --synchronous: oneof<nothing, bool> # Specify true to block until the app is restarted. By default, it is set to false, and the API responds immediately (asynchronous).
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "softRestart" $softRestart "scalar") (serialize-qp "synchronous" $synchronous "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores an app from a backup blob in Azure Storage.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/restoreFromBackupBlob
# operationId: WebApps_RestoreFromBackupBlob
# --properties shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-restore-from-backup-blob RestoreFromBackupBlob" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RestoreRequest resource specific properties — shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/restoreFromBackupBlob" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a deleted web app to this web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/restoreFromDeletedApp
# operationId: WebApps_RestoreFromDeletedApp
# --properties shape: {deletedSiteId?: string, recoverConfiguration?: bool, snapshotTime?: string, useDRSecondary?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-restore-from-deleted-app RestoreFromDeletedApp" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # DeletedAppRestoreRequest resource specific properties — shape: {deletedSiteId?: string, recoverConfiguration?: bool, snapshotTime?: string, useDRSecondary?: bool}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/restoreFromDeletedApp" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a web app from a snapshot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/restoreSnapshot
# operationId: WebApps_RestoreSnapshot
# --properties shape: {ignoreConflictingHostNames?: bool, overwrite: bool, recoverConfiguration?: bool, recoverySource?: record, snapshotTime?: string, useDRSecondary?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-restore-snapshot RestoreSnapshot" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SnapshotRestoreRequest resource specific properties — shape: {ignoreConflictingHostNames?: bool, overwrite: bool, recoverConfiguration?: bool, recoverySource?: record, snapshotTime?: string, useDRSecondary?: bool}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/restoreSnapshot" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of siteextensions for a web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/siteextensions
# operationId: WebApps_ListSiteExtensions
export def "subscriptions-resource-groups-providers-microsoft-web-sites-siteextensions ListSiteExtensions" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/siteextensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a site extension from a web site, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/siteextensions/{siteExtensionId}
# operationId: WebApps_DeleteSiteExtension
export def "subscriptions-resource-groups-providers-microsoft-web-sites-siteextensions DeleteSiteExtension" [
  resourceGroupName: string
  name: string
  siteExtensionId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/siteextensions/($siteExtensionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get site extension information by its ID for a web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/siteextensions/{siteExtensionId}
# operationId: WebApps_GetSiteExtension
export def "subscriptions-resource-groups-providers-microsoft-web-sites-siteextensions GetSiteExtension" [
  resourceGroupName: string
  name: string
  siteExtensionId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<authors: list<string>, comment: string, description: string, download_count: int, extension_id: string, extension_type: string, extension_url: string, feed_url: string, icon_url: string, installed_date_time: string, installer_command_line_params: string, license_url: string, local_is_latest_version: bool, local_path: string, project_url: string, provisioningState: string, published_date_time: string, summary: string, title: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/siteextensions/($siteExtensionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install site extension on a web site, or a deployment slot.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/siteextensions/{siteExtensionId}
# operationId: WebApps_InstallSiteExtension
export def "subscriptions-resource-groups-providers-microsoft-web-sites-siteextensions InstallSiteExtension" [
  resourceGroupName: string
  name: string
  siteExtensionId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<authors: list<string>, comment: string, description: string, download_count: int, extension_id: string, extension_type: string, extension_url: string, feed_url: string, icon_url: string, installed_date_time: string, installer_command_line_params: string, license_url: string, local_is_latest_version: bool, local_path: string, project_url: string, provisioningState: string, published_date_time: string, summary: string, title: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/siteextensions/($siteExtensionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an app's deployment slots.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots
# operationId: WebApps_ListSlots
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots ListSlots" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a web, mobile, or API app, or one of the deployment slots.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# operationId: WebApps_DeleteSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots DeleteSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteMetrics: oneof<nothing, bool> # If true, web app metrics are also deleted.
  --deleteEmptyServerFarm: oneof<nothing, bool> # Specify true if the App Service plan will be empty after app deletion and you want to delete the empty App Service plan. By default, the empty App Service plan is not deleted.
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteMetrics" $deleteMetrics "scalar") (serialize-qp "deleteEmptyServerFarm" $deleteEmptyServerFarm "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a web, mobile, or API app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# operationId: WebApps_GetSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots GetSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, clientCertExclusionPaths: string, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, sourceWebAppLocation: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, dailyMemoryTimeQuota: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, geoDistributions: list<record>, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, httpsOnly: bool, hyperV: bool, inProgressOperationId: string, isDefaultContainer: bool, isXenon: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, outboundIpAddresses: string, possibleOutboundIpAddresses: string, redundancyMode: string, repositorySiteName: string, reserved: bool, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<alwaysOn: bool, apiDefinition: record, appCommandLine: string, appSettings: list, autoHealEnabled: bool, autoHealRules: record, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list, cors: record, defaultDocuments: list, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record, ftpsState: string, handlerMappings: list, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>, slotSwapStatus: record<destinationSlotName: string, sourceSlotName: string, timestampUtc: string>, state: string, suspendedTill: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new web, mobile, or API app in an existing resource group, or updates an existing app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# operationId: WebApps_UpdateSlot
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots UpdateSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --identity: record # Managed service identity. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: any # SitePatchResource resource specific properties — shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
  --kind: string # Kind of resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, clientCertExclusionPaths: string, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, sourceWebAppLocation: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, dailyMemoryTimeQuota: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, geoDistributions: list<record>, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, httpsOnly: bool, hyperV: bool, inProgressOperationId: string, isDefaultContainer: bool, isXenon: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, outboundIpAddresses: string, possibleOutboundIpAddresses: string, redundancyMode: string, repositorySiteName: string, reserved: bool, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<alwaysOn: bool, apiDefinition: record, appCommandLine: string, appSettings: list, autoHealEnabled: bool, autoHealRules: record, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list, cors: record, defaultDocuments: list, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record, ftpsState: string, handlerMappings: list, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>, slotSwapStatus: record<destinationSlotName: string, sourceSlotName: string, timestampUtc: string>, state: string, suspendedTill: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)" $qp)
  let body = {identity: $identity, properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new web, mobile, or API app in an existing resource group, or updates an existing app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# operationId: WebApps_CreateOrUpdateSlot
# --identity shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots CreateOrUpdateSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --identity: record # Managed service identity. — shape: {type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: any # Site resource specific properties — shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, clientCertExclusionPaths?: string, cloningInfo?: record, containerSize?: int, dailyMemoryTimeQuota?: int, enabled?: bool, geoDistributions?: list, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, httpsOnly?: bool, hyperV?: bool, isXenon?: bool, redundancyMode?: "None"|"Manual"|"Failover"|"ActiveActive"|"GeoRedundant", reserved?: bool, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record, slotSwapStatus?: record}
  --kind: string # Kind of resource.
  location: string # Resource Location.
  --tags: record # Resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, clientCertExclusionPaths: string, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, sourceWebAppLocation: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, dailyMemoryTimeQuota: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, geoDistributions: list<record>, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, httpsOnly: bool, hyperV: bool, inProgressOperationId: string, isDefaultContainer: bool, isXenon: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, outboundIpAddresses: string, possibleOutboundIpAddresses: string, redundancyMode: string, repositorySiteName: string, reserved: bool, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<alwaysOn: bool, apiDefinition: record, appCommandLine: string, appSettings: list, autoHealEnabled: bool, autoHealRules: record, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list, cors: record, defaultDocuments: list, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record, ftpsState: string, handlerMappings: list, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>, slotSwapStatus: record<destinationSlotName: string, sourceSlotName: string, timestampUtc: string>, state: string, suspendedTill: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)" $qp)
  let body = {identity: $identity, properties: $properties, kind: $kind, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Analyze a custom hostname.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/analyzeCustomHostname
# operationId: WebApps_AnalyzeCustomHostnameSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-analyze-custom-hostname AnalyzeCustomHostnameSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hostName: string # Custom hostname.
  --api-version: string # API Version
]: nothing -> record<properties: record<aRecords: list<string>, alternateCNameRecords: list<string>, alternateTxtRecords: list<string>, cNameRecords: list<string>, conflictingAppResourceId: string, customDomainVerificationFailureInfo: record<code: string, extendedCode: string, innerErrors: list, message: string, messageTemplate: string, parameters: list>, customDomainVerificationTest: string, hasConflictAcrossSubscription: bool, hasConflictOnScaleUnit: bool, isHostnameAlreadyVerified: bool, txtRecords: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostName" $hostName "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/analyzeCustomHostname" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Applies the configuration settings from the target slot onto the current slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/applySlotConfig
# operationId: WebApps_ApplySlotConfigurationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-apply-slot-config ApplySlotConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --preserveVnet: oneof<nothing, bool> # <code>true</code> to preserve Virtual Network to the slot during swap; otherwise, <code>false</code>.
  targetSlot: string # Destination deployment slot during swap operation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/applySlotConfig" $qp)
  let body = {preserveVnet: $preserveVnet, targetSlot: $targetSlot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a backup of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backup
# operationId: WebApps_BackupSlot
# --properties shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backup BackupSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # BackupRequest resource specific properties — shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/backup" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets existing backups of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups
# operationId: WebApps_ListBackupsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups ListBackupsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/backups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a backup of an app by its ID.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}
# operationId: WebApps_DeleteBackupSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups DeleteBackupSlot" [
  resourceGroupName: string
  name: string
  backupId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/backups/($backupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a backup of an app by its ID.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}
# operationId: WebApps_GetBackupStatusSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups GetBackupStatusSlot" [
  resourceGroupName: string
  name: string
  backupId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/backups/($backupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets status of a web app backup that may be in progress, including secrets associated with the backup, such as the Azure Storage SAS URL. Also can be used to update the SAS URL for the backup if a new URL is passed in the request body.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/list
# operationId: WebApps_ListBackupStatusSecretsSlot
# --properties shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups-list ListBackupStatusSecretsSlot" [
  resourceGroupName: string
  name: string
  backupId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # BackupRequest resource specific properties — shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/backups/($backupId)/list" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a specific backup to another app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/restore
# operationId: WebApps_RestoreSlot
# --properties shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-backups-restore RestoreSlot" [
  resourceGroupName: string
  name: string
  backupId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RestoreRequest resource specific properties — shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/backups/($backupId)/restore" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the configurations of an app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config
# operationId: WebApps_ListConfigurationsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config ListConfigurationsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the application settings of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings
# operationId: WebApps_UpdateApplicationSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-appsettings UpdateApplicationSettingsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Settings.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/appsettings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the application settings of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings/list
# operationId: WebApps_ListApplicationSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-appsettings-list ListApplicationSettingsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/appsettings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Authentication / Authorization settings associated with web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings
# operationId: WebApps_UpdateAuthSettingsSlot
# --properties shape: {additionalLoginParams?: list, allowedAudiences?: list, allowedExternalRedirectUrls?: list, clientId?: string, clientSecret?: string, clientSecretCertificateThumbprint?: string, defaultProvider?: "AzureActiveDirectory"|"Facebook"|"Google"|"MicrosoftAccount"|"Twitter", enabled?: bool, facebookAppId?: string, facebookAppSecret?: string, facebookOAuthScopes?: list, googleClientId?: string, googleClientSecret?: string, googleOAuthScopes?: list, issuer?: string, microsoftAccountClientId?: string, microsoftAccountClientSecret?: string, microsoftAccountOAuthScopes?: list, runtimeVersion?: string, tokenRefreshExtensionHours?: float, tokenStoreEnabled?: bool, twitterConsumerKey?: string, twitterConsumerSecret?: string, unauthenticatedClientAction?: "RedirectToLoginPage"|"AllowAnonymous", validateIssuer?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-authsettings UpdateAuthSettingsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteAuthSettings resource specific properties — shape: {additionalLoginParams?: list, allowedAudiences?: list, allowedExternalRedirectUrls?: list, clientId?: string, clientSecret?: string, clientSecretCertificateThumbprint?: string, defaultProvider?: "AzureActiveDirectory"|"Facebook"|"Google"|"MicrosoftAccount"|"Twitter", enabled?: bool, facebookAppId?: string, facebookAppSecret?: string, facebookOAuthScopes?: list, googleClientId?: string, googleClientSecret?: string, googleOAuthScopes?: list, issuer?: string, microsoftAccountClientId?: string, microsoftAccountClientSecret?: string, microsoftAccountOAuthScopes?: list, runtimeVersion?: string, tokenRefreshExtensionHours?: float, tokenStoreEnabled?: bool, twitterConsumerKey?: string, twitterConsumerSecret?: string, unauthenticatedClientAction?: "RedirectToLoginPage"|"AllowAnonymous", validateIssuer?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, clientSecretCertificateThumbprint: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, runtimeVersion: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string, validateIssuer: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/authsettings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Authentication/Authorization settings of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings/list
# operationId: WebApps_GetAuthSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-authsettings-list GetAuthSettingsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, clientSecretCertificateThumbprint: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, runtimeVersion: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string, validateIssuer: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/authsettings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Azure storage account configurations of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/azurestorageaccounts
# operationId: WebApps_UpdateAzureStorageAccountsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-azurestorageaccounts UpdateAzureStorageAccountsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Azure storage accounts.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/azurestorageaccounts" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Azure storage account configurations of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/azurestorageaccounts/list
# operationId: WebApps_ListAzureStorageAccountsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-azurestorageaccounts-list ListAzureStorageAccountsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/azurestorageaccounts/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the backup configuration of an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup
# operationId: WebApps_DeleteBackupConfigurationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-backup DeleteBackupConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/backup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the backup configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup
# operationId: WebApps_UpdateBackupConfigurationSlot
# --properties shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-backup UpdateBackupConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # BackupRequest resource specific properties — shape: {backupName?: string, backupSchedule?: record, databases?: list, enabled?: bool, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<backupName: string, backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, storageAccountUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/backup" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the backup configuration of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup/list
# operationId: WebApps_GetBackupConfigurationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-backup-list GetBackupConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<backupName: string, backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, storageAccountUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/backup/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces the connection strings of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings
# operationId: WebApps_UpdateConnectionStringsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-connectionstrings UpdateConnectionStringsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Connection strings.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/connectionstrings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the connection strings of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings/list
# operationId: WebApps_ListConnectionStringsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-connectionstrings-list ListConnectionStringsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/connectionstrings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the logging configuration of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs
# operationId: WebApps_GetDiagnosticLogsConfigurationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-logs GetDiagnosticLogsConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the logging configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs
# operationId: WebApps_UpdateDiagnosticLogsConfigSlot
# --properties shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-logs UpdateDiagnosticLogsConfigSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteLogsConfig resource specific properties — shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
  --kind: string # Kind of resource.
]: any -> record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/logs" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replaces the metadata of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata
# operationId: WebApps_UpdateMetadataSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-metadata UpdateMetadataSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Settings.
  --kind: string # Kind of resource.
]: any -> record<properties: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/metadata" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the metadata of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata/list
# operationId: WebApps_ListMetadataSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-metadata-list ListMetadataSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/metadata/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Git/FTP publishing credentials of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/publishingcredentials/list
# operationId: WebApps_ListPublishingCredentialsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-publishingcredentials-list ListPublishingCredentialsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<publishingPassword: string, publishingPasswordHash: string, publishingPasswordHashSalt: string, publishingUserName: string, scmUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/publishingcredentials/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Push settings associated with web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/pushsettings
# operationId: WebApps_UpdateSitePushSettingsSlot
# --properties shape: {dynamicTagsJson?: string, isPushEnabled: bool, tagWhitelistJson?: string, tagsRequiringAuth?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-pushsettings UpdateSitePushSettingsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PushSettings resource specific properties — shape: {dynamicTagsJson?: string, isPushEnabled: bool, tagWhitelistJson?: string, tagsRequiringAuth?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<dynamicTagsJson: string, isPushEnabled: bool, tagWhitelistJson: string, tagsRequiringAuth: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/pushsettings" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Push settings associated with web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/pushsettings/list
# operationId: WebApps_ListSitePushSettingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-pushsettings-list ListSitePushSettingsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<dynamicTagsJson: string, isPushEnabled: bool, tagWhitelistJson: string, tagsRequiringAuth: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/pushsettings/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the configuration of an app, such as platform version and bitness, default documents, virtual applications, Always On, etc.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# operationId: WebApps_GetConfigurationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web GetConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/web" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the configuration of an app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# operationId: WebApps_UpdateConfigurationSlot
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web UpdateConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Configuration of an App Service app. — shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
  --kind: string # Kind of resource.
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# operationId: WebApps_CreateOrUpdateConfigurationSlot
# --properties shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web CreateOrUpdateConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # Configuration of an App Service app. — shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, azureStorageAccounts?: record, connectionStrings?: list, cors?: record, defaultDocuments?: list, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, ftpsState?: "AllAllowed"|"FtpsOnly"|"Disabled", handlerMappings?: list, http20Enabled?: bool, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, linuxFxVersion?: string, loadBalancing?: "WeightedRoundRobin"|"LeastRequests"|"LeastResponseTime"|"WeightedTotalTraffic"|"RequestHash", localMySqlEnabled?: bool, logsDirectorySizeLimit?: int, machineKey?: record, managedPipelineMode?: "Integrated"|"Classic", managedServiceIdentityId?: int, minTlsVersion?: "1.0"|"1.1"|"1.2", netFrameworkVersion?: string, nodeVersion?: string, numberOfWorkers?: int, phpVersion?: string, publishingUsername?: string, push?: record, pythonVersion?: string, remoteDebuggingEnabled?: bool, remoteDebuggingVersion?: string, requestTracingEnabled?: bool, requestTracingExpirationTime?: string, reservedInstanceCount?: int, scmIpSecurityRestrictions?: list, scmIpSecurityRestrictionsUseMain?: bool, scmType?: "None"|"Dropbox"|"Tfs"|"LocalGit"|"GitHub"|"CodePlexGit"|"CodePlexHg"|"BitbucketGit"|"BitbucketHg"|"ExternalGit"|"ExternalHg"|"OneDrive"|"VSO", tracingOptions?: string, use32BitWorkerProcess?: bool, virtualApplications?: list, vnetName?: string, webSocketsEnabled?: bool, windowsFxVersion?: string, xManagedServiceIdentityId?: int}
  --kind: string # Kind of resource.
]: any -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of web app configuration snapshots identifiers. Each element of the list contains a timestamp and the ID of the snapshot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web/snapshots
# operationId: WebApps_ListConfigurationSnapshotInfoSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web-snapshots ListConfigurationSnapshotInfoSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/web/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a snapshot of the configuration of an app at a previous point in time.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web/snapshots/{snapshotId}
# operationId: WebApps_GetConfigurationSnapshotSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web-snapshots GetConfigurationSnapshotSlot" [
  resourceGroupName: string
  name: string
  snapshotId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, azureStorageAccounts: record, connectionStrings: list<record>, cors: record<allowedOrigins: list, supportCredentials: bool>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, ftpsState: string, handlerMappings: list<record>, http20Enabled: bool, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, linuxFxVersion: string, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, machineKey: record<decryption: string, decryptionKey: string, validation: string, validationKey: string>, managedPipelineMode: string, managedServiceIdentityId: int, minTlsVersion: string, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingUsername: string, push: record<properties: record>, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, reservedInstanceCount: int, scmIpSecurityRestrictions: list<record>, scmIpSecurityRestrictionsUseMain: bool, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool, windowsFxVersion: string, xManagedServiceIdentityId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/web/snapshots/($snapshotId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reverts the configuration of an app to a previous snapshot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web/snapshots/{snapshotId}/recover
# operationId: WebApps_RecoverSiteConfigurationSnapshotSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-config-web-snapshots-recover RecoverSiteConfigurationSnapshotSlot" [
  resourceGroupName: string
  name: string
  snapshotId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/config/web/snapshots/($snapshotId)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the last lines of docker logs for the given site
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/containerlogs
# operationId: WebApps_GetWebSiteContainerLogsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-containerlogs GetWebSiteContainerLogsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/containerlogs" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the ZIP archived docker log files for the given site
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/containerlogs/zip/download
# operationId: WebApps_GetContainerLogsZipSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-containerlogs-zip-download GetContainerLogsZipSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/containerlogs/zip/download" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List continuous web jobs for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/continuouswebjobs
# operationId: WebApps_ListContinuousWebJobsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-continuouswebjobs ListContinuousWebJobsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/continuouswebjobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a continuous web job by its ID for an app, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/continuouswebjobs/{webJobName}
# operationId: WebApps_DeleteContinuousWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-continuouswebjobs DeleteContinuousWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/continuouswebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a continuous web job by its ID for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/continuouswebjobs/{webJobName}
# operationId: WebApps_GetContinuousWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-continuouswebjobs GetContinuousWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<detailed_status: string, error: string, extra_info_url: string, log_url: string, run_command: string, settings: record, status: string, url: string, using_sdk: bool, web_job_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/continuouswebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a continuous web job for an app, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/continuouswebjobs/{webJobName}/start
# operationId: WebApps_StartContinuousWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-continuouswebjobs-start StartContinuousWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/continuouswebjobs/($webJobName)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a continuous web job for an app, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/continuouswebjobs/{webJobName}/stop
# operationId: WebApps_StopContinuousWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-continuouswebjobs-stop StopContinuousWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/continuouswebjobs/($webJobName)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List deployments for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments
# operationId: WebApps_ListDeploymentsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments ListDeploymentsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a deployment by its ID for an app, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# operationId: WebApps_DeleteDeploymentSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments DeleteDeploymentSlot" [
  resourceGroupName: string
  name: string
  id: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/deployments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a deployment by its ID for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# operationId: WebApps_GetDeploymentSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments GetDeploymentSlot" [
  resourceGroupName: string
  name: string
  id: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/deployments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deployment for an app, or a deployment slot.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# operationId: WebApps_CreateDeploymentSlot
# --properties shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, message?: string, start_time?: string, status?: int}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments CreateDeploymentSlot" [
  resourceGroupName: string
  name: string
  id: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # Deployment resource specific properties — shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, message?: string, start_time?: string, status?: int}
  --kind: string # Kind of resource.
]: any -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, message: string, start_time: string, status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/deployments/($id)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List deployment log for specific deployment for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}/log
# operationId: WebApps_ListDeploymentLogSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-deployments-log ListDeploymentLogSlot" [
  resourceGroupName: string
  name: string
  id: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, message: string, start_time: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/deployments/($id)/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Discovers an existing app backup that can be restored from a blob in Azure storage. Use this to get information about the databases stored in a backup.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/discoverbackup
# operationId: WebApps_DiscoverBackupSlot
# --properties shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-discoverbackup DiscoverBackupSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RestoreRequest resource specific properties — shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<adjustConnectionStrings: bool, appServicePlan: string, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, ignoreDatabases: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/discoverbackup" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists ownership identifiers for domain associated with web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/domainOwnershipIdentifiers
# operationId: WebApps_ListDomainOwnershipIdentifiersSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-domain-ownership-identifiers ListDomainOwnershipIdentifiersSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/domainOwnershipIdentifiers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a domain ownership identifier for a web app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_DeleteDomainOwnershipIdentifierSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-domain-ownership-identifiers DeleteDomainOwnershipIdentifierSlot" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get domain ownership identifier for web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_GetDomainOwnershipIdentifierSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-domain-ownership-identifiers GetDomainOwnershipIdentifierSlot" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a domain ownership identifier for web app, or updates an existing ownership identifier.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_UpdateDomainOwnershipIdentifierSlot
# --properties shape: {id?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-domain-ownership-identifiers UpdateDomainOwnershipIdentifierSlot" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # Identifier resource specific properties — shape: {id?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a domain ownership identifier for web app, or updates an existing ownership identifier.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/domainOwnershipIdentifiers/{domainOwnershipIdentifierName}
# operationId: WebApps_CreateOrUpdateDomainOwnershipIdentifierSlot
# --properties shape: {id?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-domain-ownership-identifiers CreateOrUpdateDomainOwnershipIdentifierSlot" [
  resourceGroupName: string
  name: string
  domainOwnershipIdentifierName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # Identifier resource specific properties — shape: {id?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/domainOwnershipIdentifiers/($domainOwnershipIdentifierName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the status of the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/extensions/MSDeploy
# operationId: WebApps_GetMSDeployStatusSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-extensions-ms-deploy GetMSDeployStatusSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/extensions/MSDeploy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke the MSDeploy web app extension.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/extensions/MSDeploy
# operationId: WebApps_CreateMSDeployOperationSlot
# --properties shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-extensions-ms-deploy CreateMSDeployOperationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # MSDeploy ARM PUT core information — shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/extensions/MSDeploy" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the MSDeploy Log for the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/extensions/MSDeploy/log
# operationId: WebApps_GetMSDeployLogSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-extensions-ms-deploy-log GetMSDeployLogSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<entries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/extensions/MSDeploy/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the functions for a web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/functions
# operationId: WebApps_ListInstanceFunctionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-functions ListInstanceFunctionsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a short lived token that can be exchanged for a master key.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/functions/admin/token
# operationId: WebApps_GetFunctionsAdminTokenSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-functions-admin-token GetFunctionsAdminTokenSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/functions/admin/token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a function for web site, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/functions/{functionName}
# operationId: WebApps_DeleteInstanceFunctionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-functions DeleteInstanceFunctionSlot" [
  resourceGroupName: string
  name: string
  functionName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/functions/($functionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get function information by its ID for web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/functions/{functionName}
# operationId: WebApps_GetInstanceFunctionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-functions GetInstanceFunctionSlot" [
  resourceGroupName: string
  name: string
  functionName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<config: record, config_href: string, files: record, function_app_id: string, href: string, script_href: string, script_root_path_href: string, secrets_file_href: string, test_data: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/functions/($functionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create function for web site, or a deployment slot.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/functions/{functionName}
# operationId: WebApps_CreateInstanceFunctionSlot
# --properties shape: {config?: record, config_href?: string, files?: record, function_app_id?: string, href?: string, script_href?: string, script_root_path_href?: string, secrets_file_href?: string, test_data?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-functions CreateInstanceFunctionSlot" [
  resourceGroupName: string
  name: string
  functionName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # FunctionEnvelope resource specific properties — shape: {config?: record, config_href?: string, files?: record, function_app_id?: string, href?: string, script_href?: string, script_root_path_href?: string, secrets_file_href?: string, test_data?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<config: record, config_href: string, files: record, function_app_id: string, href: string, script_href: string, script_root_path_href: string, secrets_file_href: string, test_data: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/functions/($functionName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get function secrets for a function in a web site, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/functions/{functionName}/listsecrets
# operationId: WebApps_ListFunctionSecretsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-functions-listsecrets ListFunctionSecretsSlot" [
  resourceGroupName: string
  name: string
  functionName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<key: string, trigger_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/functions/($functionName)/listsecrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get hostname bindings for an app or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings
# operationId: WebApps_ListHostNameBindingsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings ListHostNameBindingsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hostNameBindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a hostname binding for an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# operationId: WebApps_DeleteHostNameBindingSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings DeleteHostNameBindingSlot" [
  resourceGroupName: string
  name: string
  slot: string
  hostName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hostNameBindings/($hostName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the named hostname binding for an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# operationId: WebApps_GetHostNameBindingSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings GetHostNameBindingSlot" [
  resourceGroupName: string
  name: string
  slot: string
  hostName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, siteName: string, sslState: string, thumbprint: string, virtualIP: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hostNameBindings/($hostName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a hostname binding for an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# operationId: WebApps_CreateOrUpdateHostNameBindingSlot
# --properties shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", siteName?: string, sslState?: "Disabled"|"SniEnabled"|"IpBasedEnabled", thumbprint?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-host-name-bindings CreateOrUpdateHostNameBindingSlot" [
  resourceGroupName: string
  name: string
  hostName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # HostNameBinding resource specific properties — shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", siteName?: string, sslState?: "Disabled"|"SniEnabled"|"IpBasedEnabled", thumbprint?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, siteName: string, sslState: string, thumbprint: string, virtualIP: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hostNameBindings/($hostName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a Hybrid Connection from this site.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_DeleteHybridConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybrid-connection-namespaces-relays DeleteHybridConnectionSlot" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific Service Bus Hybrid Connection used by this Web App.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_GetHybridConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybrid-connection-namespaces-relays GetHybridConnectionSlot" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Hybrid Connection using a Service Bus relay.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_UpdateHybridConnectionSlot
# --properties shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybrid-connection-namespaces-relays UpdateHybridConnectionSlot" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # HybridConnection resource specific properties — shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new Hybrid Connection using a Service Bus relay.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}
# operationId: WebApps_CreateOrUpdateHybridConnectionSlot
# --properties shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybrid-connection-namespaces-relays CreateOrUpdateHybridConnectionSlot" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # HybridConnection resource specific properties — shape: {hostname?: string, port?: int, relayArmUri?: string, relayName?: string, sendKeyName?: string, sendKeyValue?: string, serviceBusNamespace?: string, serviceBusSuffix?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the send key name and value for a Hybrid Connection.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridConnectionNamespaces/{namespaceName}/relays/{relayName}/listKeys
# operationId: WebApps_ListHybridConnectionKeysSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybrid-connection-namespaces-relays-list-keys ListHybridConnectionKeysSlot" [
  resourceGroupName: string
  name: string
  namespaceName: string
  relayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<sendKeyName: string, sendKeyValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridConnectionNamespaces/($namespaceName)/relays/($relayName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all Service Bus Hybrid Connections used by this Web App.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridConnectionRelays
# operationId: WebApps_ListHybridConnectionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybrid-connection-relays ListHybridConnectionsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<hostname: string, port: int, relayArmUri: string, relayName: string, sendKeyName: string, sendKeyValue: string, serviceBusNamespace: string, serviceBusSuffix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridConnectionRelays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets hybrid connections configured for an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection
# operationId: WebApps_ListRelayServiceConnectionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection ListRelayServiceConnectionsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridconnection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a relay service connection by its name.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: WebApps_DeleteRelayServiceConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection DeleteRelayServiceConnectionSlot" [
  resourceGroupName: string
  name: string
  entityName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridconnection/($entityName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a hybrid connection configuration by its name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: WebApps_GetRelayServiceConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection GetRelayServiceConnectionSlot" [
  resourceGroupName: string
  name: string
  entityName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridconnection/($entityName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new hybrid connection configuration (PUT), or updates an existing one (PATCH).
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: WebApps_UpdateRelayServiceConnectionSlot
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection UpdateRelayServiceConnectionSlot" [
  resourceGroupName: string
  name: string
  entityName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RelayServiceConnectionEntity resource specific properties — shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridconnection/($entityName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new hybrid connection configuration (PUT), or updates an existing one (PATCH).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# operationId: WebApps_CreateOrUpdateRelayServiceConnectionSlot
# --properties shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-hybridconnection CreateOrUpdateRelayServiceConnectionSlot" [
  resourceGroupName: string
  name: string
  entityName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RelayServiceConnectionEntity resource specific properties — shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/hybridconnection/($entityName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all scale-out instances of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances
# operationId: WebApps_ListInstanceIdentifiersSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances ListInstanceIdentifiersSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the status of the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/extensions/MSDeploy
# operationId: WebApps_GetInstanceMsDeployStatusSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-extensions-ms-deploy GetInstanceMsDeployStatusSlot" [
  resourceGroupName: string
  name: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/extensions/MSDeploy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoke the MSDeploy web app extension.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/extensions/MSDeploy
# operationId: WebApps_CreateInstanceMSDeployOperationSlot
# --properties shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-extensions-ms-deploy CreateInstanceMSDeployOperationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: record # MSDeploy ARM PUT core information — shape: {appOffline?: bool, connectionString?: string, dbType?: string, packageUri?: string, setParameters?: record, setParametersXmlFileUri?: string, skipAppData?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<complete: bool, deployer: string, endTime: string, provisioningState: string, startTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/extensions/MSDeploy" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the MSDeploy Log for the last MSDeploy operation.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/extensions/MSDeploy/log
# operationId: WebApps_GetInstanceMSDeployLogSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-extensions-ms-deploy-log GetInstanceMSDeployLogSlot" [
  resourceGroupName: string
  name: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<entries: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/extensions/MSDeploy/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of processes for a web site, or a deployment slot, or for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes
# operationId: WebApps_ListInstanceProcessesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes ListInstanceProcessesSlot" [
  resourceGroupName: string
  name: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Terminate a process by its ID for a web site, or a deployment slot, or specific scaled-out instance in a web site.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes/{processId}
# operationId: WebApps_DeleteInstanceProcessSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes DeleteInstanceProcessSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes/{processId}
# operationId: WebApps_GetInstanceProcessSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes GetInstanceProcessSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<children: list<string>, command_line: string, deployment_name: string, description: string, environment_variables: record, file_name: string, handle_count: int, href: string, identifier: int, iis_profile_timeout_in_seconds: float, is_iis_profile_running: bool, is_profile_running: bool, is_scm_site: bool, is_webjob: bool, minidump: string, module_count: int, modules: list<record>, non_paged_system_memory: int, open_file_handles: list<string>, paged_memory: int, paged_system_memory: int, parent: string, peak_paged_memory: int, peak_virtual_memory: int, peak_working_set: int, private_memory: int, privileged_cpu_time: string, start_time: string, thread_count: int, threads: list<record>, time_stamp: string, total_cpu_time: string, user_cpu_time: string, user_name: string, virtual_memory: int, working_set: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a memory dump of a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes/{processId}/dump
# operationId: WebApps_GetInstanceProcessDumpSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes-dump GetInstanceProcessDumpSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes/($processId)/dump" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List module information for a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes/{processId}/modules
# operationId: WebApps_ListInstanceProcessModulesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes-modules ListInstanceProcessModulesSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes/($processId)/modules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes/{processId}/modules/{baseAddress}
# operationId: WebApps_GetInstanceProcessModuleSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes-modules GetInstanceProcessModuleSlot" [
  resourceGroupName: string
  name: string
  processId: string
  baseAddress: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_address: string, file_description: string, file_name: string, file_path: string, file_version: string, href: string, is_debug: bool, language: string, module_memory_size: int, product: string, product_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes/($processId)/modules/($baseAddress)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the threads in a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes/{processId}/threads
# operationId: WebApps_ListInstanceProcessThreadsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes-threads ListInstanceProcessThreadsSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes/($processId)/threads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get thread information by Thread ID for a specific process, in a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/processes/{processId}/threads/{threadId}
# operationId: WebApps_GetInstanceProcessThreadSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-instances-processes-threads GetInstanceProcessThreadSlot" [
  resourceGroupName: string
  name: string
  processId: string
  threadId: string
  slot: string
  instanceId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_priority: int, current_priority: int, href: string, identifier: int, priority_level: string, priviledged_processor_time: string, process: string, start_address: string, start_time: string, state: string, total_processor_time: string, user_processor_time: string, wait_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/instances/($instanceId)/processes/($processId)/threads/($threadId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shows whether an app can be cloned to another resource group or subscription.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/iscloneable
# operationId: WebApps_IsCloneableSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-iscloneable IsCloneableSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/iscloneable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This is to allow calling via powershell and ARM template.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/listsyncfunctiontriggerstatus
# operationId: WebApps_ListSyncFunctionTriggersSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-listsyncfunctiontriggerstatus ListSyncFunctionTriggersSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<key: string, trigger_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/listsyncfunctiontriggerstatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all metric definitions of an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metricdefinitions
# operationId: WebApps_ListMetricDefinitionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-metricdefinitions ListMetricDefinitionsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/metricdefinitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets performance metrics of an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metrics
# operationId: WebApps_ListMetricsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-metrics ListMetricsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: oneof<nothing, bool> # Specify "true" to include metric details in the response. It is "false" by default.
  --filter: string # Return only metrics specified in the filter (using OData syntax). For example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq 2014-01-01T00:00:00Z and endTime eq 2014-12-31T23:59:59Z and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<endTime: string, id: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the status of MySql in app migration, if one is active, and whether or not MySql in app is enabled
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/migratemysql/status
# operationId: WebApps_GetMigrateMySqlStatusSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-migratemysql-status GetMigrateMySqlStatusSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<localMySqlEnabled: bool, migrationOperationStatus: string, operationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/migratemysql/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Swift Virtual Network connection from an app (or deployment slot).
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkConfig/virtualNetwork
# operationId: WebApps_DeleteSwiftVirtualNetworkSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-config-virtual-network DeleteSwiftVirtualNetworkSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkConfig/virtualNetwork" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Swift Virtual Network connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkConfig/virtualNetwork
# operationId: WebApps_GetSwiftVirtualNetworkConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-config-virtual-network GetSwiftVirtualNetworkConnectionSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<subnetResourceId: string, swiftSupported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkConfig/virtualNetwork" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Integrates this Web App with a Virtual Network. This requires that 1) "swiftSupported" is true when doing a GET against this resource, and 2) that the target Subnet has already been delegated, and is not in use by another App Service Plan other than the one this App is in.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkConfig/virtualNetwork
# operationId: WebApps_UpdateSwiftVirtualNetworkConnectionSlot
# --properties shape: {subnetResourceId?: string, swiftSupported?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-config-virtual-network UpdateSwiftVirtualNetworkConnectionSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SwiftVirtualNetwork resource specific properties — shape: {subnetResourceId?: string, swiftSupported?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<subnetResourceId: string, swiftSupported: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkConfig/virtualNetwork" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Integrates this Web App with a Virtual Network. This requires that 1) "swiftSupported" is true when doing a GET against this resource, and 2) that the target Subnet has already been delegated, and is not in use by another App Service Plan other than the one this App is in.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkConfig/virtualNetwork
# operationId: WebApps_CreateOrUpdateSwiftVirtualNetworkConnectionSlot
# --properties shape: {subnetResourceId?: string, swiftSupported?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-config-virtual-network CreateOrUpdateSwiftVirtualNetworkConnectionSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SwiftVirtualNetwork resource specific properties — shape: {subnetResourceId?: string, swiftSupported?: bool}
  --kind: string # Kind of resource.
]: any -> record<properties: record<subnetResourceId: string, swiftSupported: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkConfig/virtualNetwork" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all network features used by the app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkFeatures/{view}
# operationId: WebApps_ListNetworkFeaturesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-features ListNetworkFeaturesSlot" [
  resourceGroupName: string
  name: string
  view: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<hybridConnections: list<record>, hybridConnectionsV2: list<record>, virtualNetworkConnection: record<properties: record>, virtualNetworkName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkFeatures/($view)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkTrace/operationresults/{operationId}
# operationId: WebApps_GetNetworkTraceOperationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-trace-operationresults GetNetworkTraceOperationSlot" [
  resourceGroupName: string
  name: string
  operationId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkTrace/operationresults/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start capturing network packets for the site (To be deprecated).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkTrace/start
# operationId: WebApps_StartWebSiteNetworkTraceSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-trace-start StartWebSiteNetworkTraceSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --durationInSeconds: int # The duration to keep capturing in seconds. (format: int32)
  --maxFrameLength: int # The maximum frame length in bytes (Optional). (format: int32)
  --sasUrl: string # The Blob URL to store capture file.
  --api-version: string # API Version
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationInSeconds" $durationInSeconds "scalar") (serialize-qp "maxFrameLength" $maxFrameLength "scalar") (serialize-qp "sasUrl" $sasUrl "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkTrace/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkTrace/startOperation
# operationId: WebApps_StartWebSiteNetworkTraceOperationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-trace-start-operation StartWebSiteNetworkTraceOperationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --durationInSeconds: int # The duration to keep capturing in seconds. (format: int32)
  --maxFrameLength: int # The maximum frame length in bytes (Optional). (format: int32)
  --sasUrl: string # The Blob URL to store capture file.
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationInSeconds" $durationInSeconds "scalar") (serialize-qp "maxFrameLength" $maxFrameLength "scalar") (serialize-qp "sasUrl" $sasUrl "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkTrace/startOperation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop ongoing capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkTrace/stop
# operationId: WebApps_StopWebSiteNetworkTraceSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-trace-stop StopWebSiteNetworkTraceSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkTrace/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkTrace/{operationId}
# operationId: WebApps_GetNetworkTracesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-trace GetNetworkTracesSlot" [
  resourceGroupName: string
  name: string
  operationId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkTrace/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkTraces/current/operationresults/{operationId}
# operationId: WebApps_GetNetworkTraceOperationSlotV2
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-traces-current-operationresults GetNetworkTraceOperationSlotV2" [
  resourceGroupName: string
  name: string
  operationId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkTraces/current/operationresults/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named operation for a network trace capturing (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkTraces/{operationId}
# operationId: WebApps_GetNetworkTracesSlotV2
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-network-traces GetNetworkTracesSlotV2" [
  resourceGroupName: string
  name: string
  operationId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/networkTraces/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates a new publishing password for an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/newpassword
# operationId: WebApps_GenerateNewSitePublishingPasswordSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-newpassword GenerateNewSitePublishingPasswordSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/newpassword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets perfmon counters for web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/perfcounters
# operationId: WebApps_ListPerfMonCountersSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-perfcounters ListPerfMonCountersSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(startTime eq 2014-01-01T00:00:00Z and endTime eq 2014-12-31T23:59:59Z and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/perfcounters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets web app's event logs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/phplogging
# operationId: WebApps_GetSitePhpErrorLogFlagSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-phplogging GetSitePhpErrorLogFlagSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<localLogErrors: string, localLogErrorsMaxLength: string, masterLogErrors: string, masterLogErrorsMaxLength: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/phplogging" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the premier add-ons of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons
# operationId: WebApps_ListPremierAddOnsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons ListPremierAddOnsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/premieraddons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a premier add-on from an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
# operationId: WebApps_DeletePremierAddOnSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons DeletePremierAddOnSlot" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/premieraddons/($premierAddOnName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a named add-on of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
# operationId: WebApps_GetPremierAddOnSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons GetPremierAddOnSlot" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/premieraddons/($premierAddOnName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a named add-on of an app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
# operationId: WebApps_UpdatePremierAddOnSlot
# --properties shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons UpdatePremierAddOnSlot" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PremierAddOnPatchResource resource specific properties — shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/premieraddons/($premierAddOnName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a named add-on of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
# operationId: WebApps_AddPremierAddOnSlot
# --properties shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-premieraddons AddPremierAddOnSlot" [
  resourceGroupName: string
  name: string
  premierAddOnName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PremierAddOn resource specific properties — shape: {marketplaceOffer?: string, marketplacePublisher?: string, product?: string, sku?: string, vendor?: string}
  --kind: string # Kind of resource.
  location: string # Resource Location.
  --tags: record # Resource tags.
]: any -> record<properties: record<marketplaceOffer: string, marketplacePublisher: string, product: string, sku: string, vendor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/premieraddons/($premierAddOnName)" $qp)
  let body = {properties: $properties, kind: $kind, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets data around private site access enablement and authorized Virtual Networks that can access the site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/privateAccess/virtualNetworks
# operationId: WebApps_GetPrivateAccessSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-private-access-virtual-networks GetPrivateAccessSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<enabled: bool, virtualNetworks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/privateAccess/virtualNetworks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets data around private site access enablement and authorized Virtual Networks that can access the site.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/privateAccess/virtualNetworks
# operationId: WebApps_PutPrivateAccessVnetSlot
# --properties shape: {enabled?: bool, virtualNetworks?: list}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-private-access-virtual-networks PutPrivateAccessVnetSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PrivateAccess resource specific properties — shape: {enabled?: bool, virtualNetworks?: list}
  --kind: string # Kind of resource.
]: any -> record<properties: record<enabled: bool, virtualNetworks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/privateAccess/virtualNetworks" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of processes for a web site, or a deployment slot, or for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes
# operationId: WebApps_ListProcessesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes ListProcessesSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Terminate a process by its ID for a web site, or a deployment slot, or specific scaled-out instance in a web site.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes/{processId}
# operationId: WebApps_DeleteProcessSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes DeleteProcessSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes/{processId}
# operationId: WebApps_GetProcessSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes GetProcessSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<children: list<string>, command_line: string, deployment_name: string, description: string, environment_variables: record, file_name: string, handle_count: int, href: string, identifier: int, iis_profile_timeout_in_seconds: float, is_iis_profile_running: bool, is_profile_running: bool, is_scm_site: bool, is_webjob: bool, minidump: string, module_count: int, modules: list<record>, non_paged_system_memory: int, open_file_handles: list<string>, paged_memory: int, paged_system_memory: int, parent: string, peak_paged_memory: int, peak_virtual_memory: int, peak_working_set: int, private_memory: int, privileged_cpu_time: string, start_time: string, thread_count: int, threads: list<record>, time_stamp: string, total_cpu_time: string, user_cpu_time: string, user_name: string, virtual_memory: int, working_set: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes/($processId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a memory dump of a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes/{processId}/dump
# operationId: WebApps_GetProcessDumpSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes-dump GetProcessDumpSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes/($processId)/dump" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List module information for a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes/{processId}/modules
# operationId: WebApps_ListProcessModulesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes-modules ListProcessModulesSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes/($processId)/modules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get process information by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes/{processId}/modules/{baseAddress}
# operationId: WebApps_GetProcessModuleSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes-modules GetProcessModuleSlot" [
  resourceGroupName: string
  name: string
  processId: string
  baseAddress: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_address: string, file_description: string, file_name: string, file_path: string, file_version: string, href: string, is_debug: bool, language: string, module_memory_size: int, product: string, product_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes/($processId)/modules/($baseAddress)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the threads in a process by its ID for a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes/{processId}/threads
# operationId: WebApps_ListProcessThreadsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes-threads ListProcessThreadsSlot" [
  resourceGroupName: string
  name: string
  processId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes/($processId)/threads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get thread information by Thread ID for a specific process, in a specific scaled-out instance in a web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/processes/{processId}/threads/{threadId}
# operationId: WebApps_GetProcessThreadSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-processes-threads GetProcessThreadSlot" [
  resourceGroupName: string
  name: string
  processId: string
  threadId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<base_priority: int, current_priority: int, href: string, identifier: int, priority_level: string, priviledged_processor_time: string, process: string, start_address: string, start_time: string, state: string, total_processor_time: string, user_processor_time: string, wait_reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/processes/($processId)/threads/($threadId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public certificates for an app or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publicCertificates
# operationId: WebApps_ListPublicCertificatesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-public-certificates ListPublicCertificatesSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/publicCertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a hostname binding for an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publicCertificates/{publicCertificateName}
# operationId: WebApps_DeletePublicCertificateSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-public-certificates DeletePublicCertificateSlot" [
  resourceGroupName: string
  name: string
  slot: string
  publicCertificateName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/publicCertificates/($publicCertificateName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the named public certificate for an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publicCertificates/{publicCertificateName}
# operationId: WebApps_GetPublicCertificateSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-public-certificates GetPublicCertificateSlot" [
  resourceGroupName: string
  name: string
  slot: string
  publicCertificateName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<blob: string, publicCertificateLocation: string, thumbprint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/publicCertificates/($publicCertificateName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a hostname binding for an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publicCertificates/{publicCertificateName}
# operationId: WebApps_CreateOrUpdatePublicCertificateSlot
# --properties shape: {blob?: string, publicCertificateLocation?: "CurrentUserMy"|"LocalMachineMy"|"Unknown"}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-public-certificates CreateOrUpdatePublicCertificateSlot" [
  resourceGroupName: string
  name: string
  publicCertificateName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # PublicCertificate resource specific properties — shape: {blob?: string, publicCertificateLocation?: "CurrentUserMy"|"LocalMachineMy"|"Unknown"}
  --kind: string # Kind of resource.
]: any -> record<properties: record<blob: string, publicCertificateLocation: string, thumbprint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/publicCertificates/($publicCertificateName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the publishing profile for an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publishxml
# operationId: WebApps_ListPublishingProfileXmlWithSecretsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-publishxml ListPublishingProfileXmlWithSecretsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --format: string@format-completer # Name of the format. Valid values are:  FileZilla3 WebDeploy -- default Ftp
  --includeDisasterRecoveryEndpoints: oneof<nothing, bool> # Include the DisasterRecover endpoint if true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/publishxml" $qp)
  let body = {format: $format, includeDisasterRecoveryEndpoints: $includeDisasterRecoveryEndpoints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resets the configuration settings of the current slot if they were previously modified by calling the API with POST.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/resetSlotConfig
# operationId: WebApps_ResetSlotConfigurationSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-reset-slot-config ResetSlotConfigurationSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/resetSlotConfig" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restart
# operationId: WebApps_RestartSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-restart RestartSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --softRestart: oneof<nothing, bool> # Specify true to apply the configuration settings and restarts the app only if necessary. By default, the API always restarts and reprovisions the app.
  --synchronous: oneof<nothing, bool> # Specify true to block until the app is restarted. By default, it is set to false, and the API responds immediately (asynchronous).
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "softRestart" $softRestart "scalar") (serialize-qp "synchronous" $synchronous "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores an app from a backup blob in Azure Storage.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restoreFromBackupBlob
# operationId: WebApps_RestoreFromBackupBlobSlot
# --properties shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-restore-from-backup-blob RestoreFromBackupBlobSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # RestoreRequest resource specific properties — shape: {adjustConnectionStrings?: bool, appServicePlan?: string, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, ignoreDatabases?: bool, operationType?: "Default"|"Clone"|"Relocation"|"Snapshot"|"CloudFS", overwrite: bool, siteName?: string, storageAccountUrl: string}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/restoreFromBackupBlob" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a deleted web app to this web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restoreFromDeletedApp
# operationId: WebApps_RestoreFromDeletedAppSlot
# --properties shape: {deletedSiteId?: string, recoverConfiguration?: bool, snapshotTime?: string, useDRSecondary?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-restore-from-deleted-app RestoreFromDeletedAppSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # DeletedAppRestoreRequest resource specific properties — shape: {deletedSiteId?: string, recoverConfiguration?: bool, snapshotTime?: string, useDRSecondary?: bool}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/restoreFromDeletedApp" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a web app from a snapshot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restoreSnapshot
# operationId: WebApps_RestoreSnapshotSlot
# --properties shape: {ignoreConflictingHostNames?: bool, overwrite: bool, recoverConfiguration?: bool, recoverySource?: record, snapshotTime?: string, useDRSecondary?: bool}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-restore-snapshot RestoreSnapshotSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SnapshotRestoreRequest resource specific properties — shape: {ignoreConflictingHostNames?: bool, overwrite: bool, recoverConfiguration?: bool, recoverySource?: record, snapshotTime?: string, useDRSecondary?: bool}
  --kind: string # Kind of resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/restoreSnapshot" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of siteextensions for a web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/siteextensions
# operationId: WebApps_ListSiteExtensionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-siteextensions ListSiteExtensionsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/siteextensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a site extension from a web site, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/siteextensions/{siteExtensionId}
# operationId: WebApps_DeleteSiteExtensionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-siteextensions DeleteSiteExtensionSlot" [
  resourceGroupName: string
  name: string
  siteExtensionId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/siteextensions/($siteExtensionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get site extension information by its ID for a web site, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/siteextensions/{siteExtensionId}
# operationId: WebApps_GetSiteExtensionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-siteextensions GetSiteExtensionSlot" [
  resourceGroupName: string
  name: string
  siteExtensionId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<authors: list<string>, comment: string, description: string, download_count: int, extension_id: string, extension_type: string, extension_url: string, feed_url: string, icon_url: string, installed_date_time: string, installer_command_line_params: string, license_url: string, local_is_latest_version: bool, local_path: string, project_url: string, provisioningState: string, published_date_time: string, summary: string, title: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/siteextensions/($siteExtensionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install site extension on a web site, or a deployment slot.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/siteextensions/{siteExtensionId}
# operationId: WebApps_InstallSiteExtensionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-siteextensions InstallSiteExtensionSlot" [
  resourceGroupName: string
  name: string
  siteExtensionId: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<authors: list<string>, comment: string, description: string, download_count: int, extension_id: string, extension_type: string, extension_url: string, feed_url: string, icon_url: string, installed_date_time: string, installer_command_line_params: string, license_url: string, local_is_latest_version: bool, local_path: string, project_url: string, provisioningState: string, published_date_time: string, summary: string, title: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/siteextensions/($siteExtensionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the difference in configuration settings between two web app slots.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsdiffs
# operationId: WebApps_ListSlotDifferencesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-slotsdiffs ListSlotDifferencesSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --preserveVnet: oneof<nothing, bool> # <code>true</code> to preserve Virtual Network to the slot during swap; otherwise, <code>false</code>.
  targetSlot: string # Destination deployment slot during swap operation.
]: any -> record<nextLink: string, value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/slotsdiffs" $qp)
  let body = {preserveVnet: $preserveVnet, targetSlot: $targetSlot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Swaps two deployment slots of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsswap
# operationId: WebApps_SwapSlotSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-slotsswap SwapSlotSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --preserveVnet: oneof<nothing, bool> # <code>true</code> to preserve Virtual Network to the slot during swap; otherwise, <code>false</code>.
  targetSlot: string # Destination deployment slot during swap operation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/slotsswap" $qp)
  let body = {preserveVnet: $preserveVnet, targetSlot: $targetSlot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all Snapshots to the user.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/snapshots
# operationId: WebApps_ListSnapshotsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-snapshots ListSnapshotsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all Snapshots to the user from DRSecondary endpoint.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/snapshotsdr
# operationId: WebApps_ListSnapshotsFromDRSecondarySlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-snapshotsdr ListSnapshotsFromDRSecondarySlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/snapshotsdr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the source control configuration of an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: WebApps_DeleteSourceControlSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web DeleteSourceControlSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/sourcecontrols/web" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the source control configuration of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: WebApps_GetSourceControlSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web GetSourceControlSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/sourcecontrols/web" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the source control configuration of an app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: WebApps_UpdateSourceControlSlot
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web UpdateSourceControlSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteSourceControl resource specific properties — shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/sourcecontrols/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the source control configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# operationId: WebApps_CreateOrUpdateSourceControlSlot
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sourcecontrols-web CreateOrUpdateSourceControlSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteSourceControl resource specific properties — shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/sourcecontrols/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/start
# operationId: WebApps_StartSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-start StartSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/startNetworkTrace
# operationId: WebApps_StartNetworkTraceSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-start-network-trace StartNetworkTraceSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --durationInSeconds: int # The duration to keep capturing in seconds. (format: int32)
  --maxFrameLength: int # The maximum frame length in bytes (Optional). (format: int32)
  --sasUrl: string # The Blob URL to store capture file.
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationInSeconds" $durationInSeconds "scalar") (serialize-qp "maxFrameLength" $maxFrameLength "scalar") (serialize-qp "sasUrl" $sasUrl "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/startNetworkTrace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/stop
# operationId: WebApps_StopSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-stop StopSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop ongoing capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/stopNetworkTrace
# operationId: WebApps_StopNetworkTraceSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-stop-network-trace StopNetworkTraceSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/stopNetworkTrace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sync web app repository.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sync
# operationId: WebApps_SyncRepositorySlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-sync SyncRepositorySlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Syncs function trigger metadata to the scale controller
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/syncfunctiontriggers
# operationId: WebApps_SyncFunctionTriggersSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-syncfunctiontriggers SyncFunctionTriggersSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/syncfunctiontriggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List triggered web jobs for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/triggeredwebjobs
# operationId: WebApps_ListTriggeredWebJobsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-triggeredwebjobs ListTriggeredWebJobsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/triggeredwebjobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a triggered web job by its ID for an app, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/triggeredwebjobs/{webJobName}
# operationId: WebApps_DeleteTriggeredWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-triggeredwebjobs DeleteTriggeredWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/triggeredwebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a triggered web job by its ID for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/triggeredwebjobs/{webJobName}
# operationId: WebApps_GetTriggeredWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-triggeredwebjobs GetTriggeredWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<error: string, extra_info_url: string, history_url: string, latest_run: record<properties: record>, run_command: string, scheduler_logs_url: string, settings: record, url: string, using_sdk: bool, web_job_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/triggeredwebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a triggered web job's history for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/triggeredwebjobs/{webJobName}/history
# operationId: WebApps_ListTriggeredWebJobHistorySlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-triggeredwebjobs-history ListTriggeredWebJobHistorySlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/triggeredwebjobs/($webJobName)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a triggered web job's history by its ID for an app, , or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/triggeredwebjobs/{webJobName}/history/{id}
# operationId: WebApps_GetTriggeredWebJobHistorySlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-triggeredwebjobs-history GetTriggeredWebJobHistorySlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  id: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<runs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/triggeredwebjobs/($webJobName)/history/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a triggered web job for an app, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/triggeredwebjobs/{webJobName}/run
# operationId: WebApps_RunTriggeredWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-triggeredwebjobs-run RunTriggeredWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/triggeredwebjobs/($webJobName)/run" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the quota usage information of an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/usages
# operationId: WebApps_ListUsagesSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-usages ListUsagesSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Return only information specified in the filter (using OData syntax). For example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq 2014-01-01T00:00:00Z and endTime eq 2014-12-31T23:59:59Z and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/usages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the virtual networks the app (or deployment slot) is connected to.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections
# operationId: WebApps_ListVnetConnectionsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections ListVnetConnectionsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a connection from an app (or deployment slot to a named virtual network.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_DeleteVnetConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections DeleteVnetConnectionSlot" [
  resourceGroupName: string
  name: string
  vnetName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections/($vnetName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a virtual network the app (or deployment slot) is connected to by name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_GetVnetConnectionSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections GetVnetConnectionSlot" [
  resourceGroupName: string
  name: string
  vnetName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections/($vnetName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a Virtual Network connection to an app or slot (PUT) or updates the connection properties (PATCH).
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_UpdateVnetConnectionSlot
# --properties shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections UpdateVnetConnectionSlot" [
  resourceGroupName: string
  name: string
  vnetName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetInfo resource specific properties — shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections/($vnetName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a Virtual Network connection to an app or slot (PUT) or updates the connection properties (PATCH).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_CreateOrUpdateVnetConnectionSlot
# --properties shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections CreateOrUpdateVnetConnectionSlot" [
  resourceGroupName: string
  name: string
  vnetName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetInfo resource specific properties — shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections/($vnetName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets an app's Virtual Network gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: WebApps_GetVnetConnectionGatewaySlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections-gateways GetVnetConnectionGatewaySlot" [
  resourceGroupName: string
  name: string
  vnetName: string
  gatewayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections/($vnetName)/gateways/($gatewayName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a gateway to a connected Virtual Network (PUT) or updates it (PATCH).
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: WebApps_UpdateVnetConnectionGatewaySlot
# --properties shape: {vnetName?: string, vpnPackageUri: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections-gateways UpdateVnetConnectionGatewaySlot" [
  resourceGroupName: string
  name: string
  vnetName: string
  gatewayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetGateway resource specific properties — shape: {vnetName?: string, vpnPackageUri: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections/($vnetName)/gateways/($gatewayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a gateway to a connected Virtual Network (PUT) or updates it (PATCH).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: WebApps_CreateOrUpdateVnetConnectionGatewaySlot
# --properties shape: {vnetName?: string, vpnPackageUri: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-virtual-network-connections-gateways CreateOrUpdateVnetConnectionGatewaySlot" [
  resourceGroupName: string
  name: string
  vnetName: string
  gatewayName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetGateway resource specific properties — shape: {vnetName?: string, vpnPackageUri: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/virtualNetworkConnections/($vnetName)/gateways/($gatewayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List webjobs for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/webjobs
# operationId: WebApps_ListWebJobsSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-webjobs ListWebJobsSlot" [
  resourceGroupName: string
  name: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/webjobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webjob information for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/webjobs/{webJobName}
# operationId: WebApps_GetWebJobSlot
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slots-webjobs GetWebJobSlot" [
  resourceGroupName: string
  name: string
  webJobName: string
  slot: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<error: string, extra_info_url: string, run_command: string, settings: record, url: string, using_sdk: bool, web_job_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slots/($slot)/webjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the difference in configuration settings between two web app slots.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsdiffs
# operationId: WebApps_ListSlotDifferencesFromProduction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slotsdiffs ListSlotDifferencesFromProduction" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --preserveVnet: oneof<nothing, bool> # <code>true</code> to preserve Virtual Network to the slot during swap; otherwise, <code>false</code>.
  targetSlot: string # Destination deployment slot during swap operation.
]: any -> record<nextLink: string, value: table<properties: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slotsdiffs" $qp)
  let body = {preserveVnet: $preserveVnet, targetSlot: $targetSlot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Swaps two deployment slots of an app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsswap
# operationId: WebApps_SwapSlotWithProduction
export def "subscriptions-resource-groups-providers-microsoft-web-sites-slotsswap SwapSlotWithProduction" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --preserveVnet: oneof<nothing, bool> # <code>true</code> to preserve Virtual Network to the slot during swap; otherwise, <code>false</code>.
  targetSlot: string # Destination deployment slot during swap operation.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/slotsswap" $qp)
  let body = {preserveVnet: $preserveVnet, targetSlot: $targetSlot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all Snapshots to the user.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/snapshots
# operationId: WebApps_ListSnapshots
export def "subscriptions-resource-groups-providers-microsoft-web-sites-snapshots ListSnapshots" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all Snapshots to the user from DRSecondary endpoint.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/snapshotsdr
# operationId: WebApps_ListSnapshotsFromDRSecondary
export def "subscriptions-resource-groups-providers-microsoft-web-sites-snapshotsdr ListSnapshotsFromDRSecondary" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/snapshotsdr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the source control configuration of an app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: WebApps_DeleteSourceControl
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web DeleteSourceControl" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/sourcecontrols/web" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the source control configuration of an app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: WebApps_GetSourceControl
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web GetSourceControl" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/sourcecontrols/web" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the source control configuration of an app.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: WebApps_UpdateSourceControl
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web UpdateSourceControl" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteSourceControl resource specific properties — shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/sourcecontrols/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the source control configuration of an app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# operationId: WebApps_CreateOrUpdateSourceControl
# --properties shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sourcecontrols-web CreateOrUpdateSourceControl" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # SiteSourceControl resource specific properties — shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/sourcecontrols/web" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/start
# operationId: WebApps_Start
export def "subscriptions-resource-groups-providers-microsoft-web-sites-start Start" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/startNetworkTrace
# operationId: WebApps_StartNetworkTrace
export def "subscriptions-resource-groups-providers-microsoft-web-sites-start-network-trace StartNetworkTrace" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --durationInSeconds: int # The duration to keep capturing in seconds. (format: int32)
  --maxFrameLength: int # The maximum frame length in bytes (Optional). (format: int32)
  --sasUrl: string # The Blob URL to store capture file.
  --api-version: string # API Version
]: nothing -> table<message: string, path: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationInSeconds" $durationInSeconds "scalar") (serialize-qp "maxFrameLength" $maxFrameLength "scalar") (serialize-qp "sasUrl" $sasUrl "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/startNetworkTrace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops an app (or deployment slot, if specified).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/stop
# operationId: WebApps_Stop
export def "subscriptions-resource-groups-providers-microsoft-web-sites-stop Stop" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop ongoing capturing network packets for the site.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/stopNetworkTrace
# operationId: WebApps_StopNetworkTrace
export def "subscriptions-resource-groups-providers-microsoft-web-sites-stop-network-trace StopNetworkTrace" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/stopNetworkTrace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sync web app repository.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sync
# operationId: WebApps_SyncRepository
export def "subscriptions-resource-groups-providers-microsoft-web-sites-sync SyncRepository" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Syncs function trigger metadata to the scale controller
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/syncfunctiontriggers
# operationId: WebApps_SyncFunctionTriggers
export def "subscriptions-resource-groups-providers-microsoft-web-sites-syncfunctiontriggers SyncFunctionTriggers" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/syncfunctiontriggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List triggered web jobs for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/triggeredwebjobs
# operationId: WebApps_ListTriggeredWebJobs
export def "subscriptions-resource-groups-providers-microsoft-web-sites-triggeredwebjobs ListTriggeredWebJobs" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/triggeredwebjobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a triggered web job by its ID for an app, or a deployment slot.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/triggeredwebjobs/{webJobName}
# operationId: WebApps_DeleteTriggeredWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-triggeredwebjobs DeleteTriggeredWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/triggeredwebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a triggered web job by its ID for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/triggeredwebjobs/{webJobName}
# operationId: WebApps_GetTriggeredWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-triggeredwebjobs GetTriggeredWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<error: string, extra_info_url: string, history_url: string, latest_run: record<properties: record>, run_command: string, scheduler_logs_url: string, settings: record, url: string, using_sdk: bool, web_job_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/triggeredwebjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a triggered web job's history for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/triggeredwebjobs/{webJobName}/history
# operationId: WebApps_ListTriggeredWebJobHistory
export def "subscriptions-resource-groups-providers-microsoft-web-sites-triggeredwebjobs-history ListTriggeredWebJobHistory" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/triggeredwebjobs/($webJobName)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a triggered web job's history by its ID for an app, , or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/triggeredwebjobs/{webJobName}/history/{id}
# operationId: WebApps_GetTriggeredWebJobHistory
export def "subscriptions-resource-groups-providers-microsoft-web-sites-triggeredwebjobs-history GetTriggeredWebJobHistory" [
  resourceGroupName: string
  name: string
  webJobName: string
  id: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<runs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/triggeredwebjobs/($webJobName)/history/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a triggered web job for an app, or a deployment slot.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/triggeredwebjobs/{webJobName}/run
# operationId: WebApps_RunTriggeredWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-triggeredwebjobs-run RunTriggeredWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/triggeredwebjobs/($webJobName)/run" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the quota usage information of an app (or deployment slot, if specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/usages
# operationId: WebApps_ListUsages
export def "subscriptions-resource-groups-providers-microsoft-web-sites-usages ListUsages" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Return only information specified in the filter (using OData syntax). For example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq 2014-01-01T00:00:00Z and endTime eq 2014-12-31T23:59:59Z and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/usages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the virtual networks the app (or deployment slot) is connected to.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections
# operationId: WebApps_ListVnetConnections
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections ListVnetConnections" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a connection from an app (or deployment slot to a named virtual network.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_DeleteVnetConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections DeleteVnetConnection" [
  resourceGroupName: string
  name: string
  vnetName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections/($vnetName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a virtual network the app (or deployment slot) is connected to by name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_GetVnetConnection
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections GetVnetConnection" [
  resourceGroupName: string
  name: string
  vnetName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections/($vnetName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a Virtual Network connection to an app or slot (PUT) or updates the connection properties (PATCH).
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_UpdateVnetConnection
# --properties shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections UpdateVnetConnection" [
  resourceGroupName: string
  name: string
  vnetName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetInfo resource specific properties — shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections/($vnetName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a Virtual Network connection to an app or slot (PUT) or updates the connection properties (PATCH).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# operationId: WebApps_CreateOrUpdateVnetConnection
# --properties shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections CreateOrUpdateVnetConnection" [
  resourceGroupName: string
  name: string
  vnetName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetInfo resource specific properties — shape: {certBlob?: string, dnsServers?: string, isSwift?: bool, vnetResourceId?: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, isSwift: bool, resyncRequired: bool, routes: list<record>, vnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections/($vnetName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets an app's Virtual Network gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: WebApps_GetVnetConnectionGateway
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections-gateways GetVnetConnectionGateway" [
  resourceGroupName: string
  name: string
  vnetName: string
  gatewayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections/($vnetName)/gateways/($gatewayName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a gateway to a connected Virtual Network (PUT) or updates it (PATCH).
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: WebApps_UpdateVnetConnectionGateway
# --properties shape: {vnetName?: string, vpnPackageUri: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections-gateways UpdateVnetConnectionGateway" [
  resourceGroupName: string
  name: string
  vnetName: string
  gatewayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetGateway resource specific properties — shape: {vnetName?: string, vpnPackageUri: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections/($vnetName)/gateways/($gatewayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a gateway to a connected Virtual Network (PUT) or updates it (PATCH).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# operationId: WebApps_CreateOrUpdateVnetConnectionGateway
# --properties shape: {vnetName?: string, vpnPackageUri: string}
export def "subscriptions-resource-groups-providers-microsoft-web-sites-virtual-network-connections-gateways CreateOrUpdateVnetConnectionGateway" [
  resourceGroupName: string
  name: string
  vnetName: string
  gatewayName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
  --properties: any # VnetGateway resource specific properties — shape: {vnetName?: string, vpnPackageUri: string}
  --kind: string # Kind of resource.
]: any -> record<properties: record<vnetName: string, vpnPackageUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/virtualNetworkConnections/($vnetName)/gateways/($gatewayName)" $qp)
  let body = {properties: $properties, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List webjobs for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/webjobs
# operationId: WebApps_ListWebJobs
export def "subscriptions-resource-groups-providers-microsoft-web-sites-webjobs ListWebJobs" [
  resourceGroupName: string
  name: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/webjobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webjob information for an app, or a deployment slot.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/webjobs/{webJobName}
# operationId: WebApps_GetWebJob
export def "subscriptions-resource-groups-providers-microsoft-web-sites-webjobs GetWebJob" [
  resourceGroupName: string
  name: string
  webJobName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API Version
]: nothing -> record<properties: record<error: string, extra_info_url: string, run_command: string, settings: record, url: string, using_sdk: bool, web_job_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Web/sites/($name)/webjobs/($webJobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
