# Auto-generated client for Microsoft Storage Sync v2019-03-01
# Source: https://api.apis.guru/v2/specs/azure.com/storagesync/2019-03-01/swagger.json
# Auth: --token flag or $env.MICROSOFT_STORAGE_SYNC_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MICROSOFT_STORAGE_SYNC_TOKEN | default "" }
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
def type-completer [] { ["Microsoft.StorageSync/storageSyncServices"] }
def change-detection-mode-completer [] { ["Default" "Recursive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-storage-sync-operations list" } } | get name | first)
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

# Lists all of the available Storage Sync Rest API operations.
#
# GET /providers/Microsoft.StorageSync/operations
# operationId: Operations_List
export def "providers-microsoft-storage-sync-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.StorageSync/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check the give namespace name availability.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.StorageSync/locations/{locationName}/checkNameAvailability
# operationId: StorageSyncServices_CheckNameAvailability
export def "subscriptions-providers-microsoft-storage-sync-locations-check-name-availability check" [
  subscription_id: string
  location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  name: string # The name to check for availability
  type: string@type-completer # The resource type. Must be set to Microsoft.StorageSync/storageSyncServices
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, location_name: $location_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.StorageSync/locations/{location_name}/checkNameAvailability") $qp)
  let body = {"name": $name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a StorageSyncService list by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.StorageSync/storageSyncServices
# operationId: StorageSyncServices_ListBySubscription
export def "subscriptions-providers-microsoft-storage-sync-storage-sync-services list-by" [
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
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.StorageSync/storageSyncServices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Operation status
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/locations/{locationName}/workflows/{workflowId}/operations/{operationId}
# operationId: OperationStatus_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-locations-workflows-operations get" [
  subscription_id: string
  resource_group_name: string
  location_name: string
  workflow_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<endTime: string, error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, name: string, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, location_name: $location_name, workflow_id: $workflow_id, operation_id: $operation_id} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/locations/{location_name}/workflows/{workflow_id}/operations/{operation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a StorageSyncService list by Resource group name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices
# operationId: StorageSyncServices_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services list-by" [
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
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a given StorageSyncService.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a given StorageSyncService.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<storageSyncServiceStatus: int, storageSyncServiceUid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a given StorageSyncService.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Update
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services update" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: record # Storage Sync Service Update Properties object.
  --tags: record # The user-specified tags associated with the storage sync service.
]: any -> record<properties: record<storageSyncServiceStatus: int, storageSyncServiceUid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp)
  let body = {"properties": $properties, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new StorageSyncService.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Create
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  location: string # Required. Gets or sets the location of the resource. This will be one of the supported and registered Azure Geo Regions (e.g. West US, East US, Southeast Asia, etc.). The geo region of a resource cannot be changed once it is created, but if an identical geo region is specified on update, the request will succeed.
  --properties: any
  --tags: record # Gets or sets a list of key value pairs that describe the resource. These tags can be used for viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key with a length no greater than 128 characters and a value with a length no greater than 256 characters.
]: any -> record<properties: record<storageSyncServiceStatus: int, storageSyncServiceUid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp)
  let body = {"location": $location, "properties": $properties, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a given registered server list.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers
# operationId: RegisteredServers_ListByStorageSyncService
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers list-by" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the given registered server.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}
# operationId: RegisteredServers_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, server_id: $server_id} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a given registered server.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}
# operationId: RegisteredServers_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<agentVersion: string, clusterId: string, clusterName: string, discoveryEndpointUri: string, friendlyName: string, lastHeartBeat: string, lastOperationName: string, lastWorkflowId: string, managementEndpointUri: string, monitoringConfiguration: string, provisioningState: string, resourceLocation: string, serverCertificate: string, serverId: string, serverManagementErrorCode: int, serverOSVersion: string, serverRole: string, serviceLocation: string, storageSyncServiceUid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, server_id: $server_id} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new registered server.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}
# operationId: RegisteredServers_Create
# --properties shape: {agentVersion?: string, clusterId?: string, clusterName?: string, friendlyName?: string, lastHeartBeat?: string, serverCertificate?: string, serverId?: string, serverOSVersion?: string, serverRole?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: any # shape: {agentVersion?: string, clusterId?: string, clusterName?: string, friendlyName?: string, lastHeartBeat?: string, serverCertificate?: string, serverId?: string, serverOSVersion?: string, serverRole?: string}
]: any -> record<properties: record<agentVersion: string, clusterId: string, clusterName: string, discoveryEndpointUri: string, friendlyName: string, lastHeartBeat: string, lastOperationName: string, lastWorkflowId: string, managementEndpointUri: string, monitoringConfiguration: string, provisioningState: string, resourceLocation: string, serverCertificate: string, serverId: string, serverManagementErrorCode: int, serverOSVersion: string, serverRole: string, serviceLocation: string, storageSyncServiceUid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, server_id: $server_id} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Triggers Server certificate rollover.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}/triggerRollover
# operationId: RegisteredServers_triggerRollover
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers-trigger-rollover trigger" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --server-certificate: string # Certificate Data
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, server_id: $server_id} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}/triggerRollover") $qp)
  let body = {"serverCertificate": $server_certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a SyncGroup List.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups
# operationId: SyncGroups_ListByStorageSyncService
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups list-by" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a given SyncGroup.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}
# operationId: SyncGroups_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a given SyncGroup.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}
# operationId: SyncGroups_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<syncGroupStatus: string, uniqueId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new SyncGroup.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}
# operationId: SyncGroups_Create
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: record # Sync Group Create Properties object.
]: any -> record<properties: record<syncGroupStatus: string, uniqueId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a CloudEndpoint List.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints
# operationId: CloudEndpoints_ListBySyncGroup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints list-by" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a given CloudEndpoint.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}
# operationId: CloudEndpoints_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a given CloudEndpoint.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}
# operationId: CloudEndpoints_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<azureFileShareName: string, backupEnabled: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, partnershipId: string, provisioningState: string, storageAccountResourceId: string, storageAccountTenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new CloudEndpoint.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}
# operationId: CloudEndpoints_Create
# --properties shape: {azureFileShareName?: string, friendlyName?: string, storageAccountResourceId?: string, storageAccountTenantId?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: any # CloudEndpoint Properties object. — shape: {azureFileShareName?: string, friendlyName?: string, storageAccountResourceId?: string, storageAccountTenantId?: string}
]: any -> record<properties: record<azureFileShareName: string, backupEnabled: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, partnershipId: string, provisioningState: string, storageAccountResourceId: string, storageAccountTenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Post Backup a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/postbackup
# operationId: CloudEndpoints_PostBackup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-postbackup create-backup" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share: string # Azure File Share.
]: any -> record<backupMetadata: record<cloudEndpointName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/postbackup") $qp)
  let body = {"azureFileShare": $azure_file_share} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Post Restore a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/postrestore
