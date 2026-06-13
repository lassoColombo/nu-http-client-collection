# Auto-generated client for ContainerServiceClient v2019-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/containerservice-managedClusters/2019-08-01/swagger.json
# Auth: --token flag or $env.CONTAINERSERVICECLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONTAINERSERVICECLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-container-service-operations List" } } | get name | first)
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

# Gets a list of compute operations.
#
# GET /providers/Microsoft.ContainerService/operations
# operationId: Operations_List
export def "providers-microsoft-container-service-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ContainerService/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of managed clusters in the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.ContainerService/managedClusters
# operationId: ManagedClusters_List
export def "subscriptions-providers-microsoft-container-service-managed-clusters List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, tags: record, type: string, identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.ContainerService/managedClusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists managed clusters in the specified subscription and resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters
# operationId: ManagedClusters_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters ListByResourceGroup" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, tags: record, type: string, identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a managed cluster.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}
# operationId: ManagedClusters_Delete
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters Delete" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a managed cluster.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}
# operationId: ManagedClusters_Get
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters Get" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, location: string, name: string, tags: record, type: string, identity: record<principalId: string, tenantId: string, type: string>, properties: record<aadProfile: record<clientAppID: string, serverAppID: string, serverAppSecret: string, tenantID: string>, addonProfiles: any, agentPoolProfiles: list<record>, apiServerAccessProfile: record<authorizedIPRanges: list, enablePrivateCluster: bool>, dnsPrefix: string, enablePodSecurityPolicy: bool, enableRBAC: bool, fqdn: string, kubernetesVersion: string, linuxProfile: record<adminUsername: string, ssh: record>, maxAgentPools: int, networkProfile: record<dnsServiceIP: string, dockerBridgeCidr: string, loadBalancerProfile: record, loadBalancerSku: string, networkPlugin: string, networkPolicy: string, podCidr: string, serviceCidr: string>, nodeResourceGroup: string, provisioningState: string, servicePrincipalProfile: record<clientId: string, secret: string>, windowsProfile: record<adminPassword: string, adminUsername: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates tags on a managed cluster.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}
# operationId: ManagedClusters_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters UpdateTags" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --tags: record # Resource tags.
]: any -> record<id: string, location: string, name: string, tags: record, type: string, identity: record<principalId: string, tenantId: string, type: string>, properties: record<aadProfile: record<clientAppID: string, serverAppID: string, serverAppSecret: string, tenantID: string>, addonProfiles: any, agentPoolProfiles: list<record>, apiServerAccessProfile: record<authorizedIPRanges: list, enablePrivateCluster: bool>, dnsPrefix: string, enablePodSecurityPolicy: bool, enableRBAC: bool, fqdn: string, kubernetesVersion: string, linuxProfile: record<adminUsername: string, ssh: record>, maxAgentPools: int, networkProfile: record<dnsServiceIP: string, dockerBridgeCidr: string, loadBalancerProfile: record, loadBalancerSku: string, networkPlugin: string, networkPolicy: string, podCidr: string, serviceCidr: string>, nodeResourceGroup: string, provisioningState: string, servicePrincipalProfile: record<clientId: string, secret: string>, windowsProfile: record<adminPassword: string, adminUsername: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)" $qp)
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a managed cluster.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}
# operationId: ManagedClusters_CreateOrUpdate
# --identity shape: {type?: "SystemAssigned"|"None"}
# --properties shape: {aadProfile?: any, addonProfiles?: any, agentPoolProfiles?: list, apiServerAccessProfile?: any, dnsPrefix?: string, enablePodSecurityPolicy?: bool, enableRBAC?: bool, kubernetesVersion?: string, linuxProfile?: any, networkProfile?: any, nodeResourceGroup?: string, servicePrincipalProfile?: any, windowsProfile?: any}
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  location: string # Resource location
  --tags: record # Resource tags
  --identity: any # Identity for the managed cluster. — shape: {type?: "SystemAssigned"|"None"}
  --properties: any # Properties of the managed cluster. — shape: {aadProfile?: any, addonProfiles?: any, agentPoolProfiles?: list, apiServerAccessProfile?: any, dnsPrefix?: string, enablePodSecurityPolicy?: bool, enableRBAC?: bool, kubernetesVersion?: string, linuxProfile?: any, networkProfile?: any, nodeResourceGroup?: string, servicePrincipalProfile?: any, windowsProfile?: any}
]: any -> record<id: string, location: string, name: string, tags: record, type: string, identity: record<principalId: string, tenantId: string, type: string>, properties: record<aadProfile: record<clientAppID: string, serverAppID: string, serverAppSecret: string, tenantID: string>, addonProfiles: any, agentPoolProfiles: list<record>, apiServerAccessProfile: record<authorizedIPRanges: list, enablePrivateCluster: bool>, dnsPrefix: string, enablePodSecurityPolicy: bool, enableRBAC: bool, fqdn: string, kubernetesVersion: string, linuxProfile: record<adminUsername: string, ssh: record>, maxAgentPools: int, networkProfile: record<dnsServiceIP: string, dockerBridgeCidr: string, loadBalancerProfile: record, loadBalancerSku: string, networkPlugin: string, networkPolicy: string, podCidr: string, serviceCidr: string>, nodeResourceGroup: string, provisioningState: string, servicePrincipalProfile: record<clientId: string, secret: string>, windowsProfile: record<adminPassword: string, adminUsername: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)" $qp)
  let body = {location: $location, tags: $tags, identity: $identity, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets an access profile of a managed cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/accessProfiles/{roleName}/listCredential
# operationId: ManagedClusters_GetAccessProfile
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-access-profiles-list-credential GetAccessProfile" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  roleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, location: string, name: string, tags: record, type: string, properties: record<kubeConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/accessProfiles/($roleName)/listCredential" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of agent pools in the specified managed cluster.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/agentPools
# operationId: AgentPools_List
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-agent-pools List" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, type: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/agentPools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an agent pool.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/agentPools/{agentPoolName}
# operationId: AgentPools_Delete
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-agent-pools Delete" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  agentPoolName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/agentPools/($agentPoolName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the agent pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/agentPools/{agentPoolName}
# operationId: AgentPools_Get
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-agent-pools Get" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  agentPoolName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, type: string, properties: record<availabilityZones: list<string>, count: int, enableAutoScaling: bool, enableNodePublicIP: bool, maxCount: int, maxPods: int, minCount: int, nodeTaints: list<string>, orchestratorVersion: string, osDiskSizeGB: int, osType: string, provisioningState: string, scaleSetEvictionPolicy: string, scaleSetPriority: string, type: string, vmSize: string, vnetSubnetID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/agentPools/($agentPoolName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an agent pool.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/agentPools/{agentPoolName}
# operationId: AgentPools_CreateOrUpdate
# --properties shape: {availabilityZones?: list, count?: int, enableAutoScaling?: bool, enableNodePublicIP?: bool, maxCount?: int, maxPods?: int, minCount?: int, nodeTaints?: list, orchestratorVersion?: string, osDiskSizeGB?: int, osType?: "Linux"|"Windows", scaleSetEvictionPolicy?: "Delete"|"Deallocate", scaleSetPriority?: "Low"|"Regular", type?: "VirtualMachineScaleSets"|"AvailabilitySet", vmSize?: "Standard_A1"|"Standard_A10"|"Standard_A11"|"Standard_A1_v2"|"Standard_A2"|"Standard_A2_v2"|"Standard_A2m_v2"|"Standard_A3"|"Standard_A4"|"Standard_A4_v2"|"Standard_A4m_v2"|"Standard_A5"|"Standard_A6"|"Standard_A7"|"Standard_A8"|"Standard_A8_v2"|"Standard_A8m_v2"|"Standard_A9"|"Standard_B2ms"|"Standard_B2s"|"Standard_B4ms"|"Standard_B8ms"|"Standard_D1"|"Standard_D11"|"Standard_D11_v2"|"Standard_D11_v2_Promo"|"Standard_D12"|"Standard_D12_v2"|"Standard_D12_v2_Promo"|"Standard_D13"|"Standard_D13_v2"|"Standard_D13_v2_Promo"|"Standard_D14"|"Standard_D14_v2"|"Standard_D14_v2_Promo"|"Standard_D15_v2"|"Standard_D16_v3"|"Standard_D16s_v3"|"Standard_D1_v2"|"Standard_D2"|"Standard_D2_v2"|"Standard_D2_v2_Promo"|"Standard_D2_v3"|"Standard_D2s_v3"|"Standard_D3"|"Standard_D32_v3"|"Standard_D32s_v3"|"Standard_D3_v2"|"Standard_D3_v2_Promo"|"Standard_D4"|"Standard_D4_v2"|"Standard_D4_v2_Promo"|"Standard_D4_v3"|"Standard_D4s_v3"|"Standard_D5_v2"|"Standard_D5_v2_Promo"|"Standard_D64_v3"|"Standard_D64s_v3"|"Standard_D8_v3"|"Standard_D8s_v3"|"Standard_DS1"|"Standard_DS11"|"Standard_DS11_v2"|"Standard_DS11_v2_Promo"|"Standard_DS12"|"Standard_DS12_v2"|"Standard_DS12_v2_Promo"|"Standard_DS13"|"Standard_DS13-2_v2"|"Standard_DS13-4_v2"|"Standard_DS13_v2"|"Standard_DS13_v2_Promo"|"Standard_DS14"|"Standard_DS14-4_v2"|"Standard_DS14-8_v2"|"Standard_DS14_v2"|"Standard_DS14_v2_Promo"|"Standard_DS15_v2"|"Standard_DS1_v2"|"Standard_DS2"|"Standard_DS2_v2"|"Standard_DS2_v2_Promo"|"Standard_DS3"|"Standard_DS3_v2"|"Standard_DS3_v2_Promo"|"Standard_DS4"|"Standard_DS4_v2"|"Standard_DS4_v2_Promo"|"Standard_DS5_v2"|"Standard_DS5_v2_Promo"|"Standard_E16_v3"|"Standard_E16s_v3"|"Standard_E2_v3"|"Standard_E2s_v3"|"Standard_E32-16s_v3"|"Standard_E32-8s_v3"|"Standard_E32_v3"|"Standard_E32s_v3"|"Standard_E4_v3"|"Standard_E4s_v3"|"Standard_E64-16s_v3"|"Standard_E64-32s_v3"|"Standard_E64_v3"|"Standard_E64s_v3"|"Standard_E8_v3"|"Standard_E8s_v3"|"Standard_F1"|"Standard_F16"|"Standard_F16s"|"Standard_F16s_v2"|"Standard_F1s"|"Standard_F2"|"Standard_F2s"|"Standard_F2s_v2"|"Standard_F32s_v2"|"Standard_F4"|"Standard_F4s"|"Standard_F4s_v2"|"Standard_F64s_v2"|"Standard_F72s_v2"|"Standard_F8"|"Standard_F8s"|"Standard_F8s_v2"|"Standard_G1"|"Standard_G2"|"Standard_G3"|"Standard_G4"|"Standard_G5"|"Standard_GS1"|"Standard_GS2"|"Standard_GS3"|"Standard_GS4"|"Standard_GS4-4"|"Standard_GS4-8"|"Standard_GS5"|"Standard_GS5-16"|"Standard_GS5-8"|"Standard_H16"|"Standard_H16m"|"Standard_H16mr"|"Standard_H16r"|"Standard_H8"|"Standard_H8m"|"Standard_L16s"|"Standard_L32s"|"Standard_L4s"|"Standard_L8s"|"Standard_M128-32ms"|"Standard_M128-64ms"|"Standard_M128ms"|"Standard_M128s"|"Standard_M64-16ms"|"Standard_M64-32ms"|"Standard_M64ms"|"Standard_M64s"|"Standard_NC12"|"Standard_NC12s_v2"|"Standard_NC12s_v3"|"Standard_NC24"|"Standard_NC24r"|"Standard_NC24rs_v2"|"Standard_NC24rs_v3"|"Standard_NC24s_v2"|"Standard_NC24s_v3"|"Standard_NC6"|"Standard_NC6s_v2"|"Standard_NC6s_v3"|"Standard_ND12s"|"Standard_ND24rs"|"Standard_ND24s"|"Standard_ND6s"|"Standard_NV12"|"Standard_NV24"|"Standard_NV6", vnetSubnetID?: string}
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-agent-pools CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  agentPoolName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # Properties for the container service agent pool profile. — shape: {availabilityZones?: list, count?: int, enableAutoScaling?: bool, enableNodePublicIP?: bool, maxCount?: int, maxPods?: int, minCount?: int, nodeTaints?: list, orchestratorVersion?: string, osDiskSizeGB?: int, osType?: "Linux"|"Windows", scaleSetEvictionPolicy?: "Delete"|"Deallocate", scaleSetPriority?: "Low"|"Regular", type?: "VirtualMachineScaleSets"|"AvailabilitySet", vmSize?: "Standard_A1"|"Standard_A10"|"Standard_A11"|"Standard_A1_v2"|"Standard_A2"|"Standard_A2_v2"|"Standard_A2m_v2"|"Standard_A3"|"Standard_A4"|"Standard_A4_v2"|"Standard_A4m_v2"|"Standard_A5"|"Standard_A6"|"Standard_A7"|"Standard_A8"|"Standard_A8_v2"|"Standard_A8m_v2"|"Standard_A9"|"Standard_B2ms"|"Standard_B2s"|"Standard_B4ms"|"Standard_B8ms"|"Standard_D1"|"Standard_D11"|"Standard_D11_v2"|"Standard_D11_v2_Promo"|"Standard_D12"|"Standard_D12_v2"|"Standard_D12_v2_Promo"|"Standard_D13"|"Standard_D13_v2"|"Standard_D13_v2_Promo"|"Standard_D14"|"Standard_D14_v2"|"Standard_D14_v2_Promo"|"Standard_D15_v2"|"Standard_D16_v3"|"Standard_D16s_v3"|"Standard_D1_v2"|"Standard_D2"|"Standard_D2_v2"|"Standard_D2_v2_Promo"|"Standard_D2_v3"|"Standard_D2s_v3"|"Standard_D3"|"Standard_D32_v3"|"Standard_D32s_v3"|"Standard_D3_v2"|"Standard_D3_v2_Promo"|"Standard_D4"|"Standard_D4_v2"|"Standard_D4_v2_Promo"|"Standard_D4_v3"|"Standard_D4s_v3"|"Standard_D5_v2"|"Standard_D5_v2_Promo"|"Standard_D64_v3"|"Standard_D64s_v3"|"Standard_D8_v3"|"Standard_D8s_v3"|"Standard_DS1"|"Standard_DS11"|"Standard_DS11_v2"|"Standard_DS11_v2_Promo"|"Standard_DS12"|"Standard_DS12_v2"|"Standard_DS12_v2_Promo"|"Standard_DS13"|"Standard_DS13-2_v2"|"Standard_DS13-4_v2"|"Standard_DS13_v2"|"Standard_DS13_v2_Promo"|"Standard_DS14"|"Standard_DS14-4_v2"|"Standard_DS14-8_v2"|"Standard_DS14_v2"|"Standard_DS14_v2_Promo"|"Standard_DS15_v2"|"Standard_DS1_v2"|"Standard_DS2"|"Standard_DS2_v2"|"Standard_DS2_v2_Promo"|"Standard_DS3"|"Standard_DS3_v2"|"Standard_DS3_v2_Promo"|"Standard_DS4"|"Standard_DS4_v2"|"Standard_DS4_v2_Promo"|"Standard_DS5_v2"|"Standard_DS5_v2_Promo"|"Standard_E16_v3"|"Standard_E16s_v3"|"Standard_E2_v3"|"Standard_E2s_v3"|"Standard_E32-16s_v3"|"Standard_E32-8s_v3"|"Standard_E32_v3"|"Standard_E32s_v3"|"Standard_E4_v3"|"Standard_E4s_v3"|"Standard_E64-16s_v3"|"Standard_E64-32s_v3"|"Standard_E64_v3"|"Standard_E64s_v3"|"Standard_E8_v3"|"Standard_E8s_v3"|"Standard_F1"|"Standard_F16"|"Standard_F16s"|"Standard_F16s_v2"|"Standard_F1s"|"Standard_F2"|"Standard_F2s"|"Standard_F2s_v2"|"Standard_F32s_v2"|"Standard_F4"|"Standard_F4s"|"Standard_F4s_v2"|"Standard_F64s_v2"|"Standard_F72s_v2"|"Standard_F8"|"Standard_F8s"|"Standard_F8s_v2"|"Standard_G1"|"Standard_G2"|"Standard_G3"|"Standard_G4"|"Standard_G5"|"Standard_GS1"|"Standard_GS2"|"Standard_GS3"|"Standard_GS4"|"Standard_GS4-4"|"Standard_GS4-8"|"Standard_GS5"|"Standard_GS5-16"|"Standard_GS5-8"|"Standard_H16"|"Standard_H16m"|"Standard_H16mr"|"Standard_H16r"|"Standard_H8"|"Standard_H8m"|"Standard_L16s"|"Standard_L32s"|"Standard_L4s"|"Standard_L8s"|"Standard_M128-32ms"|"Standard_M128-64ms"|"Standard_M128ms"|"Standard_M128s"|"Standard_M64-16ms"|"Standard_M64-32ms"|"Standard_M64ms"|"Standard_M64s"|"Standard_NC12"|"Standard_NC12s_v2"|"Standard_NC12s_v3"|"Standard_NC24"|"Standard_NC24r"|"Standard_NC24rs_v2"|"Standard_NC24rs_v3"|"Standard_NC24s_v2"|"Standard_NC24s_v3"|"Standard_NC6"|"Standard_NC6s_v2"|"Standard_NC6s_v3"|"Standard_ND12s"|"Standard_ND24rs"|"Standard_ND24s"|"Standard_ND6s"|"Standard_NV12"|"Standard_NV24"|"Standard_NV6", vnetSubnetID?: string}
]: any -> record<id: string, name: string, type: string, properties: record<availabilityZones: list<string>, count: int, enableAutoScaling: bool, enableNodePublicIP: bool, maxCount: int, maxPods: int, minCount: int, nodeTaints: list<string>, orchestratorVersion: string, osDiskSizeGB: int, osType: string, provisioningState: string, scaleSetEvictionPolicy: string, scaleSetPriority: string, type: string, vmSize: string, vnetSubnetID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/agentPools/($agentPoolName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets upgrade profile for an agent pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/agentPools/{agentPoolName}/upgradeProfiles/default
# operationId: AgentPools_GetUpgradeProfile
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-agent-pools-upgrade-profiles-default GetUpgradeProfile" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  agentPoolName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<kubernetesVersion: string, osType: string, upgrades: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/agentPools/($agentPoolName)/upgradeProfiles/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of supported versions for the specified agent pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/availableAgentPoolVersions
# operationId: AgentPools_GetAvailableAgentPoolVersions
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-available-agent-pool-versions GetAvailableAgentPoolVersions" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<agentPoolVersions: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/availableAgentPoolVersions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets cluster admin credential of a managed cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/listClusterAdminCredential
# operationId: ManagedClusters_ListClusterAdminCredentials
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-list-cluster-admin-credential ListClusterAdminCredentials" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<kubeconfigs: table<name: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/listClusterAdminCredential" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets cluster user credential of a managed cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/listClusterUserCredential
# operationId: ManagedClusters_ListClusterUserCredentials
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-list-cluster-user-credential ListClusterUserCredentials" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<kubeconfigs: table<name: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/listClusterUserCredential" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset AAD Profile of a managed cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/resetAADProfile
# operationId: ManagedClusters_ResetAADProfile
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-reset-aad-profile ResetAADProfile" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  clientAppID: string # The client AAD application ID.
  serverAppID: string # The server AAD application ID.
  --serverAppSecret: string # The server AAD application secret.
  --tenantID: string # The AAD tenant ID to use for authentication. If not specified, will use the tenant of the deployment subscription.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/resetAADProfile" $qp)
  let body = {clientAppID: $clientAppID, serverAppID: $serverAppID, serverAppSecret: $serverAppSecret, tenantID: $tenantID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset Service Principal Profile of a managed cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/resetServicePrincipalProfile
# operationId: ManagedClusters_ResetServicePrincipalProfile
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-reset-service-principal-profile ResetServicePrincipalProfile" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  clientId: string # The ID for the service principal.
  --secret: string # The secret password associated with the service principal in plain text.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/resetServicePrincipalProfile" $qp)
  let body = {clientId: $clientId, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Rotate certificates of a managed cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/rotateClusterCertificates
# operationId: ManagedClusters_RotateClusterCertificates
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-rotate-cluster-certificates RotateClusterCertificates" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/rotateClusterCertificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets upgrade profile for a managed cluster.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/upgradeProfiles/default
# operationId: ManagedClusters_GetUpgradeProfile
export def "subscriptions-resource-groups-providers-microsoft-container-service-managed-clusters-upgrade-profiles-default GetUpgradeProfile" [
  subscriptionId: string
  resourceGroupName: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<agentPoolProfiles: list<record>, controlPlaneProfile: record<kubernetesVersion: string, name: string, osType: string, upgrades: list>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ContainerService/managedClusters/($resourceName)/upgradeProfiles/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
