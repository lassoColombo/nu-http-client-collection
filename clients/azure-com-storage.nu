# Auto-generated client for StorageManagementClient v2019-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/storage/2019-04-01/swagger.json
# Auth: --token flag or $env.STORAGEMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STORAGEMANAGEMENTCLIENT_TOKEN | default "" }
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
def type-completer [] { ["Microsoft.Storage/storageAccounts"] }
def expand-completer [] { ["geoReplicationStats"] }
def kind-completer [] { ["BlobStorage" "BlockBlobStorage" "FileStorage" "Storage" "StorageV2"] }
def signedPermission-completer [] { ["a" "c" "d" "l" "p" "r" "u" "w"] }
def signedProtocol-completer [] { ["https" "https,http"] }
def signedResourceTypes-completer [] { ["c" "o" "s"] }
def signedServices-completer [] { ["b" "f" "q" "t"] }
def signedResource-completer [] { ["b" "c" "f" "s"] }
def expand-completer-1 [] { ["kerb"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-storage-operations List" } } | get name | first)
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

# Lists all of the available Storage Rest API operations.
#
# GET /providers/Microsoft.Storage/operations
# operationId: Operations_List
export def "providers-microsoft-storage-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Storage/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks that the storage account name is valid and is not already in use.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Storage/checkNameAvailability
# operationId: StorageAccounts_CheckNameAvailability
export def "subscriptions-providers-microsoft-storage-check-name-availability CheckNameAvailability" [
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
  name: string # The storage account name.
  type: string@type-completer # The type of resource, Microsoft.Storage/storageAccounts
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Storage/checkNameAvailability" $qp)
  let body = {name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the current usage count and the limit for the resources of the location under the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Storage/locations/{location}/usages
# operationId: Usages_ListByLocation
export def "subscriptions-providers-microsoft-storage-locations-usages ListByLocation" [
  subscriptionId: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<currentValue: int, limit: int, name: record, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Storage/locations/($location)/usages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the available SKUs supported by Microsoft.Storage for given subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Storage/skus
# operationId: Skus_List
export def "subscriptions-providers-microsoft-storage-skus List" [
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
]: nothing -> record<value: table<capabilities: list, kind: string, locations: list, name: string, resourceType: string, restrictions: list, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Storage/skus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the storage accounts available under the subscription. Note that storage keys are not returned; use the ListKeys operation for this.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Storage/storageAccounts
# operationId: StorageAccounts_List
export def "subscriptions-providers-microsoft-storage-storage-accounts List" [
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
]: nothing -> record<nextLink: string, value: table<identity: record, kind: string, properties: record, sku: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Storage/storageAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the storage accounts available under the given resource group. Note that storage keys are not returned; use the ListKeys operation for this.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts
# operationId: StorageAccounts_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts ListByResourceGroup" [
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
]: nothing -> record<nextLink: string, value: table<identity: record, kind: string, properties: record, sku: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a storage account in Microsoft Azure.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}
# operationId: StorageAccounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts Delete" [
  resourceGroupName: string
  accountName: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the properties for the specified storage account including but not limited to name, SKU name, location, and account status. The ListKeys operation should be used to retrieve storage keys.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}
# operationId: StorageAccounts_GetProperties
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts GetProperties" [
  resourceGroupName: string
  accountName: string
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
  --expand: string@expand-completer # May be used to expand the properties within account's properties. By default, data is not included when fetching properties. Currently we only support geoReplicationStats.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string>, kind: string, properties: record<accessTier: string, azureFilesIdentityBasedAuthentication: record<activeDirectoryProperties: record, directoryServiceOptions: string>, creationTime: string, customDomain: record<name: string, useSubDomainName: bool>, encryption: record<keySource: string, keyvaultproperties: record, services: record>, failoverInProgress: bool, geoReplicationStats: record<canFailover: bool, lastSyncTime: string, status: string>, isHnsEnabled: bool, largeFileSharesState: string, lastGeoFailoverTime: string, networkAcls: record<bypass: string, defaultAction: string, ipRules: list, virtualNetworkRules: list>, primaryEndpoints: record<blob: string, dfs: string, file: string, queue: string, table: string, web: string>, primaryLocation: string, provisioningState: string, secondaryEndpoints: record<blob: string, dfs: string, file: string, queue: string, table: string, web: string>, secondaryLocation: string, statusOfPrimary: string, statusOfSecondary: string, supportsHttpsTrafficOnly: bool>, sku: record<capabilities: list<record>, kind: string, locations: list<string>, name: string, resourceType: string, restrictions: list<record>, tier: string>, location: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The update operation can be used to update the SKU, encryption, access tier, or tags for a storage account. It can also be used to map the account to a custom domain. Only one custom domain is supported per storage account; the replacement/change of custom domain is not supported. In order to replace an old custom domain, the old value must be cleared/unregistered before a new value can be set. The update of multiple properties is supported. This call does not change the storage keys for the account. If you want to change the storage account keys, use the regenerate keys operation. The location and name of the storage account cannot be changed after creation.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}
# operationId: StorageAccounts_Update
# --identity shape: {type: "SystemAssigned"}
# --properties shape: {accessTier?: "Hot"|"Cool", azureFilesIdentityBasedAuthentication?: any, customDomain?: any, encryption?: any, largeFileSharesState?: "Disabled"|"Enabled", networkAcls?: any, supportsHttpsTrafficOnly?: bool}
# --sku shape: {name: "Standard_LRS"|"Standard_GRS"|"Standard_RAGRS"|"Standard_ZRS"|"Premium_LRS"|"Premium_ZRS"|"Standard_GZRS"|"Standard_RAGZRS", restrictions?: list}
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts Update" [
  resourceGroupName: string
  accountName: string
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
  --identity: any # Identity for the resource. — shape: {type: "SystemAssigned"}
  --kind: string@kind-completer # Optional. Indicates the type of storage account. Currently only StorageV2 value supported by server.
  --properties: any # The parameters used when updating a storage account. — shape: {accessTier?: "Hot"|"Cool", azureFilesIdentityBasedAuthentication?: any, customDomain?: any, encryption?: any, largeFileSharesState?: "Disabled"|"Enabled", networkAcls?: any, supportsHttpsTrafficOnly?: bool}
  --sku: any # The SKU of the storage account. — shape: {name: "Standard_LRS"|"Standard_GRS"|"Standard_RAGRS"|"Standard_ZRS"|"Premium_LRS"|"Premium_ZRS"|"Standard_GZRS"|"Standard_RAGZRS", restrictions?: list}
  --tags: record # Gets or sets a list of key value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key no greater in length than 128 characters and a value no greater in length than 256 characters.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, kind: string, properties: record<accessTier: string, azureFilesIdentityBasedAuthentication: record<activeDirectoryProperties: record, directoryServiceOptions: string>, creationTime: string, customDomain: record<name: string, useSubDomainName: bool>, encryption: record<keySource: string, keyvaultproperties: record, services: record>, failoverInProgress: bool, geoReplicationStats: record<canFailover: bool, lastSyncTime: string, status: string>, isHnsEnabled: bool, largeFileSharesState: string, lastGeoFailoverTime: string, networkAcls: record<bypass: string, defaultAction: string, ipRules: list, virtualNetworkRules: list>, primaryEndpoints: record<blob: string, dfs: string, file: string, queue: string, table: string, web: string>, primaryLocation: string, provisioningState: string, secondaryEndpoints: record<blob: string, dfs: string, file: string, queue: string, table: string, web: string>, secondaryLocation: string, statusOfPrimary: string, statusOfSecondary: string, supportsHttpsTrafficOnly: bool>, sku: record<capabilities: list<record>, kind: string, locations: list<string>, name: string, resourceType: string, restrictions: list<record>, tier: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)" $qp)
  let body = {identity: $identity, kind: $kind, properties: $properties, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Asynchronously creates a new storage account with the specified parameters. If an account is already created and a subsequent create request is issued with different properties, the account properties will be updated. If an account is already created and a subsequent create or update request is issued with the exact same set of properties, the request will succeed.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}
# operationId: StorageAccounts_Create
# --identity shape: {type: "SystemAssigned"}
# --properties shape: {accessTier?: "Hot"|"Cool", azureFilesIdentityBasedAuthentication?: any, customDomain?: any, encryption?: any, isHnsEnabled?: bool, largeFileSharesState?: "Disabled"|"Enabled", networkAcls?: any, supportsHttpsTrafficOnly?: bool}
# --sku shape: {name: "Standard_LRS"|"Standard_GRS"|"Standard_RAGRS"|"Standard_ZRS"|"Premium_LRS"|"Premium_ZRS"|"Standard_GZRS"|"Standard_RAGZRS", restrictions?: list}
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts Create" [
  resourceGroupName: string
  accountName: string
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
  --identity: any # Identity for the resource. — shape: {type: "SystemAssigned"}
  kind: string@kind-completer # Required. Indicates the type of storage account.
  location: string # Required. Gets or sets the location of the resource. This will be one of the supported and registered Azure Geo Regions (e.g. West US, East US, Southeast Asia, etc.). The geo region of a resource cannot be changed once it is created, but if an identical geo region is specified on update, the request will succeed.
  --properties: any # The parameters used to create the storage account. — shape: {accessTier?: "Hot"|"Cool", azureFilesIdentityBasedAuthentication?: any, customDomain?: any, encryption?: any, isHnsEnabled?: bool, largeFileSharesState?: "Disabled"|"Enabled", networkAcls?: any, supportsHttpsTrafficOnly?: bool}
  sku: any # The SKU of the storage account. — shape: {name: "Standard_LRS"|"Standard_GRS"|"Standard_RAGRS"|"Standard_ZRS"|"Premium_LRS"|"Premium_ZRS"|"Standard_GZRS"|"Standard_RAGZRS", restrictions?: list}
  --tags: record # Gets or sets a list of key value pairs that describe the resource. These tags can be used for viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key with a length no greater than 128 characters and a value with a length no greater than 256 characters.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, kind: string, properties: record<accessTier: string, azureFilesIdentityBasedAuthentication: record<activeDirectoryProperties: record, directoryServiceOptions: string>, creationTime: string, customDomain: record<name: string, useSubDomainName: bool>, encryption: record<keySource: string, keyvaultproperties: record, services: record>, failoverInProgress: bool, geoReplicationStats: record<canFailover: bool, lastSyncTime: string, status: string>, isHnsEnabled: bool, largeFileSharesState: string, lastGeoFailoverTime: string, networkAcls: record<bypass: string, defaultAction: string, ipRules: list, virtualNetworkRules: list>, primaryEndpoints: record<blob: string, dfs: string, file: string, queue: string, table: string, web: string>, primaryLocation: string, provisioningState: string, secondaryEndpoints: record<blob: string, dfs: string, file: string, queue: string, table: string, web: string>, secondaryLocation: string, statusOfPrimary: string, statusOfSecondary: string, supportsHttpsTrafficOnly: bool>, sku: record<capabilities: list<record>, kind: string, locations: list<string>, name: string, resourceType: string, restrictions: list<record>, tier: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)" $qp)
  let body = {identity: $identity, kind: $kind, location: $location, properties: $properties, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List SAS credentials of a storage account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/ListAccountSas
# operationId: StorageAccounts_ListAccountSAS
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-list-account-sas ListAccountSAS" [
  resourceGroupName: string
  accountName: string
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
  --keyToSign: string # The key to sign the account SAS token with.
  signedExpiry: string # The time at which the shared access signature becomes invalid. (format: date-time)
  --signedIp: string # An IP address or a range of IP addresses from which to accept requests.
  signedPermission: string@signedPermission-completer # The signed permissions for the account SAS. Possible values include: Read (r), Write (w), Delete (d), List (l), Add (a), Create (c), Update (u) and Process (p).
  --signedProtocol: string@signedProtocol-completer # The protocol permitted for a request made with the account SAS.
  signedResourceTypes: string@signedResourceTypes-completer # The signed resource types that are accessible with the account SAS. Service (s): Access to service-level APIs; Container (c): Access to container-level APIs; Object (o): Access to object-level APIs for blobs, queue messages, table entities, and files.
  signedServices: string@signedServices-completer # The signed services accessible with the account SAS. Possible values include: Blob (b), Queue (q), Table (t), File (f).
  --signedStart: string # The time at which the SAS becomes valid. (format: date-time)
]: any -> record<accountSasToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/ListAccountSas" $qp)
  let body = {keyToSign: $keyToSign, signedExpiry: $signedExpiry, signedIp: $signedIp, signedPermission: $signedPermission, signedProtocol: $signedProtocol, signedResourceTypes: $signedResourceTypes, signedServices: $signedServices, signedStart: $signedStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List service SAS credentials of a specific resource.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/ListServiceSas
# operationId: StorageAccounts_ListServiceSAS
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-list-service-sas ListServiceSAS" [
  resourceGroupName: string
  accountName: string
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
  canonicalizedResource: string # The canonical path to the signed resource.
  --endPk: string # The end of partition key.
  --endRk: string # The end of row key.
  --keyToSign: string # The key to sign the account SAS token with.
  --rscc: string # The response header override for cache control.
  --rscd: string # The response header override for content disposition.
  --rsce: string # The response header override for content encoding.
  --rscl: string # The response header override for content language.
  --rsct: string # The response header override for content type.
  --signedExpiry: string # The time at which the shared access signature becomes invalid. (format: date-time)
  --signedIdentifier: string # A unique value up to 64 characters in length that correlates to an access policy specified for the container, queue, or table.
  --signedIp: string # An IP address or a range of IP addresses from which to accept requests.
  --signedPermission: string@signedPermission-completer # The signed permissions for the service SAS. Possible values include: Read (r), Write (w), Delete (d), List (l), Add (a), Create (c), Update (u) and Process (p).
  --signedProtocol: string@signedProtocol-completer # The protocol permitted for a request made with the account SAS.
  --signedResource: string@signedResource-completer # The signed services accessible with the service SAS. Possible values include: Blob (b), Container (c), File (f), Share (s).
  --signedStart: string # The time at which the SAS becomes valid. (format: date-time)
  --startPk: string # The start of partition key.
  --startRk: string # The start of row key.
]: any -> record<serviceSasToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/ListServiceSas" $qp)
  let body = {canonicalizedResource: $canonicalizedResource, endPk: $endPk, endRk: $endRk, keyToSign: $keyToSign, rscc: $rscc, rscd: $rscd, rsce: $rsce, rscl: $rscl, rsct: $rsct, signedExpiry: $signedExpiry, signedIdentifier: $signedIdentifier, signedIp: $signedIp, signedPermission: $signedPermission, signedProtocol: $signedProtocol, signedResource: $signedResource, signedStart: $signedStart, startPk: $startPk, startRk: $startRk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Failover request can be triggered for a storage account in case of availability issues. The failover occurs from the storage account's primary cluster to secondary cluster for RA-GRS accounts. The secondary cluster will become primary after failover.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/failover
# operationId: StorageAccounts_Failover
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-failover Failover" [
  resourceGroupName: string
  accountName: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/failover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the access keys or Kerberos keys (if active directory enabled) for the specified storage account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/listKeys
# operationId: StorageAccounts_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-list-keys ListKeys" [
  resourceGroupName: string
  accountName: string
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
  --expand: string@expand-completer-1 # Specifies type of the key to be listed. Possible value is kerb.
]: nothing -> record<keys: table<keyName: string, permissions: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the managementpolicy associated with the specified storage account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/managementPolicies/{managementPolicyName}
# operationId: ManagementPolicies_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-management-policies Delete" [
  resourceGroupName: string
  accountName: string
  subscriptionId: string
  managementPolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/managementPolicies/($managementPolicyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the managementpolicy associated with the specified storage account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/managementPolicies/{managementPolicyName}
# operationId: ManagementPolicies_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-management-policies Get" [
  resourceGroupName: string
  accountName: string
  subscriptionId: string
  managementPolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<lastModifiedTime: string, policy: record<rules: list>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/managementPolicies/($managementPolicyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the managementpolicy to the specified storage account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/managementPolicies/{managementPolicyName}
# operationId: ManagementPolicies_CreateOrUpdate
# --properties shape: {policy: any}
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-management-policies CreateOrUpdate" [
  resourceGroupName: string
  accountName: string
  subscriptionId: string
  managementPolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: any # The Storage Account ManagementPolicy properties. — shape: {policy: any}
]: any -> record<properties: record<lastModifiedTime: string, policy: record<rules: list>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/managementPolicies/($managementPolicyName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Regenerates one of the access keys or Kerberos keys for the specified storage account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/regenerateKey
# operationId: StorageAccounts_RegenerateKey
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-regenerate-key RegenerateKey" [
  resourceGroupName: string
  accountName: string
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
  keyName: string # The name of storage keys that want to be regenerated, possible values are key1, key2, kerb1, kerb2.
]: any -> record<keys: table<keyName: string, permissions: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/regenerateKey" $qp)
  let body = {keyName: $keyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke user delegation keys.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{accountName}/revokeUserDelegationKeys
# operationId: StorageAccounts_RevokeUserDelegationKeys
export def "subscriptions-resource-groups-providers-microsoft-storage-storage-accounts-revoke-user-delegation-keys RevokeUserDelegationKeys" [
  resourceGroupName: string
  accountName: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Storage/storageAccounts/($accountName)/revokeUserDelegationKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