# operationId: CloudEndpoints_PostRestore
# --restoreFileSpec item shape: {path?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-postrestore create-restore" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share-uri: string # Post Restore Azure file share uri.
  --failed-file-list: string # Post Restore Azure failed file list.
  --partition: string # Post Restore partition.
  --replica-group: string # Post Restore replica group.
  --request-id: string # Post Restore request id.
  --restore-file-spec: list # Post Restore restore file spec array. — item shape: {path?: string}
  --source-azure-file-share-uri: string # Post Restore Azure source azure file share uri.
  --status: string # Post Restore Azure status.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/postrestore") $qp)
  let body = {"azureFileShareUri": $azure_file_share_uri, "failedFileList": $failed_file_list, "partition": $partition, "replicaGroup": $replica_group, "requestId": $request_id, "restoreFileSpec": $restore_file_spec, "sourceAzureFileShareUri": $source_azure_file_share_uri, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pre Backup a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/prebackup
# operationId: CloudEndpoints_PreBackup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-prebackup post" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share: string # Azure File Share.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/prebackup") $qp)
  let body = {"azureFileShare": $azure_file_share} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pre Restore a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/prerestore
# operationId: CloudEndpoints_PreRestore
# --restoreFileSpec item shape: {path?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-prerestore post" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share-uri: string # Pre Restore Azure file share uri.
  --backup-metadata-property-bag: string # Pre Restore backup metadata property bag.
  --partition: string # Pre Restore partition.
  --pause-wait-for-sync-drain-time-period-in-seconds: int # Pre Restore pause wait for sync drain time period in seconds.
  --replica-group: string # Pre Restore replica group.
  --request-id: string # Pre Restore request id.
  --restore-file-spec: list # Pre Restore restore file spec array. — item shape: {path?: string}
  --source-azure-file-share-uri: string # Pre Restore Azure source azure file share uri.
  --status: string # Pre Restore Azure status.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/prerestore") $qp)
  let body = {"azureFileShareUri": $azure_file_share_uri, "backupMetadataPropertyBag": $backup_metadata_property_bag, "partition": $partition, "pauseWaitForSyncDrainTimePeriodInSeconds": $pause_wait_for_sync_drain_time_period_in_seconds, "replicaGroup": $replica_group, "requestId": $request_id, "restoreFileSpec": $restore_file_spec, "sourceAzureFileShareUri": $source_azure_file_share_uri, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restore Heartbeat a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/restoreheartbeat
# operationId: CloudEndpoints_restoreheartbeat
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-restoreheartbeat restoreheartbeat" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/restoreheartbeat") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers detection of changes performed on Azure File share connected to the specified Azure File Sync Cloud Endpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/triggerChangeDetection
# operationId: CloudEndpoints_TriggerChangeDetection
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-trigger-change-detection trigger" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --change-detection-mode: string@change-detection-mode-completer # Change Detection Mode. Applies to a directory specified in directoryPath parameter.
  --directory-path: string # Relative path to a directory Azure File share for which change detection is to be performed.
  --paths: list # Array of relative paths on the Azure File share to be included in the change detection. Can be files and directories.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, cloud_endpoint_name: $cloud_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/triggerChangeDetection") $qp)
  let body = {"changeDetectionMode": $change_detection_mode, "directoryPath": $directory_path, "paths": $paths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a ServerEndpoint list.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints
# operationId: ServerEndpoints_ListBySyncGroup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints list-by" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a given ServerEndpoint.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, server_endpoint_name: $server_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ServerEndpoint.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<cloudTiering: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, offlineDataTransfer: string, offlineDataTransferShareName: string, offlineDataTransferStorageAccountResourceId: string, offlineDataTransferStorageAccountTenantId: string, provisioningState: string, serverLocalPath: string, serverResourceId: string, syncStatus: record<combinedHealth: string, downloadActivity: record, downloadHealth: string, downloadStatus: record, lastUpdatedTimestamp: string, offlineDataTransferStatus: string, syncActivity: string, totalPersistentFilesNotSyncingCount: int, uploadActivity: record, uploadHealth: string, uploadStatus: record>, tierFilesOlderThanDays: int, volumeFreeSpacePercent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, server_endpoint_name: $server_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a given ServerEndpoint.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Update
# --properties shape: {cloudTiering?: "on"|"off", offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints update" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: record # ServerEndpoint Update Properties object. — shape: {cloudTiering?: "on"|"off", offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
]: any -> record<properties: record<cloudTiering: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, offlineDataTransfer: string, offlineDataTransferShareName: string, offlineDataTransferStorageAccountResourceId: string, offlineDataTransferStorageAccountTenantId: string, provisioningState: string, serverLocalPath: string, serverResourceId: string, syncStatus: record<combinedHealth: string, downloadActivity: record, downloadHealth: string, downloadStatus: record, lastUpdatedTimestamp: string, offlineDataTransferStatus: string, syncActivity: string, totalPersistentFilesNotSyncingCount: int, uploadActivity: record, uploadHealth: string, uploadStatus: record>, tierFilesOlderThanDays: int, volumeFreeSpacePercent: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, server_endpoint_name: $server_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new ServerEndpoint.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Create
# --properties shape: {cloudTiering?: "on"|"off", friendlyName?: string, offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, serverLocalPath?: string, serverResourceId?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: any # ServerEndpoint Properties object. — shape: {cloudTiering?: "on"|"off", friendlyName?: string, offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, serverLocalPath?: string, serverResourceId?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
]: any -> record<properties: record<cloudTiering: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, offlineDataTransfer: string, offlineDataTransferShareName: string, offlineDataTransferStorageAccountResourceId: string, offlineDataTransferStorageAccountTenantId: string, provisioningState: string, serverLocalPath: string, serverResourceId: string, syncStatus: record<combinedHealth: string, downloadActivity: record, downloadHealth: string, downloadStatus: record, lastUpdatedTimestamp: string, offlineDataTransferStatus: string, syncActivity: string, totalPersistentFilesNotSyncingCount: int, uploadActivity: record, uploadHealth: string, uploadStatus: record>, tierFilesOlderThanDays: int, volumeFreeSpacePercent: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, server_endpoint_name: $server_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Recall a server endpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}/recallAction
# operationId: ServerEndpoints_recallAction
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints-recall-action recallAction" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --pattern: string # Pattern of the files.
  --recall-path: string # Recall path.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, sync_group_name: $sync_group_name, server_endpoint_name: $server_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}/recallAction") $qp)
  let body = {"pattern": $pattern, "recallPath": $recall_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a Workflow List
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/workflows
# operationId: Workflows_ListByStorageSyncService
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-workflows list-by" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/workflows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Workflows resource
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/workflows/{workflowId}
# operationId: Workflows_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-workflows get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<lastOperationId: string, lastStepName: string, operation: string, status: string, steps: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, workflow_id: $workflow_id} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/workflows/{workflow_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort the given workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/workflows/{workflowId}/abort
# operationId: Workflows_Abort
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-workflows-abort abort" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, storage_sync_service_name: $storage_sync_service_name, workflow_id: $workflow_id} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/workflows/{workflow_id}/abort") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
