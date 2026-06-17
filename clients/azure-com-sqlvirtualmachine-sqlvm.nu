# Auto-generated client for SqlVirtualMachineManagementClient v2017-03-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/sqlvirtualmachine-sqlvm/2017-03-01-preview/swagger.json
# Auth: --token flag or $env.SQLVIRTUALMACHINEMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SQLVIRTUALMACHINEMANAGEMENTCLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-sql-virtual-machine-operations list" } } | get name | first)
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

# Lists all of the available SQL Rest API operations.
#
# GET /providers/Microsoft.SqlVirtualMachine/operations
# operationId: Operations_List
export def "providers-microsoft-sql-virtual-machine-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.SqlVirtualMachine/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all SQL virtual machine groups in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups
# operationId: SqlVirtualMachineGroups_List
export def "subscriptions-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all SQL virtual machines in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines
# operationId: SqlVirtualMachines_List
export def "subscriptions-providers-microsoft-sql-virtual-machine-sql-virtual-machines list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all SQL virtual machine groups in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups
# operationId: SqlVirtualMachineGroups_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups list-by" [
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
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a SQL virtual machine group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups delete" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a SQL virtual machine group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups get" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<properties: record<clusterConfiguration: string, clusterManagerType: string, provisioningState: string, scaleType: string, sqlImageOffer: string, sqlImageSku: string, wsfcDomainProfile: record<clusterBootstrapAccount: string, clusterOperatorAccount: string, domainFqdn: string, fileShareWitnessPath: string, ouPath: string, sqlServiceAccount: string, storageAccountPrimaryKey: string, storageAccountUrl: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates SQL virtual machine group tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_Update
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --tags: record # Resource tags.
]: any -> record<properties: record<clusterConfiguration: string, clusterManagerType: string, provisioningState: string, scaleType: string, sqlImageOffer: string, sqlImageSku: string, wsfcDomainProfile: record<clusterBootstrapAccount: string, clusterOperatorAccount: string, domainFqdn: string, fileShareWitnessPath: string, ouPath: string, sqlServiceAccount: string, storageAccountPrimaryKey: string, storageAccountUrl: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp)
  let body = {"tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a SQL virtual machine group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}
# operationId: SqlVirtualMachineGroups_CreateOrUpdate
# --properties shape: {sqlImageOffer?: string, sqlImageSku?: "Developer"|"Enterprise", wsfcDomainProfile?: record}
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups create-or-update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --properties: record # The properties of a SQL virtual machine group. — shape: {sqlImageOffer?: string, sqlImageSku?: "Developer"|"Enterprise", wsfcDomainProfile?: record}
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<properties: record<clusterConfiguration: string, clusterManagerType: string, provisioningState: string, scaleType: string, sqlImageOffer: string, sqlImageSku: string, wsfcDomainProfile: record<clusterBootstrapAccount: string, clusterOperatorAccount: string, domainFqdn: string, fileShareWitnessPath: string, ouPath: string, sqlServiceAccount: string, storageAccountPrimaryKey: string, storageAccountUrl: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}") $qp)
  let body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all availability group listeners in a SQL virtual machine group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners
# operationId: AvailabilityGroupListeners_ListByGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-listeners list-by" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an availability group listener.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners/{availabilityGroupListenerName}
# operationId: AvailabilityGroupListeners_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-listeners delete" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  availability_group_listener_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name, availability_group_listener_name: $availability_group_listener_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners/{availability_group_listener_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an availability group listener.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners/{availabilityGroupListenerName}
# operationId: AvailabilityGroupListeners_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-listeners get" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  availability_group_listener_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<properties: record<availabilityGroupName: string, createDefaultAvailabilityGroupIfNotExist: bool, loadBalancerConfigurations: list<record>, port: int, provisioningState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name, availability_group_listener_name: $availability_group_listener_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners/{availability_group_listener_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an availability group listener.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/availabilityGroupListeners/{availabilityGroupListenerName}
# operationId: AvailabilityGroupListeners_CreateOrUpdate
# --properties shape: {availabilityGroupName?: string, createDefaultAvailabilityGroupIfNotExist?: bool, loadBalancerConfigurations?: list, port?: int}
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-availability-group-listeners create-or-update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  availability_group_listener_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --properties: record # The properties of an availability group listener. — shape: {availabilityGroupName?: string, createDefaultAvailabilityGroupIfNotExist?: bool, loadBalancerConfigurations?: list, port?: int}
]: any -> record<properties: record<availabilityGroupName: string, createDefaultAvailabilityGroupIfNotExist: bool, loadBalancerConfigurations: list<record>, port: int, provisioningState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name, availability_group_listener_name: $availability_group_listener_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/availabilityGroupListeners/{availability_group_listener_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of sql virtual machines in a SQL virtual machine group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sqlVirtualMachineGroupName}/sqlVirtualMachines
# operationId: SqlVirtualMachines_ListBySqlVmGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machine-groups-sql-virtual-machines list-by-sql-vm" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_group_name: $sql_virtual_machine_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups/{sql_virtual_machine_group_name}/sqlVirtualMachines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all SQL virtual machines in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines
# operationId: SqlVirtualMachines_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines list-by" [
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
  --api-version: string # API version to use for the request.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a SQL virtual machine.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_Delete
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines delete" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_name: $sql_virtual_machine_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a SQL virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_Get
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines get" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # The child resources to include in the response.
  --api-version: string # API version to use for the request.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<autoBackupSettings: record<backupScheduleType: string, backupSystemDbs: bool, enable: bool, enableEncryption: bool, fullBackupFrequency: string, fullBackupStartTime: int, fullBackupWindowHours: int, logBackupFrequency: int, password: string, retentionPeriod: int, storageAccessKey: string, storageAccountUrl: string>, autoPatchingSettings: record<dayOfWeek: string, enable: bool, maintenanceWindowDuration: int, maintenanceWindowStartingHour: int>, keyVaultCredentialSettings: record<azureKeyVaultUrl: string, credentialName: string, enable: bool, servicePrincipalName: string, servicePrincipalSecret: string>, provisioningState: string, serverConfigurationsManagementSettings: record<additionalFeaturesServerConfigurations: record, sqlConnectivityUpdateSettings: record, sqlStorageUpdateSettings: record, sqlWorkloadTypeUpdateSettings: record>, sqlImageOffer: string, sqlImageSku: string, sqlManagement: string, sqlServerLicenseType: string, sqlVirtualMachineGroupResourceId: string, storageConfigurationSettings: record<diskConfigurationType: string, sqlDataSettings: record, sqlLogSettings: record, sqlTempDbSettings: record, storageWorkloadType: string>, virtualMachineResourceId: string, wsfcDomainCredentials: record<clusterBootstrapAccountPassword: string, clusterOperatorAccountPassword: string, sqlServiceAccountPassword: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_name: $sql_virtual_machine_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a SQL virtual machine.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_Update
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --tags: record # Resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<autoBackupSettings: record<backupScheduleType: string, backupSystemDbs: bool, enable: bool, enableEncryption: bool, fullBackupFrequency: string, fullBackupStartTime: int, fullBackupWindowHours: int, logBackupFrequency: int, password: string, retentionPeriod: int, storageAccessKey: string, storageAccountUrl: string>, autoPatchingSettings: record<dayOfWeek: string, enable: bool, maintenanceWindowDuration: int, maintenanceWindowStartingHour: int>, keyVaultCredentialSettings: record<azureKeyVaultUrl: string, credentialName: string, enable: bool, servicePrincipalName: string, servicePrincipalSecret: string>, provisioningState: string, serverConfigurationsManagementSettings: record<additionalFeaturesServerConfigurations: record, sqlConnectivityUpdateSettings: record, sqlStorageUpdateSettings: record, sqlWorkloadTypeUpdateSettings: record>, sqlImageOffer: string, sqlImageSku: string, sqlManagement: string, sqlServerLicenseType: string, sqlVirtualMachineGroupResourceId: string, storageConfigurationSettings: record<diskConfigurationType: string, sqlDataSettings: record, sqlLogSettings: record, sqlTempDbSettings: record, storageWorkloadType: string>, virtualMachineResourceId: string, wsfcDomainCredentials: record<clusterBootstrapAccountPassword: string, clusterOperatorAccountPassword: string, sqlServiceAccountPassword: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_name: $sql_virtual_machine_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp)
  let body = {"tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a SQL virtual machine.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sqlVirtualMachineName}
# operationId: SqlVirtualMachines_CreateOrUpdate
# --identity shape: {type?: "SystemAssigned"}
# --properties shape: {autoBackupSettings?: record, autoPatchingSettings?: record, keyVaultCredentialSettings?: record, serverConfigurationsManagementSettings?: record, sqlImageOffer?: string, sqlImageSku?: "Developer"|"Express"|"Standard"|"Enterprise"|"Web", sqlManagement?: "Full"|"LightWeight"|"NoAgent", sqlServerLicenseType?: "PAYG"|"AHUB"|"DR", sqlVirtualMachineGroupResourceId?: string, storageConfigurationSettings?: record, virtualMachineResourceId?: string, wsfcDomainCredentials?: record}
export def "subscriptions-resource-groups-providers-microsoft-sql-virtual-machine-sql-virtual-machines create-or-update" [
  subscription_id: string
  resource_group_name: string
  sql_virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use for the request.
  --identity: record # Azure Active Directory identity configuration for a resource. — shape: {type?: "SystemAssigned"}
  --properties: record # The SQL virtual machine properties. — shape: {autoBackupSettings?: record, autoPatchingSettings?: record, keyVaultCredentialSettings?: record, serverConfigurationsManagementSettings?: record, sqlImageOffer?: string, sqlImageSku?: "Developer"|"Express"|"Standard"|"Enterprise"|"Web", sqlManagement?: "Full"|"LightWeight"|"NoAgent", sqlServerLicenseType?: "PAYG"|"AHUB"|"DR", sqlVirtualMachineGroupResourceId?: string, storageConfigurationSettings?: record, virtualMachineResourceId?: string, wsfcDomainCredentials?: record}
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string>, properties: record<autoBackupSettings: record<backupScheduleType: string, backupSystemDbs: bool, enable: bool, enableEncryption: bool, fullBackupFrequency: string, fullBackupStartTime: int, fullBackupWindowHours: int, logBackupFrequency: int, password: string, retentionPeriod: int, storageAccessKey: string, storageAccountUrl: string>, autoPatchingSettings: record<dayOfWeek: string, enable: bool, maintenanceWindowDuration: int, maintenanceWindowStartingHour: int>, keyVaultCredentialSettings: record<azureKeyVaultUrl: string, credentialName: string, enable: bool, servicePrincipalName: string, servicePrincipalSecret: string>, provisioningState: string, serverConfigurationsManagementSettings: record<additionalFeaturesServerConfigurations: record, sqlConnectivityUpdateSettings: record, sqlStorageUpdateSettings: record, sqlWorkloadTypeUpdateSettings: record>, sqlImageOffer: string, sqlImageSku: string, sqlManagement: string, sqlServerLicenseType: string, sqlVirtualMachineGroupResourceId: string, storageConfigurationSettings: record<diskConfigurationType: string, sqlDataSettings: record, sqlLogSettings: record, sqlTempDbSettings: record, storageWorkloadType: string>, virtualMachineResourceId: string, wsfcDomainCredentials: record<clusterBootstrapAccountPassword: string, clusterOperatorAccountPassword: string, sqlServiceAccountPassword: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, sql_virtual_machine_name: $sql_virtual_machine_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines/{sql_virtual_machine_name}") $qp)
  let body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
